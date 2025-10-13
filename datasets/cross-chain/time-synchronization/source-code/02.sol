// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TargetChainBridge {
    mapping(address => uint256) public balances;
    
    function Transfer(address sender, uint256 amount, uint256 timestamp) external {
        require(amount > 0, "Invalid amount");

        // Vulnerability: timestamp used as a parameter for an hash function
        bytes32 hash = keccak256(abi.encodePacked(sender, timestamp));
        
        // Vulnerability: timestamp used as a parameter in a conditional statement
        if (timestamp > 100000) {
            balances[sender] += amount;
        }
    }
}