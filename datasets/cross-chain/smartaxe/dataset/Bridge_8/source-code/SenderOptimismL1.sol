//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./CrossChainEnabledOptimismL1.sol";

contract SenderOptimismL1 is CrossChainEnabledOptimismL1 {
    // solhint-disable-next-line no-empty-blocks
    constructor(address bridge_) CrossChainEnabledOptimismL1(bridge_) {}

    function sendCrossChainMessage(
        address destination,
        bytes memory data,
        bytes memory crossChainTxParams
    ) external payable {
        _sendCrossChainMessage(destination, data, crossChainTxParams);
    }
}
