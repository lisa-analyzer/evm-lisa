pragma solidity ^0.8.0;

interface IToken {
  function mint(address to) external;
  function burn(address to,uint tokenId) external;
}