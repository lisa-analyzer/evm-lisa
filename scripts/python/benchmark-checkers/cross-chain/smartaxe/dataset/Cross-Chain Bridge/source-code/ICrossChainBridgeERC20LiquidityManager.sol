// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import '../token/MintableERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface ICrossChainBridgeERC20LiquidityManager {
  function lpTokens(address spender) external returns (bool exists, IERC20 token);

  function createPool(address token) external returns (bool);

  function addLiquidityERC20(IERC20 token, uint256 amount) external;

  function addLiquidityNative(uint256 amount) external payable;

  function withdrawLiquidityERC20(IERC20 token, uint256 amount) external;

  function withdrawLiquidityNative(uint256 amount) external;

  function defaultLiquidityWithdrawalFee() external returns (uint256);

  function liquidityWithdrawalFees(address token) external returns (uint256);

  function setNameAndSymbolAndDecimalsOfLpToken(
    MintableERC20 contractAddress,
    string memory newName,
    string memory newSymbol,
    uint8 newDecimals
  ) external;
}