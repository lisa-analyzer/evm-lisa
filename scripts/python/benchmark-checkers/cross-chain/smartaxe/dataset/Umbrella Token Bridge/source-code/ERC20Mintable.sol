// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./Ownable.sol";
import "./ERC20Burnable.sol";

abstract contract ERC20Mintable is ERC20Burnable, Ownable {
  constructor(string memory _name, string memory _symbol)
    ERC20(_name, _symbol) {
  }

  function mint(address to, uint256 amount) onlyOwner external {
    _mint(to, amount);
  }
}