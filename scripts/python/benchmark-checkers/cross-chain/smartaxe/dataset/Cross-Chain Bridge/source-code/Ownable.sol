//SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma experimental SMTChecker;


import "OwnableIf.sol";

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable is OwnableIf {
    address public owner;

    function _owner() view override public returns (address){
        return owner;
    }

    //    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        owner = msg.sender;
    }

    //    /**
    //     * @dev Throws if called by any account other than the owner.
    //     */
    //    modifier onlyOwner() {
    //        require(msg.sender == owner);
    //        _;
    //    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    //   function renounceOwnership() public onlyOwner {
    //     emit OwnershipRenounced(owner);
    //     owner = address(0);
    //   }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) virtual public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0), "invalid _newOwner");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


