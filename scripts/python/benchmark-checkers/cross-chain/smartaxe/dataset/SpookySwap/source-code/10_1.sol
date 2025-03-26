// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

interface IWFTM {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function balanceOf(address account) external view returns (uint256);
}