//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IERC721Bridgable is IERC721Upgradeable {
	/**
	  * @dev Create a new token, of a given ID
	  * SHOULD only be callable by the bridge network
	  * MUST revert if the token already exists
	  */
	 function bridgeMint(address recipient, uint256 id) external;
}
