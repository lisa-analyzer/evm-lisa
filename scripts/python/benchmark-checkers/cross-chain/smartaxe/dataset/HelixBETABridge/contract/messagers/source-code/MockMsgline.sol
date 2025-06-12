// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

contract MockMessageLine {
    mapping(bytes32 => bool) public dones;
    bool public failedFlag;
    bool public neverDelivered;

    uint256 public sendNonce;
    uint256 public recvNonce;

    address public remote;

    function setRemote(address _remote) external {
        remote = _remote;
    }

    function setRecvFailed() external {
        failedFlag = true;
    }

    function setNeverDelivered() external {
        neverDelivered = true;
    }

    function send(
        uint256 toChainId,
        address toDapp,
        bytes calldata message,
        bytes calldata params
    ) external payable {
        require(msg.value >= 1 ether, "fee is not enough");
        sendNonce += 1;
        MockMessageLine(remote).recv(sendNonce, block.chainid, msg.sender, toDapp, message);
    }

    function recv(
        uint256 sendNonce,
        uint256 sourceChainId,
        address sourceSender,
        address toDapp,
        bytes calldata message
    ) public {
        if (neverDelivered) {
            neverDelivered = false;
            return;
        }
        recvNonce = sendNonce;
        dones[bytes32(recvNonce)] = true;
        if (failedFlag) {
            failedFlag = false;
            return;
        }

        toDapp.call(abi.encodePacked(message, sourceChainId, sourceSender));
    }

    function fee(
        uint256 toChainId,
        address toDapp,
        bytes calldata message,
        bytes calldata params
    ) external view returns (uint256) {
        return 1 ether;
    }

    function sentMessageId() external view returns(bytes32) {
        return bytes32(sendNonce);
    }

    function recvMessageId() external view returns(bytes32) {
        return bytes32(recvNonce);
    }
}


