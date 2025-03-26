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
// SPDX-License-Identifier: GPL-2.0

///@author Zapper
///@notice this contract adds liquidity to Balancer liquidity pools in one transaction

pragma solidity ^0.8.0;
import "../_base/ZapInBaseV3_1.sol";

interface IWETH {
    function deposit() external payable;
}

interface IBFactory {
    function isBPool(address b) external view returns (bool);
}

interface IBPool {
    function joinswapExternAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) external payable returns (uint256 poolAmountOut);

    function isBound(address t) external view returns (bool);
}

contract Balancer_ZapIn_General_V4 is ZapInBaseV3_1 {
    using SafeERC20 for IERC20;

    IBFactory BalancerFactory =
        IBFactory(0x9424B1412450D0f8Fc2255FAf6046b98213B76Bd);

    address private constant wethTokenAddress =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        ZapBaseV2_1(_goodwill, _affiliateSplit)
    {
        // 0x exchange
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;

        transferOwnership(ZapperAdmin);
    }

    event zapIn(address sender, address pool, uint256 tokensRec);

    /**
    @notice This function is used to invest in given balancer pool using ETH/ERC20 Tokens
    @param _FromTokenContractAddress The token used for investment (address(0x00) if ether)
    @param _ToBalancerPoolAddress The address of balancer pool
    @param _toTokenContractAddress The token with which we are adding liquidity
    @param _amount The amount of fromToken to invest
    @param _minPoolTokens Minimum quantity of pool tokens to receive. Reverts otherwise
    @param _swapTarget indicates the execution target for swap.
    @param swapData indicates the callData for execution
    @param affiliate Affiliate address
    @return LPTRec quantity of Balancer pool tokens acquired
    */
    function ZapIn(
        address _FromTokenContractAddress,
        address _ToBalancerPoolAddress,
        address _toTokenContractAddress,
        uint256 _amount,
        uint256 _minPoolTokens,
        address _swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external payable stopInEmergency returns (uint256 LPTRec) {
        require(
            BalancerFactory.isBPool(_ToBalancerPoolAddress),
            "Invalid Balancer Pool"
        );

        // get incoming tokens
        uint256 toInvest =
            _pullTokens(_FromTokenContractAddress, _amount, affiliate, true);

        LPTRec = _performZapIn(
            _FromTokenContractAddress,
            _ToBalancerPoolAddress,
            toInvest,
            _toTokenContractAddress,
            _swapTarget,
            swapData
        );

        require(LPTRec >= _minPoolTokens, "High Slippage");

        IERC20(_ToBalancerPoolAddress).safeTransfer(msg.sender, LPTRec);

        emit zapIn(msg.sender, _ToBalancerPoolAddress, LPTRec);

        return LPTRec;
    }

    function _performZapIn(
        address _FromTokenContractAddress,
        address _ToBalancerPoolAddress,
        uint256 _amount,
        address _toTokenContractAddress,
        address _swapTarget,
        bytes memory swapData
    ) internal returns (uint256 tokensBought) {
        bool isBound =
            IBPool(_ToBalancerPoolAddress).isBound(_FromTokenContractAddress);

        uint256 balancerTokens;

        if (isBound) {
            balancerTokens = _enter2Balancer(
                _ToBalancerPoolAddress,
                _FromTokenContractAddress,
                _amount
            );
        } else {
            uint256 tokenBought =
                _fillQuote(
                    _FromTokenContractAddress,
                    _toTokenContractAddress,
                    _amount,
                    _swapTarget,
                    swapData
                );

            //get BPT
            balancerTokens = _enter2Balancer(
                _ToBalancerPoolAddress,
                _toTokenContractAddress,
                tokenBought
            );
        }

        return balancerTokens;
    }

    function _fillQuote(
        address _fromTokenAddress,
        address toToken,
        uint256 _amount,
        address _swapTarget,
        bytes memory swapData
    ) internal returns (uint256 amtBought) {
        if (_fromTokenAddress == toToken) {
            return _amount;
        }

        if (_fromTokenAddress == address(0) && toToken == wethTokenAddress) {
            IWETH(wethTokenAddress).deposit{ value: _amount }();
            return _amount;
        }

        uint256 valueToSend;
        if (_fromTokenAddress == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(_fromTokenAddress, _swapTarget, _amount);
        }

        uint256 iniBal = _getBalance(toToken);
        require(approvedTargets[_swapTarget], "Target not Authorized");
        (bool success, ) = _swapTarget.call{ value: valueToSend }(swapData);
        require(success, "Error Swapping Tokens 1");
        uint256 finalBal = _getBalance(toToken);

        amtBought = finalBal - iniBal;
        require(amtBought > 0, "Swapped To Invalid Intermediate");
    }

    function _enter2Balancer(
        address _ToBalancerPoolAddress,
        address _FromTokenContractAddress,
        uint256 tokens2Trade
    ) internal returns (uint256 poolTokensOut) {
        require(
            IBPool(_ToBalancerPoolAddress).isBound(_FromTokenContractAddress),
            "Token not bound"
        );

        uint256 allowance =
            IERC20(_FromTokenContractAddress).allowance(
                address(this),
                _ToBalancerPoolAddress
            );

        if (allowance < tokens2Trade) {
            IERC20(_FromTokenContractAddress).safeApprove(
                _ToBalancerPoolAddress,
                tokens2Trade
            );
        }

        poolTokensOut = IBPool(_ToBalancerPoolAddress).joinswapExternAmountIn(
            _FromTokenContractAddress,
            tokens2Trade,
            1
        );

        require(poolTokensOut > 0, "Error Entering Pool");
    }
}