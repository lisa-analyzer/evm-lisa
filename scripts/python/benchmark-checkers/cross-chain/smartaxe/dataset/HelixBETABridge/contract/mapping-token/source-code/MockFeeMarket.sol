// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

contract MockFeeMarket {
    function market_fee() external pure returns (uint256 fee) {
        return 10 ether;
    }
}
