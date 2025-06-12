// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity ^0.8.17;

import "./BridgeV2.sol";


contract GovBridgeV2 is BridgeV2 {

    /// @dev current protocol version
    uint64 public protocolVersion;
    /// @dev next protocol version, will be accepted fron next epoch
    uint64 public nextProtocolVersion;
    /// @dev current epoch start time
    uint256 public epochStartTime;
    /// @dev epoch min duration
    uint256 public epochMinDuration;
    /// @dev last request epoch update time
    uint256 public lastRequestEpochUpdateTime;
    /// @dev epoch min request update duration
    uint256 public epochMinRequestUpdateDuration;
    /// @dev node registry contract address
    address public nodeRegistry;

    event EpochUpdateRequested(uint32 currentEpochNum, uint64 protocolVersion);
    event ProtocolVersionUpdateRequested(uint64 version, uint64 nextVersion);
    event NodeRegistrySet(address nodeRegistry);
    event EpochMinDurationSet(uint256 epochMinDuration);
    event EpochMinRequestUpdateDurationSet(uint256 epochMinRequestUpdateDuration);

    constructor() {
        protocolVersion = 1;
        nextProtocolVersion = 1;
        epochMinDuration = 2 hours;
        epochMinRequestUpdateDuration = 30 minutes;
    }

    /**
     * @dev Changes node registry address.
     *
     * Controlled by DAO and\or multisig (3 out of 5, Gnosis Safe).
     */
    function setNodeRegistry(address nodeRegistry_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(nodeRegistry_ != address(0), "GovBridge: zero address given");
        nodeRegistry = nodeRegistry_;
        emit NodeRegistrySet(nodeRegistry);
    }

    /**
     * @dev Request to update epoch. Anyone may call it after epochMinDuration passed.
     */
    function requestEpochUpdate() external {
        require(block.timestamp > lastRequestEpochUpdateTime, "GovBridge: not enough time after retry");
        require(block.timestamp > epochStartTime + epochMinDuration, "GovBridge: not enough time after epoch");
        lastRequestEpochUpdateTime = block.timestamp + epochMinRequestUpdateDuration;
        emit EpochUpdateRequested(currentEpoch.epochNum, protocolVersion);
    }

    /**
     * @dev Request to update protocol version.
     *
     * Controlled by Operator.
     */
    function requestProtocolVersionUpdate(uint64 version) external onlyRole(OPERATOR_ROLE) {
        require(version - 1 == protocolVersion, "GovBridge: wrong protocol version");
        nextProtocolVersion = version;
        emit ProtocolVersionUpdateRequested(version, nextProtocolVersion);
    }

    /**
     * @dev Set epoch min duration. Only DAO may call this.
     *
     * Controlled by DAO and\or multisig (3 out of 5, Gnosis Safe).
     */
    function setEpochMinDuration(uint256 epochMinDuration_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        epochMinDuration = epochMinDuration_;
        emit EpochMinDurationSet(epochMinDuration);
    }

    /**
     * @dev Set epoch min request update duration. Only DAO may call this.
     *
     * Controlled by DAO and\or multisig (3 out of 5, Gnosis Safe).
     */
    function setEpochMinRequestUpdateDuration(uint256 epochMinRequestUpdateDuration_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        epochMinRequestUpdateDuration = epochMinRequestUpdateDuration_;
        emit EpochMinRequestUpdateDurationSet(epochMinRequestUpdateDuration);
    }

    /**
     * @dev Hook on start new epoch.
     */
    function onEpochStart(uint64 protocolVersion_) internal override {
        uint64 prevProtocolVersion = protocolVersion;
        if (protocolVersion_ != 0) {
            protocolVersion = protocolVersion_;
        } else {
            protocolVersion = nextProtocolVersion;
        }
        require(protocolVersion >= prevProtocolVersion, "GovBridge: wrong protocol version");
        epochStartTime = block.timestamp;
        emit EpochUpdated(abi.encode(currentEpoch.publicKey), currentEpoch.epochNum, protocolVersion);
    }
}
