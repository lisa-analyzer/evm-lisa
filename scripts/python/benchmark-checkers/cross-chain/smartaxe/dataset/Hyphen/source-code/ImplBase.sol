// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./errors.sol";

/**
@title Abstract Implementation Contract.
@notice All Bridge Implementation will follow this interface. 
*/
abstract contract ImplBase is Ownable {
    using SafeERC20 for IERC20;
    address public registry;
    address public constant NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    event UpdateRegistryAddress(address indexed registryAddress);

    constructor(address _registry) Ownable() {
        registry = _registry;
    }

    modifier onlyRegistry() {
        require(msg.sender == registry, MovrErrors.INVALID_SENDER);
        _;
    }

    function updateRegistryAddress(address newRegistry) external onlyOwner {
        registry = newRegistry;
        emit UpdateRegistryAddress(newRegistry);
    }

    function rescueFunds(
        address token,
        address userAddress,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).safeTransfer(userAddress, amount);
    }

    function outboundTransferTo(
        uint256 _amount,
        address _from,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        bytes memory _extraData
    ) external payable virtual;
}