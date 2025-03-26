//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./Bridge.sol";

contract TollBridge is Bridge {
	using ECDSAUpgradeable for bytes32;
	using ECDSAUpgradeable for bytes;
	using AddressUpgradeable for address payable;

	// Errors
	error FeeValidationExpired(uint256 maxBlock, uint256 currentBlock);
	error HashMismatch(bytes32 hash, bytes32 computedHash);
	error UntrustedSigner(address signer);
	error IncorrectFeeAmount(uint256 amountPaid, uint256 amountRequired);

	// Fees that have been paid and can be withdrawn from this contract
	mapping (address => uint256) public pendingFees;

	// Address that can sign fee hashes
	// In the future we will change this to a ERC-20 token contract
	// and anyone who holds a token will be allowed to sign fee hashes
	// Could possibly also have this address be a contract that signs the hashes
	address public feeVerifier;

	function initialize(address _controller, address _verifier, uint256 _chainId) public virtual initializer {
      feeVerifier = _verifier;
		Bridge.__init_bridge(_controller, _chainId);
	}

	function setFeeVerifier(address _newVerifier) external onlyOwner {
		feeVerifier = _newVerifier;
	}

	/** @dev Uses a ECDSA hash to verify that the fee paid is valid
	 * The hash must contain the following data, in the following order, with each element seperated by ''
	 * chainId, Sender addr, destination network, fee token addr, fee token amount, block valid until, abi encoded data (exact data depends on transaction. See whitepaper) 
	 * 
	 * If `block.number` > block valid until, revert
	 * _feeData must be ABI encoded data of the following
	 * feeToken[address], feeAmount[uint256], maxBlock[uint256], hash[bytes32], signature[bytes]
	 */
	function verifyFee(
		uint256 _destination,
      bytes memory _messageWithReceiptRequestAndTo, // This will be abi.encode(message, receipt, recipient) where `message` is the bytes of the message, and `receipt` is a bool that says weather or not a delivery receipt is requested
      bytes calldata _feeData
	) internal view {
		address feeToken;
		uint256 feeAmount;
		uint256 maxBlock;
		bytes32 hash;
		bytes memory signature;

		(feeToken, feeAmount, maxBlock, hash, signature) = abi.decode(_feeData, (address, uint256, uint256, bytes32, bytes));

      // This is done in order from least gas cost to highest to save gas if one of the checks fail

		// Verfiy fee signature is still valid (within correct block range) 
		if(block.number > maxBlock) revert FeeValidationExpired(maxBlock, block.number);

		// Verify hash matches sent data
		bytes32 computedHash = keccak256(abi.encode(
			chainId(),
			_msgSender(),
			_destination,
			feeToken,
			feeAmount,
			maxBlock,
         _messageWithReceiptRequestAndTo
		)).toEthSignedMessageHash();

		if(hash != computedHash) revert HashMismatch(hash, computedHash);

		// Check that hash is signed by a valid address
		{
			address signer = hash.recover(signature);
			if(signer != feeVerifier) revert UntrustedSigner(signer);
		}
	}

	/**
	 * @dev Transfers an ERC20 token to a different chain
	 * This function simply moves the caller's tokens to this contract, and emits a `TokenTransferFungible` event
	 */
	function transferFungible(
		address _token,
	   uint256 _amount,
		uint256 _networkId,
		bytes calldata _feeData
	) external virtual override payable {
      verifyFee(_networkId, abi.encode(_token, _amount), _feeData);
	
		_transferFungible(_token, _amount, _networkId);

      _payToll(_feeData);
   }

	/**
	 * @dev Transfers an ERC721 token to a different chain
	 * This function simply moves the caller's tokens to this contract, and emits a `TokenTransferNonFungible` event
	 */
	function transferNonFungible(
		address _token,
		uint256 _tokenId,
		uint256 _networkId,
		bytes calldata _feeData
	) external virtual override payable {
		// require(networkId != chainId(), "Same chainId");
      verifyFee(_networkId, abi.encode(_token, _tokenId), _feeData);
		
		_transferNonFungible(_token, _tokenId, _networkId);

		_payToll(_feeData);
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
		bytes calldata _feeData
	) external virtual override payable {
		// require(networkId != chainId(), "Same chainId");
      verifyFee(_networkId, abi.encode(_token, _tokenId, _amount), _feeData);
		
		_transferMixedFungible(_token, _tokenId, _amount, _networkId);

		_payToll(_feeData);
	}

	function sendMessage(
		uint256 _messageId,
		uint256 _destination,
		string calldata _recipient,
		bool _receipt,
		bytes calldata _message,
		bytes calldata _feeData
	) external virtual override payable {
		verifyFee(_destination, abi.encode(_message, _receipt, _recipient), _feeData);

		_sendMessage(_messageId, _destination, _recipient, _receipt, _message);

		_payToll(_feeData);
	}

	function sendBroadcast(
		uint256 _messageId,
		bool _receipt,
		bytes calldata _message,
		bytes calldata _feeData
	) external virtual override payable {
		verifyFee(0, abi.encode(_message, _receipt), _feeData);

		_sendBroadcast(_messageId, _receipt, _message);

		_payToll(_feeData);
	}

	function withdrawalFees(address _token, uint256 _amount) external virtual onlyController {
		if(pendingFees[_token] < _amount) revert InsufficientFunds(_amount, pendingFees[_token]);
		pendingFees[_token] -= _amount;

		if(_token == address(0)) {
			payable(_msgSender()).sendValue(_amount);
		} else {
			IERC20Upgradeable(_token).transfer(_msgSender(), _amount);
		}
	}

	/**
	* @dev Pull the amount of `tollToken` equal to `_fee` from the user's account to pay the bridge toll
	*/
	function _payToll(bytes calldata _feeData) internal {
		address token;
		uint256 fee;

		(token, fee,,, ) = abi.decode(_feeData, (address, uint256, uint256, bytes32, bytes));

		// token == address(0) is used to indicate fee will be payed in base network currency (ie. ETH on Ethereum, etc.)
		if(token == address(0) && fee > 0) {
			if(msg.value != fee) revert IncorrectFeeAmount(msg.value, fee);
			pendingFees[token] += fee;
		} else if(fee > 0) {
			// Only make payable if the fee is in base network currency
			if(msg.value != 0) revert FunctionNotPayable();
			pendingFees[token] += fee;
			IERC20Upgradeable(token).transferFrom(_msgSender(), address(this), fee);
		} else /* fee == 0 */ {
			// Only make payable if the fee is in base network currency
			if(msg.value != 0) revert FunctionNotPayable();
		}
	}
}
