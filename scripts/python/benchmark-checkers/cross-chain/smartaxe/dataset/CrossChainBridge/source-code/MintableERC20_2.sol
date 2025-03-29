//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental SMTChecker;


import "ERC20Basic.sol";
import "OwnableIf.sol";

/// @title MintableERC20
abstract contract MintableERC20 is ERC20Basic, OwnableIf {
    using SafeMath for uint256;

    event Mint(address indexed to, uint256 amount);
    event MintFinished(bool indexed finished);

    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished, "can't mint");
        _;
    }

    modifier hasMintPermission() {
        require(msg.sender == _owner(), "no permission...");
        _;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(
        address _to,
        uint256 _amount
    )
    public
    hasMintPermission
    canMint
    notPaused
    returns (bool)
    {
        require(_notBlocked(_to), "to-address has been blocked");
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting(bool finished)
    public
    onlyOwner
    returns (bool) {
        mintingFinished = finished;
        emit MintFinished(mintingFinished);
        return true;
    }
}
