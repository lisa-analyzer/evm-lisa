// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

interface ICompoundToken {
    function underlying() external view returns (address);

    function mint(uint256 mintAmount) external returns (uint256);

    function mint() external payable;

    function redeem(uint256 redeemTokens) external returns (uint256);

    function exchangeRateStored() external view returns (uint256);
}