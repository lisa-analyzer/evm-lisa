pragma solidity ^0.4.24;

import "./SafeMath.sol";
import "./SubServer.sol";

interface Token {
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
contract ExchangeProxy is SubServer{

    enum HTLCStatus{
        START,
        LOCKED,
        EXPIRE,
        COMMIT,
        REVOKE
    }
    
    uint constant DEFAULT_EXPIRED_TIME = 2*3600;

    mapping(bytes32=>HTLCInfo) public htlcHistory;
    
    mapping(address=>uint) public rateMap;

    mapping(address=>uint) public incomeMap;

    struct HTLCInfo{
        bytes32 xHash;
        address currencyToken;
        address targetToken;
        uint targetAmount;
        uint originAmount;
        address receiptor;
        uint expireTime;
        address sender;
        HTLCStatus status;
    }
    
    function contractExists(address contract_address) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(contract_address)
        }
        return size > 0;
    }
    function setRate(address token, uint256 _rate)public onlyOwner(){

        require(_rate != 0x0,"bad rate data");

        // if(token != address(0x0)){
        //     require(contractExists(token),"token not exist");
        // }

        rateMap[token] =  _rate;

        emit Rate(token,_rate);
    }

    function exchangeLock(bytes32 cctTxHash,bytes32 xHash, address currencyToken, address targetToken, uint targetAmount, address receiptor) public authorized returns(address exchangeUser, uint originAmount){
        
        HTLCInfo storage htlc = htlcHistory[cctTxHash];
        require(htlc.xHash == 0x0 , "exchange htlc exists");
        // uint rateCurrency = rateMap[currencyToken];
        require((rateMap[currencyToken] != 0x0) && (rateMap[currencyToken] != 0x0),"token not supported by exchange");
        
        htlc.xHash = xHash;
        htlc.currencyToken = currencyToken;
        htlc.targetToken = targetToken;
        htlc.targetAmount = targetAmount;
        htlc.receiptor = receiptor;
        htlc.expireTime = now + DEFAULT_EXPIRED_TIME;
        htlc.status = HTLCStatus.LOCKED;
        htlc.sender = msg.sender;
        
        htlc.originAmount = SafeMath.div(SafeMath.mul(targetAmount, rateMap[currencyToken]),rateMap[targetToken]);
        
        emit ExchangeLock(cctTxHash,xHash,address(this),htlc.originAmount);
        return (address(this),htlc.originAmount);
    }
    
    function exchangeRevoke(bytes32 cctTxHash) public authorized returns(bool){
        // bytes32 xHash = keccak256(abi.encodePacked(x));
        HTLCInfo storage htlc = htlcHistory[cctTxHash];
        require(htlc.xHash != 0x0,"exchange htlc not exists");
        require(htlc.sender == msg.sender,"not authorized");
        
        require(htlc.expireTime < now,"exchange htlc not expired");
        require(htlc.status == HTLCStatus.LOCKED,"exchange htlc status is not locked");
        
        htlc.status = HTLCStatus.REVOKE;
        emit ExchangeRevoke(cctTxHash);
        return true;
    }
    
    function exchangeCommit(bytes32 cctTxHash, bytes32 x) public authorized returns(bool){
        bytes32 xHash = keccak256(abi.encodePacked(x));
        HTLCInfo storage htlc = htlcHistory[cctTxHash];
        if(htlc.xHash == 0x0 || htlc.xHash != xHash || htlc.expireTime < now || htlc.status != HTLCStatus.LOCKED){
            return false;
        }
        
        htlc.status = HTLCStatus.COMMIT;
        incomeMap[htlc.currencyToken] = SafeMath.add(incomeMap[htlc.currencyToken],htlc.originAmount);
        emit ExchangeCommit(cctTxHash);
        return true;
    }

    function withdraw(address token,uint amount) public onlyOwner(){
        require(incomeMap[token] >= amount,"not sufficient funds");

        require(Token(token).transfer(msg.sender,amount),"transfer token failed");
        incomeMap[token] = SafeMath.sub(incomeMap[token],amount);
        emit EventWithdraw(token,amount,incomeMap[token]);
    }
    
    event Rate(address currency, uint256 rate);
    event EventAddToken(address token,bytes ratesbytes);
    event EventAddReserveFund(address token,uint256 amount, uint256 newtotoal);
    event EventWithdraw(address token,uint256 amount, uint256 newtotoal);
    event EventExchange(address sender,address currency,address target,uint256 amount,uint256 targetamount,uint256 currency_reserve,uint256 target_reserve);
    
    event ExchangeLock(bytes32 cctTxHash, bytes32 xHash,address exchangeUser, uint originAmount);
    event ExchangeRevoke(bytes32 cctTxHash);
    event ExchangeCommit(bytes32 cctTxHash);
}
