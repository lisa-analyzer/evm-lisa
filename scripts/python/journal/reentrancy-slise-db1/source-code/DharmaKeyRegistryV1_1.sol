pragma solidity 0.5.11;



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}
// IGNORE_LICENSE-Identifier: MIT


/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}


/**
 * @title DharmaKeyRegistryV1
 * @author 0age
 * @notice The Dharma Key Registry is an owned contract that holds the public
 * user signing keys that will be used by the Dharma Smart Wallet. Each time a
 * particular Dharma Smart Wallet instance needs to validate a signature, it
 * will first retrieve the public address for the secondary signing key
 * associated with that wallet from the Dharma Key Registry. If a specific key
 * has not been set for that smart wallet, it will return the global public key.
 * Otherwise, it will return the specific signing key. Additional view functions
 * are also provided for retrieving public keys directly. Only the owner may
 * update these keys.
 */
contract DharmaKeyRegistryV1 is Ownable {
  using ECDSA for bytes32;

  // The global public key serves as the default signing key.
  address private _globalKey;

  // Specific keys may also be set on a per-caller basis.
  mapping (address => address) private _specificKeys;

  /**
   * @notice In the constructor, set the initial global key and the initial
   * owner to tx.origin.
   */
  constructor() public {
    // Initially set the global key to the account of the transaction submitter.
    _globalKey = tx.origin;

    // Also set the initial owner to the account of the transaction submitter.
    _transferOwnership(tx.origin);
  }

  /**
   * @notice Set a new global key. This method may only be called by the owner,
   * and a signature must also be provided in order to verify that the provided
   * global public key has a corresponding private key that can be used to sign
   * messages.
   * @param globalKey address The new global public key.
   * @param signature bytes A signature of a message hash containing the address
   * of this contract, the new global key, and a specific message, that must
   * resolve to the supplied global key.
   */
  //  SWC-Missing Protection against Signature Replay Attacks: L52 - L76
  function setGlobalKey(
    address globalKey,
    bytes calldata signature
  ) external onlyOwner {
    // Ensure that the provided global key is not the null address.
    require(globalKey != address(0), "A global key must be supplied.");

    // Message hash constructed according to EIP-191-0x45 to prevent replays.
    bytes32 messageHash = keccak256(
      abi.encodePacked(
        address(this),
        globalKey,
        "This signature demonstrates that the supplied signing key is valid."
      )
    );

    // Recover the signer of the message hash using the provided signature.
    address signer = messageHash.toEthSignedMessageHash().recover(signature);

    // Ensure that the provided signature resolves to the provided global key.
    require(globalKey == signer, "Invalid signature for supplied global key.");

    // Update the global key to the provided global key.
    _globalKey = globalKey;
  }

  /**
   * @notice Set a new specific key for a particular account. This method may
   * only be called by the owner. Signatures are not required in order to make
   * setting specific keys more efficient at scale. Providing the null address
   * for the specific key will remove a specific key from the given account.
   * @param account address The account to set the new specific public key for.
   * @param specificKey address The new specific public key.
   */
  function setSpecificKey(
    address account,
    address specificKey
  ) external onlyOwner {
    // Update specific key for provided account to the provided specific key.
    _specificKeys[account] = specificKey;
  }

  /**
   * @notice Get the public key associated with the caller of this function. If
   * a specific key is set for the caller, it will be returned; otherwise, the
   * global key will be returned.
   * @return The public key to use for the caller.
   */
  function getKey() external view returns (address key) {
    // Retrieve the specific key, if any, for the caller.
    key = _specificKeys[msg.sender];

    // Fall back to the global key in the event that no specific key is set.
    if (key == address(0)) {
      key = _globalKey;
    }
  }

  /**
   * @notice Get the public key associated with a particular account. If a
   * specific key is set for the account, it will be returned; otherwise, the
   * global key will be returned.
   * @param account address The account to find the public key for.
   * @return The public key to use for the provided account.
   */
  function getKeyForUser(address account) external view returns (address key) {
    // Retrieve the specific key, if any, for the specified account.
    key = _specificKeys[account];

    // Fall back to the global key in the event that no specific key is set.
    if (key == address(0)) {
      key = _globalKey;
    }
  }

  /**
   * @notice Get the global public key.
   * @return The global public key.
   */
  function getGlobalKey() external view returns (address globalKey) {
    // Retrieve and return the global key.
    globalKey = _globalKey;
  }

  /**
   * @notice Get the specific public key associated with the supplied account.
   * The call will revert if a specific public key is not set for the account.
   * @param account address The account to find the specific public key for.
   * @return The specific public key set on the provided account, if one exists.
   */
  function getSpecificKey(
    address account
  ) external view returns (address specificKey) {
    // Retrieve the specific key, if any, for the account.
    specificKey = _specificKeys[account];
    
    // Revert in the event that there is no specific key set.
    require(
      specificKey != address(0),
      "No specific key set for the provided account."
    );
  }
}
