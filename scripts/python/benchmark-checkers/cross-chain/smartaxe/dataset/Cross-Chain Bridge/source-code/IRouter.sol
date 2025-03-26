// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IRouter {
  function tradeERC20(
    IERC20 collectedToken,
    IERC20 burnToken,
    uint256 amount
  ) external returns (uint256 tokensReceived);

  function tradeNativeTokenForERC20(IERC20 output, uint256 inputAmount) external payable returns (uint256);

  function addSwapPath(
    address input,
    address output,
    address[] memory path
  ) external;

  function wrappedNative() external returns (address);
  //    function getDexAddress() external returns(address);
}