pragma solidity ^0.5.7;

import "./ZapBaseV1.sol";

contract ZapOutBaseV2_1 is ZapBaseV1 {
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

            IERC20 _token = IERC20(token);
            uint256 allowance = _token.allowance(msg.sender, address(this));
            _token.safeTransferFrom(msg.sender, address(this), allowance);

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
            totalGoodwillPortion = SafeMath.div(
                SafeMath.mul(amount, goodwill),
                10000
            );

            if (affiliates[affiliate]) {
                if (token == address(0)) {
                    token = ETHAddress;
                }

                uint256 affiliatePortion =
                    totalGoodwillPortion.mul(affiliateSplit).div(100);
                affiliateBalance[affiliate][token] = affiliateBalance[
                    affiliate
                ][token]
                    .add(affiliatePortion);
                totalAffiliateBalance[token] = totalAffiliateBalance[token].add(
                    affiliatePortion
                );
            }
        }
    }
}