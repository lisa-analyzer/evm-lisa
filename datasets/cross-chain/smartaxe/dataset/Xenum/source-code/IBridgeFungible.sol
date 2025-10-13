//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IBridge.sol";

/**
 * @dev Interface for bridge contract with extra functions for bridging ERC-20 tokens
 */
interface IBridgeFungible is IBridge {
	/**
	 * @dev Transfers an ERC20 token to a different chain
	 * This function simply moves the caller's tokens to this contract, and emits a `TokenTransferFungible` event
	 */
	function transferFungible(address token, uint256 amount, uint256 networkId, bytes calldata data) external payable;

	/**
	 * @dev Used by the bridge relay to 'transfer' a user's item to the chain
	 */
	function bridgeClaimFungible(address token, address to, uint256 amount) external;

	event TokenTransferFungible(address indexed from, address indexed token, uint256 amount, uint256 networkId);
	event TokenClaimedFungible(address indexed from, address indexed token, uint amount);
}
