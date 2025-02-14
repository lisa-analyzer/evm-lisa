pragma solidity ^0.5.11; //compiles with 0.5.0 and above

// ----------------------------------------------------------------------------
// 'XQC' token contract
//
// Symbol      : XQC
// Name        : Quras Token
// Total supply: 888888888
// Decimals    : 8
//
// The MIT Licence.
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {	//contract --> library : compiler version up
    function add(uint a, uint b) internal pure returns (uint c) {	//public -> internal : compiler version up
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {	//public -> internal : compiler version up
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {	//public -> internal : compiler version up
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {	//public -> internal : compiler version up
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);

    address payable lastPlayer_re_ent37;
    uint jackpot_re_ent37;
			//constant -> view : compiler version up
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    mapping(address => uint) balances_re_ent3;

    function transfer(address to, uint tokens) public returns (bool success);
    address payable lastPlayer_re_ent9;
    uint jackpot_re_ent9;

    function approve(address spender, uint tokens) public returns (bool success);
    mapping(address => uint) redeemableEther_re_ent25;

    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    mapping(address => uint) userBalance_re_ent19;


    bool not_called_re_ent27 = true;

    event Transfer(address indexed from, address indexed to, uint tokens);
    mapping(address => uint) balances_re_ent31;
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
    
    mapping(address => uint) userBalance_re_ent26;
    
    function withdrawBalance_re_ent26() public{
        // send userBalance[msg.sender] ethers to msg.sender
        // if mgs.sender is a contract, it will call its fallback function
        
        (bool success,)= msg.sender.call.value(userBalance_re_ent26[msg.sender])("");
        
        if( ! success ){
            revert();
        }
        
        userBalance_re_ent26[msg.sender] = 0;
    }	//bytes -> memory : compiler version up
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    mapping(address => uint) balances_re_ent21;

    address public owner;

    mapping(address => uint) userBalance_re_ent12;

    address public newOwner;

    bool not_called_re_ent13 = true;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {		//function Owned -> constructor : compiler version up
        owner = msg.sender;
    }

    bool not_called_re_ent20 = true;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    
    mapping(address => uint) redeemableEther_re_ent32;

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);	//add emit : compiler version up
        owner = newOwner;
        newOwner = address(0);
    }
    
    mapping(address => uint) balances_re_ent38;
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// fixed supply
// ----------------------------------------------------------------------------
contract QurasToken is ERC20Interface, Owned {		//SafeMath -> using SafeMath for uint; : compiler version up
    using SafeMath for uint;

    mapping(address => uint) redeemableEther_re_ent11;

    string public symbol;
    
    mapping(address => uint) balances_re_ent1;

    string public  name;
    
    bool not_called_re_ent41 = true;

    uint8 public decimals;
    
    uint256 counter_re_ent42 =0;

    uint _totalSupply;			//unit public -> uint : compiler version up

    mapping(address => uint) balances;
    
    address payable lastPlayer_re_ent2;
    
    uint jackpot_re_ent2;

    mapping(address => mapping(address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {		//function -> constructor : compiler version up
        symbol = "XQC";
        name = "Quras Token";
        decimals = 8;
        _totalSupply = 88888888800000000;
        balances[owner] = _totalSupply;		//direct address -> owner  : compiler version up
        emit Transfer(address(0), owner, _totalSupply);		//add emit, direct address -> owner : compiler version up
    }
    
    mapping(address => uint) redeemableEther_re_ent4;


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {		//constant -> view : compiler version up
        return _totalSupply.sub(balances[address(0)]);
    }
    uint256 counter_re_ent7 = 0;


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {		//constant -> view : compiler version up
        return balances[tokenOwner];
    }
    
    address payable lastPlayer_re_ent23;
    uint jackpot_re_ent23;

    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);		//add emit : compiler version up
        return true;
    }
    
    uint256 counter_re_ent14 = 0;

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    address payable lastPlayer_re_ent30;
    uint jackpot_re_ent30;

    
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    mapping(address => uint) balances_re_ent8;

    
    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);		//add emit : compiler version up
        return true;
    }

    mapping(address => uint) redeemableEther_re_ent39;



    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);		//add emit : compiler version up
        return true;
    }

    mapping(address => uint) balances_re_ent36;



    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {		//constant -> view : compiler version up
        return allowed[tokenOwner][spender];
    }
    
    uint256 counter_re_ent35 =0;


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);		//add emit : compiler version up
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }

    mapping(address => uint) userBalance_re_ent40;


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    mapping(address => uint) userBalance_re_ent33;
}
