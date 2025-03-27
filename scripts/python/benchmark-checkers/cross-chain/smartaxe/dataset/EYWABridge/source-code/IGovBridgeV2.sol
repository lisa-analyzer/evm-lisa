// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity ^0.8.17;

import "./IBridgeV2.sol";


interface IGovBridgeV2 is IBridgeV2 {

    /**
     * @dev Request to update epoch. Anyone may call it after epochMinDuration passed.
     */
    function requestEpochUpdate() external;

    /**
     * @dev Request to update protocol version. Only DAO may call this.
     */
    function requestProtocolVersionUpdate(uint64 version) external;

    /**
     * @dev Set epoch min duration. Only DAO may call this.
     */
    function setEpochMinDuration(uint256 epochMinDuration_) external;

    /**
     * @dev Set epoch min request update duration. Only DAO may call this.
     */
    function setEpochMinRequestUpdateDuration(uint256 epochMinRequestUpdateDuration_) external;
}
