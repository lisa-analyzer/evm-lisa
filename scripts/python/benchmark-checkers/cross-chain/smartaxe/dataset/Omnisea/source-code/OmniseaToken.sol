pragma solidity ^0.8.7;

import "./OFT.sol";

contract OmniseaToken is OFT {
    constructor(address _layerZeroEndpoint) OFT("Omnisea", "OSEA", _layerZeroEndpoint) {}
}