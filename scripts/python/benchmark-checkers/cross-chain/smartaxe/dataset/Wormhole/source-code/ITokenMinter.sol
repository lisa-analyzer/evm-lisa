// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.19;

/**
 * @title ITokenMinter
 * @notice interface for minter of tokens that are mintable, burnable, and interchangeable
 * across domains.
 */
interface ITokenMinter {
    function burnLimitsPerMessage(address token) external view returns (uint256);

    function remoteTokensToLocalTokens(bytes32 sourceIdHash) external view returns (address);
}