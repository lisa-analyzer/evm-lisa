// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IQBridgeHandler.sol";
import "../interfaces/IQBridgeDelegator.sol";
import "../library/SafeToken.sol";
import "./QBridgeToken.sol";


contract QBridgeHandler is IQBridgeHandler, OwnableUpgradeable {
    using SafeMath for uint;
    using SafeToken for address;

    /* ========== CONSTANT VARIABLES ========== */

    uint public constant OPTION_QUBIT_BNB_NONE = 100;
    uint public constant OPTION_QUBIT_BNB_0100 = 110;
    uint public constant OPTION_QUBIT_BNB_0050 = 105;
    uint public constant OPTION_BUNNY_XLP_0150 = 215;

    address public constant ETH = 0x0000000000000000000000000000000000000000;

    /* ========== STATE VARIABLES ========== */

    address public _bridgeAddress;

    mapping(bytes32 => address) public resourceIDToTokenContractAddress; // resourceID => token contract address
    mapping(address => bytes32) public tokenContractAddressToResourceID; // token contract address => resourceID

    mapping(address => bool) public burnList; // token contract address => is burnable
    mapping(address => bool) public contractWhitelist; // token contract address => is whitelisted
    mapping(uint => address) public delegators; // option => delegator contract address
    mapping(bytes32 => uint) public withdrawalFees; // resourceID => withdraw fee
    mapping(bytes32 => mapping(uint => uint)) public minAmounts; // [resourceID][option] => minDepositAmount

    /* ========== INITIALIZER ========== */

    receive() external payable {}

    function initialize(address bridgeAddress) external initializer {
        __Ownable_init();
        _bridgeAddress = bridgeAddress;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyBridge() {
        require(msg.sender == _bridgeAddress, "QBridgeHandler: caller is not the bridge contract");
        _;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setResource(bytes32 resourceID, address contractAddress) external override onlyBridge {
        resourceIDToTokenContractAddress[resourceID] = contractAddress;
        tokenContractAddressToResourceID[contractAddress] = resourceID;
        contractWhitelist[contractAddress] = true;
    }

    function setBurnable(address contractAddress) external override onlyBridge {
        require(contractWhitelist[contractAddress], "QBridgeHandler: contract address is not whitelisted");
        burnList[contractAddress] = true;
    }

    function setDelegator(uint option, address newDelegator) external onlyOwner {
        delegators[option] = newDelegator;
    }

    function setWithdrawalFee(bytes32 resourceID, uint withdrawalFee) external onlyOwner {
        withdrawalFees[resourceID] = withdrawalFee;
    }

    function setMinDepositAmount(bytes32 resourceID, uint option, uint minAmount) external onlyOwner {
        minAmounts[resourceID][option] = minAmount;
    }

    /**
        @notice A deposit is initiated by making a deposit in the Bridge contract.
        @param resourceID ResourceID used to find address of token to be used for deposit.
        @param depositer Address of account making the deposit in the Bridge contract.
        @param data passed into the function should be constructed as follows:
        option                                 uint256     bytes  0 - 32
        amount                                 uint256     bytes  32 - 64
     */
    function deposit(bytes32 resourceID, address depositer, bytes calldata data) external override onlyBridge {
        uint option;
        uint amount;
        (option, amount) = abi.decode(data, (uint, uint));

        address tokenAddress = resourceIDToTokenContractAddress[resourceID];
        require(contractWhitelist[tokenAddress], "provided tokenAddress is not whitelisted");

        if (burnList[tokenAddress]) {
            require(amount >= withdrawalFees[resourceID], "less than withdrawal fee");
            QBridgeToken(tokenAddress).burnFrom(depositer, amount);
        } else {
            require(amount >= minAmounts[resourceID][option], "less than minimum amount");
            tokenAddress.safeTransferFrom(depositer, address(this), amount);
        }
    }

    function depositETH(bytes32 resourceID, address depositer, bytes calldata data) external payable override onlyBridge {
        uint option;
        uint amount;
        (option, amount) = abi.decode(data, (uint, uint));
        require(amount == msg.value);

        address tokenAddress = resourceIDToTokenContractAddress[resourceID];
        require(contractWhitelist[tokenAddress], "provided tokenAddress is not whitelisted");

        require(amount >= minAmounts[resourceID][option], "less than minimum amount");
    }

    /**
        @notice Proposal execution should be initiated by a relayer on the deposit's destination chain.
        @param data passed into the function should be constructed as follows:
        option                                 uint256
        amount                                 uint256
        destinationRecipientAddress            address
     */
    function executeProposal(bytes32 resourceID, bytes calldata data) external override onlyBridge {
        uint option;
        uint amount;
        address recipientAddress;
        (option, amount, recipientAddress) = abi.decode(data, (uint, uint, address));

        address tokenAddress = resourceIDToTokenContractAddress[resourceID];

        require(contractWhitelist[tokenAddress], "provided tokenAddress is not whitelisted");

        if (burnList[tokenAddress]) {
            address delegatorAddress = delegators[option];
            if (delegatorAddress == address(0)) {
                QBridgeToken(tokenAddress).mint(recipientAddress, amount);
            } else {
                QBridgeToken(tokenAddress).mint(delegatorAddress, amount);
                IQBridgeDelegator(delegatorAddress).delegate(tokenAddress, recipientAddress, option, amount);
            }
        } else if (tokenAddress == ETH) {
            SafeToken.safeTransferETH(recipientAddress, amount.sub(withdrawalFees[resourceID]));
        } else {
            tokenAddress.safeTransfer(recipientAddress, amount.sub(withdrawalFees[resourceID]));
        }
    }

    function withdraw(address tokenAddress, address recipient, uint amount) external override onlyBridge {
        if (tokenAddress == ETH)
            SafeToken.safeTransferETH(recipient, amount);
        else
            tokenAddress.safeTransfer(recipient, amount);
    }

}