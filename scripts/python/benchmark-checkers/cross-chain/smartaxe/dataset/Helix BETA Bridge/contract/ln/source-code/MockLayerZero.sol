// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../messager/interface/ILayerZeroEndpoint.sol";

interface ILayerZeroReceiver {
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

contract LayerZeroEndpointMock is ILayerZeroEndpoint {
    uint16 public srcChainId;
    constructor(uint16 _srcChainId) {
        srcChainId = _srcChainId;
    }

    function send(
        uint16,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable,
        address,
        bytes calldata
    ) external payable {
        address receiver = address(bytes20(_destination[0:20]));
        bytes memory path = _destination;
        address srcInPath;
        assembly {
            srcInPath := mload(add(add(path, 20), 20))
        }
        bytes memory transformedDestination = abi.encodePacked(srcInPath, receiver);
        ILayerZeroReceiver(receiver).lzReceive(
            srcChainId,
            transformedDestination,
            0,
            _payload
        );
    }

    function estimateFees(
        uint16,
        address,
        bytes calldata,
        bool,
        bytes calldata
    ) external pure returns (uint nativeFee, uint zroFee) {
        return (0.001 ether, 0);
    }
}
