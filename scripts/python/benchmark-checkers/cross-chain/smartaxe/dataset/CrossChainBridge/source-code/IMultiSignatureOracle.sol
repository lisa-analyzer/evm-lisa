// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IMultiSignatureOracle {
  function signaturesCheckERC721(
    uint8[] memory sigV,
    bytes32[] memory sigR,
    bytes32[] memory sigS,
    address receiverAddress,
    address collectionAddress,
    uint256 tokenId,
    uint256 depositChainId,
    uint256 depositNumber
  ) external returns (bool);

  function signaturesCheckERC20(
    uint8[] memory sigV,
    bytes32[] memory sigR,
    bytes32[] memory sigS,
    address receiverAddress,
    address sourceNetworkTokenAddress,
    uint256 amount,
    uint256 depositChainId,
    uint256 depositNumber
  ) external returns (bool);
}