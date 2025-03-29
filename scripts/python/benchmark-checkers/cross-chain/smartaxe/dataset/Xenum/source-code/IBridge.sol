//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMessageReceiver.sol";

/**
 * @dev Interface for bridge contract
 */
interface IBridge {
	/**
	 * @dev Used to send arbitrary messages to other networks
	 * MUST emit `MessageSent` event
	 */
	function sendMessage(
		uint256 messageId,
		uint256 destination,
		string calldata recipient,
		bool receipt,
		bytes calldata message,
		bytes calldata data
	) external payable;

	/**
	 * @dev Used to send arbitrary messages to all other contracts within the same project as sender
	 * MUST emit `BroadcastSent` event
	 */
	function sendBroadcast(
		uint256 messageId,
		bool receipt,
		bytes calldata message,
		bytes calldata data
	) external payable;

	/**
	 * @dev Relay message from another network. MUST only be callable by bridge network
	 * MUST emit `MessageReceived` event
	 */
	function relayMessage(
		IMessageReceiver recipient,
		uint256 messageId,
		string calldata sender,
		uint256 fromNetworkId,
		bool receipt,
		bytes calldata message
	) external returns (bool);

	event MessageSent(
		address indexed from,
		uint256 indexed messageId,
		uint256 destination,
		string recipient,
		bool receipt,
		bytes message
	);
	event BroadcastSent(
		address indexed from,
		uint256 indexed messageId,
		bool receipt,
		bytes message
	);
	event MessageReceived(
		IMessageReceiver indexed receiver,
		string from,
		uint256 fromNetworkId,
		bool success,
		uint256 messageId,
		bool receipt
	);
}
