pragma solidity 0.7.5;

import "../../../../upgradeability/EternalStorage.sol";

/**
 * @title BridgeOperationsStorage
 * @dev Functionality for storing processed bridged operations.
 */
abstract contract BridgeOperationsStorage is EternalStorage {
    /**
     * @dev Set bridged message checksum.
     * @param _messageId id of the sent AMB message.
     * @param _checksum checksum of the bridge operation.
     */
    function setMessageChecksum(bytes32 _messageId, bytes32 _checksum) internal {
        uintStorage[keccak256(abi.encodePacked("messageChecksum", _messageId))] = uint256(_checksum);
    }

    /**
     * @dev Tells the bridged message checksum.
     * @param _messageId id of the sent AMB message.
     * @return saved message checksum associated with the given message id.
     */
    function getMessageChecksum(bytes32 _messageId) internal view returns (bytes32) {
        return bytes32(uintStorage[keccak256(abi.encodePacked("messageChecksum", _messageId))]);
    }

    /**
     * @dev Calculates message checksum, used for verifying correctness of the given parameters when fixing message.
     * @param _token address of the bridged token contract on this side current side of the bridge.
     * @param _sender address of the tokens sender.
     * @param _tokenIds list of ids of sent tokens.
     * @param _values list of sent token amounts. Should be an empty array for ERC721 tokens.
     * @return message checksum.
     */
    function _messageChecksum(
        address _token,
        address _sender,
        uint256[] memory _tokenIds,
        uint256[] memory _values
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(_token, _sender, _tokenIds, _values));
    }
}