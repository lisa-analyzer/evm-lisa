// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

interface IErc20MappingTokenFactory {
    function newErc20Contract(
        address originalToken,
        string memory bridgedChainName,
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 dailyLimit
    ) external returns (address mappingToken);
    function issueMappingToken(
        address originalToken,
        address recipient,
        uint256 amount
    ) external;
}
     
