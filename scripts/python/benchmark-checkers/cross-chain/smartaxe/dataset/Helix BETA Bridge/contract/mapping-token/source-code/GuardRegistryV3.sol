// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.10;
pragma experimental ABIEncoderV2;

import "@zeppelin-solidity/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title Manages a set of guards and a threshold to double-check BEEFY commitment
 * @dev Stores the guards and a threshold
 * @author echo
 */
contract GuardRegistryV3 {
    event AddedGuard(address guard);
    event RemovedGuard(address guard);
    event ChangedThreshold(uint256 threshold);

    // keccak256(
    //     "EIP712Domain(uint256 chainId,address verifyingContract)"
    // );
    bytes32 internal constant DOMAIN_SEPARATOR_TYPEHASH = 0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218;

    address internal constant SENTINEL_GUARDS = address(0x1);

    /**
     * @dev Nonce to prevent replay of update operations
     */
    uint256 public nonce;
    /**
     * @dev Store all guards in the linked list
     */
    mapping(address => address) internal guards;
    /**
     * @dev Count of all guards
     */
    uint256 internal guardCount;
    /**
     * @dev Number of required confirmations for update operations
     */
    uint256 internal threshold;

    /**
     * @dev Sets initial storage of contract.
     * @param _guards List of Safe guards.
     * @param _threshold Number of required confirmations for check commitment or change guards.
     */
    function initialize(address[] memory _guards, uint256 _threshold) internal {
        // Threshold can only be 0 at initialization.
        // Check ensures that setup function can only be called once.
        require(threshold == 0, "Guard: Guards have already been setup");
        // Validate that threshold is smaller than number of added guards.
        require(_threshold <= _guards.length, "Guard: Threshold cannot exceed guard count");
        // There has to be at least one Safe guard.
        require(_threshold >= 1, "Guard: Threshold needs to be greater than 0");
        // Initializing Safe guards.
        address currentGuard = SENTINEL_GUARDS;
        for (uint256 i = 0; i < _guards.length; i++) {
            // Guard address cannot be null.
            address guard = _guards[i];
            require(guard != address(0) && guard != SENTINEL_GUARDS && guard != address(this) && currentGuard != guard, "Guard: Invalid guard address provided");
            // No duplicate guards allowed.
            require(guards[guard] == address(0), "Guard: Address is already an guard");
            guards[currentGuard] = guard;
            currentGuard = guard;
            emit AddedGuard(guard);
        }
        guards[currentGuard] = SENTINEL_GUARDS;
        guardCount = _guards.length;
        threshold = _threshold;
    }

    /**
     * @dev Allows to add a new guard to the registry and update the threshold at the same time.
     *      This can only be done via multi-sig.
     * @notice Adds the guard `guard` to the registry and updates the threshold to `_threshold`.
     * @param guard New guard address.
     * @param _threshold New threshold.
     * @param signatures The signatures of the guards which to add new guard and update the `threshold` .
     */
    function addGuardWithThreshold(
        address guard,
        uint256 _threshold,
        bytes[] memory signatures
    ) public {
        // Guard address cannot be null, the sentinel or the registry itself.
        require(guard != address(0) && guard != SENTINEL_GUARDS && guard != address(this), "Guard: Invalid guard address provided");
        // No duplicate guards allowed.
        require(guards[guard] == address(0), "Guard: Address is already an guard");
        verifyGuardSignatures(msg.sig, abi.encode(guard, _threshold), signatures);
        guards[guard] = guards[SENTINEL_GUARDS];
        guards[SENTINEL_GUARDS] = guard;
        guardCount++;
        emit AddedGuard(guard);
        // Change threshold if threshold was changed.
        if (threshold != _threshold) _changeThreshold(_threshold);
    }

    /**
     * @dev Allows to remove an guard from the registry and update the threshold at the same time.
     *      This can only be done via multi-sig.
     * @notice Removes the guard `guard` from the registry and updates the threshold to `_threshold`.
     * @param prevGuard Guard that pointed to the guard to be removed in the linked list
     * @param guard Guard address to be removed.
     * @param _threshold New threshold.
     * @param signatures The signatures of the guards which to remove a guard and update the `threshold` .
     */
    function removeGuard(
        address prevGuard,
        address guard,
        uint256 _threshold,
        bytes[] memory signatures
    ) public {
        // Only allow to remove an guard, if threshold can still be reached.
        require(guardCount - 1 >= _threshold, "Guard: Threshold cannot exceed guard count");
        // Validate guard address and check that it corresponds to guard index.
        require(guard != address(0) && guard != SENTINEL_GUARDS, "Guard: Invalid guard address provided");
        require(guards[prevGuard] == guard, "Guard: Invalid prevGuard, guard pair provided");
        verifyGuardSignatures(msg.sig, abi.encode(prevGuard, guard, _threshold), signatures);
        guards[prevGuard] = guards[guard];
        guards[guard] = address(0);
        guardCount--;
        emit RemovedGuard(guard);
        // Change threshold if threshold was changed.
        if (threshold != _threshold) _changeThreshold(_threshold);
    }

    /**
     * @dev Allows to swap/replace a guard from the registry with another address.
     *      This can only be done via multi-sig.
     * @notice Replaces the guard `oldGuard` in the registry with `newGuard`.
     * @param prevGuard guard that pointed to the guard to be replaced in the linked list
     * @param oldGuard guard address to be replaced.
     * @param newGuard New guard address.
     * @param signatures The signatures of the guards which to swap/replace a guard and update the `threshold` .
     */
    function swapGuard(
        address prevGuard,
        address oldGuard,
        address newGuard,
        bytes[] memory signatures
    ) public {
        // Guard address cannot be null, the sentinel or the registry itself.
        require(newGuard != address(0) && newGuard != SENTINEL_GUARDS && newGuard != address(this), "Guard: Invalid guard address provided");
        // No duplicate guards allowed.
        require(guards[newGuard] == address(0), "Guard: Address is already an guard");
        // Validate oldGuard address and check that it corresponds to guard index.
        require(oldGuard != address(0) && oldGuard != SENTINEL_GUARDS, "Guard: Invalid guard address provided");
        require(guards[prevGuard] == oldGuard, "Guard: Invalid prevGuard, guard pair provided");
        verifyGuardSignatures(msg.sig, abi.encode(prevGuard, oldGuard, newGuard), signatures);
        guards[newGuard] = guards[oldGuard];
        guards[prevGuard] = newGuard;
        guards[oldGuard] = address(0);
        emit RemovedGuard(oldGuard);
        emit AddedGuard(newGuard);
    }

    /**
     * @dev Allows to update the number of required confirmations by guards.
     *      This can only be done via multi-sig.
     * @notice Changes the threshold of the registry to `_threshold`.
     * @param _threshold New threshold.
     * @param signatures The signatures of the guards which to update the `threshold` .
     */
    function changeThreshold(uint256 _threshold, bytes[] memory signatures) public {
        verifyGuardSignatures(msg.sig, abi.encode(_threshold), signatures);
        _changeThreshold(_threshold);
    }

    function _changeThreshold(uint256 _threshold) internal {
        // Validate that threshold is smaller than number of owners.
        require(_threshold <= guardCount, "Guard: Threshold cannot exceed guard count");
        // There has to be at least one guard.
        require(_threshold >= 1, "Guard: Threshold needs to be greater than 0");
        threshold = _threshold;
        emit ChangedThreshold(threshold);
    }

    function getThreshold() public view returns (uint256) {
        return threshold;
    }

    function isGuard(address guard) public view returns (bool) {
        return guard != SENTINEL_GUARDS && guards[guard] != address(0);
    }

    /**
     * @dev Returns array of guards.
     * @return Array of guards.
     */
    function getGuards() public view returns (address[] memory) {
        address[] memory array = new address[](guardCount);

        // populate return array
        uint256 index = 0;
        address currentGuard = guards[SENTINEL_GUARDS];
        while (currentGuard != SENTINEL_GUARDS) {
            array[index] = currentGuard;
            currentGuard = guards[currentGuard];
            index++;
        }
        return array;
    }

    function verifyGuardSignatures(
        bytes4 methodID,
        bytes memory params,
        bytes[] memory signatures
    ) internal {
        bytes32 structHash =
            keccak256(
                abi.encode(
                    methodID,
                    params,
                    nonce
                )
            );
        checkGuardSignatures(structHash, signatures);
        nonce++;
    }

    function verifyGuardSignaturesWithoutNonce(
        bytes4 methodID,
        bytes memory params,
        bytes[] memory signatures
    ) view internal {
        bytes32 structHash =
            keccak256(
                abi.encode(
                    methodID,
                    params
                )
            );
        checkGuardSignatures(structHash, signatures);
    }

    /**
     * @dev Checks whether the signature provided is valid for the provided data, hash. Will revert otherwise.
     * @param structHash The struct Hash of the data (could be either a message/commitment hash).
     * @param signatures Signature data that should be verified. only ECDSA signature.
     * Signers need to be sorted in ascending order
     */
    function checkGuardSignatures(
        bytes32 structHash,
        bytes[] memory signatures
    ) public view {
        // Load threshold to avoid multiple storage loads
        uint256 _threshold = threshold;
        // Check that a threshold is set
        require(_threshold > 0, "Guard: Threshold needs to be defined");
        bytes32 dataHash = encodeDataHash(structHash);
        checkNSignatures(dataHash, signatures, _threshold);
    }

    /**
     * @dev Checks whether the signature provided is valid for the provided data, hash. Will revert otherwise.
     * @param dataHash Hash of the data (could be either a message hash or transaction hash).
     * @param signatures Signature data that should be verified. only ECDSA signature.
     * Signers need to be sorted in ascending order
     * @param requiredSignatures Amount of required valid signatures.
     */
    function checkNSignatures(
        bytes32 dataHash,
        bytes[] memory signatures,
        uint256 requiredSignatures
    ) public view {
        // Check that the provided signature data is not too short
        require(signatures.length >= requiredSignatures, "GS020");
        // There cannot be an owner with address 0.
        address lastGuard = address(0);
        address currentGuard;
        for (uint256 i = 0; i < requiredSignatures; i++) {
            currentGuard = ECDSA.recover(dataHash, signatures[i]);
            require(currentGuard > lastGuard && guards[currentGuard] != address(0) && currentGuard != SENTINEL_GUARDS, "Guard: Invalid guard provided");
            lastGuard = currentGuard;
        }
    }

    /**
     * @dev Returns the chain id used by this contract.
     */
    function getChainId() public view returns (uint256) {
        uint256 id;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
    }

    function domainSeparator() public view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, getChainId(), address(this)));
    }

    function encodeDataHash(bytes32 structHash) public view returns (bytes32) {
        return keccak256(abi.encodePacked(hex"1901", domainSeparator(), structHash));
    }
}
