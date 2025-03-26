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
///@notice This contract deposits and withdraws assets to/from Idle Finance 'Best Yield' and 'Risk Adjusted' opportunities
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "../_base/ZapInBaseV3_1.sol";
import "../_base/ZapOutBaseV3_1.sol";
import "./IdleInterface.sol";

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

contract Idle_Zap_V1 is ZapInBaseV3_1, ZapOutBaseV3_1 {
    using SafeERC20 for IERC20;

    address private constant wethTokenAddress =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IIdleTokenHelper private constant IdleTokenHelper =
        IIdleTokenHelper(0x04Ce60ed10F6D2CfF3AA015fc7b950D13c113be5);

    // COMP, IDLE, stkAAVE
    address[] govTokens = [
        0xc00e94Cb662C3520282E6f5717214004A7f26888,
        0x875773784Af8135eA0ef43b5a374AaD105c5D39e,
        0x4da27a545c0c5B758a6BA100e3a049001de870f5
    ];

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        ZapBaseV2_1(_goodwill, _affiliateSplit)
    {
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
    }

    event zapIn(address sender, address token, uint256 tokensRec);
    event zapOut(address sender, address token, uint256 tokensRec);

    /**
    @notice This function deposits assets into Idle finance with ETH or ERC20 tokens
    @param fromToken The token used for entry (address(0) if ether)
    @param amountIn The amount of fromToken to invest
    @param idleToken Address of the Idle token
    @param minIdleTokens The minimum acceptable quantity Idle tokens to receive. Reverts otherwise
    @param swapTarget Excecution target for the swap or zap
    @param swapData DEX or Zap data. Must swap to cToken underlying address
    @param affiliate Affiliate address
    @return idleTokensRec Quantity of cTokens received
     */
    function ZapIn(
        address fromToken,
        uint256 amountIn,
        address idleToken,
        uint256 minIdleTokens,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external payable stopInEmergency returns (uint256 idleTokensRec) {
        uint256 toInvest = _pullTokens(fromToken, amountIn, affiliate, true);

        address toToken = getUnderlyingToken(idleToken);

        uint256 tokensBought =
            _fillQuote(fromToken, toToken, toInvest, swapTarget, swapData);

        (idleTokensRec) = enterIdle(idleToken, toToken, tokensBought);
        require(idleTokensRec > minIdleTokens, "High Slippage");

        IERC20(idleToken).safeTransfer(msg.sender, idleTokensRec);

        emit zapIn(msg.sender, idleToken, idleTokensRec);
    }

    function enterIdle(
        address idleToken,
        address underlyingToken,
        uint256 underlyingAmount
    ) internal returns (uint256 idleTokensRec) {
        uint256 initialBalance = _getBalance(idleToken);

        _approveToken(underlyingToken, idleToken, underlyingAmount);
        IIdleToken(idleToken).mintIdleToken(
            underlyingAmount,
            true,
            ZapperAdmin
        );

        idleTokensRec = _getBalance(idleToken) - initialBalance;
    }

    /**
    @notice This function withdraws assets from Idle finance, receiving tokens or ETH
    @param fromToken The Idle token being withdrawn
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

        (uint256 underlyingRec, uint256[] memory govTokensRec) =
            exitIdle(fromToken, amountIn);

        address underlyingToken = getUnderlyingToken(fromToken);

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

        for (uint256 i = 0; i < govTokens.length; i++) {
            if (govTokensRec[i] > 0) {
                IERC20(govTokens[i]).safeTransfer(msg.sender, govTokensRec[i]);
            }
        }

        tokensRec = tokensRec - totalGoodwillPortion;

        emit zapOut(msg.sender, toToken, tokensRec);
    }

    function exitIdle(address idleToken, uint256 idleTokenAmount)
        internal
        returns (uint256, uint256[] memory)
    {
        uint256[] memory initialGovBalance = new uint256[](govTokens.length);
        for (uint256 i = 0; i < govTokens.length; i++) {
            initialGovBalance[i] = _getBalance(govTokens[i]);
        }

        uint256 underlyingRec =
            IIdleToken(idleToken).redeemIdleToken(idleTokenAmount);

        uint256[] memory govTokensRec = new uint256[](govTokens.length);
        for (uint256 i = 0; i < govTokens.length; i++) {
            govTokensRec[i] = _getBalance(govTokens[i]) - initialGovBalance[i];
        }
        return (underlyingRec, govTokensRec);
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

    function getUnderlyingToken(address idleToken)
        public
        view
        returns (address)
    {
        return IIdleToken(idleToken).token();
    }

    function removeLiquidityReturn(address idleToken, uint256 idleTokenAmount)
        external
        view
        returns (uint256 underlyingRec)
    {
        return
            (IdleTokenHelper.getRedeemPrice(idleToken) * idleTokenAmount) /
            10**18;
    }
}