// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;


interface IStrategy {
    function vault() external view returns (address);
    function want() external view returns (address);
    function isActive() external view returns (bool);
    function delegatedAssets() external view returns (uint256);
    function estimatedTotalAssets() external view returns (uint256);
    function withdraw(uint256 _amountNeeded) external returns (uint256 _loss);
    function migrate(address newStrategy) external;
}