pragma solidity ^0.8.6;

import "./Bridge.sol";

contract BridgeBSC is Bridge {
    constructor(address _token) Bridge(_token) {}
}
