// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.19;

contract CircleIntegrationStorage {
    struct State {
        /// Wormhole chain ID of this contract
        uint16 chainId;

        /**
         * The number of block confirmations needed before the wormhole network
         * will attest a message.
         */
        uint8 wormholeFinality;

        /// Circle domain for this blockchain (grabbed from Circle's MessageTransmitter)
        uint32 localDomain;

        /// address of the Wormhole contract on this chain
        address wormhole;

        /// Wormhole governance chain ID
        uint16 governanceChainId;

        /// Wormhole governance contract address (bytes32 zero-left-padded)
        bytes32 governanceContract;

        /// address of the Circle Bridge contract on this chain
        address circleBridgeAddress;

        /// address of the Circle Message Transmitter on this chain
        address circleTransmitterAddress;

        /// address of the Circle Token Minter on this chain
        address circleTokenMinterAddress;

        /// mapping of initialized implementation (logic) contracts
        mapping(address => bool) initializedImplementations;

        /// Wormhole chain ID to known emitter address mapping
        mapping(uint16 => bytes32) registeredEmitters;

        /// Wormhole chain ID to Circle chain domain mapping
        mapping(uint16 => uint32) chainIdToDomain;

        /// Wormhole chain ID to Circle chain domain mapping
        mapping(uint32 => uint16) domainToChainId;

        /// verified Wormhole message hash to boolean
        mapping(bytes32 => bool) consumedMessages;

        /// expected EVM chain ID
        uint256 evmChain;

        /// storage gap for additional state variables in future versions
        uint256[50] ______gap;
    }
}

contract CircleIntegrationState {
    CircleIntegrationStorage.State _state;
}