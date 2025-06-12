// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

interface IibToken {
    function deposit(uint256 amount) external;

    function deposit() external payable;

    function withdraw(uint256 amount) external;

    function cToken() external view returns (address);

    function uToken() external view returns (address);
}