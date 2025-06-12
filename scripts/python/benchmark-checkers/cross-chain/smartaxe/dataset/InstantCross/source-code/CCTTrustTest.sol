pragma solidity ^0.4.24;

interface CCTTrust{
    function verify(bytes32 pmId, bytes memory proofData , bytes memory biszData) public returns(bool);
}

contract CCTTrustTest is CCTTrust{
    address cctRoot;

    
    mapping(bytes32=>address) public pmMap;

    constructor(address cctroot)public {
        cctRoot = cctroot;
    }
    
    function ecverify(bytes32 hashdata, bytes memory proofData) private pure returns (address signature_address)
    {
        //emit E2("data",hashdata);
        //emit E1("proofData",proofData);
        require(proofData.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        // The proofData format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        assembly {
            r := mload(add(proofData, 32))
            s := mload(add(proofData, 64))

            // Here we are loading the last 32 bytes, including 31 bytes of 's'.
            //v := byte(0, mload(add(proofData, 96)))
            v := and(mload(add(proofData, 65)), 255)
        }

        // Version of proofData should be 27 or 28, but 0 and 1 are also possible
        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28);

        /* prefix is needed for geth only
        * https://github.com/ethereum/go-ethereum/issues/3731
        */
        // bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        //bytes32 hashdata = keccak256(prefix, hashdata);
        //emit E2("hashdata",hashdata);
        //bytes32 hashdata = keccak256(data);
        //signature_address = ecrecover(keccak256(abi.encodePacked(prefix, hashdata)), v, r, s);
        signature_address = ecrecover(hashdata, v, r, s);
        //emit E3("signature_address",signature_address);
        //emit E1("r",r);
        //emit E1("s",s);
        //emit E4("v",v);
        // ecrecover returns zero on error
        require(signature_address != address(0x0));

        //emit E2("address",signature_address);

        return signature_address;
    }
    
    function verify(bytes32 pmId,bytes memory proofData , bytes memory crossData) public returns(bool){
        bytes32 hashData = keccak256(abi.encodePacked(crossData));
        address operatorAddress = pmMap[pmId];
        require(operatorAddress != address(0x0),"");
        if(ecverify(hashData,proofData) == operatorAddress) {
            emit VerifyEvent(proofData,crossData);
            return true;
        }else{
            return false;
        }
        // return true;
    }

    function registerPm(bytes32 pmId,bytes memory params) public returns(bool){
        require(msg.sender == cctRoot);
        bytes memory data = abi.encodePacked(params);
        address nodeAddr;
        
        assembly{
            // nodeAddr := and(mload(data),0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            nodeAddr := mload(add(data,20))
        }
        
        pmMap[pmId] = nodeAddr;
        
        emit PmRegister(pmId,address(this),pmMap[pmId]);
        return true;
    }
    
    event VerifyEvent(bytes proofData, bytes crossData);
    event PmRegister(bytes32 pmId,address ccttrust,address params);
}
