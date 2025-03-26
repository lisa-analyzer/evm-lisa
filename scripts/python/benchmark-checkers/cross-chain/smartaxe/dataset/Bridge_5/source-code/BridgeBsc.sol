// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import './BridgeBase.sol';

// After constructing and deploying bridge base code, deploy Binance bridge using the following code
contract BridgeBsc is BridgeBase {
    constructor(address token) BridgeBase(token){}
}