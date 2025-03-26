// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PolkaBridgeNFT is ERC1155, Ownable {
    string public name = "PolkaBridge NFT";
    string public symbol = "PBRNFT";
    constructor(string memory _uri) ERC1155(_uri) {
        _setURI(_uri);
    }

    function setURI(string memory uri_) 
        public onlyOwner {
        _setURI(uri_);
    }

    function mintNFT(address recipient_, uint256 id_, uint256 amount_)
        public onlyOwner {    
        _mint(recipient_, id_, amount_, '');
    }

    function multiMintNFT(address recipient_, uint256[] memory ids_, uint256[] memory amounts_)
        public onlyOwner {
        _mintBatch(recipient_, ids_, amounts_, '');
    }
}