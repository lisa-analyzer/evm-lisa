// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

interface IErc1155Metadata {
    function uri(uint256 tokenId) external view returns (string memory);
}
