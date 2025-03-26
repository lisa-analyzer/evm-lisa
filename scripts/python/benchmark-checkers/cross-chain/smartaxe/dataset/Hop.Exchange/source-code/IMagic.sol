// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@solidstate/contracts/token/ERC20/IERC20.sol';

interface IMagic is IERC20 {
    function mint(address account, uint256 amount) external;
}