//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
    string private _greeting;

    constructor(string memory greeting_) {
        _greeting = greeting_;
    }

    function greet() public view returns (string memory) {
        return _greeting;
    }

    function setGreeting(string memory greeting_) public payable {
        _greeting = greeting_;
    }
}
