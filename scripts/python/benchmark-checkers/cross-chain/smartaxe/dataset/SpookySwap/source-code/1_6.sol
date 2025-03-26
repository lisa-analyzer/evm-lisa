// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV02Router.sol";


contract POL is Ownable {
    using SafeERC20 for IERC20;

    IUniswapV2Router02 public immutable router;

    IUniswapV2Pair public immutable pair;
    IERC20 public immutable wftm;
    IERC20 public immutable usdc;

    constructor(address _router, address _wftm_usdc, address _wftm, address _usdc) {
        router = IUniswapV2Router02(_router);
        pair = IUniswapV2Pair(_wftm_usdc);
        wftm = IERC20(_wftm);
        usdc = IERC20(_usdc);
        wftm.approve(address(router), 2**256 - 1);
        usdc.approve(address(router), 2**256 - 1);
    }

    function makePOL() external {
        uint balanceWFTM = wftm.balanceOf(address(this)) / 2;
        _swap(balanceWFTM);
        uint balanceUSDC = usdc.balanceOf(address(this));
        router.addLiquidity(address(wftm), address(usdc), balanceWFTM, balanceUSDC, balanceWFTM * 900/1000, balanceUSDC * 900/1000, address(this), block.timestamp + 180);
    }

    function withdrawERC20(address erc20) external onlyOwner {
        IERC20(erc20).transfer(msg.sender, IERC20(erc20).balanceOf(address(this)));
    }


    function _swap(
        uint256 amountIn
    ) internal returns (uint256 amountOut) {
        address fromToken = address(wftm);
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        (uint reserveInput, uint reserveOutput) = fromToken == pair.token0() ? (reserve0, reserve1) : (reserve1, reserve0);
        IERC20(fromToken).safeTransfer(address(pair), amountIn);
        uint amountInput = IERC20(fromToken).balanceOf(address(pair)) - reserveInput; // calculate amount that was transferred, this accounts for transfer taxes

        amountOut = getAmountOut(amountInput, reserveInput, reserveOutput);
        (uint amount0Out, uint amount1Out) = fromToken == pair.token0() ? (uint(0), amountOut) : (amountOut, uint(0));
        pair.swap(amount0Out, amount1Out, address(this), new bytes(0));
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'POL: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'POL: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn * 998;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

}