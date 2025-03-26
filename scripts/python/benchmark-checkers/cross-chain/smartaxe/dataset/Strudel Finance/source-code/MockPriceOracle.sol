// SPDX-License-Identifier: MPL-2.0

pragma solidity 0.6.6;

import "@uniswap/lib/contracts/libraries/FixedPoint.sol";
import "../IPriceOracle.sol";

contract MockPriceOracle is IPriceOracle {
  using FixedPoint for *;

  FixedPoint.uq112x112 public priceAverage;

  function update(uint256 average) external {
    priceAverage = FixedPoint.fraction(uint112(average), uint112(1e6));
  }

  // note this will always return 0 before update has been called successfully for the first time.
  function consult(uint256 amountOfX) external view override returns (uint256 priceInEth) {
    return priceAverage.mul(amountOfX).decode144();
  }
}