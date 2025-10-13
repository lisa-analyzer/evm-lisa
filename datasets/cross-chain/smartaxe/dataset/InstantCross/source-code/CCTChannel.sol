pragma solidity ^0.4.24;

// pragma experimental ABIEncoderV2;
import "./CCTRoot.sol";
import "./rlp.sol";

contract CCTChannel{
    using RLP for bytes;
    using RLP for RLP.RLPItem;
    
    struct SubSrvItem{
        bytes32 srvId;
        bytes32 fromChainId;
        address subSrvFromChain;
        address subSrvToChain;
    }
    struct ChannelInfo{
        bytes32 toChainId;
        address entry;
        uint [] entryModList;
        mapping(bytes32=>SubSrvItem) subSrvMap;
        bytes32 [] subSrvIdList;
    }
    
    // mapping(bytes32=> SubSrvItem) public subSrvMap;
    address owner;
    mapping(bytes32=>ChannelInfo) public channels ;
    mapping(bytes32=>bytes32[]) public pmChannelMap;
    CCTRoot public cctRoot;
    
    constructor (address cctroot) public{
        cctRoot = CCTRoot(cctroot);
        owner = msg.sender;
    }
    
    function getChannelCrossChain(bytes32 id) public view returns(bytes32 ChanId){
        return channels[id].toChainId;
    }
    
    function getChannelEntry(bytes32 id) public view returns(address entry){
        return channels[id].entry;
    }
    
    function getChannelSubSrv(bytes32 id,bytes32 srvId) public view returns(address subSrvAddr){
        return channels[id].subSrvMap[srvId].subSrvToChain;
    }
    
    // function getChannelData(bytes32 id) public view returns(bytes memory channelData){
        
    //     channelData = abi.encodePacked(channels[id].toChainId,channels[id].entry);
    //     uint256 index;
    //     for(index = 0; index < channels[id].subSrvList.length; index++){
    //         SubSrvItem storage subSrv = channels[id].subSrvList[index];
    //         channelData = abi.encodePacked(channelData,subSrv.srvId,subSrv.fromChainAddress,subSrv.toChainAddress);
    //     }
    // }
    
    
    function parseAndSaveChannelData(bytes32 channelId,bytes memory channelData) private{
        
        RLP.RLPItem [] memory channelAttrItems = channelData.toRLPItem().toList();
        require(channelAttrItems.length == 4,"bad channel data");
        
        ChannelInfo storage channel = channels[channelId];
        channel.toChainId = channelAttrItems[0].toBytes32();
        channel.entry = channelAttrItems[1].toAddress();
        
        RLP.RLPItem [] memory ls = channelAttrItems[2].toList();
        uint256 i;
        for(i = 0; i < ls.length; i ++){
            channel.entryModList.push(ls[i].toUint());
        }
        
        ls = channelAttrItems[3].toList();
        for(i = 0; i < ls.length; i ++){
            RLP.RLPItem [] memory items = ls[i].toList();
            bytes32 subSrvId = items[0].toBytes32();
            bytes32 fromChainId = items[1].toBytes32();
            address subSrvFromChain = items[2].toAddress();
            address subSrvToChain = items[3].toAddress();
            channel.subSrvIdList.push(subSrvId); 
            channel.subSrvMap[subSrvId] = SubSrvItem(subSrvId,fromChainId,subSrvFromChain,subSrvToChain);
        }
        
    }
    //TO MODIFY
    function registerChannel(bytes32 pmId, bytes32 channelId, bytes memory channelData) public returns(bool){
        require(msg.sender == owner,"not authorized");
        // require(cctRoot.verify(pmId,proofData,channelData),"register channel no authorized");
        
        // if(channels[channelId].toChainId != 0x0){
        //     pmChannelMap[pmId].push(channelId);
        //     emit RegisterChannelEvent(pmId,channelId);
        //     return true;
        // }
        
        parseAndSaveChannelData(channelId,channelData);
        bytes32 [] storage pmChannelList = pmChannelMap[pmId];
        uint i;
        for(i =0; i < pmChannelList.length; i++){
            if(pmChannelList[i] == channelId){
                emit RegisterChannelEvent(pmId,channelId);
                return true;
            }
        }
        
        pmChannelMap[pmId].push(channelId);
        
        emit RegisterChannelEvent(pmId,channelId);
        return true;
    }
    
    function authorized( bytes32 pmId, bytes32 channelId) public view returns(bool){
        uint256 i;
        bytes32 [] storage channellist = pmChannelMap[pmId];

        for(i = 0; i < channellist.length; i++){
            if(pmChannelMap[pmId][i] == channelId) {
                // ChannelInfo storage channel = channels[channelId];
                // if( toChain != channel.toChainId) return false;
                // else return true;
                return true;
            }
        }
        
        return false;
    }
    
    event RegisterChannelEvent(bytes32 pmId,bytes32 channelId);
}


