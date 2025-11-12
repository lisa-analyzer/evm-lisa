// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleBridge {
    event SimpleTransfer(address indexed user, uint256 amount, uint256 timestamp);

    mapping(address => uint256) public balances;

    // VULNERABILITY: Local Dependency - block.timestamp used in state modification
    function transfer(address recipient, uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");

        // Local Dependency vulnerability: block.timestamp is untrusted external data
        // used directly in state-modifying operation without validation
        balances[msg.sender] -= amount;
        balances[recipient] += amount;

        emit SimpleTransfer(recipient, amount, block.timestamp);
    }

    // Wrapper function that calls transfer
    function sendFunds(address recipient, uint256 amount) public {
        this.transfer(recipient, amount);
    }
}
