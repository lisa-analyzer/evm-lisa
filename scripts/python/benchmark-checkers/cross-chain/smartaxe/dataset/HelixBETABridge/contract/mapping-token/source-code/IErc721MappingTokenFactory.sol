// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

interface IErc721MappingTokenFactory {
    function newErc721Contract(
        address originalToken,
        address attrSerializer
    ) external returns (address mappingToken);

    function issueMappingToken(
        address originalToken,
        address recipient,
        uint256[] calldata ids,
        bytes[] calldata attrs
    ) external;
}
     
