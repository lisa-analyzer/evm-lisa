//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental SMTChecker;


import "MemberMgrIf.sol";
import "ERC20If.sol";
/// @title ERC20ControllerViewIf
abstract contract ERC20ControllerViewIf {
    function blocked(address _who) virtual public view returns (bool);

    function paused() virtual public view returns (bool);
}

/// @title ccTokenControllerIf
abstract contract ccTokenControllerIf is MemberMgrIf, ERC20ControllerViewIf {
    function mint(address to, uint amount) virtual external returns (bool);

    function burn(uint value) virtual external returns (bool);

    function getToken() virtual external returns (ERC20If);
}
