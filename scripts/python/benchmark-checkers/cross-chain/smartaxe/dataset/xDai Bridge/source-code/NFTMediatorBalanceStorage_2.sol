pragma solidity 0.7.5;

import "../../../../upgradeability/EternalStorage.sol";

/**
 * @title NFTMediatorBalanceStorage
 * @dev Functionality for storing expected mediator balance for native tokens.
 */
contract NFTMediatorBalanceStorage is EternalStorage {
    /**
     * @dev Tells amount of owned tokens recorded at this mediator. More strict than regular token.ownerOf()/token.balanceOf() checks,
     * since does not take into account forced tokens.
     * @param _token address of token contract.
     * @param _tokenId id of the new owned token.
     * @return amount of owned tokens, 0 or 1 for ERC721 NFTs.
     */
    function mediatorOwns(address _token, uint256 _tokenId) public view returns (uint256 amount) {
        bytes32 key = _getStorageKey(_token, _tokenId);
        assembly {
            amount := sload(key)
        }
    }

    /**
     * @dev Updates ownership information for the particular token.
     * @param _token address of token contract.
     * @param _tokenId id of the new owned token.
     * @param _value amount of owned tokens, 0 or 1 for ERC721 NFTs.
     */
    function _setMediatorOwns(
        address _token,
        uint256 _tokenId,
        uint256 _value
    ) internal {
        bytes32 key = _getStorageKey(_token, _tokenId);
        assembly {
            sstore(key, _value)
        }
    }

    function _getStorageKey(address _token, uint256 _tokenId) private pure returns (bytes32) {
        // same as boolStorage[keccak256(abi.encodePacked("mediatorOwns", _token, _tokenId))]
        return keccak256(abi.encodePacked(keccak256(abi.encodePacked("mediatorOwns", _token, _tokenId)), uint256(4)));
    }
}