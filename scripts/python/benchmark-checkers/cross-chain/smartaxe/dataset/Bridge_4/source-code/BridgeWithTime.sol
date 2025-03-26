//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract BridgeWithTime is ReentrancyGuard, AccessControl {
    using ECDSA for bytes32;

    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");

    event SwapInitilaized(
        address indexed receiver,
        address indexed token,
        uint256 amount,
        uint256 nonce,
        uint256 time,
        uint256 chainFrom,
        uint256 indexed chainTo
    );

    event RedeemInitilaized(
        address indexed receiver,
        address indexed token,
        uint256 amount,
        uint256 indexed nonce
    );

    event ChainByldUpdated(uint256 indexed chainId, bool status);
    event TokenIncluded(address indexed tokenAddress, string indexed symbol);
    event TokenExcluded(string indexed symbol);

    mapping(address => mapping(uint256 => bool)) private usersNonces;
    mapping(string => address) private supportedTokens;
    mapping(uint256 => bool) private supportedChains;

    uint256 private thisChainId;

    constructor(address validator, uint256 chainId) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(VALIDATOR_ROLE, validator);
        thisChainId = chainId;
        supportedChains[chainId] = true;
    }

    modifier adminControl() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Bridge: Only admin can use this function"
        );
        _;
    }

    modifier checkNonce(uint256 nonce) {
        require(
            usersNonces[msg.sender][nonce] == false,
            "Bridge: This nonce was already used"
        );
        _;
    }
    modifier TokenSupported(string memory symbol) {
        require(
            supportedTokens[symbol] != address(0),
            "Bridge: This token is not supported"
        );
        _;
    }

    function swap(
        address receiver,
        uint256 amount,
        uint256 chainTo,
        uint256 nonce,
        string memory symbol
    ) external nonReentrant checkNonce(nonce) TokenSupported(symbol) {
        require(
            supportedChains[thisChainId] == true &&
                supportedChains[chainTo] == true,
            "Bridge: One of the blockchains isn't supported"
        );

        IERC20(supportedTokens[symbol]).burnFrom(msg.sender, amount);
        usersNonces[msg.sender][nonce] = true;

        emit SwapInitilaized(
            receiver,
            supportedTokens[symbol],
            amount,
            nonce,
            block.timestamp,
            thisChainId,
            chainTo
        );
    }

    function redeem(
        address receiver,
        string memory symbol,
        uint256 amount,
        uint256 nonce,
        uint256 time,
        uint256 chainTo,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant checkNonce(nonce) TokenSupported(symbol) {
        require(receiver == msg.sender, "Only receiver can call this function");
        require(
            chainTo == thisChainId,
            "This transaction is for another chain"
        );

        bytes32 signedDataHash = keccak256(
            abi.encodePacked(
                receiver,
                supportedTokens[symbol],
                amount,
                nonce,
                time,
                chainTo
            )
        );
        bytes32 message = signedDataHash.toEthSignedMessageHash();
        address signer = message.recover(v, r, s);
        require(hasRole(VALIDATOR_ROLE, signer), "Bridge: invalid sig");

        IERC20(supportedTokens[symbol]).mint(receiver, amount);
        usersNonces[msg.sender][nonce] == true;

        emit RedeemInitilaized(
            receiver,
            supportedTokens[symbol],
            amount,
            nonce
        );
    }

    function updateChainByld(uint256 chainId, bool status)
        external
        adminControl
    {
        supportedChains[chainId] = status;
        emit ChainByldUpdated(chainId, status);
    }

    function includeToken(address token, string memory symbol)
        external
        adminControl
    {
        supportedTokens[symbol] = token;
        emit TokenIncluded(token, symbol);
    }

    function excludeToken(string memory symbol) external adminControl {
        delete supportedTokens[symbol];
        emit TokenExcluded(symbol);
    }

    function isTokenSupported(string memory symbol)
        external
        view
        returns (bool)
    {
        return supportedTokens[symbol] != address(0);
    }

    function isChainSupported(uint256 chainId) external view returns (bool) {
        return supportedChains[chainId];
    }

    function getBridgeChainId() external view returns (uint256) {
        return thisChainId;
    }

    function nonceStatus(address user, uint256 nonce)
        external
        view
        returns (bool)
    {
        return usersNonces[user][nonce];
    }

    function getToken(string memory symbol) external view returns (address) {
        return supportedTokens[symbol];
    }
}