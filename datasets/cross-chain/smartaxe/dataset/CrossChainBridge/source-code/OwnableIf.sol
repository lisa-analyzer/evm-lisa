//SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma experimental SMTChecker;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
abstract contract OwnableIf {

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner(), "not owner......");
        _;
    }

    function _owner() view virtual public returns (address);
}
