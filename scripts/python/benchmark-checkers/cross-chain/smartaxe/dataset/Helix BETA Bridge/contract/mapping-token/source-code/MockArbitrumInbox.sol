// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
import "hardhat/console.sol";

contract MockArbitrumInbox {
    function calculateRetryableSubmissionFee(uint256 length, uint256 baseFee) external returns(uint256) {
        return 0.01 ether;
    }

    function createRetryableTicket(
        address to,
        uint256 l2CallValue,
        uint256 maxSubmissionCost,
        address excessFeeRefundAddress,
        address callValueRefundAddress,
        uint256 gasLimit,
        uint256 maxFeePerGas,
        bytes calldata data
    ) external payable returns (uint256) {
        // we use this gas price to mock failed remote call
        console.log("mock arbitrum inbox call", to);
        require(msg.value >= 0.01 ether, "fee is required");
        if (maxFeePerGas > 100) {
            (bool result, ) = to.call(data);
            require(result == true, "arbitrum mock call failed");
        }
    }
}
 
