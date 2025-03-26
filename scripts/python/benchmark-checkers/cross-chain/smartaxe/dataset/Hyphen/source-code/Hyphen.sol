// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

interface HyphenLiquidityPoolManager {
    function depositErc20(
        address tokenAddress,
        address receiver,
        uint256 amount,
        uint256 toChainId
    ) external;

    function depositNative(address receiver, uint256 toChainId)
        external
        payable;
}