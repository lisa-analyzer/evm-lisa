// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BridgeToken is ERC20 {
    uint8 private _decimals = 18;
    address public _owner;

    modifier onlyOwner() {
        require(msg.sender == _owner, "BridgeToken: Caller is not the minter");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address owner,
        uint8 decimals
    ) ERC20(name, symbol) {
        _decimals = decimals;
        _owner = owner;
    }

    function mint(
        address account,
        uint256 amount /* onlyOwner */
    ) external {
        super._mint(account, amount);
    }

    function burn(
        address account,
        uint256 amount /* onlyOwner */
    ) external {
        super._burn(account, amount);
    }
}
