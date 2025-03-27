// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWToken {
    function deposit() external payable;
    function withdraw(uint wad) external;
}
