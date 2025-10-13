pragma solidity ^0.4.24;

// import "./CCTChannel.sol";

interface CCTChannel{
    function getChannelSubSrv(bytes32 id,bytes32 srvId) public view returns(address subSrvAddr);
    function getChannelCrossChain(bytes32 id) public view returns(bytes32 ChanId);
    function getChannelEntry(bytes32 id) public view returns(address entry);
}


interface CCTRoot{
    function getChainId() public view returns(bytes32);
}

interface BIZ{
    function handleProof(bytes32 fromChain, bytes32 toChain, bytes32 pmId,bytes32 channel,bytes32 fromSrv, uint entryMod, bytes32 cctTxHash, bytes memory businessProof) public returns(bool);
}

contract AggregationBase is BIZ{
    
    uint constant ENTRYMOD_EXCHANGEBUYLOCK = 0x01;
    uint constant ENTRYMOD_EXCHANGEBUYCOMMIT = 0x02;
    uint constant ENTRYMOD_EXCHANGEBUYREVOKE = 0x03;
    uint constant ENTRYMOD_EXCHANGEBUYCOMFIRM = 0x04;
    uint constant ENTRYMOD_EXCHANGEPAYLOCK = 0x05;
    // uint constant ENTRYMOD_EXCHANGEPAYCOMMIT = 0x06;
    // uint constant ENTRYMOD_EXCHANGEPAYREVOKE = 0x07;
    // uint constant ENTRYMOD_EXCHANGEPAYCOMFIRM = 0x08;
    
    uint constant HTLC_EXPIRE_TIME = 3600;
    
    bytes32 constant SRVID = 0x0000000000000000000000000000000000000000000000000000000000000001;
    bytes32 constant SRVID_EXCHANGE = 0x0000000000000000000000000000000000000000000000000000000000000002;
    bytes32 constant SRVID_GOODS = 0x0000000000000000000000000000000000000000000000000000000000000003;
    bytes32 constant SRVID_WRCH = 0x0000000000000000000000000000000000000000000000000000000000000004;
    
    CCTChannel cctChannel;
    address public cctDispatcher;
    bytes32 public chainId;
    
    enum ProofStatus{
        INVALID,
        LOCK,
        CONFIRM,
        COMMIT,
        REVOKE
    }
    struct SubSrvStatus{
        bytes32 srvId;
        ProofStatus status;
    }
    struct ProofRecord{
        bytes32 toChain;
        bytes32 pmId;
        bytes32 channel;
        // bytes32 xHash;
        bytes32 cctTxHash;
        // uint expireTime;
        ProofStatus status;
        // bytes32 bizHash;
        mapping(bytes32=>uint) subSrvMap;
        SubSrvStatus [] subSrvStatuList;
    }
    
    mapping(bytes32=>ProofRecord) public proofHistory;
    address owner;
    
    constructor(address cctdispatcher, bytes32 chainid,address cctchannel) public{
        // require(contractExists(cctdispatcher),"CCTDispatcher not exists");
        require(contractExists(cctchannel),"CCTChannel not exists");
        cctChannel = CCTChannel(cctchannel);
        cctDispatcher = cctdispatcher;
        chainId = chainid;
        owner = msg.sender;
    }
    
    function setSubSrvStatus(bytes32 cctTxHash, bytes32 subSrvId, ProofStatus status)internal returns(bool){
        ProofRecord storage proofRecord = proofHistory[cctTxHash];
        if(proofRecord.cctTxHash == 0x0) return false;
        
        uint index = proofRecord.subSrvMap[subSrvId];
        if(index == 0){
            index = proofRecord.subSrvStatuList.length+1;
            proofRecord.subSrvMap[subSrvId] = index;
            proofRecord.subSrvStatuList.push(SubSrvStatus(subSrvId,status));
        }else{
            proofRecord.subSrvStatuList[proofRecord.subSrvMap[subSrvId]-1].status = status;
        }
        
        // proofRecord.subSrvStatuList.push(SubSrvStatus(subSrvId,status));
        
        return true;
    }
    
    function getSubSrvStatus(bytes32 cctTxHash, bytes32 subSrvId)internal view returns(ProofStatus){
        ProofRecord storage proofRecord = proofHistory[cctTxHash];
        if(proofRecord.cctTxHash == 0x0) return ProofStatus.INVALID;
        
        return proofRecord.subSrvStatuList[proofRecord.subSrvMap[subSrvId]-1].status;
        
    }
    
    function calAndUpdateProofStatus(bytes32 cctTxHash) internal {
        ProofRecord storage proofRecord = proofHistory[cctTxHash];
        if(proofRecord.cctTxHash == 0x0 || proofRecord.subSrvStatuList.length == 0) return;
        
        uint i;
        // uint cnt = 0;
        ProofStatus status;
        if(proofRecord.subSrvStatuList.length == 1) {
            proofRecord.status = proofRecord.subSrvStatuList[0].status;
            return;
        }
        
        status = proofRecord.subSrvStatuList[0].status;
        for(i =1 ;i < proofRecord.subSrvStatuList.length; i++){
            if(status != proofRecord.subSrvStatuList[i].status) return;
        }
        
        proofRecord.status = status;
        
    }
    
    function contractExists(address contract_address) internal view returns (bool) {
        uint size;

        assembly {
            size := extcodesize(contract_address)
        }

        return size > 0;
    }
    
    modifier onlyCCTDispatcher() {
        require( msg.sender == cctDispatcher, "Sender not authorized." );
        _;
    }
    
    modifier onlyOwner(){
        require(owner == msg.sender,"not owner");
        _;
    }
    
    function handleProof(bytes32 fromChain, bytes32 toChain, bytes32 pmId,bytes32 channel,bytes32 fromSrv, uint entryMod, bytes32 cctTxHash, bytes memory businessProof) public returns(bool){

        if( msg.sender != cctDispatcher && msg.sender != owner) return false;
        if(toChain != chainId) return false;

        return process(fromChain, toChain, pmId,channel,fromSrv, entryMod, cctTxHash, businessProof);
    }
    
    function process(bytes32 fromChain, bytes32 toChain, bytes32 pmId,bytes32 channel,bytes32 fromSrv, uint entryMod, bytes32 cctTxHash, bytes memory businessProof) private returns(bool){
        return true;
    }
    
    event Confirm(bytes32 fromChain, bytes32 toChain, bytes32 pmId,bytes32 channel,bytes32 cctTxHash, bytes32 fromSrv,uint entryMod);
    event Revoke(bytes32 fromChain, bytes32 toChain, bytes32 pmId,bytes32 channel,bytes32 cctTxHash, bytes32 fromSrv,uint entryMod);
    event Commit(bytes32 fromChain,bytes32 toChain,bytes32 pmId,bytes32 channel,bytes32 cctTxHash,bytes32 fromSrv,uint entryMod,bytes32 x);

}
