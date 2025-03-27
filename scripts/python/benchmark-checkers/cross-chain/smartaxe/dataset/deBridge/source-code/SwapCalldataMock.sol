// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./CalldataUtils.sol";
import "./SwapCalldataUtils.sol";

contract SwapCalldataMock {
    using CalldataUtils for bytes;
    using SwapCalldataUtils for bytes;

    function patch(bytes calldata _data, uint256 amount)
        external
        pure
        returns (bytes memory patchedData, bool success)
    {
        (patchedData, success) = _data.patch(amount);
    }
}