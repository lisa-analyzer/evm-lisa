//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./IExampleToken.sol";

contract ChainBridge is AccessControl{
    address public validator;
    uint256 private nonce;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    enum Status{Nonexist, Undone, Done}

    mapping (uint256 => mapping (address => bool)) public isERC20valid;
    mapping (bytes32 => Status) public redeemStatus;

    constructor() {
        validator = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    event SwapInitialized(address from, address recepient, uint256 amount, uint256 chainIdfrom, address erc20from, uint256 chainIdto, address erc20to, uint256 nonce);
    event RedeemInitialized(address recepient, uint256 amount, address erc20to, uint chainId, address erc20from, uint256 nonce);

    modifier isAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "You dont have ADMIN rights");
        _;
    }

    modifier isBridgeValid(address erc20from, uint256 chainIdto, address erc20to) {
        require(isERC20valid[getChainID()][erc20from], "ERC20 address from is not valid");
        require(isERC20valid[chainIdto][erc20to], "Chain id or ERC20 address to is not valid");
        _;
    }

    function giveAdminRights(address account) external isAdmin {
        _grantRole(ADMIN_ROLE, account);
    }

    function revokeAdminRights(address account) external isAdmin {
        _revokeRole(ADMIN_ROLE, account);
    }

    function checkSign(address recepient, uint256 amount, uint256 chainIdfrom, address erc20from, uint256 nonce, uint8 v, bytes32 r, bytes32 s) public view returns (bool) {
        bytes32 message = keccak256(
            abi.encodePacked(recepient, amount, chainIdfrom, erc20from, nonce)
        );

        address addr = ecrecover(hashMessage(message), v, r, s);
        if(addr == validator) {
            return true;
        } else {
            return false;
        }
    }

    function hashMessage(bytes32 message) private pure returns (bytes32) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return keccak256(abi.encodePacked(prefix, message));
    }

    function swap(address recepient, uint256 amount, address erc20from, uint256 chainIdto, address erc20to) external isBridgeValid(erc20from, chainIdto, erc20to) {
        IExampleToken(erc20from).burn(msg.sender, amount);
        nonce += 1;

        emit SwapInitialized(msg.sender, recepient, amount, getChainID(), erc20from, chainIdto, erc20to, nonce);
    }

    function redeem(address recepient, uint256 amount, uint256 chainIdfrom, address erc20from, address erc20to, uint256 nonce, uint8 v, bytes32 r, bytes32 s) external {
        require(isERC20valid[chainIdfrom][erc20from], "Chain id or ERC20 address from is not valid");
        require(isERC20valid[getChainID()][erc20to], "ERC20 on this chain is not valid");
        require(checkSign(recepient, amount, chainIdfrom, erc20from, nonce, v, r, s), "Input is not valid");

        bytes32 redeemHash = keccak256(abi.encodePacked(recepient, amount, chainIdfrom, erc20from, nonce, v, r, s));
        redeemStatus[redeemHash] = Status.Undone;

        require(redeemStatus[redeemHash] == Status.Undone, "Hash is not valid");

        redeemStatus[redeemHash] = Status.Done;
        IExampleToken(erc20to).mint(recepient, amount);

        emit RedeemInitialized(recepient, amount, erc20to, chainIdfrom, erc20from, nonce);
    }

    function updateERC20ById(uint256 chainId, address erc20address, bool valid) external isAdmin {
        isERC20valid[chainId][erc20address] = valid;  
    }

    function setNewValidator(address newValidator) external isAdmin {
        validator = newValidator;
    }

    function getChainID() public view returns (uint256) {
        uint256 id;
            assembly {
                id := chainid()
            }
        return id;
    }
}
