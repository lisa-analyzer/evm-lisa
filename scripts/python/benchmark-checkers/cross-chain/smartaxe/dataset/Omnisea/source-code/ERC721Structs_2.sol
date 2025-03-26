// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
     * @notice Parameters for ERC721 collection creation.
     *
     * @param dstChainName Name of the destination chain.
     * @param name Name of the collection.
     * @param uri URI to collection's metadata.
     * @param fileURI URI of the file linked with the collection.
     * @param price Price for a single ERC721 mint.
     * @param assetName Mapping name of the ERC20 being a currency for the minting price.
     * @param from Minting start date.
     * @param to Minting end date.
     * @param tokensURI CID of the NFTs metadata directory.
     * @param maxSupply Collection's max supply. Unlimited if 0.
     * @param isZeroIndexed First token ID.
     * @param gas Cross-chain task (tx) execution gas limit
     * @param redirectFee Fee required to cover transaction fee on the redirectChain, if involved. OmnichainRouter-specific.
     *        Involved during cross-chain multi-protocol routing. For example, Optimism (LayerZero) to Moonbeam (Axelar).
     */
struct CreateParams {
    string dstChainName;
    string name;
    string uri;
    uint256 price;
    string assetName;
    uint256 from;
    uint256 to;
    string tokensURI;
    uint256 maxSupply;
    bool isZeroIndexed;
    uint256 points;
    uint gas;
    uint256 redirectFee;
}

/**
     * @notice Parameters for ERC721 mint.
     *
     * @param dstChainName Name of the destination (NFT's) chain.
     * @param coll Address of the collection.
     * @param mintPrice Price for the ERC721 mint. Used during cross-chain mint for locking purpose. Validated on the dstChain.
     * @param assetName Mapping name of the ERC20 being a currency for the minting price.
     * @param creator Address of the creator.
     * @param gas Cross-chain task (tx) execution gas limit
     * @param redirectFee Fee required to cover transaction fee on the redirectChain, if involved. OmnichainRouter-specific.
     *        Involved during cross-chain multi-protocol routing. For example, Optimism (LayerZero) to Moonbeam (Axelar).
     */
struct MintParams {
    string dstChainName;
    address coll;
    uint256 mintPrice;
    string assetName;
    uint256 quantity;
    address creator;
    bytes32[] merkleProof;
    uint256 gas;
    uint256 redirectFee;
}

/**
  * @notice Asset supported for omnichain minting.
  *
  * @param dstChainName Name of the destination (NFT's) chain.
  * @param coll Address of the collection.
*/
struct Asset {
    IERC20 token;
    uint256 decimals;
}

struct Allowlist {
    uint256 maxPerAddress;
    uint256 maxPerAddressPublic;
    uint256 publicFrom;
    uint256 price;
    bytes32 merkleRoot;
    bool isEnabled;
}