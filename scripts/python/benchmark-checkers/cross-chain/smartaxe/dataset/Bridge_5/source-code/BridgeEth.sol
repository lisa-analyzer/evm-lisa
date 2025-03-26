// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import './BridgeBase.sol';

// Next, deploy another component of the decentralized token bridge; the Ethereum token bridge using the following code.
contract BridgeEth is BridgeBase{
    constructor(address token) BridgeBase(token){}
}