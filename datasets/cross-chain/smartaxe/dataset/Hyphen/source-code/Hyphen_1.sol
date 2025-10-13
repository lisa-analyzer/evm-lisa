// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

interface HyphenLiquidityPoolManager {
    function depositErc20(
        uint256 toChainId,
        address tokenAddress,
        address receiver,
        uint256 amount,
        string calldata tag
    ) external;

    function depositNative(
        address receiver,
        uint256 toChainId,
        string calldata tag
    ) external payable;
}