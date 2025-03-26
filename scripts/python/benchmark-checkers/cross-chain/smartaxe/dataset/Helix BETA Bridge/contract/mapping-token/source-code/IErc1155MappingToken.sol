// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

interface IErc1155MappingToken {
    function metaDataAddress() external view returns(address);
    function mint(address to, uint256 id, uint256 amount) external;
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) external;
    function burn(uint256 id, uint256 amount) external;
    function burnBatch(uint256[] memory ids, uint256[] memory amounts) external;
}
