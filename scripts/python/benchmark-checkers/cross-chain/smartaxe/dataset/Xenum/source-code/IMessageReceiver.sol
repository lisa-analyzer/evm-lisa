//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface for receiving messages from bridge
 */
interface IMessageReceiver {
	function receiveBridgeMessage(
		string calldata sender,
		uint256 fromNetworkId,
		bytes calldata message
	) external returns (bool);
}
