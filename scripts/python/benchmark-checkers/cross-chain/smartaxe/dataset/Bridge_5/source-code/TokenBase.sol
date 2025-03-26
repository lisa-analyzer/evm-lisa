// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';


contract TokenBase is ERC20{
    address public _admin;
    constructor(string memory name, string memory symbol) ERC20(name, symbol){
        _admin = msg.sender;
    }

    modifier _restricted(){
        require(msg.sender == _admin, 'only admin');
        _;
    }

    function updateAdmin(address newAdmin) external _restricted {
        _admin = newAdmin;
    }

    function mint(address to, uint amount) external _restricted {
        _mint(to, amount);
    }

    function burn(address owner, uint amount) external _restricted {
        _burn(owner, amount);
    }
}