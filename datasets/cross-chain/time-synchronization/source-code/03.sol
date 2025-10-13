// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Target2ChainBridge {
    mapping(address => uint256) public balances;
    
    function Deposit(address sender, uint256 amount, uint256 timestamp) external {
        require(amount > 0, "Invalid amount");

        // Vulnerability: timestamp used as a parameter to modify the state
        balances[sender] += timestamp;
    }
}