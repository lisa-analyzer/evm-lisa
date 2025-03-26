pragma solidity ^0.4.24;

import "./CCTRoot.sol";
import "./CCTChannel.sol";
import "./rlp.sol";

interface BIZ{
    function handleProof(bytes32 fromChain, bytes32 toChain, bytes32 pmId,bytes32 channel,bytes32 fromSrv, uint entryMod, bytes32 cctTxHash, bytes memory businessProof) public returns(bool);
}

contract CCTDispatcher{

    using RLP for bytes;
    using RLP for RLP.RLPItem;
    
    address owner;
    CCTRoot cctRoot;
    CCTChannel cctChannel;
     
    constructor(address cctroot, address cctchannel) public {
        
        owner = msg.sender;
        cctRoot = CCTRoot(cctroot);
        cctChannel = CCTChannel(cctchannel);
     }
    
    function addCrossData(bytes32 fromChain, bytes32 toChain, bytes32 pmId, bytes memory proofData, bytes memory crossData) public {
        require(fromChain != toChain,"fromChain is the same as the toChain");
        require(cctRoot.getChainId() == toChain, "bad chainId");
        
        require(cctRoot.verify(pmId,proofData,crossData),"no authorized pmId");
        

        //decode crossData
        RLP.RLPItem[] memory ls = crossData.toRLPItem().toList(); 
        
        uint i;
        for(i = 0; i < ls.length; i++){
            RLP.RLPItem[] memory pd = ls[i].toList();
            
            if(pd.length !=5 && pd.length != 4) {
                emit BadProofData(crossData,1);
                continue;
            }
            bytes32 channel = pd[0].toBytes32();
            bytes32 cctTxHash = pd[1].toBytes32();
            bytes32 fromSrv = pd[2].toBytes32();
            uint entryMod = pd[3].toUint();
            
            bytes memory businessProof = pd[4].toBytes();
            
            if(!cctChannel.authorized(pmId,channel)) {
                emit BadProofData(crossData,2);
                continue;
            }
            address entry = cctChannel.getChannelEntry(channel);
            
            if(entry ==  address(0x0) || !contractExists(entry)){
                emit ProofEvent(fromChain,toChain, pmId,channel,fromSrv,entryMod,cctTxHash,businessProof,false);
                 continue;
            }
            
            if(BIZ(entry).handleProof(fromChain,toChain, pmId,channel,fromSrv,entryMod,cctTxHash,businessProof)){
                emit ProofEvent(fromChain,toChain, pmId,channel,fromSrv,entryMod,cctTxHash,businessProof,true);
            }else{
                emit ProofEvent(fromChain,toChain, pmId,channel,fromSrv,entryMod,cctTxHash,businessProof,false);
            }
        }
        
    }
    
    function contractExists(address contract_address) private view returns (bool) {
        uint size;

        assembly {
            size := extcodesize(contract_address)
        }

        return size > 0;
    }
    
    function test(bytes memory crossData)public{
        //decode crossData
        RLP.RLPItem[] memory ls = crossData.toRLPItem().toList(); 
        uint i;
        bytes32 fromChain = 0x0000000000000000000000000000000000000000000000000000000000000001;
        bytes32 toChain = 0x0000000000000000000000000000000000000000000000000000000000000002;
        bytes32 pmId = fromChain;
        for(i = 0; i < ls.length; i++){
            RLP.RLPItem[] memory pd = ls[i].toList();
            // emit TestEvent2(pd.length,0);
            if(pd.length !=5) break;
            bytes32 channel = pd[0].toBytes32();
            bytes32 cctTxHash = pd[1].toBytes32();
            bytes32 fromSrv = pd[2].toBytes32();
            uint entryMod = pd[3].toUint();
            
            bytes memory businessProof = pd[4].toBytes();
            // if(!cctChannel.authorized(fromChain,toChain,pmId,channel,fromSrv)) {
            //     emit BadProofData(crossData,1);
            //     continue;
            // }
            
            emit ProofEvent(fromChain,toChain, pmId,channel,fromSrv,entryMod,cctTxHash,businessProof,true);
            
            RLP.RLPItem [] memory bizItems = businessProof.toRLPItem().toList();
            uint j;
            for(j = 0; j < bizItems.length; j++){
                emit BadProofData(bizItems[j].toBytes(),j);
            }
            // BIZ entry = BIZ(cctChannel.getChannelEntry(channel));
            // if(entry.handleProof(fromChain,toChain, pmId,channel,fromSrv,entryMod,cctTxHash,businessProof)){
            //     emit ProofEvent(fromChain,toChain, pmId,channel,fromSrv,entryMod,cctTxHash,businessProof,true);
            // }else{
            //     emit ProofEvent(fromChain,toChain, pmId,channel,fromSrv,entryMod,cctTxHash,businessProof,false);
            // }
        }
    }

    event ProofEvent(bytes32 fromChain, bytes32 toChain,bytes32 pmId,bytes32 channel,bytes32 fromSrv,uint entryMod,bytes32 cctTxHash,bytes businessProof,bool result);
    event BadProofData(bytes data,uint errCode);
}
