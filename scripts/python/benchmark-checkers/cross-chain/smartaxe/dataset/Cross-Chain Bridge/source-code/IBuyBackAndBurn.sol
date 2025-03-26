// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './IRouter.sol';

interface IBuyBackAndBurn {
  function depositERC20(IERC20 token, uint256 amount) external;

  function depositNativeToken(uint256 amount) external payable;
  //function iRouter() external returns (IRouter);
}