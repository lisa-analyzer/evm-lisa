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

contract Goods is SubServer{
    address public owner;
    mapping(bytes32=>uint) public goodsMap;
    enum HTLCStatus{
        LOCKED,
        EXPIRE,
        COMMIT,
        REVOKE
    }
    uint constant DEFAULT_EXPIRED_TIME = 2*1800;
    struct HTLCInfo{
        bytes32 xHash;
        address receiptToken;
        address goodsOwner;
        address goodsReceiptor;
        bytes32 goodsId;
        uint goodsAmount;
        uint goodsPrice;
        uint expireTime;
        address sender;
        HTLCStatus status;
    }
    mapping(bytes32=>HTLCInfo) public goodsLockMap;
    mapping(address=>mapping(bytes32=>uint)) public userGoodsMap;
    bytes32 [] public htlcList;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require( msg.sender == owner, "Sender not authorized." );
        _;
    }

    function addGoods(bytes32 goodsId, uint amount) onlyOwner public{
        uint oldAmount = goodsMap[goodsId];
        goodsMap[goodsId] = oldAmount + amount;
        emit AddGoodsEvent(goodsId, oldAmount, goodsMap[goodsId]);
    }
    
    function unlockExpireHtlc()public {
        uint i;
        for(i = 0; i < htlcList.length; i++){
            HTLCInfo storage checkHtlc = goodsLockMap[htlcList[i]];
            if(checkHtlc.expireTime < now && checkHtlc.status == HTLCStatus.LOCKED){
                checkHtlc.status = HTLCStatus.EXPIRE;
                goodsMap[checkHtlc.goodsId] = SafeMath.add(goodsMap[checkHtlc.goodsId],checkHtlc.goodsAmount);
            }
        }
    }

    function buyLock(bytes32 cctTxHash, bytes32 xHash, bytes memory goodsInfo, address goodsReceiptor) public authorized returns(address goodsOwner,address receiptToken,uint totalValue){
        if(goodsInfo.length != 136) return (address(0x0), address(0x0), 0);
        HTLCInfo storage htlc = goodsLockMap[cctTxHash];
        if((htlc.xHash != 0x0) && (htlc.status != HTLCStatus.LOCKED)) return (address(0x0), address(0x0), 0);
        
        bytes memory data = abi.encodePacked(goodsInfo);
        bytes32 goodsId;
        uint goodsPrice;
        uint goodsAmount;
        assembly{
            goodsId := mload(add(data,32))
            goodsOwner := and(mload(add(data, 52)),0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            receiptToken := and(mload(add(data, 72)),0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            goodsPrice := mload(add(data, 104))
            goodsAmount := mload(add(data,136))
        }
        
        if(goodsMap[goodsId] < goodsAmount) return (address(0x0),address(0x0),0x0);
        
        totalValue = SafeMath.mul(goodsPrice,goodsAmount);
        htlc.xHash = xHash;
        htlc.receiptToken = receiptToken;
        htlc.goodsOwner = goodsOwner;
        htlc.goodsReceiptor = goodsReceiptor;
        htlc.goodsId = goodsId;
        htlc.goodsAmount = goodsAmount;
        htlc.goodsPrice = goodsPrice;
        htlc.expireTime = now + DEFAULT_EXPIRED_TIME;
        htlc.status = HTLCStatus.LOCKED;
        htlc.sender = msg.sender;

        goodsMap[goodsId] = SafeMath.sub(goodsMap[goodsId], goodsAmount);
        emit GoodsLock(cctTxHash);
    }

    function buyCommit(bytes32 cctTxHash, bytes32 x) public authorized returns(bool){

        bytes32 xHash = keccak256(abi.encodePacked(x));
        HTLCInfo storage htlc = goodsLockMap[cctTxHash];
        require(htlc.xHash != 0x0 && htlc.xHash == xHash && htlc.sender == msg.sender && htlc.expireTime >= now && htlc.status == HTLCStatus.LOCKED,"goods htlc invalid");
        
        userGoodsMap[htlc.goodsReceiptor][htlc.goodsId] = SafeMath.add(userGoodsMap[htlc.goodsReceiptor][htlc.goodsId],htlc.goodsAmount);
        htlc.status = HTLCStatus.COMMIT;
        
        emit GoodsCommit(cctTxHash, htlc.goodsId, htlc.goodsReceiptor);

        return true;
    }

    function buyRevoke(bytes32 cctTxHash)public authorized returns(bool){
        // bytes32 xHash = keccak256(abi.encodePacked(x));
        HTLCInfo storage htlc = goodsLockMap[cctTxHash];
        if(htlc.xHash == 0x0) return false;
        if(htlc.sender != msg.sender) return false;
        if(htlc.expireTime >= now) return false;
        if(htlc.status != HTLCStatus.LOCKED) return false;
        
        goodsMap[htlc.goodsId] = SafeMath.add(goodsMap[htlc.goodsId], htlc.goodsAmount);
        
        htlc.status = HTLCStatus.REVOKE;
        
        
        emit GoodsRevoke(cctTxHash, htlc.goodsId, htlc.goodsReceiptor);

        return true;
    }
    function buy(bytes32 goodsId,uint goodsAmount,address token,uint goodsPrice,address goodsOwner) public{
        require(goodsMap[goodsId] >= goodsAmount,"Shortage of goods");
        uint totalValue = SafeMath.mul(goodsPrice,goodsAmount);
        require(Token(token).transferFrom(msg.sender,goodsOwner,totalValue),"payment failure");

        goodsMap[goodsId] = SafeMath.sub(goodsMap[goodsId], goodsAmount);
        userGoodsMap[msg.sender][goodsId] = SafeMath.add(userGoodsMap[msg.sender][goodsId],goodsAmount);
        emit GoodsBuy(msg.sender, goodsId, goodsAmount,goodsPrice);
    }

    event GoodsLock(bytes32 cctTxHash);
    event GoodsCommit(bytes32 cctTxHash, bytes32 goodsId, address buyer);
    event GoodsBuy(address buyer, bytes32 goodsId, uint goodsAmount,uint goodsPrice);
    event GoodsRevoke(bytes32 cctTxHash, bytes32 goodsId, address buyer);

    event AddGoodsEvent(bytes32 goodsId, uint oldAmount, uint newAmount);
}
