//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental SMTChecker;


import "ERC20If.sol";
import "SafeMathLib.sol";

/// @title ERC20Basic
contract ERC20Basic is ERC20If {
    using SafeMath for uint256;

    mapping(address => uint256) internal balances;

    mapping(address => mapping(address => uint256)) internal allowed;

    uint256 internal totalSupply_;

    function _notPaused() virtual internal view returns (bool){return false;}

    function _notBlocked(address) virtual internal view returns (bool){return false;}

    modifier notPaused() {
        require(_notPaused(), "contract has been paused");
        _;
    }

    modifier notBlocked() {
        require(_notBlocked(msg.sender), "sender has been blocked");
        _;
    }

    function totalSupply() override public view returns (uint256) {
        return totalSupply_;
    }

    function transfer(address _to, uint256 _value) override public notPaused notBlocked returns (bool) {
        require(_notBlocked(_to), "to-address has been blocked");
        require(_value <= balances[msg.sender], "insufficient balance");
        require(_to != address(0), "invalid to-address");

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) override public view returns (uint256) {
        return balances[_owner];
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    override public notPaused notBlocked
    returns (bool)
    {
        require(_notBlocked(_from), "from-address has been blocked");
        require(_notBlocked(_to), "to-address has been blocked");
        require(_value <= balances[_from], "insufficient balance");
        require(_to != address(0), "invalid to-address");
        if (_from == msg.sender){
            balances[_from] = balances[_from].sub(_value);
            balances[_to] = balances[_to].add(_value);
            return true;
        }

        require(_value <= allowed[_from][msg.sender], "value > allowed");


        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
    override public notPaused notBlocked
    returns (bool) {
        require(_notBlocked(_spender), "spender-address has been blocked");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
    public notPaused notBlocked
    returns (bool)
    {
        require(_notBlocked(_spender), "spender-address has been blocked");
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(
        address _spender,
        uint _subtractedValue
    )
    public
    notPaused notBlocked
    returns (bool success)
    {
        require(_notBlocked(_spender), "spender-address has been blocked");

        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function allowance(
        address _owner,
        address _spender
    )
    override
    public
    view
    returns (uint256)
    {
        return allowed[_owner][_spender];
    }
}
