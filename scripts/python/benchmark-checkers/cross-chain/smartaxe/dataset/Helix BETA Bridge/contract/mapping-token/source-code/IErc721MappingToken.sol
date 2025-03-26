// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

interface IErc721MappingToken {
    function attributeSerializer() external view returns(address);
    function burn(uint256 id) external;
    function mint(address recipient, uint256 tokenId) external;
}
