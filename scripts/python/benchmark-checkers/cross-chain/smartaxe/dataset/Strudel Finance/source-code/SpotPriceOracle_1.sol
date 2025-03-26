// SPDX-License-Identifier: MPL-2.0

pragma solidity 0.6.6;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/lib/contracts/libraries/FixedPoint.sol";
import "@uniswap/v2-periphery/contracts/libraries/UniswapV2OracleLibrary.sol";
import "@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol";
import "./IPriceOracle.sol";

// fixed window oracle that recomputes the average price for the entire period once every period
// note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
contract SpotPriceOracle is IPriceOracle {
  using FixedPoint for *;

  uint256 public constant PERIOD = 1 minutes;

  address public immutable weth;
  address public immutable factory;
  address public immutable vBtc;

  // working memory
  uint256 public priceCumulativeLast;
  uint32 public blockTimestampLast;
  FixedPoint.uq112x112 public priceAverage;

  constructor(
    address _factory,
    address _wEth,
    address _vBtc
  ) public {
    factory = _factory;
    weth = _wEth;

    // check inputs
    require(_vBtc != address(0), "zero token");
    vBtc = _vBtc;

    // check pair
    IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(_factory, _wEth, _vBtc));
    require(address(pair) != address(0), "no pair");
    uint112 reserve0;
    uint112 reserve1;
    (reserve0, reserve1, ) = pair.getReserves();
    require(reserve0 != 0 && reserve1 != 0, "SpotOracle: NO_RESERVES"); // ensure that there's liquidity in the pair

    // fetch the current accumulated price value (0 / 1)
    priceCumulativeLast = (pair.token0() == _wEth)
      ? pair.price1CumulativeLast()
      : pair.price0CumulativeLast();
  }

  function update() external {
    uint32 blockTimestamp;
    uint224 priceSum = 0;

    IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, weth, vBtc));
    uint256 price0Cumulative;
    uint256 price1Cumulative;
    (price0Cumulative, price1Cumulative, blockTimestamp) = UniswapV2OracleLibrary
      .currentCumulativePrices(address(pair));
    uint256 priceCumulative = (pair.token0() == weth) ? price1Cumulative : price0Cumulative;
    uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

    // ensure that at least one full period has passed since the last update
    require(timeElapsed >= PERIOD, "ExampleOracleSimple: PERIOD_NOT_ELAPSED");

    // overflow is desired, casting never truncates
    // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
    priceAverage = FixedPoint.uq112x112(
      uint224((priceCumulative - priceCumulativeLast) / timeElapsed)
    );
    priceCumulativeLast = priceCumulative;
    blockTimestampLast = blockTimestamp;
  }

  // note this will always return 0 before update has been called successfully for the first time.
  function consult(uint256 amountIn) external view override returns (uint256 amountOut) {
    return priceAverage.mul(amountIn).decode144();
  }
}