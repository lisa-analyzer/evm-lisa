pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IBurnableMintableERC721Token is IERC721 {
    function mint(address _to, uint256 _tokeId) external;

    function burn(uint256 _tokenId) external;

    function setTokenURI(uint256 _tokenId, string calldata _tokenURI) external;
}