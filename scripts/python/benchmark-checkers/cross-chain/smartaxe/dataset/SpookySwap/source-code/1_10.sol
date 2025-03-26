// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import "./utils/SpookyApprovals.sol";
import "./utils/SelfPermit.sol";
import "./utils/Multicall.sol";
import "./router/UniswapV2Router02.sol";

/// @notice boooo! spooooky!! nyahaha! ₍⸍⸌̣ʷ̣̫⸍̣⸌₎
contract LiquidityBrewer is SpookyApprovals, UniswapV2Router02, SelfPermit, Multicall {
    IMCV2 public MCV21;
    IMCV2 public MCV22;

    constructor(address _factory, address _WETH, address mcv21, address mcv22) UniswapV2Router02(_factory, _WETH) {
        MCV21 = IMCV2(mcv21);
        MCV22 = IMCV2(mcv22);
    }

    //add liquidity and deposit to masterchef v2
    function addLiquidityAndDeposit(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        uint pid,
        bool useMCV22
    ) external {
        (,, uint liquidity) = addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, address(this), deadline);

        IMCV2 MCV2 = useMCV22 ? MCV22 : MCV21;
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        _approveIfNeeded(pair, address(MCV2));
        MCV2.deposit(pid, liquidity, to);
    }

    //add liquidity eth and deposit to masterchef v2
    function addLiquidityETHAndDeposit(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        uint pid,
        bool useMCV22
    ) external payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        (amountToken, amountETH) = _addLiquidity(token, WETH, amountTokenDesired, msg.value, amountTokenMin, amountETHMin);
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IUniswapV2Pair(pair).mint(address(this));
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);

        IMCV2 MCV2 = useMCV22 ? MCV22 : MCV21;
        _approveIfNeeded(pair, address(MCV2));
        MCV2.deposit(pid, liquidity, to);
    }

    //deposit to masterchef v2
    function deposit(uint pid, uint amount, address to, bool useMCV22) external {
        IMCV2 MCV2 = useMCV22 ? MCV22 : MCV21;
        address token = address(MCV2.lpToken(pid));
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        _approveIfNeeded(token, address(MCV2));
        MCV2.deposit(pid, amount, to);
    }

    //in case more than max_uint wei of a token are transferred in the lifetime
    function reApprove(uint pid, bool useMCV22) external {
        IMCV2 MCV2 = useMCV22 ? MCV22 : MCV21;
        IERC20(address(MCV2.lpToken(pid))).approve(address(MCV2), 2**256 - 1);
    }
}

interface IMCV2 {
    function deposit(uint pid, uint amount, address to) external;
    function lpToken(uint) external returns (IERC20);
}