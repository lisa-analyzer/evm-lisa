//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Bridge is ReentrancyGuard, AccessControl {
    using ECDSA for bytes32;

    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");

    event SwapInitilaized(
        address indexed receiver,
        address indexed token,
        uint256 indexed chainTo,
        uint256 amount,
        uint256 nonce,
        uint256 chainFrom
    );

    event RedeemInitilaized(
        address indexed receiver,
        address indexed token,
        uint256 amount,
        uint256 indexed nonce
    );

    event ChainByIdUpdated(uint256 indexed chainId, bool status);
    event TokenIncluded(
        address indexed thisChainToken,
        address indexed token,
        uint256 indexed chainId
    );
    event TokenExcluded(
        address indexed thisChainToken,
        uint256 indexed chainId
    );

    mapping(address => mapping(uint256 => bool)) private usersNonces;
    mapping(address => mapping(uint256 => address)) private supportedTokens;
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

    function swap(
        address receiver,
        address thisChainToken,
        uint256 amount,
        uint256 chainTo,
        uint256 nonce
    ) external nonReentrant checkNonce(nonce) {
        require(
            supportedChains[thisChainId] == true &&
                supportedChains[chainTo] == true,
            "Bridge: One of the blockchains isn't supported"
        );
        require(
            supportedTokens[thisChainToken][chainTo] != address(0),
            "Bridge: This token is not supported"
        );

        IERC20(thisChainToken).burnFrom(msg.sender, amount);
        usersNonces[msg.sender][nonce] = true;

        emit SwapInitilaized(
            receiver,
            supportedTokens[thisChainToken][chainTo],
            chainTo,
            amount,
            nonce,
            thisChainId
        );
    }

    function redeem(
        address receiver,
        address token,
        uint256 amount,
        uint256 nonce,
        uint256 chainTo,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant checkNonce(nonce) {
        require(
            receiver == msg.sender,
            "Only the receiver can collect the tokens"
        );
        require(
            chainTo == thisChainId,
            "This transaction is for another chain"
        );

        bytes32 signedDataHash = keccak256(
            abi.encode(receiver, token, chainTo, amount, nonce)
        );

        address signer = signedDataHash.toEthSignedMessageHash().recover(
            v,
            r,
            s
        );
        require(hasRole(VALIDATOR_ROLE, signer), "Bridge: invalid sig");

        IERC20(token).mint(receiver, amount);
        usersNonces[receiver][nonce] = true;

        emit RedeemInitilaized(receiver, token, amount, nonce);
    }

    function updateChainById(uint256 chainId, bool status)
        external
        adminControl
    {
        supportedChains[chainId] = status;
        emit ChainByIdUpdated(chainId, status);
    }

    function includeToken(
        address thisChainToken,
        address token,
        uint256 chainId
    ) external adminControl {
        supportedTokens[thisChainToken][chainId] = token;
        emit TokenIncluded(thisChainToken, token, chainId);
    }

    function excludeToken(address thisChainToken, uint256 chainId)
        external
        adminControl
    {
        delete supportedTokens[thisChainToken][chainId];
        emit TokenExcluded(thisChainToken, chainId);
    }

    function isTokenSupported(address thisChainToken, uint256 chainId)
        external
        view
        returns (bool)
    {
        return supportedTokens[thisChainToken][chainId] != address(0);
    }

    function isChainSupported(uint256 chainId) external view returns (bool) {
        return supportedChains[chainId];
    }

    function nonceStatus(address user, uint256 nonce)
        external
        view
        returns (bool)
    {
        return usersNonces[user][nonce];
    }
}
