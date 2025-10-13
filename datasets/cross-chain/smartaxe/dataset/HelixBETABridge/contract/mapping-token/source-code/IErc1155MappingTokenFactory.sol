// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

interface IErc1155MappingTokenFactory {
    function newErc1155Contract(
        address originalToken,
        address metadataAddress
    ) external returns (address mappingToken);

    function issueMappingToken(
        address originalToken,
        address recipient,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external;
}
     
