// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;


interface IQBridgeDelegator {

    function delegate(address xToken, address account, uint option, uint amount) external;
}
