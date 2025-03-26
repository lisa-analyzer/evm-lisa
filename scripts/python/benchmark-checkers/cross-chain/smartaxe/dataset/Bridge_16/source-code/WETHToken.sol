pragma solidity ^0.8.10;

import './TokenBase.sol';

contract WETHToken is TokenBase {
  constructor() TokenBase('Wrapped ETH Token', 'WET') {}
}