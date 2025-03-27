pragma solidity ^0.4.24;

import "./AggregationBase.sol";
import {Exchange} from "./Exchange.sol";
import {Goods} from "./Goods.sol";
import "./rlp.sol";

contract Aggregation is AggregationBase{
    using RLP for bytes;
    using RLP for RLP.RLPItem;
    
    constructor(address cctdispatcher, bytes32 chainid,address cctchannel) AggregationBase(cctdispatcher,chainid,cctchannel) public{

    }
    
    function process(bytes32 fromChain, bytes32 toChain, bytes32 pmId,bytes32 channel,bytes32 fromSrv, uint entryMod, bytes32 cctTxHash, bytes memory businessProof) private returns(bool){
         if(entryMod == ENTRYMOD_EXCHANGEBUYLOCK){
            return exchangeBuyLock(toChain, pmId, channel, cctTxHash, businessProof);
        }else if(entryMod == ENTRYMOD_EXCHANGEBUYREVOKE){
            return revoke(cctTxHash);
        }else if(entryMod == ENTRYMOD_EXCHANGEPAYLOCK){
            return exchangePayLock(toChain, pmId, channel, cctTxHash, businessProof);
        }
        
        return false;
    }
    
    function exchangBuyLockHandle(bytes32 cctTxHash,bytes32 channel,bytes32 xHash, bytes memory goodsInfo, address goodsReceiptor,address payToken) private returns(bool){
        address goodsOwner;
        address receiptToken;
        uint amount;
        address subSrvGoods;
        address subSrvExchange;
        
        bool goodsFlag = false;
        subSrvGoods = cctChannel.getChannelSubSrv(channel,SRVID_GOODS);
        // if(!contractExists(subSrvGoods)) return false;//,"Goods not exists");
        (goodsOwner,receiptToken,amount) = Goods(subSrvGoods).buyLock(cctTxHash,xHash, goodsInfo, goodsReceiptor);
        if(goodsOwner == address(0x0) && receiptToken == address(0x0) && amount == 0) {
            setSubSrvStatus(cctTxHash,SRVID_GOODS,ProofStatus.LOCK);
            goodsFlag = false;
        }else{
            setSubSrvStatus(cctTxHash,SRVID_GOODS,ProofStatus.CONFIRM);
            goodsFlag = true;
        }
        
        bool exchangeFlag = false;
        subSrvExchange = cctChannel.getChannelSubSrv(channel,SRVID_EXCHANGE);
        // if(!contractExists(subSrvExchange)) return false;//,"Exchange not exists");
        if(!Exchange(subSrvExchange).exchangeLock(cctTxHash,xHash, payToken, receiptToken, amount, goodsOwner)) {
            setSubSrvStatus(cctTxHash,SRVID_EXCHANGE,ProofStatus.LOCK);
            exchangeFlag = false;
        }else{
            setSubSrvStatus(cctTxHash,SRVID_EXCHANGE,ProofStatus.CONFIRM);
            exchangeFlag = true;
        }
        
        
        return exchangeFlag && goodsFlag;
    }
    
    function decodeBuyLock(bytes memory data) private pure returns(bytes32 xHash,bytes memory goodsInfo,address goodsReceiptor,address payToken){
        
        RLP.RLPItem  []  memory ls = data.toRLPItem().toList();
        
        xHash = ls[0].toBytes32();
        goodsInfo = ls[1].toBytes(); 
        goodsReceiptor = ls[2].toAddress();
        payToken = ls[3].toAddress();
    }
    
    function exchangeBuyLock(bytes32 toChain, bytes32 pmId, bytes32 channel,bytes32 cctTxHash, bytes memory businessProof) private returns(bool){
        
        ProofRecord storage proofRecord =  proofHistory[cctTxHash];
        if(proofRecord.cctTxHash != 0x0) return false;
        
        bytes32 xHash;
        bytes memory goodsInfo; 
        address goodsReceiptor;
        address payToken;
        //TODO: decode businessProof with RLP
        (xHash,goodsInfo,goodsReceiptor,payToken) = decodeBuyLock(businessProof);
        if(xHash == 0x0 && goodsReceiptor == address(0x0) && payToken == address(0x0)) return false;
        
        proofRecord.toChain = toChain;
        proofRecord.pmId = pmId;
        proofRecord.channel = channel;
        proofRecord.cctTxHash = cctTxHash;
        proofRecord.status = ProofStatus.LOCK;
        
        exchangBuyLockHandle(cctTxHash,channel,xHash, goodsInfo, goodsReceiptor,payToken);
        
        calAndUpdateProofStatus(cctTxHash);
        
        if (proofRecord.status == ProofStatus.CONFIRM){
            emit ExchangeBuyConfirm(chainId, cctChannel.getChannelCrossChain(channel), proofRecord.pmId, proofRecord.channel,cctTxHash, SRVID, ENTRYMOD_EXCHANGEBUYCOMFIRM);
            return true;
        }else{
            return false;
        }
    }
    
    function exchangePayHandle(bytes32 cctTxHash,  bytes memory businessProof)private returns(bool){
        
        RLP.RLPItem  []  memory ls = businessProof.toRLPItem().toList();
        
        bytes32 xHash = ls[0].toBytes32();
        address payToken = ls[1].toAddress(); 
        // address payAddress = ls[2].toAddress();
        address receiptToken = ls[3].toAddress();
        address receiptAddress = ls[4].toAddress();
        uint receiptAmount = ls[5].toUint();
        
        ProofRecord storage proofRecord = proofHistory[cctTxHash];

        address subSrvExchange;
        
        bool exchangeFlag = false;
        subSrvExchange = cctChannel.getChannelSubSrv(proofRecord.channel,SRVID_EXCHANGE);
        // if(!contractExists(subSrvExchange)) return false;//,"Exchange not exists");
        if(!Exchange(subSrvExchange).exchangeLock(cctTxHash,xHash, payToken, receiptToken, receiptAmount, receiptAddress)) {
            setSubSrvStatus(cctTxHash,SRVID_EXCHANGE,ProofStatus.LOCK);
            exchangeFlag = false;
        }else{
            setSubSrvStatus(cctTxHash,SRVID_EXCHANGE,ProofStatus.CONFIRM);
            exchangeFlag = true;
        }
        
        return exchangeFlag;
    }
    
    function exchangePayLock(bytes32 toChain, bytes32 pmId, bytes32 channel,bytes32 cctTxHash, bytes memory businessProof) private returns(bool){
        
        ProofRecord storage proofRecord =  proofHistory[cctTxHash];
        if(proofRecord.cctTxHash != 0x0) return false;
        
        proofRecord.toChain = toChain;
        proofRecord.pmId = pmId;
        proofRecord.channel = channel;
        proofRecord.cctTxHash = cctTxHash;
        proofRecord.status = ProofStatus.LOCK;
        
        
        
        if(!exchangePayHandle(cctTxHash,businessProof)) return false;
        
        calAndUpdateProofStatus(cctTxHash);
        
        if (proofRecord.status == ProofStatus.CONFIRM){
            emit ExchangePayConfirm(chainId, cctChannel.getChannelCrossChain(channel), proofRecord.pmId, proofRecord.channel,cctTxHash, SRVID, ENTRYMOD_EXCHANGEBUYCOMFIRM);
            return true;
        }else{
            return false;
        }
    }
    
    function revoke(bytes32 cctTxHash) private returns(bool){
        
        ProofRecord storage  proofRecord = proofHistory[cctTxHash];
        if(proofRecord.cctTxHash == 0x0) return false;
        
        //TODO: decode businessProof with RLP
        // RLP.RLPItem memory item = businessProof.toRLPItem();
        // bytes32 x = item.toBytes32();

        if(proofRecord.status != ProofStatus.CONFIRM && proofRecord.status != ProofStatus.LOCK){
            return false;
        }

        uint i;
        for (i = 0; i < proofRecord.subSrvStatuList.length; i++) {
            address subSrv;
            bool ret;
            if(proofRecord.subSrvStatuList[i].srvId == SRVID_EXCHANGE){
                
                subSrv = cctChannel.getChannelSubSrv(proofRecord.channel,SRVID_EXCHANGE);
                // if(!contractExists(subSrv)) return false;
                ret = Exchange(subSrv).exchangeRevoke(cctTxHash); 
                if(ret) {
                    setSubSrvStatus(cctTxHash,SRVID_EXCHANGE,ProofStatus.REVOKE);
                }
            }else if(proofRecord.subSrvStatuList[i].srvId == SRVID_GOODS){
                subSrv = cctChannel.getChannelSubSrv(proofRecord.channel,SRVID_GOODS);
                // if(!contractExists(subSrv)) return false;
                ret = Goods(subSrv).buyRevoke(cctTxHash);
                if(ret) {
                    setSubSrvStatus(cctTxHash,SRVID_GOODS,ProofStatus.REVOKE);
                }
            }else{
                return false;
            }
        }
        
        calAndUpdateProofStatus(cctTxHash);
    
        if (proofRecord.status == ProofStatus.REVOKE){
            emit Revoke(chainId, cctChannel.getChannelCrossChain(proofRecord.channel), proofRecord.pmId, proofRecord.channel,cctTxHash, SRVID, ENTRYMOD_EXCHANGEBUYREVOKE);
            return true;
        }else{
            return false;
        }
    }

    function commit( bytes32 cctTxHash, bytes32 x) public{
        
        ProofRecord storage  proofRecord = proofHistory[cctTxHash];
        
	    require(proofRecord.cctTxHash != 0x0, "proofRecord not exists");
        require(proofRecord.status == ProofStatus.CONFIRM,"proofRecord valid");
        uint i;
        for (i = 0; i < proofRecord.subSrvStatuList.length; i++) {
            address subSrv;
            if(proofRecord.subSrvStatuList[i].srvId == SRVID_EXCHANGE){
                
                subSrv = cctChannel.getChannelSubSrv(proofRecord.channel,SRVID_EXCHANGE);
                // require(contractExists(subSrv),"ExchangeProxy not exists");
                Exchange(subSrv).exchangeCommit(cctTxHash,x);
            }else if(proofRecord.subSrvStatuList[i].srvId == SRVID_GOODS){
                subSrv = cctChannel.getChannelSubSrv(proofRecord.channel,SRVID_GOODS);
                // require(contractExists(subSrv),"GoodsProxy not exists");
                Goods(subSrv).buyCommit(cctTxHash, x);
            }else{
                require(false,"");
            }
        }
        
        proofRecord.status = ProofStatus.COMMIT;
        
        emit Commit(chainId,cctChannel.getChannelCrossChain(proofRecord.channel),proofRecord.pmId,proofRecord.channel,proofRecord.cctTxHash,SRVID,ENTRYMOD_EXCHANGEBUYCOMMIT,x);
    }

    event ExchangeBuyConfirm(bytes32 fromChain, bytes32 toChain, bytes32 pmId,bytes32 channel,bytes32 cctTxHash, bytes32 fromSrv,uint entryMod);
    event ExchangePayConfirm(bytes32 fromChain, bytes32 toChain, bytes32 pmId,bytes32 channel,bytes32 cctTxHash, bytes32 fromSrv,uint entryMod);
    
}
