//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IBridge.sol";

/**
 * @dev Interface for bridge contract with added support for NonFungible tokens that follow the ERC-721 standard
 */
interface IBridgeNonFungible is IBridge {
	/**
	 * @dev Transfers an ERC721 token to a different chain
	 * This function simply moves the caller's tokens to this contract, and emits a `TokenTransferFungible` event
	 */
	function transferNonFungible(address token, uint256 tokenId, uint256 networkId, bytes calldata data) external payable;

	/**
	 * @dev Used by the bridge relay to 'transfer' a user's item to the chain
	 */
	function bridgeClaimNonFungible(address token, address to, uint256 tokenId) external;

	event TokenTransferNonFungible(address indexed from, address indexed token, uint256 tokenId, uint256 networkId);
	event TokenClaimedNonFungible(address indexed from, address indexed token, uint256 tokenId);
}
