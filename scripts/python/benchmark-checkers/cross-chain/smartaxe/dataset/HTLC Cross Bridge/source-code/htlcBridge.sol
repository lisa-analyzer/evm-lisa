//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract htlcBridge is Ownable {

    event NewPortal(address indexed Sender, uint Amount, address Contract);
    event DestinationPortalOpened(address indexed Sender, address indexed Receiver, uint Amount);
    event DestinationTransferFinalized(address indexed Sender);

    struct Transfer {
        bytes32 commitment;     //merkle tree root hash
        address sender;         //used to generate commitment (leaf)
        address receiver;       //used to generate commitment (leaf)
        address tokenContract;  //used to generate commitment (leaf)
        uint amount;            //used to generate commitment (leaf)
        bytes32 hashLock;
        uint timeLock;
    }

    mapping(address=>Transfer) _transfersOut;
    mapping(address=>Transfer) _transfersIn;
    mapping(address=>bool) _hasActiveTransferOut;
    mapping(address=>address) public contractToContract;

    modifier noActiveTransferOut {
        require(_hasActiveTransferOut[msg.sender] == false, "Error: Ongoing Transfer, wait until it either completes or expires");
        _;
    }

    function initPortal(bytes32 _commitment, bytes32 _hashLock, address _tokenContract, address _receiver, uint _amount) external noActiveTransferOut{
        IERC20 tokenContract = IERC20(_tokenContract);
        require(tokenContract.allowance(msg.sender, address(this)) >= _amount, "Error: Insuficient allowance");
        _hasActiveTransferOut[msg.sender] = true;
        _transfersOut[msg.sender] = Transfer(_commitment, msg.sender, _receiver, _tokenContract, _amount, _hashLock, block.timestamp + 1 hours);
        tokenContract.transferFrom(msg.sender, address(this), _amount);
        emit NewPortal(msg.sender, _amount, _tokenContract);
    }

    function portalFromOtherChain(
        bytes32 _commitment, 
        bytes32 _hashLock, 
        uint _timeLock, 
        address _tokenContract, 
        address _sender, 
        address _receiver, 
        uint _amount) 
    external {
        //require(getCommitment(_sender, _receiver, _tokenContract, _amount) == _commitment, "Error: Transfer data doesn't match commitment");
        require(contractToContract[_tokenContract] != address(0x0), "Error: Token contract doesn't have a match in this chain");
        _transfersIn[_receiver] = Transfer(_commitment, _sender, _receiver, contractToContract[_tokenContract], _amount, _hashLock, _timeLock);
        emit DestinationPortalOpened(_sender, _receiver, _amount);

    }

    function finalizeInterPortalTransferDest(address _receiver, string memory _secretKey) public { 
        Transfer memory transfer = _transfersIn[_receiver];
        IERC20 tokenContract = IERC20(contractToContract[transfer.tokenContract]);
        require(hashThis(abi.encode(_secretKey)) == transfer.hashLock, "Error: hash lock does not match");
        require(block.timestamp <= transfer.timeLock, "Error: transfer wasn't finalized within time");
        require(tokenContract.balanceOf(address(this)) >= transfer.amount, "Error: not enough liquidity to bridge funds");
        tokenContract.transfer(_receiver, transfer.amount);
        emit DestinationTransferFinalized(transfer.sender);
    }

    function finalizeInterPortalTransferOrigin(address _sender) public { 
        _hasActiveTransferOut[_sender] = false;
    }

    function withdrawFunds() public {
        require(_hasActiveTransferOut[msg.sender], "Error: sender does not have a pending transfer");
        Transfer memory transfer = _transfersOut[msg.sender];
        require(transfer.timeLock < block.timestamp, "Error: ongoing transfer");
        _hasActiveTransferOut[msg.sender] = false;
        IERC20 tokenContract = IERC20(transfer.tokenContract);
        tokenContract.transfer(msg.sender, transfer.amount);
    }

    function setPairContract(address _source, address _local) public onlyOwner {
        contractToContract[_source] = _local;
    }

    function getTransferOut(address _sender) external view
    returns(
        bytes32,
        address,
        address,
        address,
        uint,
        uint,
        bytes32
    ){
        require(_hasActiveTransferOut[_sender], "Error: There aren't any ongoing transfer for the sender");
        Transfer memory transfer = _transfersOut[_sender];
        return (transfer.commitment, _sender, transfer.receiver, transfer.tokenContract, transfer.amount, transfer.timeLock, transfer.hashLock);
    }

    function getCommitment(address _sender, address _receiver, address _tokenContract, uint _amount) public pure returns(bytes32) {
        return hashThis(abi.encodePacked(
                    hashThis(abi.encodePacked(hashThis(abi.encodePacked(_sender)),hashThis(abi.encodePacked(_receiver)))),
                    hashThis(abi.encodePacked(hashThis(abi.encodePacked(_tokenContract)),hashThis(abi.encodePacked(_amount))))
        ));
    }
    
    function hashThis(bytes memory _input) public pure returns(bytes32){
        return sha256(_input);
    }

    function encode(address _x) public pure returns(bytes memory) {
        return abi.encodePacked(_x);
    }
}