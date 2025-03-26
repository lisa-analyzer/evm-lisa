//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interface/ITokenForBridge.sol";
import "hardhat/console.sol";
error ZeroAddress();
error ZeroChainId();
error IncorrectAction(address, bool);
error IncorrectSignature();

contract Bridge is Ownable {
    using ECDSA for bytes32;

    event Swap(address _tokenTo, address _to, uint256 _amount, uint256 _nonce);

    struct Chain {
        uint256 chainId;
        mapping(address => bool) tokens;
    }

    uint256 private _nonce;
    address public validator;

    mapping(uint256 => Chain) private chains;

    constructor() {
        validator = msg.sender;
    }

    function includeToken(uint256 _chainId, address _token) external onlyOwner {
        if (_token == address(0x0)) revert ZeroAddress();
        if (chains[_chainId].tokens[_token])
            revert IncorrectAction(_token, true);

        setChainId(_chainId);
        chains[_chainId].tokens[_token] = true;
    }

    function excludeToken(uint256 _chainId, address _token) external onlyOwner {
        if (_token == address(0x0)) revert ZeroAddress();
        if (_chainId == 0) revert ZeroChainId();
        if (!chains[_chainId].tokens[_token])
            revert IncorrectAction(_token, false);

        chains[_chainId].tokens[_token] = false;
    }

    function setChainId(uint256 _chainId) public onlyOwner {
        if (_chainId == 0) revert ZeroChainId();

        chains[_chainId].chainId = _chainId; // Set to zero to "delete" the blockchain
    }

    function swap(
        address _tokenFrom,
        address _tokenTo,
        uint256 _amount,
        uint256 _chainId
    ) external {
        if (_tokenFrom == address(0x0) || _tokenTo == address(0x0))
            revert ZeroAddress();
        if (!chains[block.chainid].tokens[_tokenFrom])
            revert IncorrectAction(_tokenFrom, false);
        if (!chains[_chainId].tokens[_tokenTo])
            revert IncorrectAction(_tokenTo, false);

        _nonce++;
        ITokenForBridge(_tokenFrom).burn(msg.sender, _amount);
        emit Swap(_tokenTo, msg.sender, _amount, _nonce);
    }

    function reedem(
        address _tokenTo,
        address _to,
        uint256 _amount,
        uint256 _nonce_,
        bytes memory _signature
    ) external {
        bytes32 signedHash = keccak256(
            abi.encodePacked(_tokenTo, _to, _amount, _nonce_)
        );
        bytes32 messageHash = signedHash.toEthSignedMessageHash();
        address messageSender = messageHash.recover(_signature);

        if (messageSender != validator) revert IncorrectSignature();

        ITokenForBridge(_tokenTo).mint(_to, _amount);
    }
}
