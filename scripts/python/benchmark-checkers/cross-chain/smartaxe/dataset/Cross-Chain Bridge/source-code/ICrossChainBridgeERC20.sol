// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface ICrossChainBridgeERC20 {
  struct LPToken {
    bool exists;
    IERC20 token;
  }

  function lpTokens(address) external returns (LPToken calldata);

  function defaultLiquidityWithdrawalFee() external returns (uint256);

  function liquidityWithdrawalFees(address) external returns (uint256);

  function defaultBridgeFee() external returns (uint256);

  function bridgeFees(address) external returns (uint256);

  function addLiquidityERC20(IERC20, uint256) external;

  function withdrawLiquidity(IERC20, uint256) external;

  function depositERC20(
    IERC20,
    uint256,
    address,
    uint256
  ) external;

  function releaseERC20(
    uint8[] calldata,
    bytes32[] calldata,
    bytes32[] calldata,
    address,
    address,
    uint256,
    uint256,
    uint256
  ) external;

  function registerTokenTransferApprovals(address) external returns (bool);

  function sendCollectedTokensToBuyBackAndBurn(IERC20 token) external;

  function forwardCollectedFees(
    IERC20 token,
    bool,
    bool,
    bool
  ) external;
}