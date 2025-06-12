//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface for receiving message sent receipts from bridge
 */
interface IMessageReceiptGetter {

	// MUST only be callable by bridge network
	function messageReceipt(
		uint256 messageId,
		uint256 fromNetworkId,
		bool success
	) external;
}
