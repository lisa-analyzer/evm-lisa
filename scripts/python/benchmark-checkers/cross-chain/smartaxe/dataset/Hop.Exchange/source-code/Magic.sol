// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@solidstate/contracts/access/OwnableInternal.sol';
import '@solidstate/contracts/token/ERC20/ERC20.sol';

import './IMagic.sol';

contract Magic is IMagic, ERC20, OwnableInternal {
    uint256 public teamMintAmount;
    mapping(address => bool) private whitelist;

    function setWhitelist(address[] calldata minters) external onlyOwner {
        require(!whitelist[address(this)], 'Magic: whitelist already set');

        for (uint256 i; i < minters.length; i++) {
            whitelist[minters[i]] = true;
        }

        whitelist[address(this)] = true;
    }

    function mint(address account, uint256 amount) external override {
        require(whitelist[msg.sender], 'Magic: sender must be whitelisted');
        _mint(account, amount);
    }

    function teamMint(address account, uint256 amount) external onlyOwner {
        require(
            (totalSupply() + amount) / (teamMintAmount + amount) >= 10,
            'Magic: excessive mint'
        );
        _mint(account, amount);
        teamMintAmount += amount;
    }
}