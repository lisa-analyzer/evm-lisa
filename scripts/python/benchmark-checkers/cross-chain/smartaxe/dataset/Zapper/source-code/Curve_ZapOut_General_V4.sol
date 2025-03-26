// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract removes liquidity from Curve pools
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.5.7;
import "../_base/ZapOutBaseV2.sol";
import "./Curve_Registry_V2.sol";

interface ICurveSwap {
    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount,
        bool removeUnderlying
    ) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        uint256 i,
        uint256 min_amount
    ) external;

    function calc_withdraw_one_coin(uint256 tokenAmount, int128 index)
        external
        view
        returns (uint256);

    function calc_withdraw_one_coin(
        uint256 tokenAmount,
        int128 index,
        bool _use_underlying
    ) external view returns (uint256);

    function calc_withdraw_one_coin(uint256 tokenAmount, uint256 index)
        external
        view
        returns (uint256);
}

interface IWETH {
    function withdraw(uint256 wad) external;

    function deposit() external payable;
}

contract Curve_ZapOut_General_V4_2 is ZapOutBaseV2_1 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address private constant wethTokenAddress =
        address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    Curve_Registry_V2 public curveReg;

    mapping(address => bool) public approvedTargets;

    mapping(address => bool) internal v2Pool;

    constructor(
        Curve_Registry_V2 _curveRegistry,
        uint256 _goodwill,
        uint256 _affiliateSplit
    ) public ZapBaseV1(_goodwill, _affiliateSplit) {
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
        v2Pool[0x80466c64868E1ab14a1Ddf27A676C3fcBE638Fe5] = true;
        curveReg = _curveRegistry;
    }

    event zapOut(
        address sender,
        address pool,
        address token,
        uint256 tokensRec
    );

    /**
    @notice This method removes the liquidity from curve pools to ETH/ERC tokens
    @param swapAddress indicates Curve swap address for the pool
    @param incomingCrv indicates the amount of lp tokens to remove
    @param intermediateToken specifies in which token to exit the curve pool
    @param toToken indicates the ETH/ERC token to which tokens to convert
    @param minToTokens indicates the minimum amount of toTokens to receive
    @param _swapTarget Excecution target for the first swap
    @param _swapCallData DEX quote data
    @param affiliate Affiliate address to share fees
    @param shouldSellEntireBalance True if incomingCrv is determined at execution time (i.e. contract is caller)
    @return ToTokensBought- indicates the amount of toTokens received
     */
    function ZapOut(
        address swapAddress,
        uint256 incomingCrv,
        address intermediateToken,
        address toToken,
        uint256 minToTokens,
        address _swapTarget,
        bytes calldata _swapCallData,
        address affiliate,
        bool shouldSellEntireBalance
    ) external stopInEmergency returns (uint256 ToTokensBought) {
        address poolTokenAddress = curveReg.getTokenAddress(swapAddress);

        // get lp tokens
        incomingCrv = _pullTokens(
            poolTokenAddress,
            incomingCrv,
            shouldSellEntireBalance
        );

        if (intermediateToken == address(0)) {
            intermediateToken = ETHAddress;
        }

        // perform zapOut
        ToTokensBought = _zapOut(
            swapAddress,
            incomingCrv,
            intermediateToken,
            toToken,
            _swapTarget,
            _swapCallData
        );
        require(ToTokensBought >= minToTokens, "High Slippage");

        uint256 totalGoodwillPortion;

        // Transfer tokens
        if (toToken == address(0)) {
            totalGoodwillPortion = _subtractGoodwill(
                ETHAddress,
                ToTokensBought,
                affiliate,
                true
            );
            Address.sendValue(
                msg.sender,
                ToTokensBought.sub(totalGoodwillPortion)
            );
        } else {
            totalGoodwillPortion = _subtractGoodwill(
                toToken,
                ToTokensBought,
                affiliate,
                true
            );

            IERC20(toToken).safeTransfer(
                msg.sender,
                ToTokensBought.sub(totalGoodwillPortion)
            );
        }

        emit zapOut(msg.sender, swapAddress, toToken, ToTokensBought);

        return ToTokensBought.sub(totalGoodwillPortion);
    }

    function _zapOut(
        address swapAddress,
        uint256 incomingCrv,
        address intermediateToken,
        address toToken,
        address _swapTarget,
        bytes memory _swapCallData
    ) internal returns (uint256 ToTokensBought) {
        (bool isUnderlying, uint256 underlyingIndex) =
            curveReg.isUnderlyingToken(swapAddress, intermediateToken);

        // not metapool
        if (isUnderlying) {
            uint256 intermediateBought =
                _exitCurve(
                    swapAddress,
                    incomingCrv,
                    underlyingIndex,
                    intermediateToken
                );

            if (intermediateToken == ETHAddress) intermediateToken = address(0);

            ToTokensBought = _fillQuote(
                intermediateToken,
                toToken,
                intermediateBought,
                _swapTarget,
                _swapCallData
            );
        } else {
            // from metapool
            address[4] memory poolTokens = curveReg.getPoolTokens(swapAddress);
            address intermediateSwapAddress;
            uint8 i;
            for (; i < 4; i++) {
                if (curveReg.getSwapAddress(poolTokens[i]) != address(0)) {
                    intermediateSwapAddress = curveReg.getSwapAddress(
                        poolTokens[i]
                    );
                    break;
                }
            }
            // _exitCurve to intermediateSwapAddress Token
            uint256 intermediateCrvBought =
                _exitMetaCurve(swapAddress, incomingCrv, i, poolTokens[i]);
            // _performZapOut: fromPool = intermediateSwapAddress
            ToTokensBought = _zapOut(
                intermediateSwapAddress,
                intermediateCrvBought,
                intermediateToken,
                toToken,
                _swapTarget,
                _swapCallData
            );
        }
    }

    /**
    @notice This method removes the liquidity from meta curve pools
    @param swapAddress indicates the curve pool address from which liquidity to be removed.
    @param incomingCrv indicates the amount of liquidity to be removed from the pool
    @param index indicates the index of underlying token of the pool in which liquidity will be removed. 
    @return tokensReceived- indicates the amount of reserve tokens received 
    */
    function _exitMetaCurve(
        address swapAddress,
        uint256 incomingCrv,
        uint256 index,
        address exitTokenAddress
    ) internal returns (uint256 tokensReceived) {
        address tokenAddress = curveReg.getTokenAddress(swapAddress);
        _approveToken(tokenAddress, swapAddress);

        uint256 iniTokenBal = IERC20(exitTokenAddress).balanceOf(address(this));
        ICurveSwap(swapAddress).remove_liquidity_one_coin(
            incomingCrv,
            int128(index),
            0
        );
        tokensReceived = (IERC20(exitTokenAddress).balanceOf(address(this)))
            .sub(iniTokenBal);

        require(tokensReceived > 0, "Could not receive reserve tokens");
    }

    /**
    @notice This method removes the liquidity from given curve pool
    @param swapAddress indicates the curve pool address from which liquidity to be removed.
    @param incomingCrv indicates the amount of liquidity to be removed from the pool
    @param index indicates the index of underlying token of the pool in which liquidity will be removed. 
    @return tokensReceived- indicates the amount of reserve tokens received 
    */
    function _exitCurve(
        address swapAddress,
        uint256 incomingCrv,
        uint256 index,
        address exitTokenAddress
    ) internal returns (uint256 tokensReceived) {
        address depositAddress = curveReg.getDepositAddress(swapAddress);

        address tokenAddress = curveReg.getTokenAddress(swapAddress);
        _approveToken(tokenAddress, depositAddress);

        address balanceToken =
            exitTokenAddress == ETHAddress ? address(0) : exitTokenAddress;

        uint256 iniTokenBal = _getBalance(balanceToken);

        if (curveReg.shouldAddUnderlying(swapAddress)) {
            // aave
            ICurveSwap(depositAddress).remove_liquidity_one_coin(
                incomingCrv,
                int128(index),
                0,
                true
            );
        } else if (v2Pool[swapAddress]) {
            ICurveSwap(depositAddress).remove_liquidity_one_coin(
                incomingCrv,
                index,
                0
            );
        } else {
            ICurveSwap(depositAddress).remove_liquidity_one_coin(
                incomingCrv,
                int128(index),
                0
            );
        }

        tokensReceived = _getBalance(balanceToken).sub(iniTokenBal);

        require(tokensReceived > 0, "Could not receive reserve tokens");
    }

    /**
    @notice This method swaps the fromToken to toToken using the 0x swap
    @param _fromTokenAddress indicates the ETH/ERC20 token
    @param _toTokenAddress indicates the ETH/ERC20 token
    @param _amount indicates the amount of from tokens to swap
    @param _swapTarget Excecution target for the first swap
    @param _swapCallData DEX quote data
    */
    function _fillQuote(
        address _fromTokenAddress,
        address _toTokenAddress,
        uint256 _amount,
        address _swapTarget,
        bytes memory _swapCallData
    ) internal returns (uint256 amountBought) {
        if (_fromTokenAddress == _toTokenAddress) return _amount;

        if (
            _fromTokenAddress == wethTokenAddress &&
            _toTokenAddress == address(0)
        ) {
            IWETH(wethTokenAddress).withdraw(_amount);
            return _amount;
        } else if (
            _fromTokenAddress == address(0) &&
            _toTokenAddress == wethTokenAddress
        ) {
            IWETH(wethTokenAddress).deposit.value(_amount)();
            return _amount;
        }

        uint256 valueToSend;
        if (_fromTokenAddress == address(0)) valueToSend = _amount;
        else _approveToken(_fromTokenAddress, _swapTarget, _amount);

        uint256 iniBal = _getBalance(_toTokenAddress);
        require(approvedTargets[_swapTarget], "Target not Authorized");
        (bool success, ) = _swapTarget.call.value(valueToSend)(_swapCallData);
        require(success, "Error Swapping Tokens");
        uint256 finalBal = _getBalance(_toTokenAddress);

        amountBought = finalBal.sub(iniBal);

        require(amountBought > 0, "Swapped To Invalid Intermediate");
    }

    /**
    @notice Utility function to determine the quantity and address of a token being removed
    @param swapAddress indicates the curve pool address from which liquidity to be removed
    @param tokenAddress token to be removed
    @param liquidity Quantity of LP tokens to remove.
    @return  amount Quantity of token removed
    */
    function removeLiquidityReturn(
        address swapAddress,
        address tokenAddress,
        uint256 liquidity
    ) external view returns (uint256 amount) {
        if (tokenAddress == address(0)) tokenAddress = ETHAddress;
        (bool underlying, uint256 index) =
            curveReg.isUnderlyingToken(swapAddress, tokenAddress);
        if (underlying) {
            if (v2Pool[swapAddress]) {
                return
                    ICurveSwap(curveReg.getDepositAddress(swapAddress))
                        .calc_withdraw_one_coin(liquidity, uint256(index));
            } else if (curveReg.shouldAddUnderlying(swapAddress)) {
                return
                    ICurveSwap(curveReg.getDepositAddress(swapAddress))
                        .calc_withdraw_one_coin(liquidity, int128(index), true);
            } else {
                return
                    ICurveSwap(curveReg.getDepositAddress(swapAddress))
                        .calc_withdraw_one_coin(liquidity, int128(index));
            }
        } else {
            address[4] memory poolTokens = curveReg.getPoolTokens(swapAddress);
            address intermediateSwapAddress;
            for (uint256 i = 0; i < 4; i++) {
                intermediateSwapAddress = curveReg.getSwapAddress(
                    poolTokens[i]
                );
                if (intermediateSwapAddress != address(0)) break;
            }
            uint256 metaTokensRec =
                ICurveSwap(swapAddress).calc_withdraw_one_coin(
                    liquidity,
                    int128(1)
                );

            (, index) = curveReg.isUnderlyingToken(
                intermediateSwapAddress,
                tokenAddress
            );

            return
                ICurveSwap(intermediateSwapAddress).calc_withdraw_one_coin(
                    metaTokensRec,
                    int128(index)
                );
        }
    }

    function updateCurveRegistry(Curve_Registry_V2 newCurveRegistry)
        external
        onlyOwner
    {
        require(newCurveRegistry != curveReg, "Already using this Registry");
        curveReg = newCurveRegistry;
    }

    function setApprovedTargets(
        address[] calldata targets,
        bool[] calldata isApproved
    ) external onlyOwner {
        require(targets.length == isApproved.length, "Invalid Input length");

        for (uint256 i = 0; i < targets.length; i++) {
            approvedTargets[targets[i]] = isApproved[i];
        }
    }

    function setV2Pool(address[] calldata pool, bool[] calldata isV2Pool)
        external
        onlyOwner
    {
        require(pool.length == isV2Pool.length, "Invalid Input length");

        for (uint256 i = 0; i < pool.length; i++) {
            v2Pool[pool[i]] = isV2Pool[i];
        }
    }
}