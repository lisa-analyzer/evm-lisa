// SPDX-License-Identifier: BlockchainBic
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./BridgeToken.sol";

contract BridgeContract {
  BridgeToken public token;

  mapping(address => mapping(uint256 => bool)) public hasProcessed;
  mapping(address => uint256) public transfers;

  enum Type {
    BURN,
    MINT
  }

  constructor(address _token) {
    token = BridgeToken(_token);
  }

  // will give mint and burn functions

  event Transfer(
    address indexed from,
    address to,
    uint256 amount,
    uint256 date,
    uint256 nonce,
    bytes signature,
    Type indexed step
  );

  // Burn
  function Burn(
    address to,
    uint256 amount,
    uint256 nonce,
    bytes calldata signature
  ) external {
    transfers[msg.sender] = transfers[msg.sender] + 1;
    token.burn(msg.sender, amount);
    emit Transfer(
      msg.sender,
      to,
      amount,
      block.timestamp,
      nonce,
      signature,
      Type.BURN
    );
  }

  // Mint
  function Mint(
    address from,
    address to,
    uint256 amount,
    uint256 nonce,
    bytes calldata signature
  ) external {
    bytes32 messageHash = keccak256(abi.encodePacked(to, amount, nonce));
    bytes32 message = ECDSA.toEthSignedMessageHash(messageHash);
    address signer = ECDSA.recover(message, signature);

    require(signer == from, "incorret Signature");

    uint256 id = transfers[to];
    hasProcessed[to][id] = true;

    token.mint(to, amount);

    emit Transfer(
      msg.sender,
      to,
      amount,
      block.timestamp,
      nonce,
      signature,
      Type.MINT
    );
  }
}
