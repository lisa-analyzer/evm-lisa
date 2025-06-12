pragma solidity ^0.4.24;

import "./AggregationBase.sol";
// import {Wrch} from "./wrch.sol";
// import {ExchangeProxy} from "./ExchangeProxy.sol";
// import {GoodsProxy} from "./GoodsProxy.sol";
import "./rlp.sol";

interface Wrch {
    function lock(bytes32 cctTxHash, bytes32 xHash, address token, uint amount, address _from, address _to) public  returns(bool);
    function commit(bytes32 cctTxHash, bytes32 x) public  returns(bool);
    function revoke(bytes32 cctTxHash) public  returns(bool);
}

interface GoodsProxy {
    function buyLock(bytes32 cctTxHash, bytes32 xHash, bytes memory goodsInfo,address goodsReceiptor) public  returns(address goodsOwner,address receiptToken,uint totalValue);
    function buyCommit(bytes32 cctTxHash, bytes32 x) public  returns(bool);
    function buyRevoke(bytes32 cctTxHash) public  returns(bool);
}

interface ExchangeProxy {
    function exchangeLock(bytes32 cctTxHash,bytes32 xHash, address currencyToken, address targetToken, uint targetAmount, address receiptor) public  returns(address exchangeUser, uint originAmount);
    function exchangeCommit(bytes32 cctTxHash, bytes32 x) public  returns(bool);
    function exchangeRevoke(bytes32 cctTxHash) public  returns(bool);
}
contract AggregationWan is AggregationBase{
    using RLP for bytes;
    using RLP for RLP.RLPItem;

    Wrch wrch_;
    
    uint public nonce;
    bytes32 public currentTxHash;
   
    constructor(address cctdispatcher, bytes32 chainid,address cctchannel/*, address wrch*/) AggregationBase(cctdispatcher,chainid,cctchannel) public{
        // require(contractExists(wrch),"Wrch not exists");
        // wrch_ = Wrch(wrch);
    }
    
    function setWrch(address wrch) public onlyOwner{
        require(contractExists(wrch),"Wrch not exists");
        wrch_ = Wrch(wrch);
    }
    function getWrch()public view returns(address){
        return address(wrch_);
    }
    
    function process(bytes32 fromChain, bytes32 toChain, bytes32 pmId,bytes32 channel,bytes32 fromSrv, uint entryMod, bytes32 cctTxHash, bytes memory businessProof) private returns(bool){

        if(entryMod == ENTRYMOD_EXCHANGEBUYCOMFIRM){
            return comfirm(cctTxHash, businessProof);
        }
        else if(entryMod == ENTRYMOD_EXCHANGEBUYCOMMIT){
            return commit(cctTxHash, businessProof);
        }
        // else if(entryMod == ENTRYMOD_EXCHANGEBUYREVOKE){
        //     return revokeByPm(cctTxHash);
        // }
        require(false,"unknow entryMod");
        return false;
    }
    
    function comfirm(bytes32 cctTxHash, bytes memory businessProof) private returns(bool){
        
        //TODO: decode businessProof with RLP
        bytes32 xHash = businessProof.toRLPItem().toBytes32();
        
        ProofRecord storage proofRecord = proofHistory[cctTxHash];
        if(proofRecord.cctTxHash == 0x0) return false;
        if(proofRecord.status != ProofStatus.LOCK && proofRecord.status != ProofStatus.CONFIRM) return false;
        proofRecord.status = ProofStatus.CONFIRM;
        
        // emit Locked(cctTxHash);
        emit Confirm(chainId,cctChannel.getChannelCrossChain(proofRecord.channel),proofRecord.pmId,proofRecord.channel,cctTxHash,SRVID,ENTRYMOD_EXCHANGEBUYCOMMIT);
        return true;
    }
    
    function commit(bytes32 cctTxHash, bytes memory businessProof) private returns(bool){
    
        ProofRecord storage proofRecord = proofHistory[cctTxHash];
        if(proofRecord.cctTxHash == 0x0) return false;

        // //TODO: decode businessProof with RLP
        // RLP.RLPItem memory item = businessProof.toRLPItem();
        bytes32 x = businessProof.toRLPItem().toBytes32();
        
        
        if(proofRecord.status != ProofStatus.CONFIRM && proofRecord.status != ProofStatus.LOCK){
            return false;
        }
        uint i;
        for (i = 0; i < proofRecord.subSrvStatuList.length; i++) {
            address subSrv;
            bool ret;
            if(proofRecord.subSrvStatuList[i].srvId == SRVID_WRCH){
                ret = wrch_.commit(cctTxHash, x);
                if(ret) setSubSrvStatus(cctTxHash,SRVID_WRCH,ProofStatus.COMMIT);
            }
            else if(proofRecord.subSrvStatuList[i].srvId == SRVID_EXCHANGE){
                
                subSrv = cctChannel.getChannelSubSrv(proofRecord.channel,SRVID_EXCHANGE);
        
                ret = ExchangeProxy(subSrv).exchangeCommit(cctTxHash, x);
                if(ret) setSubSrvStatus(cctTxHash,SRVID_EXCHANGE,ProofStatus.COMMIT);

            }else if(proofRecord.subSrvStatuList[i].srvId == SRVID_GOODS){
                subSrv = cctChannel.getChannelSubSrv(proofRecord.channel,SRVID_GOODS);
                ret = GoodsProxy(subSrv).buyCommit(cctTxHash, x);
                if(ret) setSubSrvStatus(cctTxHash,SRVID_GOODS,ProofStatus.COMMIT);

            }else{
                return false;
            }
        }
        
        calAndUpdateProofStatus(cctTxHash);
        
        if(proofRecord.status == ProofStatus.COMMIT) {
            emit Commit(chainId,cctChannel.getChannelCrossChain(proofRecord.channel),proofRecord.pmId,proofRecord.channel,cctTxHash,SRVID,ENTRYMOD_EXCHANGEBUYCOMMIT,x);
            return true;
        }
        
        return false;
    }
    
    function exchangBuyLockHandle(bytes32 cctTxHash, bytes32 channel,bytes32 xHash, bytes memory goodsInfo, address goodsReceiptor,address payToken) private returns(bool){
        // ProofRecord storage proofRecord = proofHistory[cctTxHash];
        
        address goodsOwner;
        address receiptToken;
        uint amount;
        address subSrvGoods;
        
        subSrvGoods = cctChannel.getChannelSubSrv(channel,SRVID_GOODS);
        require(contractExists(subSrvGoods),"GoodsProxy not exists");
        (goodsOwner,receiptToken,amount) = GoodsProxy(subSrvGoods).buyLock(cctTxHash,xHash, goodsInfo, goodsReceiptor);
        setSubSrvStatus(cctTxHash,SRVID_GOODS,ProofStatus.LOCK);
        
        address subSrvExchange;
        address exchangeReceiptor;
        
        subSrvExchange = cctChannel.getChannelSubSrv(channel,SRVID_EXCHANGE);
        require(contractExists(subSrvExchange),"ExchangeProxy not exists");
        (exchangeReceiptor,amount) = ExchangeProxy(subSrvExchange).exchangeLock(cctTxHash,xHash, payToken, receiptToken,amount,goodsOwner);
        setSubSrvStatus(cctTxHash,SRVID_EXCHANGE,ProofStatus.LOCK);
        
        wrch_.lock(cctTxHash,xHash, payToken, amount, msg.sender,exchangeReceiptor);
        setSubSrvStatus(cctTxHash,SRVID_WRCH,ProofStatus.CONFIRM);
        
        return true;
    }
    
    function exchangeBuy(bytes32 pmId,bytes32 channel,bytes32 xHash, bytes memory goodsInfo, address goodsReceiptor,address payToken)public {

        bytes32 cctTxHash = keccak256(abi.encodePacked(nonce,address(this)));
        
        ProofRecord storage proofRecord = proofHistory[cctTxHash];
        require((proofRecord.cctTxHash == 0x0),"proofRecord is exists");
        
        proofRecord.toChain = cctChannel.getChannelCrossChain(channel);
        proofRecord.pmId = pmId;
        proofRecord.channel = channel;
        proofRecord.cctTxHash = cctTxHash;
        proofRecord.status = ProofStatus.LOCK;
        // proofRecord.sender = msg.sender;
        
        exchangBuyLockHandle(cctTxHash, channel,xHash, goodsInfo, goodsReceiptor,payToken);
        
        nonce +=1;
        currentTxHash = cctTxHash;
        
        
        
        emit ExchangeBuy(chainId,proofRecord.toChain,proofRecord.pmId,proofRecord.channel,cctTxHash,SRVID,ENTRYMOD_EXCHANGEBUYLOCK,xHash,goodsInfo,goodsReceiptor,payToken);
    }
    
    function exchangePayHandle(bytes32 cctTxHash, bytes32 channel, bytes32 xHash, address payToken, address payAddress,address receiptToken,address receiptAddress,uint receiptAmount)private returns(bool){

        address subSrvExchange;
        address exchangeReceiptor;
        uint payAmount;

        subSrvExchange = cctChannel.getChannelSubSrv(channel,SRVID_EXCHANGE);
        require(contractExists(subSrvExchange),"ExchangeProxy not exists");
        (exchangeReceiptor,payAmount) = ExchangeProxy(subSrvExchange).exchangeLock(cctTxHash,xHash, payToken, receiptToken,receiptAmount,receiptAddress);
        setSubSrvStatus(cctTxHash,SRVID_EXCHANGE,ProofStatus.LOCK);

        wrch_.lock(cctTxHash,xHash, payToken, payAmount, payAddress,exchangeReceiptor);
        setSubSrvStatus(cctTxHash,SRVID_WRCH,ProofStatus.CONFIRM);

        return true;

    }


    function exchangePay(bytes32 pmId,bytes32 channel,bytes32 xHash, address payToken, address receiptToken,address receiptAddress,uint receiptAmount)public {

        bytes32 cctTxHash = keccak256(abi.encodePacked(nonce,address(this)));

        ProofRecord storage proofRecord = proofHistory[cctTxHash];
        require((proofRecord.cctTxHash == 0x0),"proofRecord is exists");

        proofRecord.toChain = cctChannel.getChannelCrossChain(channel);
        proofRecord.pmId = pmId;
        proofRecord.channel = channel;
        proofRecord.cctTxHash = cctTxHash;
        proofRecord.status = ProofStatus.LOCK;
        // proofRecord.sender = msg.sender;
        
        exchangePayHandle(cctTxHash, channel,xHash, payToken, msg.sender, receiptToken, receiptAddress, receiptAmount);

        nonce +=1;
        currentTxHash = cctTxHash;

        emit ExchangePay(chainId,proofRecord.toChain,proofRecord.pmId,proofRecord.channel,cctTxHash,SRVID,ENTRYMOD_EXCHANGEPAYLOCK,xHash,payToken,msg.sender,receiptToken,receiptAddress,receiptAmount);

    }
    
    function revoke(bytes32 cctTxHash) public {
        ProofRecord storage  proofRecord = proofHistory[cctTxHash];
        require(proofRecord.cctTxHash != 0x0, "proofRecord not exists");
        require(proofRecord.status == ProofStatus.CONFIRM || proofRecord.status == ProofStatus.LOCK,"proofRecord is not LOCKED");
        // require(proofRecord.sender == msg.sender, "not authorized");
        
        uint i;
        for (i = 0; i < proofRecord.subSrvStatuList.length; i++) {
            address subSrv;
            bool ret;
            if(proofRecord.subSrvStatuList[i].srvId == SRVID_WRCH){
                wrch_.revoke(cctTxHash);
                setSubSrvStatus(cctTxHash,SRVID_WRCH,ProofStatus.REVOKE);
            }
            else if(proofRecord.subSrvStatuList[i].srvId == SRVID_EXCHANGE){
                
                subSrv = cctChannel.getChannelSubSrv(proofRecord.channel,SRVID_EXCHANGE);
        
                ExchangeProxy(subSrv).exchangeRevoke(cctTxHash);
                setSubSrvStatus(cctTxHash,SRVID_EXCHANGE,ProofStatus.COMMIT);

            }else if(proofRecord.subSrvStatuList[i].srvId == SRVID_GOODS){
                subSrv = cctChannel.getChannelSubSrv(proofRecord.channel,SRVID_GOODS);
                GoodsProxy(subSrv).buyRevoke(cctTxHash);
                setSubSrvStatus(cctTxHash,SRVID_GOODS,ProofStatus.COMMIT);

            }else{
                require(false,"");
            }
        }
        
        proofRecord.status = ProofStatus.REVOKE;
        
        emit Revoke(chainId,proofRecord.toChain,proofRecord.pmId,proofRecord.channel,cctTxHash,SRVID,ENTRYMOD_EXCHANGEBUYREVOKE);
    }
    
    
    event ExchangeBuy(bytes32 fromChain, bytes32 toChain, bytes32 pmId,bytes32 channel, bytes32 cctTxHash, bytes32 fromSrv,uint entryMod,bytes32 xHash,bytes goodsInfo,address goodsReceiptor,address payToken);
    event ExchangePay(bytes32 fromChain, bytes32 toChain,bytes32 pmId,bytes32 channel,bytes32 cctTxHash,bytes32 fromSrv,uint entryMod, bytes32 xHash,address payToken,address payAddress,address receiptToken,address receiptAddress,uint receiptAmount);
}
