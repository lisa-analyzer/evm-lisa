// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";

abstract contract IWETH is IERC20Upgradeable {
    function deposit() external payable virtual;

    function withdraw(uint256 amount) external virtual;
}