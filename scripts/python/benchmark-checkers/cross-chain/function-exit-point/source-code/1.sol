// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ExitPointIdentifier {

    function simpleFunction() public view returns (uint256) {
        uint256 exitTimestamp = block.timestamp;
        return exitTimestamp;
    }

    function anotherExitFunction() public {
        uint256 exitGas = gasleft();
    }
    
}