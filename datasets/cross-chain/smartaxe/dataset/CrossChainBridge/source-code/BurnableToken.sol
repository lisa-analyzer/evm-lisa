pragma solidity ^0.7.0;
pragma experimental SMTChecker;

//SPDX-License-Identifier: MIT

import "ERC20Basic.sol";

/// @title BurnableToken
contract BurnableToken is ERC20Basic {
    using SafeMath for uint256;

    event Burn(address indexed burner, uint256 value);

    function burn(uint256 _value) public returns (bool){
        address _who = msg.sender;
        require(_value <= balances[_who]);

        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);

        return true;
    }
}
