pragma solidity ^0.4.24;

interface CCTTrust{
    function verify(bytes32 pmId, bytes memory proofData , bytes memory biszData) public returns(bool);
    function registerPm(bytes32 pmId,bytes memory params) public returns(bool);
}

contract CCTRoot{

    mapping(bytes32=>address) public pmCCTTrustMap;
    
    address public owner;
    bytes32 public chainId;
    
    constructor(bytes32 chainid)public{
        owner = msg.sender;
        chainId = chainid;
    }
    
    modifier onlyOwner() {
        require( msg.sender == owner, "Sender not authorized." );
        _;
    }

    function contractExists(address contract_address) internal view returns (bool) {
        uint size;

        assembly {
            size := extcodesize(contract_address)
        }

        return size > 0;
    }
    
    function verify(bytes32 pmId, bytes memory proofData, bytes memory data) public returns(bool){
        
        require( pmCCTTrustMap[pmId] != address(0x0),"CCTTrust not supported by pmId");
        CCTTrust ccttrust = CCTTrust(pmCCTTrustMap[pmId]);
        
        
        // require( contractExists(ccttrust),"CCTTrust not exist");
        
        return ccttrust.verify(pmId,proofData, data);
    }
    
    function registerPm(bytes32 pmId, address ccttrust,bytes memory ccttrustParams) onlyOwner public{
        CCTTrust cctTrust = CCTTrust(ccttrust);

        if(cctTrust.registerPm(pmId,ccttrustParams)){
            emit RegisterPm(pmId,ccttrust,ccttrustParams);
            pmCCTTrustMap[pmId] = ccttrust;
        }
    }
    
    function getChainId() public view returns(bytes32){
        return chainId;
    }
    
    event RegisterPm(bytes32 pmId, address ccttrust,bytes ccttrustParams);
}
