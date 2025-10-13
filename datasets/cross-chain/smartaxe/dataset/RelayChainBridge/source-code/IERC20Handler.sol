pragma solidity 0.6.4;

interface IERC20Handler {
    function setFeePercent(uint256 feePercent) external;
    function setFeePercentTreasury(address newTreasury) external;
}