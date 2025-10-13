// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMessageLine {
    function send(uint256 toChainId, address toDapp, bytes calldata message, bytes calldata params) external payable;
    function fee(uint256 toChainId, address toDapp, bytes calldata message, bytes calldata params) external view returns (uint256);
}

abstract contract Application {
    function _msgSender() internal view returns (address payable _line) {
        _line = payable(msg.sender);
    }

    function _fromChainId() internal pure returns (uint256 _msgDataFromChainId) {
        require(msg.data.length >= 52, "!fromChainId");
        assembly {
            _msgDataFromChainId := calldataload(sub(calldatasize(), 52))
        }
    }

    function _xmsgSender() internal pure returns (address payable _from) {
        require(msg.data.length >= 20, "!line");
        assembly {
            _from := shr(96, calldataload(sub(calldatasize(), 20)))
        }
    }
}
