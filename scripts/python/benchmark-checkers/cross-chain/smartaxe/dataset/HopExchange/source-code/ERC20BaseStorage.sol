// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC20BaseStorage {
  struct Layout {
    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowances;
    uint totalSupply;
  }

  bytes32 internal constant STORAGE_SLOT = keccak256(
    'solidstate.contracts.storage.ERC20Base'
  );

  function layout () internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly { l.slot := slot }
  }
}