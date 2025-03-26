// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.19;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IWormhole} from "wormhole/interfaces/IWormhole.sol";
import {BytesLib} from "wormhole/libraries/external/BytesLib.sol";

import {ICircleBridge} from "../interfaces/circle/ICircleBridge.sol";

import {CircleIntegrationGovernance} from "./CircleIntegrationGovernance.sol";
import {CircleIntegrationMessages} from "./CircleIntegrationMessages.sol";

/**
 * @notice This contract burns and mints Circle-supported tokens by using Circle's Cross-Chain Transfer Protocol. It also emits
 * Wormhole messages with arbitrary payloads to allow for additional composability when performing cross-chain
 * transfers of Circle-suppored assets.
 */
contract CircleIntegration is CircleIntegrationMessages, CircleIntegrationGovernance, ReentrancyGuard {
    using BytesLib for bytes;

    /**
     * @notice Emitted when Circle-supported assets have been minted to the mintRecipient
     * @param emitterChainId Wormhole chain ID of emitter contract on source chain
     * @param emitterAddress Address (bytes32 zero-left-padded) of emitter on source chain
     * @param sequence Sequence of Wormhole message used to mint tokens
     */
    event Redeemed(uint16 indexed emitterChainId, bytes32 indexed emitterAddress, uint64 indexed sequence);

    /**
     * @notice `transferTokensWithPayload` calls the Circle Bridge contract to burn Circle-supported tokens. It emits
     * a Wormhole message containing a user-specified payload with instructions for what to do with
     * the Circle-supported assets once they have been minted on the target chain.
     * @dev reverts if:
     * - user passes insufficient value to pay Wormhole message fee
     * - `token` is not supported by Circle Bridge
     * - `amount` is zero
     * - `targetChain` is not supported
     * - `mintRecipient` is bytes32(0)
     * @param transferParams Struct containing the following attributes:
     * - `token` Address of the token to be burned
     * - `amount` Amount of `token` to be burned
     * - `targetChain` Wormhole chain ID of the target blockchain
     * - `mintRecipient` The recipient wallet or contract address on the target chain
     * @param batchId ID for Wormhole message batching
     * @param payload Arbitrary payload to be delivered to the target chain via Wormhole
     * @return messageSequence Wormhole sequence number for this contract
     */
    function transferTokensWithPayload(TransferParameters memory transferParams, uint32 batchId, bytes memory payload)
        public
        payable
        nonReentrant
        returns (uint64 messageSequence)
    {
        // cache wormhole instance and fees to save on gas
        IWormhole wormhole = wormhole();
        uint256 wormholeFee = wormhole.messageFee();

        // confirm that the caller has sent enough ether to pay for the wormhole message fee
        require(msg.value == wormholeFee, "insufficient value");

        // Call the circle bridge and `depositForBurnWithCaller`. The `mintRecipient`
        // should be the target contract (or wallet) composing on this contract.
        (uint64 nonce, uint256 amountReceived) = _transferTokens(
            transferParams.token, transferParams.amount, transferParams.targetChain, transferParams.mintRecipient
        );

        // encode DepositWithPayload message
        bytes memory encodedMessage = encodeDepositWithPayload(
            DepositWithPayload({
                token: addressToBytes32(transferParams.token),
                amount: amountReceived,
                sourceDomain: localDomain(),
                targetDomain: getDomainFromChainId(transferParams.targetChain),
                nonce: nonce,
                fromAddress: addressToBytes32(msg.sender),
                mintRecipient: transferParams.mintRecipient,
                payload: payload
            })
        );

        // send the DepositWithPayload wormhole message
        messageSequence = wormhole.publishMessage{value: wormholeFee}(batchId, encodedMessage, wormholeFinality());
    }

    function _transferTokens(address token, uint256 amount, uint16 targetChain, bytes32 mintRecipient)
        internal
        returns (uint64 nonce, uint256 amountReceived)
    {
        // sanity check user input
        require(amount > 0, "amount must be > 0");
        require(mintRecipient != bytes32(0), "invalid mint recipient");
        require(isAcceptedToken(token), "token not accepted");
        require(getRegisteredEmitter(targetChain) != bytes32(0), "target contract not registered");

        // take custody of tokens
        amountReceived = custodyTokens(token, amount);

        // cache Circle Bridge instance
        ICircleBridge circleBridge = circleBridge();

        // approve the Circle Bridge to spend tokens
        SafeERC20.safeApprove(IERC20(token), address(circleBridge), amountReceived);

        // burn tokens on the bridge
        nonce = circleBridge.depositForBurnWithCaller(
            amountReceived, getDomainFromChainId(targetChain), mintRecipient, token, getRegisteredEmitter(targetChain)
        );
    }

    function custodyTokens(address token, uint256 amount) internal returns (uint256) {
        // query own token balance before transfer
        (, bytes memory queriedBalanceBefore) =
            token.staticcall(abi.encodeWithSelector(IERC20.balanceOf.selector, address(this)));
        uint256 balanceBefore = abi.decode(queriedBalanceBefore, (uint256));

        // deposit tokens
        SafeERC20.safeTransferFrom(IERC20(token), msg.sender, address(this), amount);

        // query own token balance after transfer
        (, bytes memory queriedBalanceAfter) =
            token.staticcall(abi.encodeWithSelector(IERC20.balanceOf.selector, address(this)));
        uint256 balanceAfter = abi.decode(queriedBalanceAfter, (uint256));

        return balanceAfter - balanceBefore;
    }

    /**
     * @notice `redeemTokensWithPayload` verifies the Wormhole message from the source chain and
     * verifies that the passed Circle Bridge message is valid. It calls the Circle Bridge
     * contract by passing the Circle message and attestation to mint tokens to the specified
     * mint recipient. It also verifies that the caller is the specified mint recipient to ensure
     * atomic execution of the additional instructions in the Wormhole message.
     * @dev reverts if:
     * - Wormhole message is not properly attested
     * - Wormhole message was not emitted from a registered contrat
     * - Wormhole message was already consumed by this contract
     * - msg.sender is not the encoded mintRecipient
     * - Circle Bridge message and Wormhole message are not associated
     * - `receiveMessage` call to Circle Transmitter fails
     * @param params Struct containing the following attributes:
     * - `encodedWormholeMessage` Wormhole message emitted by a registered contract including
     * information regarding the token burn on the source chain and an arbitrary message.
     * - `circleBridgeMessage` Message emitted by Circle Bridge contract with information regarding
     * the token burn on the source chain.
     * - `circleAttestation` Serialized EC Signature attesting the cross-chain transfer
     * @return depositInfo Struct containing the following attributes:
     * - `token` Address (bytes32 left-zero-padded) of token to be minted
     * - `amount` Amount of tokens to be minted
     * - `sourceDomain` Circle domain for the source chain
     * - `targetDomain` Circle domain for the target chain
     * - `nonce` Circle sequence number for the transfer
     * - `fromAddress` Source CircleIntegration contract caller's address
     * - `mintRecipient` Recipient of minted tokens (must be caller of this contract)
     * - `payload` Arbitrary Wormhole message payload
     */
    function redeemTokensWithPayload(RedeemParameters calldata params)
        public
        returns (DepositWithPayload memory depositInfo)
    {
        // verify the wormhole message
        IWormhole.VM memory verifiedMessage = verifyWormholeRedeemMessage(params.encodedWormholeMessage);

        // Decode the message payload into the DepositWithPayload struct. Call the Circle TokenMinter
        // contract to determine the address of the encoded token on this chain.
        depositInfo = decodeDepositWithPayload(verifiedMessage.payload);
        depositInfo.token = fetchLocalTokenAddress(depositInfo.sourceDomain, depositInfo.token);

        // confirm that circle gave us a valid token address
        require(depositInfo.token != bytes32(0), "invalid local token address");

        // confirm that the caller is the `mintRecipient` to ensure atomic execution
        require(addressToBytes32(msg.sender) == depositInfo.mintRecipient, "caller must be mintRecipient");

        // confirm that the caller passed the correct message pair
        require(
            verifyCircleMessage(
                params.circleBridgeMessage, depositInfo.sourceDomain, depositInfo.targetDomain, depositInfo.nonce
            ),
            "invalid message pair"
        );

        // call the circle bridge to mint tokens to the recipient
        bool success = circleTransmitter().receiveMessage(params.circleBridgeMessage, params.circleAttestation);
        require(success, "CIRCLE_INTEGRATION: failed to mint tokens");

        // emit Redeemed event
        emit Redeemed(verifiedMessage.emitterChainId, verifiedMessage.emitterAddress, verifiedMessage.sequence);
    }

    function verifyWormholeRedeemMessage(bytes memory encodedMessage) internal returns (IWormhole.VM memory) {
        require(evmChain() == block.chainid, "invalid evm chain");

        // parse and verify the Wormhole core message
        (IWormhole.VM memory verifiedMessage, bool valid, string memory reason) =
            wormhole().parseAndVerifyVM(encodedMessage);

        // confirm that the core layer verified the message
        require(valid, reason);

        // verify that this message was emitted by a trusted contract
        require(verifyEmitter(verifiedMessage), "unknown emitter");

        // revert if this message has been consumed already
        require(!isMessageConsumed(verifiedMessage.hash), "message already consumed");
        consumeMessage(verifiedMessage.hash);

        return verifiedMessage;
    }

    function verifyEmitter(IWormhole.VM memory vm) internal view returns (bool) {
        // verify that the sender of the wormhole message is a trusted
        return (
            getRegisteredEmitter(vm.emitterChainId) == vm.emitterAddress &&
            vm.emitterAddress != bytes32(0)
        );
    }

    function verifyCircleMessage(bytes memory circleMessage, uint32 sourceDomain, uint32 targetDomain, uint64 nonce)
        internal
        pure
        returns (bool)
    {
        // parse the circle bridge message inline
        uint32 circleSourceDomain = circleMessage.toUint32(4);
        uint32 circleTargetDomain = circleMessage.toUint32(8);
        uint64 circleNonce = circleMessage.toUint64(12);

        // confirm that both the Wormhole message and Circle message share the same transfer info
        return (sourceDomain == circleSourceDomain && targetDomain == circleTargetDomain && nonce == circleNonce);
    }

    /**
     * @notice Fetches the local token address given an address and domain from
     * a different chain.
     * @param sourceDomain Circle domain for the sending chain.
     * @param sourceToken Address of the token for the sending chain.
     * @return Address bytes32 formatted address of the `sourceToken` on this chain.
     */
    function fetchLocalTokenAddress(uint32 sourceDomain, bytes32 sourceToken)
        public
        view
        returns (bytes32)
    {
        return addressToBytes32(
            circleTokenMinter().remoteTokensToLocalTokens(
                keccak256(abi.encodePacked(sourceDomain, sourceToken))
            )
        );
    }

    /**
     * @notice Converts type address to bytes32 (left-zero-padded)
     * @param address_ Address to convert to bytes32
     * @return Address bytes32
     */
    function addressToBytes32(address address_) public pure returns (bytes32) {
        return bytes32(uint256(uint160(address_)));
    }
}