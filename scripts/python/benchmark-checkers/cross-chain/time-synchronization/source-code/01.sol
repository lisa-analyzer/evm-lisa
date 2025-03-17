// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OriginChainBridge {
    event Transfer(address indexed sender, uint256 amount, uint256 timestamp);

    function initiateTransfer(address recipient, uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");

        // Vulnerabilities:
        // - Time synchronization: the timestamp is used as a parameter for a function that is called on another contract.
        // - Event order: emit of an event without a state modification.
        emit Transfer(msg.sender, amount, block.timestamp);
    }
}