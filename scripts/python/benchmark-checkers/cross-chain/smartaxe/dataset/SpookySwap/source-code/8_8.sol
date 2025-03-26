// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/ISwapper.sol";


contract Swapper is ISwapper, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    uint public slippage = 9;
    mapping(address => bool) public slippageOverrode;


    // onlyAuth type functions

    function overrideSlippage(address _token) external onlyOwner {
        slippageOverrode[_token] = !slippageOverrode[_token];
    }

    function setSlippage(uint _amt) external onlyOwner {
        require(_amt < 20, "slippage setting too high"); // the higher this setting, the lower the slippage tolerance, too high and buybacks would never work
        slippage = _amt;
    }

    function swap(
        address fromToken,
        IUniswapV2Pair pair,
        uint256 amountIn
    ) external returns (uint256 amountOut) {
        require(address(pair) != address(0), "BrewBoo: Cannot convert");

        (uint256 ui1, uint256 ui2, ) = pair.getReserves();
        bool isToken0 = fromToken == pair.token0();
        (ui1, ui2) = isToken0 ? (ui1, ui2) : (ui2, ui1);
        
        IERC20(fromToken).safeTransferFrom(msg.sender, address(pair), amountIn);
        amountIn = IERC20(fromToken).balanceOf(address(pair)).sub(ui1); // calculate amount that was transferred, this accounts for transfer taxes
        require(ui1.div(amountIn) > slippage || slippageOverrode[fromToken], "slippage too high");

        require(amountIn > 0, 'BrewBoo: INSUFFICIENT_INPUT_AMOUNT');
        require(ui1 > 0 && ui2 > 0, 'BrewBoo: INSUFFICIENT_LIQUIDITY');
        amountIn = amountIn.mul(998);
        amountOut = amountIn.mul(ui2) / ui1.mul(1000).add(amountIn);

        (ui1, ui2) = isToken0 ? (uint(0), amountOut) : (amountOut, uint(0));
        pair.swap(ui1, ui2, msg.sender, new bytes(0));
    }
}