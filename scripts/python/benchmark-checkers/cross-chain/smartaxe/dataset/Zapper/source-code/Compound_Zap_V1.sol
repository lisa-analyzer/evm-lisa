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
///@notice This contract deposits and withdraws assets to/from Compound
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "../_base/ZapInBaseV3_1.sol";
import "../_base/ZapOutBaseV3_1.sol";
import "./CompoundInterface.sol";

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

contract Compound_Zap_V1 is ZapInBaseV3_1, ZapOutBaseV3_1 {
    using SafeERC20 for IERC20;

    address private constant wethTokenAddress =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address private constant cETH = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        ZapBaseV2_1(_goodwill, _affiliateSplit)
    {
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
    }

    event zapIn(address sender, address token, uint256 tokensRec);
    event zapOut(address sender, address token, uint256 tokensRec);

    /**
    @notice This function deposits assets into Compound with ETH or ERC20 tokens
    @param fromToken The token used for entry (address(0) if ether)
    @param amountIn The amount of fromToken to invest
    @param cToken Address of the cToken
    @param minCtokens The minimum acceptable quantity cTokens to receive. Reverts otherwise
    @param swapTarget Excecution target for the swap or zap
    @param swapData DEX or Zap data. Must swap to cToken underlying address
    @param affiliate Affiliate address
    @return cTokensRec Quantity of cTokens received
     */
    function ZapIn(
        address fromToken,
        uint256 amountIn,
        address cToken,
        uint256 minCtokens,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external payable stopInEmergency returns (uint256 cTokensRec) {
        uint256 toInvest = _pullTokens(fromToken, amountIn, affiliate, true);

        address toToken = getUnderlyingToken(cToken);

        uint256 tokensBought =
            _fillQuote(fromToken, toToken, toInvest, swapTarget, swapData);

        (cTokensRec) = enterCompound(cToken, toToken, tokensBought);
        require(cTokensRec > minCtokens, "High Slippage");

        IERC20(cToken).safeTransfer(msg.sender, cTokensRec);

        emit zapIn(msg.sender, cToken, cTokensRec);
    }

    function enterCompound(
        address cToken,
        address underlyingToken,
        uint256 underlyingAmount
    ) internal returns (uint256 cTokensRec) {
        uint256 initialBalance = _getBalance(cToken);

        if (underlyingToken == address(0)) {
            ICompoundToken(cToken).mint{ value: underlyingAmount }();
        } else {
            _approveToken(underlyingToken, cToken, underlyingAmount);
            ICompoundToken(cToken).mint(underlyingAmount);
        }

        cTokensRec = _getBalance(cToken) - initialBalance;
    }

    /**
    @notice This function withdraws assets from Compound, receiving tokens or ETH
    @param fromToken The cToken being withdrawn
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
    ) public stopInEmergency returns (uint256 tokensRec) {
        amountIn = _pullTokens(fromToken, amountIn);

        address underlyingToken = getUnderlyingToken(fromToken);

        uint256 underlyingRec =
            exitCompound(fromToken, amountIn, underlyingToken);

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

        emit zapOut(msg.sender, toToken, tokensRec);
    }

    function exitCompound(
        address cToken,
        uint256 cTokenAmount,
        address underlyingToken
    ) internal returns (uint256 underlyingRec) {
        uint256 initialBalance = _getBalance(underlyingToken);

        ICompoundToken(cToken).redeem(cTokenAmount);

        underlyingRec = _getBalance(underlyingToken) - initialBalance;
    }

    function _fillQuote(
        address fromToken,
        address toToken,
        uint256 _amount,
        address swapTarget,
        bytes memory swapData
    ) internal returns (uint256 amountBought) {
        if (fromToken == toToken) {
            return _amount;
        }

        if (fromToken == address(0) && toToken == wethTokenAddress) {
            IWETH(wethTokenAddress).deposit{ value: _amount }();
            return _amount;
        }

        if (fromToken == wethTokenAddress && toToken == address(0)) {
            IWETH(wethTokenAddress).withdraw(_amount);
            return _amount;
        }

        uint256 valueToSend;
        if (fromToken == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(fromToken, swapTarget);
        }

        uint256 initialBalance = _getBalance(toToken);

        require(approvedTargets[swapTarget], "Target not Authorized");
        (bool success, ) = swapTarget.call{ value: valueToSend }(swapData);
        require(success, "Error Swapping Tokens");

        amountBought = _getBalance(toToken) - initialBalance;

        require(amountBought > 0, "Swapped To Invalid Intermediate");
    }

    function getUnderlyingToken(address cToken) public view returns (address) {
        return
            cToken == cETH ? address(0) : ICompoundToken(cToken).underlying();
    }

    function removeLiquidityReturn(address cToken, uint256 cTokenAmt)
        external
        view
        returns (uint256 underlyingRec)
    {
        return
            (cTokenAmt * ICompoundToken(cToken).exchangeRateStored()) / 10**18;
    }
}