pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IBurnableMintableERC1155Token is IERC1155 {
    function mint(
        address _to,
        uint256[] calldata _tokenIds,
        uint256[] calldata _values
    ) external;

    function burn(uint256[] calldata _tokenId, uint256[] calldata _values) external;
}