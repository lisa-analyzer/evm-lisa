//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./TollBridge.sol";
import "hardhat/console.sol";

contract FeeVerifyTester is TollBridge {
	using ECDSAUpgradeable for bytes32;
	using ECDSAUpgradeable for bytes;

	function toString(address account) private pure returns(string memory) {
		return toString(abi.encodePacked(account));
	}

	function toString(uint256 value) private pure returns(string memory) {
		return toString(abi.encodePacked(value));
	}

	function toString(bytes32 value) private pure returns(string memory) {
		return toString(abi.encodePacked(value));
	}

	function toString(bytes memory data) private pure returns(string memory) {
		bytes memory alphabet = "0123456789abcdef";

		bytes memory str = new bytes(2 + data.length * 2);
		str[0] = "0";
		str[1] = "x";
		for (uint i = 0; i < data.length; i++) {
			str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
			str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
		}
		return string(str);
	}

	function testVerifyFee(
      uint256 _destination,
		bytes calldata _encodedMessage,
		bytes calldata _feeData
	) external view returns (address) {
		address feeToken;
		uint256 feeAmount;
		uint256 maxBlock;
		bytes32 hash;
		bytes memory signature;

		(feeToken, feeAmount, maxBlock, hash, signature) = abi.decode(_feeData, (address, uint256, uint256, bytes32, bytes));

		bytes memory messageWithReceipt = _encodedMessage;

		console.log(toString(keccak256(abi.encode(
			chainId(),
			_msgSender(),
			_destination,
			feeToken,
			feeAmount,
			maxBlock,
			messageWithReceipt
		))));

		bytes32 computedHash = keccak256(abi.encode(
			chainId(),
			_msgSender(),
			_destination,
			feeToken,
			feeAmount,
			maxBlock,
			messageWithReceipt
		)).toEthSignedMessageHash();

		console.log(toString(computedHash));

		verifyFee(_destination, messageWithReceipt, _feeData);

		console.log(hash.recover(signature));

		return hash.recover(signature);
	}

	function gasTester(
		bytes calldata _message,
		bytes calldata _feeData
	) external { // This could be view, but we want it to burn gas
		address feeToken;
		uint256 feeAmount;
		uint256 maxBlock;
		bytes32 hash;
		bytes memory signature;

		(feeToken, feeAmount, maxBlock, hash, signature) = abi.decode(_feeData, (address, uint256, uint256, bytes32, bytes));

		// address testAddress = address(0);
		// bool testBool = true;
		// uint256 destination = 100;

		bytes memory messageWithBool = abi.encode(_message, true);

		uint256 remainingGas = gasleft();

		block.number <= maxBlock;

		uint256 blockCheckGasUsed = remainingGas - gasleft();

		remainingGas = gasleft();

		hash.recover(signature) == feeVerifier;

		uint256 sigCheckGasUsed = remainingGas - gasleft();

		remainingGas = gasleft();

		// Verify hash matches sent data
		bytes32 computedHash = keccak256(abi.encode(
			chainId(),
			_msgSender(),
			100,
			feeToken,
			feeAmount,
			maxBlock,
			messageWithBool
		)).toEthSignedMessageHash();

		hash == computedHash;

		uint256 hashCheckGasUsed = remainingGas - gasleft();

		remainingGas = gasleft();

		verifyFee(100, messageWithBool, _feeData);

		uint256 verifyFeeGasUsed = remainingGas - gasleft();

		console.log("blockCheckGasUsed: ", blockCheckGasUsed);
		console.log("sigCheckGasUsed: ", sigCheckGasUsed);
		console.log("hashCheckGasUsed: ", hashCheckGasUsed);
		console.log("verifyFeeGasUsed: ", verifyFeeGasUsed);
	}
}
