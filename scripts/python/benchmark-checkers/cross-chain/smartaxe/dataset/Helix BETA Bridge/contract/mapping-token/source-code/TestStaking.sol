// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
import "hardhat/console.sol";

contract TestStaking {
    function stakingRewards(uint _value, uint _month) view public returns (uint) {
        // these two actually mean the multiplier is 1.015
        uint numerator = 67 ** _month;
        uint denominator = 66 ** _month;
        uint quotient;
        uint remainder;
        uint unitInterest = 10**9;

        assembly {
            quotient := div(numerator, denominator)
            remainder := mod(numerator, denominator)
        }
        console.log(numerator, denominator, quotient, remainder);
        // depositing X RING for 12 months, interest is about (1 * unitInterest * X / 10**7) KTON
        // and the multiplier is about 3
        // ((quotient - 1) * 1000 + remainder * 1000 / denominator) is 197 when _month is 12.
        return (unitInterest * uint(_value)) * ((quotient - 1) * 1000 + remainder * 1000 / denominator) / (197 * 10**4);
    }
}
