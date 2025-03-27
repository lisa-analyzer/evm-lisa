// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import "./BeaconProxy.sol";

contract DeBridgeTokenProxy is BeaconProxy {
    constructor(address beacon, bytes memory data) BeaconProxy(beacon, data) {

    }
}