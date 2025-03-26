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
///@notice This contract deposits and withdraws assets to/from Alpha Homora V2 Earn
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "../_base/ZapInBaseV3_1.sol";
import "../_base/ZapOutBaseV3_1.sol";
import "./ibTokenInterface.sol";
import "../Cream/CreamInterface.sol";

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

contract Alpha_Homora_Earn_Zap_V1 is ZapInBaseV3_1, ZapOutBaseV3_1 {
    using SafeERC20 for IERC20;

    address private constant wethTokenAddress =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address private constant ibETH = 0xeEa3311250FE4c3268F8E684f7C87A82fF183Ec1;

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        ZapBaseV2_1(_goodwill, _affiliateSplit)
    {
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
        transferOwnership(ZapperAdmin);
    }

    event zapIn(
        address sender,
        address token,
        uint256 tokensRec,
        address affiliate
    );
    event zapOut(
        address sender,
        address token,
        uint256 tokensRec,
        address affiliate
    );

    /**
    @notice This function deposits assets into Alpha Homora V2 Earn with ETH or ERC20 tokens
    @param fromToken The token used for entry (address(0) if ether)
    @param amountIn The amount of fromToken to invest
    @param ibToken Address of the ibToken
    @param minIbTokens The minimum acceptable quantity ibTokens to receive. Reverts otherwise
    @param swapTarget Excecution target for the swap or zap
    @param swapData DEX or Zap data. Must swap to ibToken underlying address
    @param affiliate Affiliate address
    @return ibTokensRec Quantity of ibTokens received
     */
    function ZapIn(
        address fromToken,
        uint256 amountIn,
        address ibToken,
        uint256 minIbTokens,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external payable stopInEmergency returns (uint256 ibTokensRec) {
        uint256 toInvest = _pullTokens(fromToken, amountIn, affiliate, true);

        address toToken = getUnderlyingToken(ibToken);

        uint256 tokensBought =
            _fillQuote(fromToken, toToken, toInvest, swapTarget, swapData);

        (ibTokensRec) = enterAlpha(ibToken, toToken, tokensBought);
        require(ibTokensRec > minIbTokens, "High Slippage");

        IERC20(ibToken).safeTransfer(msg.sender, ibTokensRec);

        emit zapIn(msg.sender, ibToken, ibTokensRec, affiliate);
    }

    function enterAlpha(
        address ibToken,
        address underlyingToken,
        uint256 underlyingAmount
    ) internal returns (uint256 ibTokensRec) {
        uint256 initialBalance = _getBalance(ibToken);

        if (underlyingToken == address(0)) {
            IibToken(ibToken).deposit{ value: underlyingAmount }();
        } else {
            _approveToken(underlyingToken, ibToken, underlyingAmount);
            IibToken(ibToken).deposit(underlyingAmount);
        }

        ibTokensRec = _getBalance(ibToken) - initialBalance;
    }

    /**
    @notice This function withdraws assets from Alpha Homora V2 Earn, receiving tokens or ETH
    @param fromToken The ibToken being withdrawn
    @param amountIn The quantity of fromToken to withdraw
    @param toToken Address of the token to receive (0 address if ETH)
    @param minToTokens The minimum acceptable quantity tokens to receive. Reverts otherwise
    @param swapTarget Excecution target for the swap or zap
    @param swapData DEX or Zap data
    @param affiliate Affiliate address
    @return tokensRec Quantity of aTokens received
     */
    function ZapOut(
        address fromToken,
        uint256 amountIn,
        address toToken,
        uint256 minToTokens,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external stopInEmergency returns (uint256 tokensRec) {
        amountIn = _pullTokens(fromToken, amountIn);

        address underlyingToken = getUnderlyingToken(fromToken);

        uint256 underlyingRec = exitAlpha(fromToken, amountIn, underlyingToken);

        tokensRec = _fillQuote(
            underlyingToken,
            toToken,
            underlyingRec,
            swapTarget,
            swapData
        );

        require(tokensRec >= minToTokens, "High Slippage");

        uint256 totalGoodwillPortion;

        if (toToken == address(0)) {
            totalGoodwillPortion = _subtractGoodwill(
                ETHAddress,
                tokensRec,
                affiliate,
                true
            );

            payable(msg.sender).transfer(tokensRec - totalGoodwillPortion);
        } else {
            totalGoodwillPortion = _subtractGoodwill(
                toToken,
                tokensRec,
                affiliate,
                true
            );

            IERC20(toToken).safeTransfer(
                msg.sender,
                tokensRec - totalGoodwillPortion
            );
        }

        tokensRec = tokensRec - totalGoodwillPortion;

        emit zapOut(msg.sender, toToken, tokensRec, affiliate);
    }

    function exitAlpha(
        address ibToken,
        uint256 ibTokenAmount,
        address underlyingToken
    ) internal returns (uint256 underlyingRec) {
        uint256 initialBalance = _getBalance(underlyingToken);

        IibToken(ibToken).withdraw(ibTokenAmount);

        underlyingRec = _getBalance(underlyingToken) - initialBalance;
    }

    function _fillQuote(
        address fromToken,
        address toToken,
        uint256 amount,
        address swapTarget,
        bytes memory swapData
    ) internal returns (uint256 amountBought) {
        if (fromToken == toToken) {
            return amount;
        }

        if (fromToken == address(0) && toToken == wethTokenAddress) {
            IWETH(wethTokenAddress).deposit{ value: amount }();
            return amount;
        }

        if (fromToken == wethTokenAddress && toToken == address(0)) {
            IWETH(wethTokenAddress).withdraw(amount);
            return amount;
        }

        uint256 valueToSend;
        if (fromToken == address(0)) {
            valueToSend = amount;
        } else {
            _approveToken(fromToken, swapTarget, amount);
        }

        uint256 initialBalance = _getBalance(toToken);

        require(approvedTargets[swapTarget], "Target not Authorized");
        (bool success, ) = swapTarget.call{ value: valueToSend }(swapData);
        require(success, "Error Swapping Tokens");

        amountBought = _getBalance(toToken) - initialBalance;

        require(amountBought > 0, "Swapped To Invalid Intermediate");
    }

    function getCyToken(address ibToken) public view returns (address) {
        return IibToken(ibToken).cToken();
    }

    function getUnderlyingToken(address ibToken) public view returns (address) {
        return ibToken == ibETH ? address(0) : IibToken(ibToken).uToken();
    }

    function removeLiquidityReturn(address ibToken, uint256 ibTokenAmount)
        external
        view
        returns (uint256 underlyingRec)
    {
        return
            (ibTokenAmount *
                ICreamToken(getCyToken(ibToken)).exchangeRateStored()) / 10**18;
    }
}