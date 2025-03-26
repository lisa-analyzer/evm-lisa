//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IBridgeComplete.sol";
import "./Controllable.sol";
import "./IERC721Bridgable.sol";
import "./IERC1155Bridgable.sol";
import "./IMessageReceiver.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";

contract Bridge is IBridgeComplete, Controllable, ERC1155HolderUpgradeable, ERC721HolderUpgradeable {
	// Errors
	error FunctionNotPayable();
	error InsufficientFunds(uint256 amountRequested, uint256 amountRemaining);

	// Replaces function that gets it to save gas
	// Is private so it can't be changed when this contract is extended
	uint256 private setChainId;

	function __init_bridge(address _controller, uint256 _chainId) internal virtual onlyInitializing {
		setChainId = _chainId;
		Controllable.__init_controller(_controller);
		ERC1155HolderUpgradeable.__ERC1155Holder_init();
	}

	/**
	 * @dev Returns the chainId of the network this contract is deployed on
	 */
	function chainId() public view returns (uint256) {
		/*
		uint256 id;
		assembly {
			id := chainid()
		}
		return id;
		*/
	  return setChainId;
	}

	/**
	 * @dev Transfers an ERC20 token to a different chain
	 * This function simply moves the caller's tokens to this contract, and emits a `TokenTransferFungible` event
	 */
	function transferFungible(
		address token,
		uint256 amount,
		uint256 networkId,
		bytes calldata
	) external virtual override payable {
		// This function is only payable so it can be overriden by TollBridge. We don't want to actually accept any ETH 
		if(msg.value != 0) revert FunctionNotPayable();

		_transferFungible(token, amount, networkId);
	}

	/**
	 * @dev Used by bridge network to transfer the item directly to user without need for manual claiming
	 */
	function bridgeClaimFungible(
		address _token,
		address _to,
		uint256 _amount
	) external virtual override onlyController {
		if(IERC20Upgradeable(_token).balanceOf(address(this)) < _amount) revert InsufficientFunds(_amount, IERC20Upgradeable(_token).balanceOf(address(this)));

		IERC20Upgradeable(_token).transfer(_to, _amount);

		emit TokenClaimedFungible(_to, _token, _amount);
	}

	/**
	 * @dev Transfers an ERC721 token to a different chain
	 * This function simply moves the caller's tokens to this contract, and emits a `TokenTransferNonFungible` event
	 */
	function transferNonFungible(
		address _token,
		uint256 _tokenId,
		uint256 _networkId,
		bytes calldata
	) external virtual override payable {
		// This function is only payable so it can be overriden by TollBridge. We don't want to actually accept any ETH 
		if(msg.value != 0) revert FunctionNotPayable();

		_transferNonFungible(_token, _tokenId, _networkId);
	}

	/**
	* @dev Used by bridge network to transfer the item directly to user without need for manual claiming
	*/
	function bridgeClaimNonFungible(
		address _token,
		address _to,
		uint256 _tokenId
	) external virtual override onlyController {
		address tokenOwner;
		// The try-catch block is because `ownerOf` can (and I think is supposed to) revert if the item doesn't yet exist on this chain
		try IERC721Bridgable(_token).ownerOf(_tokenId) returns (address owner) {
			tokenOwner = owner;
		} catch {
			tokenOwner = address(0);
		}

		// Check if the token needs to be minted
		// If it does, attempt to mint it (will fail if this contract has no such permission, or the ERC721 contract doesn't support bridgeMint)
		// If the token exists, and the owner is this contract, it will be sent like normal
		// Otherwise this contract will revert
		if(tokenOwner == address(0)) {
			IERC721Bridgable(_token).bridgeMint(_to, _tokenId);
		} else {
			// This will revert if the bridge does not own the token; this is intended
			IERC721Bridgable(_token).transferFrom(address(this), _to, _tokenId);
		}

		emit TokenClaimedNonFungible(_to, _token, _tokenId);
	}

	/**
	* @dev Transfers an ERC1155 token to a different chain
	* This function simply moves the caller's tokens to this contract, and emits a `TokenTransferMixedFungible` event
	*/
	function transferMixedFungible(
		address _token,
		uint256 _tokenId,
		uint256 _amount,
		uint256 _networkId,
		bytes calldata
	) external virtual override payable {
		// This function is only payable so it can be overriden by TollBridge. We don't want to actually accept any ETH 
		if(msg.value != 0) revert FunctionNotPayable();

		_transferMixedFungible(_token, _tokenId, _amount, _networkId);
	}

	/**
	* @dev Used by bridge network to transfer the item directly to user without need for manual claiming
	*/
	function bridgeClaimMixedFungible(
		address token,
		address to,
		uint256 tokenId,
		uint256 amount
	) external virtual override onlyController {
		// Get balance of tokens that this contract owns, mint the rest
		uint256 balance = IERC1155Bridgable(token).balanceOf(address(this), tokenId);
		uint256 balanceToMint = 0;
		uint256 balanceToTransfer = amount;

		if(balance < amount) {
			balanceToMint = amount - balance;
			balanceToTransfer = balance;
		}

		IERC1155Bridgable(token).safeTransferFrom(address(this), to, tokenId, balanceToTransfer, "");

		if(balanceToMint > 0) {
			IERC1155Bridgable(token).bridgeMint(to, tokenId, balanceToMint);
		}

		emit TokenClaimedMixedFungible(to, token, tokenId, amount);
	}

	function sendMessage(
		uint256 _messageId,
		uint256 _destination,
		string calldata _recipient,
		bool _receipt,
		bytes calldata _message,
		bytes calldata
	) external virtual override payable {
		// This function is only payable so it can be overriden by TollBridge. We don't want to actually accept any ETH 
		if(msg.value != 0) revert FunctionNotPayable();

		_sendMessage(_messageId, _destination, _recipient, _receipt, _message);
	}

	function sendBroadcast(
		uint256 _messageId,
		bool _receipt,
		bytes calldata _message,
		bytes calldata
	) external virtual override payable {
		// This function is only payable so it can be overriden by TollBridge. We don't want to actually accept any ETH 
		if(msg.value != 0) revert FunctionNotPayable();

		_sendBroadcast(_messageId, _receipt, _message);
	}

	function relayMessage(
		IMessageReceiver _recipient,
		uint256 _messageId,
		string calldata _sender,
		uint256 _fromNetworkId,
		bool _receipt,
		bytes calldata _message
	) external virtual override onlyController returns (bool success) {
		try _recipient.receiveBridgeMessage(_sender, _fromNetworkId, _message) returns (bool result) {
			success = result;
		} catch {
			success = false;
		}

		emit MessageReceived(_recipient, _sender, _fromNetworkId, success, _messageId, _receipt);
	}

	function _transferFungible(address token, uint256 amount, uint256 networkId) internal {
		// require(networkId != chainId(), "Same chainId");

		IERC20Upgradeable(token).transferFrom(_msgSender(), address(this), amount);

		emit TokenTransferFungible(_msgSender(), token, amount, networkId);
	}

	function _transferNonFungible(address _token, uint256 _tokenId, uint256 _networkId) internal {
		// require(networkId != chainId(), "Same chainId");

		IERC721Upgradeable(_token).transferFrom(_msgSender(), address(this), _tokenId);

		emit TokenTransferNonFungible(_msgSender(), _token, _tokenId, _networkId);
	}

	function _transferMixedFungible(
		address _token,
		uint256 _tokenId,
		uint256 _amount,
		uint256 _networkId
	) internal {
		// require(networkId != chainId(), "Same chainId");

		IERC1155Upgradeable(_token).safeTransferFrom(_msgSender(), address(this), _tokenId, _amount, "");

		emit TokenTransferMixedFungible(_msgSender(), _token, _tokenId, _amount, _networkId);
	}

	function _sendMessage(
		uint256 _messageId,
		uint256 _destination,
		string calldata _recipient,
		bool _receipt,
		bytes calldata _message
	) internal {
		emit MessageSent(_msgSender(), _messageId, _destination, _recipient, _receipt, _message);
	}

	function _sendBroadcast(
		uint256 _messageId,
		bool _receipt,
		bytes calldata _message
	) internal {
		emit BroadcastSent(_msgSender(), _messageId, _receipt, _message);
	}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
