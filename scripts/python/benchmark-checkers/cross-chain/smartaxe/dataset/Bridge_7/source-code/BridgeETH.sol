pragma solidity ^0.8.6;

import "./Bridge.sol";

contract BridgeETH is Bridge {
    constructor(address _token) Bridge(_token) {}
}
