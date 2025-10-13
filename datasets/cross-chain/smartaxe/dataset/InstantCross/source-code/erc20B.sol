pragma solidity ^0.4.24;



contract ERC20B {

    string public _name; //token name

    string public  _symbol; //token symbol

    uint8 _decimal; //decimal count

    uint256 _totalSupply; //total supply

 

    constructor() public {

        _name = "TokenB";

        _symbol = "@#@";

        _decimal = 18;

        _totalSupply = 30000000 ether;

        balances[0xA0b53488C70721AB54411F903C9688e26e26F0e2] = 10000000 ether;
        balances[0xa89f2ab8335b0d0ad5e9d5257abadd15cadc7b10] = 10000000 ether;
        balances[0x52f1045671f56f572f7743232b558ddca0627e10] = 10000000 ether;

    }

    function decimals() public view returns (uint8) {

        return _decimal;

    }

    

    function totalSupply() public view returns (uint256) {

        return _totalSupply;

    }

    

    //get the balance of _owner.

    function balanceOf(address _owner) public view returns (uint) {

        return balances[_owner];

    }

    

    //transfer _value balance from sender account to _to account.

    function transfer(address _to, uint _value) public returns (bool) {

        if (balances[msg.sender] >= _value) {

            balances[msg.sender] -= _value;

            balances[_to] += _value;

            emit Transfer(msg.sender, _to, _value);

            return true;

        } else { 

            return false;

        }

    }

    

    //transfer _value from _from to _to.

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {

        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value) {

            balances[_to] += _value;

            balances[_from] -= _value;

            allowed[_from][msg.sender] -= _value;

            emit Transfer(_from, _to, _value);

            return true;

        } else {

            return false;

        }

    }

    

    //approve _spender transfer _value from sender account.

    function approve(address _spender, uint _value) public returns (bool) {

        // To change the approve amount you first have to reduce the addresses`

        //  allowance to zero by calling `approve(_spender, 0)` if it is not

        //  already 0 to mitigate the race condition described here:

        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729

        //  assert((_value == 0) || (allowed[msg.sender][_spender] == 0));



        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;

    }

    

    function allowance(address _owner, address _spender) public view returns (uint) {

        return allowed[_owner][_spender];

    }

    

    mapping (address => uint) balances; //The balances for per account.

    mapping (address => mapping (address => uint)) allowed; //allowed list.

    

    event Transfer(address indexed _from, address indexed _to, uint _value);

    event Approval(address indexed _owner, address indexed _spender, uint _value);

}




