//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IBridge.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";

/**
 * @dev Interface for bridge contract with added support for MixedFungible tokens that follow the ERC-1155 standard
 */
interface IBridgeMixedFungible is IBridge, IERC1155ReceiverUpgradeable {
	/**
	 * @dev Transfers an ERC1155 token to a different chain
	 * This function simply moves the caller's tokens to this contract, and emits a `TokenTransferMixedFungible` event
	 */
	function transferMixedFungible(address token, uint256 tokenId, uint256 amount, uint256 networkId, bytes calldata data) external payable;

	/**
	 * @dev Used by the bridge relay to 'transfer' a user's item to the chain
	 */
	function bridgeClaimMixedFungible(address token, address to, uint256 tokenId, uint256 amount) external;

	event TokenTransferMixedFungible(address indexed from, address indexed token, uint256 tokenId, uint256 amount, uint256 networkId);
	event TokenClaimedMixedFungible(address indexed from, address indexed token, uint256 tokenId, uint256 amount);
}
