// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

// source: @uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol

import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";


/// @title Oracle library
/// @notice Provides functions to integrate with V3 pool oracle
library OracleLibrary {

    /// @notice Calculates time-weighted means of tick and liquidity for a given Uniswap V3 pool
    /// @param pool Address of the pool that we want to observe
    /// @param secondsAgo Number of seconds in the past from which to calculate the time-weighted means
    /// @return success false on throw
    /// @return arithmeticMeanTick The arithmetic mean tick from (block.timestamp - secondsAgo) to block.timestamp
    /// @return harmonicMeanLiquidity The harmonic mean liquidity from (block.timestamp - secondsAgo) to block.timestamp
    function consult(address pool, uint32 secondsAgo)
        internal
        view
        returns (bool success, int24 arithmeticMeanTick, uint128 harmonicMeanLiquidity)
    {
        require(secondsAgo != 0, "BP");

        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = secondsAgo;
        secondsAgos[1] = 0;

        int56[] memory tickCumulatives;
        uint160[] memory secondsPerLiquidityCumulativeX128s;

        (success, tickCumulatives, secondsPerLiquidityCumulativeX128s) = observe(IUniswapV3Pool(pool), secondsAgos);
        // IUniswapV3Pool(pool).observe(secondsAgos); <<< this can revert

        if (success) {
            int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
            uint160 secondsPerLiquidityCumulativesDelta =
            secondsPerLiquidityCumulativeX128s[1] - secondsPerLiquidityCumulativeX128s[0];

            arithmeticMeanTick = int24(tickCumulativesDelta / secondsAgo);
            // Always round to negative infinity
            if (tickCumulativesDelta < 0 && (tickCumulativesDelta % secondsAgo != 0)) arithmeticMeanTick--;

            // We are multiplying here instead of shifting to ensure that harmonicMeanLiquidity doesn"t overflow uint128
            uint192 secondsAgoX160 = uint192(secondsAgo) * type(uint160).max;
            harmonicMeanLiquidity = uint128(secondsAgoX160 / (uint192(secondsPerLiquidityCumulativesDelta) << 32));
        }
    }

    function observe(IUniswapV3Pool pool, uint32[] memory secondsAgos)
        internal
        view
        returns (bool success, int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s)
    {
        bytes4 observeSelector = pool.observe.selector;
        bytes memory data = abi.encodeWithSelector(observeSelector, secondsAgos);
        // solhint-disable-next-line avoid-low-level-calls
        (success, data) = address(pool).staticcall(data);

        if (success) {
            (tickCumulatives, secondsPerLiquidityCumulativeX128s) = abi.decode(data, (int56[], uint160[]));
        }
    }

    /// @notice Given a tick and a token amount, calculates the amount of token received in exchange
    /// @param tick Tick value used to calculate the quote
    /// @param baseAmount Amount of token to be converted
    /// @param baseToken Address of an ERC20 token contract used as the baseAmount denomination
    /// @param quoteToken Address of an ERC20 token contract used as the quoteAmount denomination
    /// @return quoteAmount Amount of quoteToken received for baseAmount of baseToken
    function getQuoteAtTick(
        int24 tick,
        uint128 baseAmount,
        address baseToken,
        address quoteToken
    ) internal pure returns (uint256 quoteAmount) {
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);

        // Calculate quoteAmount with better precision if it doesn"t overflow when multiplied by itself
        if (sqrtRatioX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
            quoteAmount = baseToken < quoteToken
            ? FullMath.mulDiv(ratioX192, baseAmount, 1 << 192)
            : FullMath.mulDiv(1 << 192, baseAmount, ratioX192);
        } else {
            uint256 ratioX128 = FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, 1 << 64);
            quoteAmount = baseToken < quoteToken
            ? FullMath.mulDiv(ratioX128, baseAmount, 1 << 128)
            : FullMath.mulDiv(1 << 128, baseAmount, ratioX128);
        }
    }
}