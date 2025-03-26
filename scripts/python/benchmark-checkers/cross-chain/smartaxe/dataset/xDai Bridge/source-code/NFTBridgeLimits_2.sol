pragma solidity 0.7.5;

import "../../../Ownable.sol";

/**
 * @title NFTBridgeLimits
 * @dev Functionality for keeping track of bridging limits for multiple ERC721 tokens.
 */
abstract contract NFTBridgeLimits is Ownable {
    // token == 0x00..00 represents global restriction applied for all tokens
    event TokenBridgingDisabled(address indexed token, bool disabled);
    event TokenExecutionDisabled(address indexed token, bool disabled);

    /**
     * @dev Checks if specified token was already bridged at least once.
     * @param _token address of the token contract.
     * @return true, if token was already bridged.
     */
    function isTokenRegistered(address _token) public view virtual returns (bool);

    /**
     * @dev Disabled bridging operations for the particular token.
     * @param _token address of the token contract, or address(0) for configuring the global restriction.
     * @param _disable true for disabling.
     */
    function disableTokenBridging(address _token, bool _disable) external onlyOwner {
        require(_token == address(0) || isTokenRegistered(_token));
        boolStorage[keccak256(abi.encodePacked("bridgingDisabled", _token))] = _disable;
        emit TokenBridgingDisabled(_token, _disable);
    }

    /**
     * @dev Disabled execution operations for the particular token.
     * @param _token address of the token contract, or address(0) for configuring the global restriction.
     * @param _disable true for disabling.
     */
    function disableTokenExecution(address _token, bool _disable) external onlyOwner {
        require(_token == address(0) || isTokenRegistered(_token));
        boolStorage[keccak256(abi.encodePacked("executionDisabled", _token))] = _disable;
        emit TokenExecutionDisabled(_token, _disable);
    }

    /**
     * @dev Tells if the bridging operations for the particular token are allowed.
     * @param _token address of the token contract.
     * @return true, if bridging operations are allowed.
     */
    function isTokenBridgingAllowed(address _token) public view returns (bool) {
        bool isDisabled = boolStorage[keccak256(abi.encodePacked("bridgingDisabled", _token))];
        if (isDisabled || _token == address(0)) {
            return !isDisabled;
        }
        return isTokenBridgingAllowed(address(0));
    }

    /**
     * @dev Tells if the execution operations for the particular token are allowed.
     * @param _token address of the token contract.
     * @return true, if execution operations are allowed.
     */
    function isTokenExecutionAllowed(address _token) public view returns (bool) {
        bool isDisabled = boolStorage[keccak256(abi.encodePacked("executionDisabled", _token))];
        if (isDisabled || _token == address(0)) {
            return !isDisabled;
        }
        return isTokenExecutionAllowed(address(0));
    }
}