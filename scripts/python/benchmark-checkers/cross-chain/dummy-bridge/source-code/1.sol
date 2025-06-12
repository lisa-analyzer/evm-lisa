// Event order: 5
// Tx.origin: 1
// Reentrancy: 2

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OriginChainBridge {
    event Transfer(address indexed sender, uint256 amount, uint256 timestamp);
    event Deposit(address indexed sender, uint256 amount, uint256 timestamp);
    event Withdraw(address indexed recipient, uint256 amount, bytes32 txHash);
    
    mapping(bytes32 => bool) public processedTxs;
    mapping(address => uint256) public userBalances;
    
    address public owner;
    bool private locked;
    
    constructor() {
        owner = msg.sender;
    }
    
    function initiateTransfer(address recipient, uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");

        // Vulnerability (x2): Time synchronization - the timestamp is used as a parameter for a function that is called on another contract.
        // Vulnerability (x2): Event order - emit of an event without a state modification.
        // Vulnerability (x2): Randomness dependency - using block.timestamp for event
        emit Transfer(msg.sender, amount, block.timestamp);
        emit Deposit(msg.sender, amount, block.timestamp);
    }
    
    function depositFunds() external payable {
        // Vulnerability: TxOrigin - authorization using tx.origin instead of msg.sender
        require(tx.origin == owner, "Only owner can deposit funds");
        
        // Vulnerability: Event order - event emitted without state modification
        // Vulnerability: Randomness dependency - using block.timestamp for event
        // Vulnerability: Time synchronization - the timestamp is used as a parameter for a computation
        emit Deposit(msg.sender, msg.value, block.timestamp);
        
        userBalances[msg.sender] += msg.value;
    }
    
    function withdrawFunds(uint256 amount) external {
        // Vulnerability: Unchecked external influence - external input used without validation
        userBalances[msg.sender] -= amount;
        
        // Vulnerability: Reentrancy - external call before state update
        // Vulnerability: Unchecked external influence - external input used without validation
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        // Vulnerability: Randomness dependency - using block.timestamp for hash
        // Vulnerability: Unchecked external influence - external input used without validation
        bytes32 txHash = keccak256(abi.encodePacked(msg.sender, amount, block.timestamp));
        
        emit Withdraw(msg.sender, amount, txHash);
    }
    
    function initiateSecureTransfer(address recipient, uint256 amount) external {
        // Vulnerability: Randomness dependency - using block.timestamp for critical logic
        if (block.timestamp % 2 == 0) {
            // Vulnerability: Unchecked external influence - external input used without validation
            userBalances[recipient] += amount * 2;
        } else {
            // Vulnerability: Unchecked external influence - external input used without validation
            userBalances[recipient] += amount;
        }
        
        // Vulnerability: Unchecked external influence - updates state based on external data without validation
        // Vulnerability: Randomness dependency - using block.timestamp for hash
        bytes32 txHash = keccak256(abi.encodePacked(recipient, amount, block.timestamp));
        processedTxs[txHash] = true;
        
        // Vulnerability: Randomness dependency - using block.timestamp for event
        // Vulnerability: Time synchronization - the timestamp is used as a parameter for a computation
        emit Transfer(msg.sender, amount, block.timestamp);
    }
}