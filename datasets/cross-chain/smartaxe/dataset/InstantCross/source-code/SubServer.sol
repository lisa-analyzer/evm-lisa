pragma solidity ^0.4.24;

contract SubServer{
    address [] public authorizerList;
    address public owner;
    
    constructor()public{
        owner = msg.sender;
    }
    
    modifier onlyOwner(){
        require(owner == msg.sender,"not owner");
        _;
    }
    modifier authorized(){
        uint i;
        bool flag = false;
        for(i = 0; i < authorizerList.length; i++){
            if(authorizerList[i] == msg.sender) {
                flag = true;
                break;
            }
        }
        require(flag,"not authorized to call method");
        _;
    }
    
    function approve(address caller) onlyOwner public{
        uint i;
        bool flag = false;
        for(i = 0; i < authorizerList.length; i++){
            if(authorizerList[i] == caller) {
                flag = true;
                break;
            }
        }
        if(!flag) authorizerList.push(caller);
        emit Approve(caller);
    }
    
    event Approve(address caller);
}
