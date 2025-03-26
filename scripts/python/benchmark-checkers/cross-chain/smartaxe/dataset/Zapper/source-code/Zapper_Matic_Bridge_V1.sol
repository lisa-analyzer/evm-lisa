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
///@notice This contract swaps and bridges ETH/Tokens to Matic/Polygon
// SPDX-License-Identifier: GPLv2

pragma solidity ^0.8.0;

import "../../_base/ZapBaseV2.sol";

// PoS Bridge
interface IRootChainManager {
    function depositEtherFor(address user) external payable;

    function depositFor(
        address user,
        address rootToken,
        bytes calldata depositData
    ) external;

    function tokenToType(address) external returns (bytes32);

    function typeToPredicate(bytes32) external returns (address);
}

// Plasma Bridge
interface IDepositManager {
    function depositERC20ForUser(
        address _token,
        address _user,
        uint256 _amount
    ) external;
}

interface IWETH {
    function deposit() external payable;
}

contract Zapper_Matic_Bridge_V1_1 is ZapBaseV2 {
    using SafeERC20 for IERC20;

    address private constant wethTokenAddress =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IRootChainManager public rootChainManager =
        IRootChainManager(0xA0c68C638235ee32657e8f720a23ceC1bFc77C77);
    IDepositManager public depositManager =
        IDepositManager(0x401F6c983eA34274ec46f84D70b31C151321188b);

    address private constant maticAddress =
        0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0;

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        ZapBaseV2(_goodwill, _affiliateSplit)
    {
        _approveToken(maticAddress, address(depositManager));

        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
    }

    /**
    @notice Bridge from Ethereum to Matic
    @notice Use index 0 for primary swap and index 1 for matic swap
    @param fromToken Address of the token to swap from
    @param toToken Address of the token to bridge
    @param swapAmounts Quantites of fromToken to swap to toToken and matic
    @param minTokensRec Minimum acceptable quantity of swapped tokens and/or matic
    @param swapTargets Execution targets for swaps
    @param swapData DEX swap data
    @param affiliate Affiliate address
    */
    function ZapBridge(
        address fromToken,
        address toToken,
        uint256[2] calldata swapAmounts,
        uint256[2] calldata minTokensRec,
        address[2] calldata swapTargets,
        bytes[2] calldata swapData,
        address affiliate
    ) external payable stopInEmergency {
        uint256[2] memory toInvest =
            _pullTokens(fromToken, swapAmounts, affiliate);

        if (swapAmounts[0] > 0) {
            // Token swap
            uint256 toTokenAmt =
                _fillQuote(
                    fromToken,
                    toInvest[0],
                    toToken,
                    swapTargets[0],
                    swapData[0]
                );
            require(toTokenAmt >= minTokensRec[0], "ERR: High Slippage 1");

            _bridgeToken(toToken, toTokenAmt);
        }

        // Matic swap
        if (swapAmounts[1] > 0) {
            uint256 maticAmount =
                _fillQuote(
                    fromToken,
                    toInvest[1],
                    maticAddress,
                    swapTargets[1],
                    swapData[1]
                );
            require(maticAmount >= minTokensRec[1], "ERR: High Slippage 2");

            _bridgeMatic(maticAmount);
        }
    }

    function _bridgeToken(address toToken, uint256 toTokenAmt) internal {
        if (toToken == address(0)) {
            rootChainManager.depositEtherFor{ value: toTokenAmt }(msg.sender);
        } else {
            bytes32 tokenType = rootChainManager.tokenToType(toToken);
            address predicate = rootChainManager.typeToPredicate(tokenType);
            _approveToken(toToken, predicate);
            rootChainManager.depositFor(
                msg.sender,
                toToken,
                abi.encode(toTokenAmt)
            );
        }
    }

    function _bridgeMatic(uint256 maticAmount) internal {
        depositManager.depositERC20ForUser(
            maticAddress,
            msg.sender,
            maticAmount
        );
    }

    // 0x Swap
    function _fillQuote(
        address fromToken,
        uint256 amount,
        address toToken,
        address swapTarget,
        bytes memory swapCallData
    ) internal returns (uint256 amtBought) {
        if (fromToken == wethTokenAddress && toToken == address(0)) {
            IWETH(wethTokenAddress).deposit{ value: amount }();
            return amount;
        }

        uint256 valueToSend;

        if (fromToken == toToken) {
            return amount;
        }

        if (fromToken == address(0)) {
            valueToSend = amount;
        } else {
            _approveToken(fromToken, swapTarget);
        }

        uint256 iniBal = _getBalance(toToken);
        require(approvedTargets[swapTarget], "Target not Authorized");
        (bool success, ) = swapTarget.call{ value: valueToSend }(swapCallData);
        require(success, "Error Swapping Tokens");
        uint256 finalBal = _getBalance(toToken);

        amtBought = finalBal - iniBal;
    }

    function _pullTokens(
        address fromToken,
        uint256[2] memory swapAmounts,
        address affiliate
    ) internal returns (uint256[2] memory toInvest) {
        if (fromToken == address(0)) {
            require(msg.value > 0, "No eth sent");
            require(
                swapAmounts[0] + (swapAmounts[1]) == msg.value,
                "msg.value != fromTokenAmounts"
            );
        } else {
            require(msg.value == 0, "Eth sent with token");

            // transfer token
            IERC20(fromToken).safeTransferFrom(
                msg.sender,
                address(this),
                swapAmounts[0] + (swapAmounts[1])
            );
        }

        if (swapAmounts[0] > 0) {
            toInvest[0] =
                swapAmounts[0] -
                (_subtractGoodwill(fromToken, swapAmounts[0], affiliate));
        }

        if (swapAmounts[1] > 0) {
            toInvest[1] =
                swapAmounts[1] -
                (_subtractGoodwill(fromToken, swapAmounts[1], affiliate));
        }
    }

    function _subtractGoodwill(
        address token,
        uint256 amount,
        address affiliate
    ) internal returns (uint256 totalGoodwillPortion) {
        bool whitelisted = feeWhitelist[msg.sender];
        if (!whitelisted && goodwill > 0) {
            totalGoodwillPortion = (amount * goodwill) / 10000;

            if (affiliates[affiliate]) {
                if (token == address(0)) {
                    token = ETHAddress;
                }

                uint256 affiliatePortion =
                    (totalGoodwillPortion * affiliateSplit) / 100;
                affiliateBalance[affiliate][token] += affiliatePortion;
                totalAffiliateBalance[token] += affiliatePortion;
            }
        }
    }
}