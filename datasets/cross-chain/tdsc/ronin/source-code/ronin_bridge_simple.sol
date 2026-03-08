// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bridge {
    uint public constant THRESHOLD = 5;
    mapping(address => bool) public validators;

    constructor(address[] memory _validators) {
        for (uint i = 0; i < _validators.length; i++) {
            validators[_validators[i]] = true;
        }
    }

    function withdraw(bytes calldata payload, bytes[] calldata sigs) external {
        bytes32 h = keccak256(payload);
        require(verifySignatures(h, sigs) >= THRESHOLD, "Insufficient signatures");
        executeWithdrawal(payload);
    }

    function verifySignatures(bytes32 hash, bytes[] calldata sigs) internal view returns (uint) {
        address signer;
        uint valid = 0;
        for (uint i = 0; i < sigs.length; i++) {
            signer = recoverSigner(hash, sigs[i]);
            if (validators[signer]) valid++;
        }
        return valid;
    }

    function recoverSigner(bytes32 hash, bytes calldata sig) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(sig);
        return ecrecover(hash, v, r, s);
    }

    function splitSignature(bytes calldata sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "Invalid signature length");
        assembly {
            r := calldataload(sig.offset)
            s := calldataload(add(sig.offset, 32))
            v := byte(0, calldataload(add(sig.offset, 64)))
        }
    }

    function executeWithdrawal(bytes calldata payload) internal {
        // Simplified: decode and transfer payload
        (address to, uint amount) = abi.decode(payload, (address, uint));
        payable(to).transfer(amount);
    }
}
