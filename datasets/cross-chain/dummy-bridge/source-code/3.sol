// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Target2ChainBridge {
    mapping(address => uint256) public balances;
    mapping(address => bool) public authorizedUsers;
    
    uint256 private lastProcessedTimestamp;
    address private admin;

    event RegisterUser(address indexed user, uint256 timestamp);
    event RewardClaimed(address indexed user, uint256 amount, uint256 timestamp);
    
    constructor() {
        admin = msg.sender;
        lastProcessedTimestamp = block.timestamp;
    }
    
    function Deposit(address sender, uint256 amount, uint256 timestamp) external {
        require(amount > 0, "Invalid amount");

        balances[sender] += timestamp;
    }
    
    function registerUser(address user) external {
        // Vulnerability: Tx.Origin - using tx.origin for authorization
        if (tx.origin == admin) {
            // Vulnerability: Unchecked external influence - no validation on user input
            authorizedUsers[user] = true;
            
            // Vulnerability: Randomness dependency - timestamp used as a parameter in an event
            // Vulnerability: Time synchronization - the timestamp is used as a parameter for a computation
            emit RegisterUser(user, block.timestamp);
        }
    }    
    
    function claimRewards(uint256 amount) external {
        // Vulnerability: Event order - emit event before state modification
        // Vulnerability: Randomness dependency - timestamp used as a parameter in an event
        // Vulnerability: Time synchronization - the timestamp is used as a parameter for a computation
        emit RewardClaimed(msg.sender, amount, block.timestamp);
        
        // Vulnerability: Reentrancy - external call before updating state
        // Vulnerability: Unchecked external influence - no validation on amount
        (bool success, ) = msg.sender.call{value: amount}("");
        
        if (success) {
            // Vulnerability: Unchecked external influence - no validation on amount
            balances[msg.sender] -= amount;
        }
    }
}