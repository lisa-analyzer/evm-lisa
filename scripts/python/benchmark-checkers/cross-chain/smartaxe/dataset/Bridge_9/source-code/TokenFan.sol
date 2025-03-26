pragma solidity ^0.8.0;

import './TokenBase.sol';

contract TokenFan is TokenBase {
  constructor() TokenBase('FAN Token', 'FAN') {}
}