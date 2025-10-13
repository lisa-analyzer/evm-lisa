// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "./ZapBaseV2.sol";

abstract contract ZapOutBaseV3 is ZapBaseV2 {
    using SafeERC20 for IERC20;

    /**
        @dev Transfer tokens from msg.sender to this contract
        @param token The ERC20 token to transfer to this contract
        @param shouldSellEntireBalance If True transfers entrire allowable amount from another contract
        @return Quantity of tokens transferred to this contract
     */
    function _pullTokens(
        address token,
        uint256 amount,
        bool shouldSellEntireBalance
    ) internal returns (uint256) {
        if (shouldSellEntireBalance) {
            require(
                Address.isContract(msg.sender),
                "ERR: shouldSellEntireBalance is true for EOA"
            );

            uint256 allowance =
                IERC20(token).allowance(msg.sender, address(this));
            IERC20(token).safeTransferFrom(
                msg.sender,
                address(this),
                allowance
            );

            return allowance;
        } else {
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

            return amount;
        }
    }

    function _subtractGoodwill(
        address token,
        uint256 amount,
        address affiliate,
        bool enableGoodwill
    ) internal returns (uint256 totalGoodwillPortion) {
        bool whitelisted = feeWhitelist[msg.sender];
        if (enableGoodwill && !whitelisted && goodwill > 0) {
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