pragma solidity ^0.4.24;

import "./SafeMath.sol";
import "./SubServer.sol";

contract GoodsProxy is SubServer{
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
    mapping(bytes32=>HTLCInfo) public htlcHistory;
    
    function buyLock(bytes32 cctTxHash, bytes32 xHash, bytes memory goodsInfo,address goodsReceiptor) public authorized returns(address goodsOwner,address receiptToken,uint totalValue){
        require(goodsInfo.length == 136,"bad goods data");
        HTLCInfo storage htlc = htlcHistory[cctTxHash];
        require(htlc.xHash == 0x0, "goods htlc exsits");
        
        bytes memory data = abi.encodePacked(goodsInfo);
        bytes32 goodsId;
        uint goodsAmount;
        uint goodsPrice;
        assembly{
            goodsId := mload(add(data,32))
            goodsOwner := and(mload(add(data, 52)),0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            receiptToken := and(mload(add(data, 72)),0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            goodsPrice := mload(add(data, 104))
            goodsAmount := mload(add(data,136))
        }
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
        
        emit GoodsLock(cctTxHash, xHash,goodsOwner,receiptToken,totalValue);
    }
    
    function buyRevoke(bytes32 cctTxHash) public authorized returns(bool){
        // bytes32 xHash = keccak256(abi.encodePacked(x));
        HTLCInfo storage htlc = htlcHistory[cctTxHash];
        require(htlc.xHash != 0x0,"goods htlc not exists");
        require(htlc.sender == msg.sender,"not authorized");
        require(htlc.expireTime < now,"goods htlc not expired");
        require(htlc.status == HTLCStatus.LOCKED,"goods htlc status is not locked");
        
        htlc.status = HTLCStatus.REVOKE;
        
        emit GoodsRevoke(cctTxHash);
        return true;
    }
    
    function buyCommit(bytes32 cctTxHash, bytes32 x) public authorized returns(bool){
        bytes32 xHash = keccak256(abi.encodePacked(x));
        HTLCInfo storage htlc = htlcHistory[cctTxHash];
        if(htlc.xHash == 0x0 || htlc.xHash != xHash || htlc.expireTime < now || htlc.status != HTLCStatus.LOCKED){
            return false;
        }
        
        htlc.status = HTLCStatus.COMMIT;
        emit GoodsCommit(cctTxHash);
        return true;
    }
    
    event GoodsLock(bytes32 cctTxHash, bytes32 xHash,address goodsOwner,address receiptToken,uint totalValue);
    event GoodsRevoke(bytes32 cctTxHash);
    event GoodsCommit(bytes32 cctTxHash);
    
}
