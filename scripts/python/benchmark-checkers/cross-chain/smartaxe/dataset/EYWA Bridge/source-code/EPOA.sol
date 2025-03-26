// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity 0.8.17;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract EPOA is Ownable, ERC20Permit {
    address public nodeRegistry;

    constructor(
        address nodeRegistry_
    ) ERC20Permit("EYWA") ERC20("EYWA PoA Token", "EPOA") {
        require(nodeRegistry_ != address(0), "EPOA: zero address given");
        nodeRegistry = nodeRegistry_;
    }

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    function mintWithAllowance(
        address account,
        address spender,
        uint256 amount
    ) external onlyOwner {
        _mint(account, amount);
        _approve(account, spender, allowance(account, spender) + amount);
    }

    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    function burnWithAllowanceDecrease(
        address account,
        address spender,
        uint256 amount
    ) external onlyOwner {
        uint256 currentAllowance = allowance(account, spender);
        require(currentAllowance >= amount, "EPOA: decreased allowance below zero");

        _approve(account, spender, currentAllowance - amount);
        _burn(account, amount);
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        require(to == nodeRegistry, "EPOA: transfer only to NodeRegistry");
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        require(to == nodeRegistry, "EPOA: transfer only to NodeRegistry");
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function setNodeRegistry(address nodeRegistry_) external onlyOwner {
        require(nodeRegistry_ != address(0), "EPOA: zero address given");
        nodeRegistry = nodeRegistry_;
    }
}
