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
///@notice This contract adds liquidity to Curve pools with ETH or ERC tokens.
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "../_base/ZapInBaseV3.sol";

interface IWETH {
    function deposit() external payable;
}

interface ICurveSwap {
    function coins(int128 arg0) external view returns (address);

    function underlying_coins(int128 arg0) external view returns (address);

    function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount)
        external;

    function add_liquidity(
        uint256[4] calldata amounts,
        uint256 min_mint_amount,
        bool addUnderlying
    ) external;

    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount)
        external;

    function add_liquidity(
        uint256[3] calldata amounts,
        uint256 min_mint_amount,
        bool addUnderlying
    ) external;

    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount)
        external;

    function add_liquidity(
        uint256[2] calldata amounts,
        uint256 min_mint_amount,
        bool addUnderlying
    ) external;
}

interface ICurveEthSwap {
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount)
        external
        payable
        returns (uint256);
}

interface ICurveRegistry {
    function getSwapAddress(address tokenAddress)
        external
        view
        returns (address swapAddress);

    function getTokenAddress(address swapAddress)
        external
        view
        returns (address tokenAddress);

    function getDepositAddress(address swapAddress)
        external
        view
        returns (address depositAddress);

    function getPoolTokens(address swapAddress)
        external
        view
        returns (address[4] memory poolTokens);

    function shouldAddUnderlying(address swapAddress)
        external
        view
        returns (bool);

    function getNumTokens(address swapAddress)
        external
        view
        returns (uint8 numTokens);

    function isBtcPool(address swapAddress) external view returns (bool);

    function isEthPool(address swapAddress) external view returns (bool);

    function isUnderlyingToken(
        address swapAddress,
        address tokenContractAddress
    ) external view returns (bool, uint8);
}

contract Curve_ZapIn_General_V4 is ZapInBaseV3 {
    using SafeERC20 for IERC20;

    ICurveRegistry public curveReg;

    address private constant wethTokenAddress =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    constructor(
        ICurveRegistry _curveRegistry,
        uint256 _goodwill,
        uint256 _affiliateSplit
    ) ZapBaseV2(_goodwill, _affiliateSplit) {
        curveReg = _curveRegistry;

        // 0x exchange
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
    }

    event zapIn(address sender, address pool, uint256 tokensRec);

    /**
        @notice This function adds liquidity to a Curve pool with ETH or ERC20 tokens
        @param fromTokenAddress The token used for entry (address(0) if ether)
        @param toTokenAddress The intermediate ERC20 token to swap to
        @param swapAddress Curve swap address for the pool
        @param incomingTokenQty The amount of fromTokenAddress to invest
        @param minPoolTokens The minimum acceptable quantity of Curve LP to receive. Reverts otherwise
        @param swapTarget Excecution target for the first swap
        @param swapData DEX quote data
        @param affiliate Affiliate address
        @param shouldSellEntireBalance If True transfers entrire allowable amount from another contract
        @return crvTokensBought Quantity of Curve LP tokens received
    */
    function ZapIn(
        address fromTokenAddress,
        address toTokenAddress,
        address swapAddress,
        uint256 incomingTokenQty,
        uint256 minPoolTokens,
        address swapTarget,
        bytes calldata swapData,
        address affiliate,
        bool shouldSellEntireBalance
    ) external payable stopInEmergency returns (uint256 crvTokensBought) {
        uint256 toInvest =
            _pullTokens(
                fromTokenAddress,
                incomingTokenQty,
                affiliate,
                true,
                shouldSellEntireBalance
            );
        if (fromTokenAddress == address(0)) {
            fromTokenAddress = ETHAddress;
        }

        // perform zapIn
        crvTokensBought = _performZapIn(
            fromTokenAddress,
            toTokenAddress,
            swapAddress,
            toInvest,
            swapTarget,
            swapData
        );

        require(
            crvTokensBought > minPoolTokens,
            "Received less than minPoolTokens"
        );

        address poolTokenAddress = curveReg.getTokenAddress(swapAddress);

        emit zapIn(msg.sender, poolTokenAddress, crvTokensBought);

        IERC20(poolTokenAddress).transfer(msg.sender, crvTokensBought);
    }

    function _performZapIn(
        address fromTokenAddress,
        address toTokenAddress,
        address swapAddress,
        uint256 toInvest,
        address swapTarget,
        bytes memory swapData
    ) internal returns (uint256 crvTokensBought) {
        (bool isUnderlying, uint8 underlyingIndex) =
            curveReg.isUnderlyingToken(swapAddress, fromTokenAddress);

        if (isUnderlying) {
            crvTokensBought = _enterCurve(
                swapAddress,
                toInvest,
                underlyingIndex
            );
        } else {
            //swap tokens using 0x swap
            uint256 tokensBought =
                _fillQuote(
                    fromTokenAddress,
                    toTokenAddress,
                    toInvest,
                    swapTarget,
                    swapData
                );
            if (toTokenAddress == address(0)) toTokenAddress = ETHAddress;

            //get underlying token index
            (isUnderlying, underlyingIndex) = curveReg.isUnderlyingToken(
                swapAddress,
                toTokenAddress
            );

            if (isUnderlying) {
                crvTokensBought = _enterCurve(
                    swapAddress,
                    tokensBought,
                    underlyingIndex
                );
            } else {
                (uint256 tokens, uint8 metaIndex) =
                    _enterMetaPool(swapAddress, toTokenAddress, tokensBought);

                crvTokensBought = _enterCurve(swapAddress, tokens, metaIndex);
            }
        }
    }

    /**
        @notice This function gets adds the liquidity for meta pools and returns the token index and swap tokens
        @param swapAddress Curve swap address for the pool
        @param toTokenAddress The ERC20 token to which from token to be convert
        @param swapTokens quantity of toToken to invest
        @return tokensBought quantity of curve LP acquired
        @return index index of LP token in swapAddress whose pool tokens were acquired
     */
    function _enterMetaPool(
        address swapAddress,
        address toTokenAddress,
        uint256 swapTokens
    ) internal returns (uint256 tokensBought, uint8 index) {
        address[4] memory poolTokens = curveReg.getPoolTokens(swapAddress);
        for (uint8 i = 0; i < 4; i++) {
            address intermediateSwapAddress =
                curveReg.getSwapAddress(poolTokens[i]);
            if (intermediateSwapAddress != address(0)) {
                (, index) = curveReg.isUnderlyingToken(
                    intermediateSwapAddress,
                    toTokenAddress
                );

                tokensBought = _enterCurve(
                    intermediateSwapAddress,
                    swapTokens,
                    index
                );

                return (tokensBought, i);
            }
        }
    }

    function _fillQuote(
        address fromTokenAddress,
        address toTokenAddress,
        uint256 amount,
        address swapTarget,
        bytes memory swapData
    ) internal returns (uint256 amountBought) {
        if (fromTokenAddress == toTokenAddress) {
            return amount;
        }

        if (swapTarget == wethTokenAddress) {
            IWETH(wethTokenAddress).deposit{ value: amount }();
            return amount;
        }

        uint256 valueToSend;
        if (fromTokenAddress == ETHAddress) {
            valueToSend = amount;
        } else {
            _approveToken(fromTokenAddress, swapTarget, amount);
        }

        uint256 initialBalance = _getBalance(toTokenAddress);

        require(approvedTargets[swapTarget], "Target not Authorized");
        (bool success, ) = swapTarget.call{ value: valueToSend }(swapData);
        require(success, "Error Swapping Tokens");

        amountBought = _getBalance(toTokenAddress) - initialBalance;

        require(amountBought > 0, "Swapped To Invalid Intermediate");
    }

    /**
        @notice This function adds liquidity to a curve pool
        @param swapAddress Curve swap address for the pool
        @param amount The quantity of tokens being added as liquidity
        @param index The token index for the add_liquidity call
        @return crvTokensBought the quantity of curve LP tokens received
    */
    function _enterCurve(
        address swapAddress,
        uint256 amount,
        uint8 index
    ) internal returns (uint256 crvTokensBought) {
        address tokenAddress = curveReg.getTokenAddress(swapAddress);
        address depositAddress = curveReg.getDepositAddress(swapAddress);
        uint256 initialBalance = _getBalance(tokenAddress);
        address entryToken = curveReg.getPoolTokens(swapAddress)[index];
        if (entryToken != ETHAddress) {
            IERC20(entryToken).safeIncreaseAllowance(
                address(depositAddress),
                amount
            );
        }

        uint256 numTokens = curveReg.getNumTokens(swapAddress);
        bool addUnderlying = curveReg.shouldAddUnderlying(swapAddress);

        if (numTokens == 4) {
            uint256[4] memory amounts;
            amounts[index] = amount;
            if (addUnderlying) {
                ICurveSwap(depositAddress).add_liquidity(amounts, 0, true);
            } else {
                ICurveSwap(depositAddress).add_liquidity(amounts, 0);
            }
        } else if (numTokens == 3) {
            uint256[3] memory amounts;
            amounts[index] = amount;
            if (addUnderlying) {
                ICurveSwap(depositAddress).add_liquidity(amounts, 0, true);
            } else {
                ICurveSwap(depositAddress).add_liquidity(amounts, 0);
            }
        } else {
            uint256[2] memory amounts;
            amounts[index] = amount;
            if (curveReg.isEthPool(depositAddress)) {
                ICurveEthSwap(depositAddress).add_liquidity{ value: amount }(
                    amounts,
                    0
                );
            } else if (addUnderlying) {
                ICurveSwap(depositAddress).add_liquidity(amounts, 0, true);
            } else {
                ICurveSwap(depositAddress).add_liquidity(amounts, 0);
            }
        }
        crvTokensBought = _getBalance(tokenAddress) - initialBalance;
    }

    function updateCurveRegistry(ICurveRegistry newCurveRegistry)
        external
        onlyOwner
    {
        require(newCurveRegistry != curveReg, "Already using this Registry");
        curveReg = newCurveRegistry;
    }
}