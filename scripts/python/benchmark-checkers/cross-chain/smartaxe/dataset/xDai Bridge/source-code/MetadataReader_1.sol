pragma solidity 0.7.5;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155MetadataURI.sol";
import "../../../Ownable.sol";

/**
 * @title MetadataReader
 * @dev Functionality for reading metadata from ERC721/ERC1155 tokens.
 */
contract MetadataReader is Ownable {
    /**
     * @dev Sets the custom metadata for the given ERC721/ERC1155 token.
     * Only owner can call this method.
     * Useful when original NFT token does not implement neither name() nor symbol() methods.
     * @param _token address of the token contract.
     * @param _name custom name for the token contract.
     * @param _symbol custom symbol for the token contract.
     */
    function setCustomMetadata(
        address _token,
        string calldata _name,
        string calldata _symbol
    ) external onlyOwner {
        stringStorage[keccak256(abi.encodePacked("customName", _token))] = _name;
        stringStorage[keccak256(abi.encodePacked("customSymbol", _token))] = _symbol;
    }

    /**
     * @dev Internal function for reading ERC721/ERC1155 token name.
     * Use custom predefined name in case name() function is not implemented.
     * @param _token address of the ERC721/ERC1155 token contract.
     * @return name for the token.
     */
    function _readName(address _token) internal view returns (string memory) {
        (bool status, bytes memory data) = _token.staticcall(abi.encodeWithSelector(IERC721Metadata.name.selector));
        return status ? abi.decode(data, (string)) : stringStorage[keccak256(abi.encodePacked("customName", _token))];
    }

    /**
     * @dev Internal function for reading ERC721/ERC1155 token symbol.
     * Use custom predefined symbol in case symbol() function is not implemented.
     * @param _token address of the ERC721/ERC1155 token contract.
     * @return symbol for the token.
     */
    function _readSymbol(address _token) internal view returns (string memory) {
        (bool status, bytes memory data) = _token.staticcall(abi.encodeWithSelector(IERC721Metadata.symbol.selector));
        return status ? abi.decode(data, (string)) : stringStorage[keccak256(abi.encodePacked("customSymbol", _token))];
    }

    /**
     * @dev Internal function for reading ERC721 token URI.
     * @param _token address of the ERC721 token contract.
     * @param _tokenId unique identifier for the token.
     * @return token URI for the particular token, if any.
     */
    function _readERC721TokenURI(address _token, uint256 _tokenId) internal view returns (string memory) {
        (bool status, bytes memory data) =
            _token.staticcall(abi.encodeWithSelector(IERC721Metadata.tokenURI.selector, _tokenId));
        return status ? abi.decode(data, (string)) : "";
    }

    /**
     * @dev Internal function for reading ERC1155 token URI.
     * @param _token address of the ERC1155 token contract.
     * @param _tokenId unique identifier for the token.
     * @return token URI for the particular token, if any.
     */
    function _readERC1155TokenURI(address _token, uint256 _tokenId) internal view returns (string memory) {
        (bool status, bytes memory data) =
            _token.staticcall(abi.encodeWithSelector(IERC1155MetadataURI.uri.selector, _tokenId));
        return status ? abi.decode(data, (string)) : "";
    }
}