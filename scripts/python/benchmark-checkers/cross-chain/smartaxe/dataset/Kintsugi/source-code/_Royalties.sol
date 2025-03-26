// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
* @dev Interface for the NFT Royalty Standard
* @dev See: https://eips.ethereum.org/EIPS/eip-2981
*/
interface IERC2981 is IERC165 {    

    /**
    * @notice Called with the sale price to determine how much royalty is owed and to whom.
    * @param _tokenId - the NFT asset queried for royalty information
    * @param _salePrice - the sale price of the NFT asset specified by _tokenId
    * @return receiver - address of who should be sent the royalty payment
    * @return royaltyAmount - the royalty payment amount for _salePrice
    */ 
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    );
}

abstract contract _Royalties is IERC2981 {     
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC2981).interfaceId;
    }
}