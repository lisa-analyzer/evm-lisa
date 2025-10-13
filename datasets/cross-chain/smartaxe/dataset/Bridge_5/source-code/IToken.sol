// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IToken {
    function _mint(address to, uint amount) external;
    function _burn(address owner, uint amount) external;
}