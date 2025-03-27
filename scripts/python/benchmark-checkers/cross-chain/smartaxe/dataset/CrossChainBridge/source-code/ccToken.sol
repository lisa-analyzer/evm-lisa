//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental SMTChecker;


import "ccTokenControllerIf.sol";
import "NamedERC20.sol";
import "MintableERC20.sol";
import "BurnableToken.sol";
import "Claimable.sol";
import "CanReclaimToken.sol";

/// @title ccToken
contract ccToken is NamedERC20, Claimable, MintableERC20, BurnableToken, CanReclaimToken {
    using SafeMath for uint256;

    ERC20ControllerViewIf public erc20Controller;
    constructor(string memory _name,
        string memory _symbol,
        uint8 _decimals,
        ERC20ControllerViewIf _erc20Controller
    ) NamedERC20(_name, _symbol, _decimals){
        erc20Controller = _erc20Controller;
    }

    function hasController() view public returns (bool){
        return (address)(erc20Controller) != (address)(0);
    }

    function _notPaused() override internal view returns (bool){
        if (hasController()) {
            return !erc20Controller.paused();
        }
        return true;
    }

    function _notBlocked(address _who) override internal view returns (bool){
        if (hasController()) {
            return !erc20Controller.blocked(_who);
        }
        return true;
    }

    function setController(ERC20ControllerViewIf newController) public onlyOwner {
        erc20Controller = newController;
    }

    event BurnBlocked(address indexed burner, uint256 value);

    function burnBlocked(address addrBlocked, uint256 amount) public onlyOwner returns (bool){
        address _who = addrBlocked;
        require(!_notBlocked(_who), "addr not blocked");

        uint256 _value = amount;
        if (_value > balances[_who]) {
            _value = balances[_who];
        }

        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit BurnBlocked(_who, _value);
        emit Transfer(_who, address(0), _value);

        return true;
    }

}
