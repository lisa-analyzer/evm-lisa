// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../v2/erc20-mapping-protocol/Erc20.sol";

contract MockErc20Withdraw is Erc20 {
    constructor(string memory _name, string memory _symbol, uint8 _decimals) Erc20(_name, _symbol, _decimals) {}
    function withdraw(uint wad) public {
        // do nothing
    }
}
 
