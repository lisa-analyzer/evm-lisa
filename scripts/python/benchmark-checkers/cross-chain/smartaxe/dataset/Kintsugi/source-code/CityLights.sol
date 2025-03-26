// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 eepmon. All rights reserved. */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

contract CityLights {

    using Address for address;

    address private _owner;
    address private _executor;

    constructor(address executor) {
        require(executor.isContract(), "invalid executor");
        _owner = msg.sender;
        _executor = executor;
    }

    function changeExecutor(address newExecutor) public {
        require(msg.sender == _owner, "owner only");
        require(newExecutor != address(0x0), "address must be set");
        _executor = newExecutor;        
    }
}