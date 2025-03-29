// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBridge {
    event Deposit      (address token, address from, uint amount, uint targetChain);
    
    function addToken(address[] memory _tokens) external;
    function createToken(string[] memory names, string[] memory symbols, uint8[] memory decimals) external;

    function deposit(address token, uint amount, uint targetChain) external payable;
    function transfer(uint[][] memory args) external payable;
}