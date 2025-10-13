// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IBiconomyRouter {
    function depositErc20(
        address tokenAddress,
        address receiver,
        uint256 amount,
        uint256 toChainId
    ) external;

    function depositNative(address receiver, uint256 toChainId) external payable;
}