pragma solidity 0.7.5;

import "../../../../upgradeability/EternalStorage.sol";

/**
 * @title NativeTokensRegistry
 * @dev Functionality for keeping track of registered native tokens.
 */
contract NativeTokensRegistry is EternalStorage {
    uint256 internal constant REGISTERED = 1;
    uint256 internal constant REGISTERED_AND_DEPLOYED = 2;

    /**
     * @dev Checks if for a given native token, the deployment of its bridged alternative was already acknowledged.
     * @param _token address of native token contract.
     * @return true, if bridged token was already deployed.
     */
    function isBridgedTokenDeployAcknowledged(address _token) public view returns (bool) {
        return uintStorage[keccak256(abi.encodePacked("tokenRegistered", _token))] == REGISTERED_AND_DEPLOYED;
    }

    /**
     * @dev Checks if a given token is a bridged token that is native to this side of the bridge.
     * @param _token address of token contract.
     * @return message id of the send message.
     */
    function isRegisteredAsNativeToken(address _token) public view returns (bool) {
        return uintStorage[keccak256(abi.encodePacked("tokenRegistered", _token))] > 0;
    }

    /**
     * @dev Internal function for marking native token as registered.
     * @param _token address of the token contract.
     * @param _state registration state.
     */
    function _setNativeTokenIsRegistered(address _token, uint256 _state) internal {
        if (uintStorage[keccak256(abi.encodePacked("tokenRegistered", _token))] != _state) {
            uintStorage[keccak256(abi.encodePacked("tokenRegistered", _token))] = _state;
        }
    }
}