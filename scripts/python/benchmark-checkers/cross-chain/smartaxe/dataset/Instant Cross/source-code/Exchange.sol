pragma solidity ^0.4.24;

import "./SafeMath.sol";
import "./SubServer.sol";

contract Token {
    // function totalSupply() public view returns (uint256 supply);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    // function approve(address _spender, uint256 _value) public returns (bool success);
    // function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    // event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    // function decimals() public view returns (uint8 _decimals);
}

contract Exchange is SubServer{
    mapping(address=>uint256) public reserveFund;
    address [] tokenSupport;
    uint constant DEFAULT_EXPIRED_TIME = 2*1800;
    mapping(bytes32=>HTLCInfo) public htlcHistory;
    // bytes32 [] public htlcList;
    
    address owner;
    
    enum HTLCStatus{
        LOCKED,
        EXPIRE,
        COMMIT,
        REVOKE
    }
    
    struct HTLCInfo{
        bytes32 xHash;
        address currencyToken;
        address targetToken;
        uint targetAmount;
        address receiptor;
        uint expireTime;
        address sender;
        HTLCStatus status;
    }
    
    constructor() public {
        owner = msg.sender;
    }

    function contractExists(address contract_address) internal view returns (bool) {
        uint size;

        assembly {
            size := extcodesize(contract_address)
        }

        return size > 0;
    }

    // modifier onlyOwner(){
    //     require(msg.sender == owner,"not authorized");
    //     _;
    // }

    function destroy()public payable onlyOwner  {

        for(uint i = 0; i < tokenSupport.length; i++){
            if(tokenSupport[i] != address(0x0) && reserveFund[tokenSupport[i]] > 0){
                Token(tokenSupport[i]).transfer(owner,reserveFund[tokenSupport[i]]);
            }
        }

        selfdestruct(owner);
    } 

    function exchangeLock(bytes32 cctTxHash, bytes32 xHash, address currencyToken, address targetToken, uint targetAmount, address receiptor) public authorized returns(bool){
        HTLCInfo storage htlc = htlcHistory[cctTxHash];
        if(htlc.xHash != 0x0) return false;
            
        if(reserveFund[targetToken] < targetAmount) {
            return false;
        }
        
        // if(htlc.xHash == 0x0) {
        //     htlcList.push(cctTxHash);
        // }
        
        htlc.xHash = xHash;
        htlc.currencyToken = currencyToken;
        htlc.targetToken = targetToken;
        htlc.targetAmount = targetAmount;
        htlc.receiptor = receiptor;
        htlc.expireTime = now + DEFAULT_EXPIRED_TIME;
        htlc.status = HTLCStatus.LOCKED;
        htlc.sender = msg.sender;
        
        
        reserveFund[targetToken] = SafeMath.sub(reserveFund[targetToken],targetAmount);

        emit ExchangeLock(cctTxHash, xHash, currencyToken, targetToken, targetAmount);
        
        return true;
    }
    
    function exchangeRevoke(bytes32 cctTxHash) public authorized returns(bool){
        // bytes32 xHash = keccak256(abi.encodePacked(x));
        HTLCInfo storage htlc = htlcHistory[cctTxHash];
        if(htlc.xHash == 0x0) return false;
        if(htlc.sender != msg.sender) return false;
        if(htlc.expireTime >= now) return false;
        if(htlc.status != HTLCStatus.LOCKED) return false;
        
        reserveFund[htlc.targetToken] = SafeMath.add(reserveFund[htlc.targetToken],htlc.targetAmount);
        
        htlc.status = HTLCStatus.REVOKE;
        emit ExchangeRevoke(cctTxHash);
        
        return true;
    }
    
    function exchangeCommit(bytes32 cctTxHash, bytes32 x) public authorized returns(bool){
        bytes32 xHash = keccak256(abi.encodePacked(x));
        HTLCInfo storage htlc = htlcHistory[cctTxHash];
        // if(htlc.xHash == 0x0) return false;
        
        // if(htlc.expireTime < now) return false;
        // if(htlc.status != HTLCStatus.LOCKED) return false;
        require(htlc.xHash != 0x0 && htlc.xHash == xHash && htlc.sender == msg.sender && htlc.expireTime >= now && htlc.status == HTLCStatus.LOCKED,"exchange htlc invalid");
        
        // reserveFund[htlc.targetToken] = SafeMath.sub(reserveFund[htlc.targetToken],htlc.targetAmount);
        
        Token erc20 = Token(htlc.targetToken);
        require(erc20.transfer(htlc.receiptor,htlc.targetAmount),"transfer failed");
        htlc.status = HTLCStatus.COMMIT;
        
        emit ExchangeCommit(cctTxHash);
        
        return true;
    }
    
    // function unlockExpireHtlc()public {
    //     uint i;
    //     for(i = 0; i < htlcList.length; i++){
    //         HTLCInfo storage checkHtlc = htlcHistory[htlcList[i]];
    //         if(checkHtlc.expireTime < now && checkHtlc.status == HTLCStatus.LOCKED){
    //             checkHtlc.status = HTLCStatus.EXPIRE;
    //             reserveFund[checkHtlc.targetToken] = SafeMath.add(reserveFund[checkHtlc.targetToken],checkHtlc.targetAmount);
    //         }
    //     }
    // }
    
    function getBalance(address token)public view returns (uint256 _balance){
        Token erc20 = Token(token);
        _balance = erc20.balanceOf(address(this));
    }
    
    function addReserveFund(address token, uint256 amount)public payable onlyOwner(){

        // require(reserveFund[token] != 0x0,"token not support");

        reserveFund[token] = SafeMath.add(reserveFund[token], amount);

        if(token != address(0x0)){
            require(Token(token).transferFrom(msg.sender, address(this), amount),"transferForm failed");
        }
        else{
            // require(amount == msg.value,"amount is note correct");
            require(false,"");
        }

        //reserve = reserveFund[token];
        emit EventAddReserveFund(token,amount,reserveFund[token]);
    }
    
    function withdraw(address token,uint256 amount)public onlyOwner(){
        
        require(reserveFund[token] >= amount, "not enough token");

        reserveFund[token] = SafeMath.sub(reserveFund[token], amount);

        if(token != address(0x0)){
            require(Token(token).transfer(msg.sender, amount),"transfer token failed");
        }else{
            //require(amount <= msg.value,"balance is note enough");
            // address(msg.sender).transfer(amount);
            require(false,"");
        }

        emit EventWithdraw(token,amount,reserveFund[token]);
    }

    
    // event Rate(address currency, uint256 rate);
    event EventAddToken(address token,bytes ratesbytes);
    event EventAddReserveFund(address token,uint amount, uint newtotoal);
    event EventWithdraw(address token,uint amount, uint newtotoal);
    
    event ExchangeLock(bytes32 cctTxHash, bytes32 xHash,address currency,address target,uint targetAmount);
    event ExchangeRevoke(bytes32 cctTxHash);
    event ExchangeCommit(bytes32 cctTxHash);
}
