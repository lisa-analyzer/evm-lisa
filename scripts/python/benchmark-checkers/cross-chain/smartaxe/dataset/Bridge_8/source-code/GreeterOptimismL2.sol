//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./crosschain/optimism/CrossChainEnabledOptimismL2.sol";

contract GreeterOptimismL2 is CrossChainEnabledOptimismL2 {
    string private _greeting;

    constructor(address bridge_, string memory greeting_) CrossChainEnabledOptimismL2(bridge_) {
        _greeting = greeting_;
    }

    function greet() public view returns (string memory) {
        return _greeting;
    }

    function setGreeting(string memory greeting_) public payable onlyCrossChain {
        _greeting = greeting_;
    }
}
