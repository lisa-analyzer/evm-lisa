// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (crosschain/arbitrum/LibArbitrumL1.sol)

pragma solidity ^0.8.4;

import {IBridge as ArbitrumL1_Bridge} from "./IBridge.sol";
import {IInbox as ArbitrumL1_Inbox} from "./IInbox.sol";
import {IOutbox as ArbitrumL1_Outbox} from "./IOutbox.sol";
import "./errors.sol";

/**
 * @dev Primitives for cross-chain aware contracts for
 * https://arbitrum.io/[Arbitrum].
 *
 * This version should only be used on L1 to process cross-chain messages
 * originating from L2, or to send cross-chain messages from L1 to L2. For
 * the other side, use {LibArbitrumL2}.
 */
library LibArbitrumL1 {
    /**
     * @dev This is the first 4 bytes of the keccak256('Arbitrum-L1L2')
     */
    bytes4 public constant BRIDGE_ID = 0xf99ba2be;

    /**
     * @dev These are the parameters required for creating the Retryable Ticket in L2.
     *
     * NOTE: Refer to the https://developer.offchainlabs.com/docs/l1_l2_messages#parameters[Parameters Docs] in Arbitrum
     * for a detailed explanation of each param.
     *
     * @param bridgeId This Id is used to ensure this bridge only send messages intended for this bridge,
     * avoiding some unexpected scenarios if a config for a different bridge matches.
     */
    struct CrossChainTxParams {
        bytes4 bridgeId;
        uint256 depositValue;
        uint256 l2CallValue;
        uint256 maxSubmissionCost;
        address excessFeeRefundAddress;
        address callValueRefundAddress;
        uint256 maxGas;
        uint256 gasPriceBid;
    }

    /**
     * @dev Returns whether the current function call is the result of a
     * cross-chain message relayed by the `bridge`.
     */
    function isCrossChain(address bridge) internal view returns (bool) {
        return msg.sender == bridge;
    }

    /**
     * @dev Returns the address of the sender that triggered the current
     * cross-chain message through the `bridge`.
     *
     * NOTE: {isCrossChain} should be checked before trying to recover the
     * sender, as it will revert with `NotCrossChainCall` if the current
     * function call is not the result of a cross-chain message.
     */
    function crossChainSender(address bridge) internal view returns (address) {
        if (!isCrossChain(bridge)) revert NotCrossChainCall();

        address sender = ArbitrumL1_Outbox(ArbitrumL1_Bridge(bridge).activeOutbox()).l2ToL1Sender();
        require(sender != address(0), "LibArbitrumL1: system messages without sender");

        return sender;
    }

    /**
     * @dev Sends a cross-chain message from L1 to L2 via `Inbox`.
     * @param bridge The Bridge contract in the L1.
     * @param destination The address of the cross-chain target contract.
     * @param data The calldata of the cross-chain call.
     * @param crossChainTxParams An ABI encoded {CrossChainTxParams} representing the parameters required
     * for the message to be sent through the bridge.
     * @return ticketId A unique identifier for the Retryable Ticket created.
     */
    function sendCrossChainMessage(
        address bridge,
        address destination,
        bytes memory data,
        bytes memory crossChainTxParams
    ) internal returns (uint256 ticketId) {
        // there delayed inbox is the first of the allowedInboxList
        address delayedInbox = ArbitrumL1_Bridge(bridge).allowedInboxList(0);

        CrossChainTxParams memory params = abi.decode(crossChainTxParams, (CrossChainTxParams));

        if (BRIDGE_ID != params.bridgeId) revert InvalidTargetBridge(params.bridgeId, BRIDGE_ID);

        ticketId = ArbitrumL1_Inbox(delayedInbox).createRetryableTicket{value: params.depositValue}(
            destination,
            params.l2CallValue,
            params.maxSubmissionCost,
            params.excessFeeRefundAddress,
            params.callValueRefundAddress,
            params.maxGas,
            params.gasPriceBid,
            data
        );
    }
}
