// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Migrations{
    address public _owner = msg.sender;
    uint public _last_complete_migration;


    modifier _restricted(){ 
        require(msg.sender == _owner, "This function is restricted to the contract owner");
        _;
    }

    function setComplete(uint complete) public _restricted {
        _last_complete_migration = complete;
    }
}