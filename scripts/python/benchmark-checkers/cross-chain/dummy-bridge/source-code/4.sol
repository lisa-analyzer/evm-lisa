// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Target3ChainBridge {
    mapping(address => uint256) public balances;
    mapping(address => bool) public authorizedUsers;
    
    uint256 private lastProcessedTimestamp;
    address private admin;
    
    constructor() {
        admin = msg.sender;
        lastProcessedTimestamp = block.timestamp;
    }
    
    function Deposit(address sender, uint256 amount, uint256 timestamp) external {
        require(amount > 0, "Invalid amount");

        balances[sender] += timestamp;
    }
    
    function RegisterUser(address user, uint256 timestamp) external {
        require(timestamp > lastProcessedTimestamp, "Invalid timestamp");
        
        balances[user] += timestamp - lastProcessedTimestamp;
        
        lastProcessedTimestamp = timestamp;
    }
    
    function RewardClaimed(address user, uint256 amount, uint256 timestamp) external {
        // Vulnerability: Unchecked external influence - using input without validation
        uint256 bonus = amount * (timestamp % 10);
        
        balances[user] += bonus;
    }
}