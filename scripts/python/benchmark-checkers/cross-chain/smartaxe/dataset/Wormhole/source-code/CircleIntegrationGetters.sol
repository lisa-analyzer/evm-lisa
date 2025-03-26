// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.19;

import {IWormhole} from "wormhole/interfaces/IWormhole.sol";
import {ICircleBridge} from "../interfaces/circle/ICircleBridge.sol";
import {IMessageTransmitter} from "../interfaces/circle/IMessageTransmitter.sol";
import {ITokenMinter} from "../interfaces/circle/ITokenMinter.sol";

import {CircleIntegrationSetters} from "./CircleIntegrationSetters.sol";

contract CircleIntegrationGetters is CircleIntegrationSetters {
    /**
     * @notice isInitialized boolean for implementation (logic) contract
     * @param impl Address of implementation contract
     * @return IsInitialized bool
     */
    function isInitialized(address impl) public view returns (bool) {
        return _state.initializedImplementations[impl];
    }

    /**
     * @notice Wormhole contract interface
     * @return IWormhole interface
     */
    function wormhole() public view returns (IWormhole) {
        return IWormhole(_state.wormhole);
    }

    /**
     * @notice Wormhole chain ID of this chain
     * @return chainId uint16
     */
    function chainId() public view returns (uint16) {
        return _state.chainId;
    }

    /**
     * @notice Wormhole message finality
     * @return wormholeFinality uint8
     */
    function wormholeFinality() public view returns (uint8) {
        return _state.wormholeFinality;
    }

    /**
     * @notice Circle Bridge contract interface
     * @return ICircleBridge interface
     */
    function circleBridge() public view returns (ICircleBridge) {
        return ICircleBridge(_state.circleBridgeAddress);
    }

    /**
     * @notice Circle Transmitter contract interface
     * @return ICircleTransmitter interface
     */
    function circleTransmitter() public view returns (IMessageTransmitter) {
        return IMessageTransmitter(_state.circleTransmitterAddress);
    }

    /**
     * @notice Circle Token Minter contract interface
     * @return ITokenMinter interface
     */
    function circleTokenMinter() public view returns (ITokenMinter) {
        return ITokenMinter(_state.circleTokenMinterAddress);
    }

    /**
     * @notice Registered Circle Integration contracts on other blockchains
     * @param emitterChainId Wormhole chain ID for message sender
     * @return RegisteredEmitter bytes32
     */
    function getRegisteredEmitter(uint16 emitterChainId) public view returns (bytes32) {
        return _state.registeredEmitters[emitterChainId];
    }

    /**
     * @notice Circle Bridge registered token boolean
     * @param token Address of token being checked against the Circle TokenMinter
     * @return AcceptedToken bool
     */
    function isAcceptedToken(address token) public view returns (bool) {
        return circleTokenMinter().burnLimitsPerMessage(token) > 0;
    }

    /**
     * @notice Circle domain to Wormhole chain ID
     * @param chainId_ Wormhole chain ID
     * @return CircleDomain uint32
     */
    function getDomainFromChainId(uint16 chainId_) public view returns (uint32) {
        return _state.chainIdToDomain[chainId_];
    }

    /**
     * @notice Wormhole chain ID to Circle domain
     * @param domain Circle domain
     * @return chainId uint16
     */
    function getChainIdFromDomain(uint32 domain) public view returns (uint16) {
        return _state.domainToChainId[domain];
    }

    /**
     * @notice Checks if Wormhole message was already consumed by this contract
     * @param hash Wormhole message hash
     * @return IsMessageConsumed bool
     */
    function isMessageConsumed(bytes32 hash) public view returns (bool) {
        return _state.consumedMessages[hash];
    }

    /**
     * @notice Circle domain on this chain
     * @return LocalDomain uint32
     */
    function localDomain() public view returns (uint32) {
        return _state.localDomain;
    }

    /**
     * @notice Wormhole governance chain ID
     * @return GovernanceChainId uint16
     */
    function governanceChainId() public view returns (uint16) {
        return _state.governanceChainId;
    }

    /**
     * @notice Wormhole governance contract address (zero-left-padded address less than 32 bytes)
     * @return GovernanceContract bytes32
     */
    function governanceContract() public view returns (bytes32) {
        return _state.governanceContract;
    }

    /**
     * @notice EVM chain ID
     * @return EVMChainID uint256
     */
    function evmChain() public view returns (uint256) {
        return _state.evmChain;
    }
}