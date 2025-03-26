// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./interfaces/IMessageTransmitter.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract UsdcMinter is UUPSUpgradeable, AccessControlUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");

    IMessageTransmitter public messageTransmitter;
    address public reserveHandler;
    address public usdc;
    bytes32 public constant RESOURCE_SETTER = keccak256("RESOURCE_SETTER");
    mapping(uint8 => mapping(uint64 => bool)) public mintCompleted;

    event UsdcMinted(bool success, uint256 mintAmount);

    function initialize(
        address _usdc,
        address _messageTransmitter,
        address _reserveHandler
    ) external initializer {
        messageTransmitter = IMessageTransmitter(_messageTransmitter);
        reserveHandler = _reserveHandler;
        usdc = _usdc;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(RESOURCE_SETTER, msg.sender);
    }

    function setUsdcMessageTransmitter(address _messageTransmitter) external onlyRole(RESOURCE_SETTER) {
        messageTransmitter = IMessageTransmitter(_messageTransmitter);
    }

    function setUsdcAddress(address _usdc) external onlyRole(RESOURCE_SETTER) {
        usdc = _usdc;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function mintUsdcToReserveHandler(
        bytes calldata message,
        bytes calldata attestation,
        uint8 srcChainId,
        uint64 depositNonce
    ) external onlyRole(RELAYER_ROLE) {
        require(address(messageTransmitter) != address(0) && usdc != address(0), "usdc or message transmitter not set");
        address _usdc = usdc;
        address _reserveHandler = reserveHandler;
        uint256 balBefore = IERC20Upgradeable(_usdc).balanceOf(_reserveHandler);
        bool success = messageTransmitter.receiveMessage(message, attestation);
        uint256 balAfter = IERC20Upgradeable(_usdc).balanceOf(_reserveHandler);

        require(success, "USDC Minter: Failed transaction");
        require(balAfter > balBefore, "USDC Minter: Balance after minting not greater than before it");

        mintCompleted[srcChainId][depositNonce] = true;

        emit UsdcMinted(success, balAfter - balBefore);
    }
}