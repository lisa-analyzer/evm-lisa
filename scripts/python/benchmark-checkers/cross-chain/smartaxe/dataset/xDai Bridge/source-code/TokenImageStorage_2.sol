pragma solidity 0.7.5;

import "@openzeppelin/contracts/utils/Address.sol";
import "../../../Ownable.sol";

/**
 * @title TokenImageStorage
 * @dev Storage functionality for working with ERC721/ERC1155 image contract.
 */
contract TokenImageStorage is Ownable {
    bytes32 internal constant ERC721_TOKEN_IMAGE_CONTRACT =
        0x20b8ca26cc94f39fab299954184cf3a9bd04f69543e4f454fab299f015b8130f; // keccak256(abi.encodePacked("tokenImageContract"))
    bytes32 internal constant ERC1155_TOKEN_IMAGE_CONTRACT =
        0x02e1d283efd236e8b97cefe072f0c863fa2db9f9ba42b0eca53ab31c49067a67; // keccak256(abi.encodePacked("erc1155tokenImageContract"))

    /**
     * @dev Updates address of the used ERC721 token image.
     * Only owner can call this method.
     * @param _image address of the new token image.
     */
    function setTokenImageERC721(address _image) external onlyOwner {
        _setTokenImageERC721(_image);
    }

    /**
     * @dev Updates address of the used ERC1155 token image.
     * Only owner can call this method.
     * @param _image address of the new token image.
     */
    function setTokenImageERC1155(address _image) external onlyOwner {
        _setTokenImageERC1155(_image);
    }

    /**
     * @dev Tells the address of the used ERC721 token image.
     * @return address of the used token image.
     */
    function tokenImageERC721() public view returns (address) {
        return addressStorage[ERC721_TOKEN_IMAGE_CONTRACT];
    }

    /**
     * @dev Tells the address of the used ERC1155 token image.
     * @return address of the used token image.
     */
    function tokenImageERC1155() public view returns (address) {
        return addressStorage[ERC1155_TOKEN_IMAGE_CONTRACT];
    }

    /**
     * @dev Internal function for updating address of the used ERC721 token image.
     * @param _image address of the new token image.
     */
    function _setTokenImageERC721(address _image) internal {
        require(Address.isContract(_image));
        addressStorage[ERC721_TOKEN_IMAGE_CONTRACT] = _image;
    }

    /**
     * @dev Internal function for updating address of the used ERC1155 token image.
     * @param _image address of the new token image.
     */
    function _setTokenImageERC1155(address _image) internal {
        require(Address.isContract(_image));
        addressStorage[ERC1155_TOKEN_IMAGE_CONTRACT] = _image;
    }
}