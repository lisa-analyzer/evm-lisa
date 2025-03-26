pragma solidity ^0.8.10;

import './TokenBase.sol';

contract WBSCToken is TokenBase {
  constructor() TokenBase('Wrapped BSC Token', 'WBT') {}
}