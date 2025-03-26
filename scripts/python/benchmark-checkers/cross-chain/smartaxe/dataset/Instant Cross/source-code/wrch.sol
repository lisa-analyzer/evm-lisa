pragma solidity ^0.4.24;

import "./SafeMath.sol";
import "./SubServer.sol";

interface ERC20Token {
    // function totalSupply() public view returns (uint256 supply);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    // function approve(address _spender, uint256 _value) public returns (bool success);
    // function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    // event Transfer(address indexed _from, address indexed _to, uint256 _value);
    // event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    // function decimals() public view returns (uint8 _decimals);
}

contract Wrch is SubServer{
    uint public lockAmout;
    address public owner;
    enum HTLCStatus{
        START,
        LOCKED,
        EXPIRE,
        COMMIT,
        REVOKE
    }
    uint constant DEFAULT_EXPIRED_TIME = 2*3600;
    struct HTLCInfo{
        bytes32 xHash;
        address token;
        address _from;
        address _to;
        uint amount;
        uint expireTime;
        address sender;
        HTLCStatus status;
    }
    mapping(bytes32=>HTLCInfo) public htlcHistory;
    
    constructor()public SubServer(){
    }
    
    function balanceOf(address token) public view returns(uint balance){
        ERC20Token erc20 = ERC20Token(token);
        balance = erc20.balanceOf(address(this));
    }

    function lock(bytes32 cctTxHash, bytes32 xHash, address token, uint amount, address _from, address _to) public authorized returns(bool){
        HTLCInfo storage htlc = htlcHistory[cctTxHash];
        require(htlc.xHash == 0x0,"htlc is exists");
        
        ERC20Token erc20 = ERC20Token(token);
        // require(erc20.balanceOf(_from) >= amount,"not sufficient funds");
        // require(erc20.allowance(_from,address(this)) >= amount,"Insufficient authorized amount");
        require(erc20.transferFrom(_from,address(this),amount),"transferFrom failed");
        lockAmout += amount;
        
        htlc.xHash = xHash;
        htlc.token = token;
        htlc._from = _from;
        htlc._to = _to;
        htlc.amount = amount;
        htlc.expireTime = now + DEFAULT_EXPIRED_TIME;
        htlc.status = HTLCStatus.LOCKED;
        htlc.sender = msg.sender;
        
        return true;
    }
    
    // function lockTo(bytes32 xHash, address _to) public returns(bool){
    //     return true;
    // }

    function commit(bytes32 cctTxHash, bytes32 x) public authorized returns(bool){
        bytes32 xHash = keccak256(abi.encodePacked(x));
        HTLCInfo storage htlc = htlcHistory[cctTxHash];
        if(htlc.xHash == 0x0 || htlc.xHash != xHash) return false;
        if(htlc.sender != msg.sender) return false;
        if(htlc.expireTime < now) return false;
        if(htlc.status != HTLCStatus.LOCKED) return false;
        
        ERC20Token erc20 = ERC20Token(htlc.token);
        require(erc20.transfer(htlc._to,htlc.amount),"transfer failed");
        
        htlc.status = HTLCStatus.COMMIT;
        lockAmout -= htlc.amount;
        
        return true;
    }

    function revoke(bytes32 cctTxHash) public authorized returns(bool){
        // bytes32 xHash = keccak256(abi.encodePacked(x));
        HTLCInfo storage htlc = htlcHistory[cctTxHash];
        if(htlc.xHash == 0x0) return false;
        if(htlc.sender != msg.sender) return false;
        if(htlc.expireTime >= now) return false;
        if(htlc.status != HTLCStatus.LOCKED) return false;
        
        ERC20Token erc20 = ERC20Token(htlc.token);
        require(erc20.transfer(htlc._from,htlc.amount),"transfer failed");

        lockAmout -= htlc.amount;
        htlc.status = HTLCStatus.REVOKE;
        
        return true;
    }
}
