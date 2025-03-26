// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.19;

import {ERC1967Upgrade} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";

import {IWormhole} from "wormhole/interfaces/IWormhole.sol";
import {BytesLib} from "wormhole/libraries/external/BytesLib.sol";

import {CircleIntegrationSetters} from "./CircleIntegrationSetters.sol";
import {CircleIntegrationGetters} from "./CircleIntegrationGetters.sol";
import {CircleIntegrationState} from "./CircleIntegrationState.sol";
import {ICircleIntegration} from "../interfaces/ICircleIntegration.sol";

contract CircleIntegrationGovernance is CircleIntegrationGetters, ERC1967Upgrade {
    using BytesLib for bytes;

    /**
     * @notice Emitted when implementation (logic) contracts are upgraded
     * @param oldContract Previous implementation contract address
     * @param newContract New implementation contract address
     */
    event ContractUpgraded(address indexed oldContract, address indexed newContract);

    /**
     * @notice Emitted when the Wormhole message finality state variable changes
     * @param oldFinality Previous `wormholeFinality` value
     * @param newFinality New `wormholeFinality` value
     */
    event WormholeFinalityUpdated(uint8 indexed oldFinality, uint8 indexed newFinality);

    // "CircleIntegration" (left-zero-padded)
    bytes32 constant GOVERNANCE_MODULE = 0x000000000000000000000000000000436972636c65496e746567726174696f6e;

    // for updating `wormholeFinality`
    uint8 constant GOVERNANCE_UPDATE_WORMHOLE_FINALITY = 1;
    uint256 constant GOVERNANCE_UPDATE_WORMHOLE_FINALITY_LENGTH = 36;

    // for registering an emitter (CircleIntegration contact on other blockchains) and Circle Bridge domain
    uint8 constant GOVERNANCE_REGISTER_EMITTER_AND_DOMAIN = 2;
    uint256 constant GOVERNANCE_REGISTER_EMITTER_AND_DOMAIN_LENGTH = 73;

    // for upgrading implementation (logic) contracts
    uint8 constant GOVERNANCE_UPGRADE_CONTRACT = 3;
    uint256 constant GOVERNANCE_UPGRADE_CONTRACT_LENGTH = 67;

    /**
     * @notice `updateWormholeFinality` changes the wormhole message consistencyLevel.
     * @param encodedMessage Attested Wormhole governance message with the following
     * relevant fields:
     * - Field Bytes Type Index
     * - finality 1 uint8 35
     */
    function updateWormholeFinality(bytes memory encodedMessage) public {
        bytes memory payload = verifyAndConsumeGovernanceMessage(encodedMessage, GOVERNANCE_UPDATE_WORMHOLE_FINALITY);
        require(payload.length == GOVERNANCE_UPDATE_WORMHOLE_FINALITY_LENGTH, "invalid governance payload length");

        // cache the current `wormholeFinality` value
        uint8 currentWormholeFinality = wormholeFinality();

        // updating finality should only be relevant for this contract's chain ID
        require(payload.toUint16(33) == chainId(), "invalid target chain");

        // parse the new `wormholeFinality` value at byte 35
        uint8 newWormholeFinality = payload.toUint8(35);
        require(newWormholeFinality > 0, "invalid finality");

        setWormholeFinality(newWormholeFinality);

        emit WormholeFinalityUpdated(currentWormholeFinality, newWormholeFinality);
    }

    /**
     * @notice `registerEmitterAndDomain` saves trusted CircleIntegration contract addresses
     * and Circle's chain domains.
     * @param encodedMessage Attested Wormhole governance message with the following
     * relevant fields:
     * - Field Bytes Type Index
     * - foreignEmitterChainId 2 uint16 35
     * - foreignEmitterAddress 32 bytes32 37
     * - domain 4 uint32 69
     */
    function registerEmitterAndDomain(bytes memory encodedMessage) public {
        bytes memory payload = verifyAndConsumeGovernanceMessage(encodedMessage, GOVERNANCE_REGISTER_EMITTER_AND_DOMAIN);
        require(payload.length == GOVERNANCE_REGISTER_EMITTER_AND_DOMAIN_LENGTH, "invalid governance payload length");

        // registering emitters should only be relevant for this contract's chain ID
        require(payload.toUint16(33) == chainId(), "invalid target chain");

        // emitterChainId at byte 35
        uint16 emitterChainId = payload.toUint16(35);
        require(emitterChainId > 0 && emitterChainId != chainId(), "invalid chain");
        require(getRegisteredEmitter(emitterChainId) == bytes32(0), "chain already registered");

        // emitterAddress at byte 37
        bytes32 emitterAddress = payload.toBytes32(37);
        require(emitterAddress != bytes32(0), "emitter cannot be zero address");

        // domain at byte 69 (hehe)
        uint32 domain = payload.toUint32(69);
        require(domain != localDomain(), "domain == localDomain()");

        // update the registeredEmitters state variable
        setEmitter(emitterChainId, emitterAddress);

        // update the chainId to domain (and domain to chainId) mappings
        setChainIdToDomain(emitterChainId, domain);
        setDomainToChainId(domain, emitterChainId);
    }

    /**
     * @notice `upgradeContract` upgrades the implementation (logic) contract and
     * initializes the new implementation.
     * @param encodedMessage Attested Wormhole governance message with the following
     * relevant fields:
     * - Field Bytes Type Index
     * - newImplementation 32 bytes32 35
     */
    function upgradeContract(bytes memory encodedMessage) public {
        bytes memory payload = verifyAndConsumeGovernanceMessage(encodedMessage, GOVERNANCE_UPGRADE_CONTRACT);
        require(payload.length == GOVERNANCE_UPGRADE_CONTRACT_LENGTH, "invalid governance payload length");

        // contract upgrades should only be relevant for this contract's chain ID
        require(payload.toUint16(33) == chainId(), "invalid target chain");

        address currentImplementation = _getImplementation();

        // newImplementation at byte 35 (32 bytes, but last 20 is the address)
        address newImplementation = readAddressFromBytes32(payload, 35);
        {
            (, bytes memory queried) =
                newImplementation.staticcall(abi.encodeWithSignature("circleIntegrationImplementation()"));
            require(queried.length == 32, "invalid implementation");
            require(
                abi.decode(queried, (bytes32)) == keccak256("circleIntegrationImplementation()"),
                "invalid implementation"
            );
        }

        _upgradeTo(newImplementation);

        // call initialize function of the new implementation
        (bool success, bytes memory reason) = newImplementation.delegatecall(abi.encodeWithSignature("initialize()"));
        require(success, string(reason));

        emit ContractUpgraded(currentImplementation, newImplementation);
    }

    function verifyAndConsumeGovernanceMessage(bytes memory encodedMessage, uint8 action)
        internal
        returns (bytes memory)
    {
        // verify the governance message
        (bytes32 messageHash, bytes memory payload) = verifyGovernanceMessage(encodedMessage, action);

        // store the hash for replay protection
        consumeMessage(messageHash);

        return payload;
    }

    /**
     * @notice `verifyGovernanceMessage` validates governance messages attested by
     * Wormhole's network of guardians.
     * @dev reverts if:
     * - the EVM blockchain has forked
     * - the governance message was not attested
     * - the governance message was generated on the wrong blockchain
     * - the governance message was already consumed
     * - the encoded governance module is incorrect
     * - the encoded governance action is incorrect
     * @param encodedMessage Attested Wormhole governance message with the following
     * relevant fields:
     * - Field Bytes Type Index
     * - governanceModule 32 bytes32 0
     * - governanceAction 1 uint8 32
     * @param action Expected governance action
     * @return messageHash Wormhole governance message hash
     * @return payload Verified Wormhole governance message payload
     */
    function verifyGovernanceMessage(bytes memory encodedMessage, uint8 action)
        public
        view
        returns (bytes32 messageHash, bytes memory payload)
    {
        // make sure the blockchain has not forked
        require(evmChain() == block.chainid, "invalid evm chain");

        // verify the governance message
        (IWormhole.VM memory vm, bool valid, string memory reason) = wormhole().parseAndVerifyVM(encodedMessage);
        require(valid, reason);

        // confirm that the governance message was sent from the governance contract
        require(vm.emitterChainId == governanceChainId(), "invalid governance chain");
        require(vm.emitterAddress == governanceContract(), "invalid governance contract");

        // confirm that this governance action has not been consumed already
        require(!isMessageConsumed(vm.hash), "governance action already consumed");

        // module at byte 0
        require(vm.payload.toBytes32(0) == GOVERNANCE_MODULE, "invalid governance module");

        // action at byte 32
        require(vm.payload.toUint8(32) == action, "invalid governance action");

        // set return values
        payload = vm.payload;
        messageHash = vm.hash;
    }

    function readAddressFromBytes32(bytes memory serialized, uint256 start) internal pure returns (address) {
        uint256 end = start + 12;
        for (uint256 i = start; i < end;) {
            require(serialized.toUint8(i) == 0, "invalid address");
            unchecked {
                i += 1;
            }
        }
        return serialized.toAddress(end);
    }
}