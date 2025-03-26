// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 

import "./BridgeNFT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract XPNFT is Ownable, ERC721Enumerable, BridgeNFT {
    string public baseUri;

    // WARN: baseURI_ MUST be "/" suffixed
    constructor(string memory name_, string memory symbol_, string memory baseURI_) ERC721(name_, symbol_) {
        baseUri = baseURI_;
    }

	function mint(address to, uint256 id, bytes calldata) override external onlyOwner {
		_safeMint(to, id);
	}

	function burnFor(address from, uint256 id) override external onlyOwner {
        require(ownerOf(id) == from, "You don't own this nft!");
		_burn(id);
	}

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function baseURI() override external view returns (string memory)  {
        return string(abi.encodePacked(baseUri, "{id}"));
    }
}