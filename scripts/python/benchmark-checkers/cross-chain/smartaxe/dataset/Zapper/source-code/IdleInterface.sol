// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

interface IIdleToken {
    function token() external view returns (address);

    function mintIdleToken(
        uint256 _amount,
        bool _skipWholeRebalance,
        address _referral
    ) external returns (uint256 mintedTokens);

    function redeemIdleToken(uint256 _amount)
        external
        returns (uint256 redeemedTokens);

    function getGovTokens() external view returns (address[] memory);

    function tokenPrice() external view returns (uint256 price);
}

interface IIdleTokenHelper {
    function getRedeemPrice(address idleYieldToken)
        external
        view
        returns (uint256 redeemPrice);
}