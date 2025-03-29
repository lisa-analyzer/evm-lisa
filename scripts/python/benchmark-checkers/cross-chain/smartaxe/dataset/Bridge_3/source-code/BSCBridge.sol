// SPDX-License-Identifier: BlockchainBic
pragma solidity 0.8.9;

import "./BridgeContract.sol";

contract BSC_Bridge is BridgeContract {
    constructor(address _token) BridgeContract(_token) {
        
    }
}