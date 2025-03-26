/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

// Sources flattened with hardhat v2.6.1 https://hardhat.org

// File @openzeppelin/contracts/utils/Context.sol@v4.3.2

// : MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/Ownable.sol@v4.3.2

// : MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/libraries/resolver/Lib_AddressManager.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/* External Imports */

/**
 * @title Lib_AddressManager
 */
contract Lib_AddressManager is Ownable {
    /**********
     * Events *
     **********/

    event AddressSet(string indexed _name, address _newAddress, address _oldAddress);

    /*************
     * Variables *
     *************/

    mapping(bytes32 => address) private addresses;

    /********************
     * Public Functions *
     ********************/

    /**
     * Changes the address associated with a particular name.
     * @param _name String name to associate an address with.
     * @param _address Address to associate with the name.
     */
    function setAddress(string memory _name, address _address) external onlyOwner {
        bytes32 nameHash = _getNameHash(_name);
        address oldAddress = addresses[nameHash];
        addresses[nameHash] = _address;

        emit AddressSet(_name, _address, oldAddress);
    }

    /**
     * Retrieves the address associated with a given name.
     * @param _name Name to retrieve an address for.
     * @return Address associated with the given name.
     */
    function getAddress(string memory _name) external view returns (address) {
        return addresses[_getNameHash(_name)];
    }

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Computes the hash of a name.
     * @param _name Name to compute a hash for.
     * @return Hash of the given name.
     */
    function _getNameHash(string memory _name) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_name));
    }
}


// File contracts/libraries/resolver/Lib_AddressResolver.sol

// : MIT
pragma solidity ^0.8.9;

/* Library Imports */

/**
 * @title Lib_AddressResolver
 */
abstract contract Lib_AddressResolver {
    /*************
     * Variables *
     *************/

    Lib_AddressManager public libAddressManager;

    /***************
     * Constructor *
     ***************/

    /**
     * @param _libAddressManager Address of the Lib_AddressManager.
     */
    constructor(address _libAddressManager) {
        libAddressManager = Lib_AddressManager(_libAddressManager);
    }

    /********************
     * Public Functions *
     ********************/

    /**
     * Resolves the address associated with a given name.
     * @param _name Name to resolve an address for.
     * @return Address associated with the given name.
     */
    function resolve(string memory _name) public view returns (address) {
        return libAddressManager.getAddress(_name);
    }
}


// File contracts/MVM/iMVM_CanonicalTransaction.sol

// : MIT
pragma solidity ^0.8.9;

/* Contract Imports */

/* External Imports */

/**
 * @title ICanonicalTransactionChain
 */
interface iMVM_CanonicalTransaction {
    /*********
     * Enums *
     *********/

    enum STAKESTATUS {
        INIT,
        SEQ_SET,
        VERIFIER_SET,
        PAYBACK
    }

    /**********
     * Events *
     **********/

    event VerifierStake(
        address _sender,
        uint256 _chainId,
        uint256 _batchIndex,
        uint256 _blockNumber,
        uint256 _amount
    );

    // default : stakeAmount=0, verified=true, sequencer=true
    // sequencer response for stake: stakeAmount>0, verified=true, sequencer=true
    // verifier response for stake timeout: stakeAmount>0, verified=false, sequencer=false
    event SetBatchTxData(
        address _sender,
        uint256 _chainId,
        uint256 _batchIndex,
        uint256 _blockNumber,
        uint256 _stakeAmount,
        bool _verified,
        bool _sequencer
    );

    event AppendBatchElement (
        uint256 _chainId,
        uint256 _batchIndex,
        uint40 _shouldStartAtElement,
        uint24 _totalElementsToAppend,
        uint256 _txBatchSize,
        uint256 _txBatchTime,
        bytes32 _root
    );

    /***********
     * Structs *
     ***********/

    // locker the same sender for 30 min
    struct TxDataSlice {
        address sender;
        uint256 blockNumber;
        uint256 batchIndex;
        uint256 timestamp;
        bytes txData;
        bool verified;
    }

    struct TxDataRequestStake {
        address sender;
        uint256 blockNumber;
        uint256 batchIndex;
        uint256 timestamp;
        uint256 endtime;
        uint256 amount;
        STAKESTATUS status;
    }

    struct BatchElement {
        uint40 shouldStartAtElement;
        uint24 totalElementsToAppend;
        uint256 txBatchSize;
        uint256 txBatchTime; // sequencer client encode timestamp(ms)
        bytes32 root; // merkle hash root with [hash(txDataBytes + blockNumber)]
        uint256 timestamp; // block timestamp
    }

    /*******************************
     * Authorized Setter Functions *
     *******************************/

    /**
     * Sets address's chain id.
     * @param _address contract address.
     * @param _chainId chain id.
     */
    // function setAddressChainId(address _address, uint256 _chainId) external;

    /**
     * Gets address's chain id.
     */
    // function getAddressChainId(address _address) external view returns (uint256);

    /**
     * Sets the verifier stake base cost of ETH.
     * @param _stakeBaseCost Stake base cost for verifier.
     */
    function setStakeBaseCost(uint256 _stakeBaseCost) external;

    /**
     * Gets the verifier stake base cost of ETH.
     */
    function getStakeBaseCost() external view returns (uint256);

    /**
     * Sets the verifier stake unit cost of ETH.
     * @param _stakeUnitCost Stake cost for verifier.
     */
    function setStakeUnitCost(uint256 _stakeUnitCost) external;

    /**
     * Gets the verifier stake unit cost of ETH for per storage unit.
     */
    function getStakeUnitCost() external view returns (uint256);

    /**
     * Gets the verifier stake cost of ETH by batch index.
     */
    function getStakeCostByBatch(uint256 _chainId, uint256 _batchIndex) external view returns (uint256);

    /**
     * Sets batch transaction data slice size per submit.
     * @param _size Slice size of batch transaction data.
     */
    function setTxDataSliceSize(uint256 _size) external;

    /**
     * Gets batch transaction data slice size per submit.
     */
    function getTxDataSliceSize() external view returns (uint256);

    /**
     * Sets batch size per batch.
     * @param _size Batch size of batch.
     */
    function setTxBatchSize(uint256 _size) external;

    /**
     * Gets batch size per batch.
     */
    function getTxBatchSize() external view returns (uint256);

    /**
     * Sets slice count per batch transaction data.
     * @param _count Slice count per batch transaction data.
     */
    function setTxDataSliceCount(uint256 _count) external;

    /**
     * Gets slice count per batch transaction data.
     */
    function getTxDataSliceCount() external view returns (uint256);

    /**
     * Sets seconds can submit transaction data after staking.
     * @param _seconds Seconds the Sequencer can sumbit transaction data after verifier staking.
     */
    function setStakeSeqSeconds(uint256 _seconds) external;

    /**
     * Gets seconds can submit transaction data after staking.
     * @return Seconds the Sequencer can sumbit transaction data after verifier staking.
     */
    function getStakeSeqSeconds() external view returns (uint256);

    function isWhiteListed(address _verifier) external view returns(bool);

    // add the verifier to the whitelist
    function setWhiteList(address _verifier, bool _allowed) external;

    // allow everyone to be the verifier
    function disableWhiteList() external;

    /**
     * Allows the sequencer to append a batch of transactions.
     * @dev This function uses a custom encoding scheme for efficiency reasons.
     */
    function appendSequencerBatchByChainId() external;

    /**
     * Sets batch tx data for stake.
     * @param _chainId chain id.
     * @param _batchIndex batch index of CTC.
     * @param _blockNumber slice index.
     * @param _data tx data hex.
    */
    function setBatchTxDataForStake(uint256 _chainId, uint256 _batchIndex, uint256 _blockNumber, bytes memory _data, uint256 _leafIndex, uint256 _totalLeaves, bytes32[] memory _proof) external;

    /**
     * Sets batch tx data for verifier.
     * @param _chainId chain id.
     * @param _batchIndex batch index of CTC.
     * @param _blockNumber slice index.
     * @param _data tx data hex.
    */
    function setBatchTxDataForVerifier(uint256 _chainId, uint256 _batchIndex, uint256 _blockNumber, bytes memory _data) external;

    /**
     * Gets batch tx data.
     * @param _chainId chain id.
     * @param _batchIndex batch index of CTC.
     * @param _blockNumber block number.
     * @return txData
     * @return verified
    */
    function getBatchTxData(uint256 _chainId, uint256 _batchIndex, uint256 _blockNumber) external view returns (bytes memory txData, bool verified);

    function checkBatchTxHash(uint256 _chainId, uint256 _batchIndex, uint256 _blockNumber, bytes memory _data) external view returns (bytes32 txHash, bool verified);

    function setBatchTxDataVerified(uint256 _chainId, uint256 _batchIndex, uint256 _blockNumber, bool _verified) external;

    /**
     * Stake by verifier.
     * @param _chainId chain id.
     * @param _batchIndex batch index of CTC.
     * @param _blockNumber block number.
    */
    function verifierStake(uint256 _chainId, uint256 _batchIndex, uint256 _blockNumber) external payable;

    /**
     * Withdraw stake by verifier.
     * @param _chainId chain id.
     * @param _batchIndex batch index of CTC.
     * @param _blockNumber block number.
    */
    function withdrawStake(uint256 _chainId, uint256 _batchIndex, uint256 _blockNumber) external;

}


// File contracts/libraries/rlp/Lib_RLPReader.sol

// : MIT
pragma solidity ^0.8.9;

/**
 * @title Lib_RLPReader
 * @dev Adapted from "RLPReader" by Hamdi Allam (hamdi.allam97@gmail.com).
 */
library Lib_RLPReader {
    /*************
     * Constants *
     *************/

    uint256 internal constant MAX_LIST_LENGTH = 32;

    /*********
     * Enums *
     *********/

    enum RLPItemType {
        DATA_ITEM,
        LIST_ITEM
    }

    /***********
     * Structs *
     ***********/

    struct RLPItem {
        uint256 length;
        uint256 ptr;
    }

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Converts bytes to a reference to memory position and length.
     * @param _in Input bytes to convert.
     * @return Output memory reference.
     */
    function toRLPItem(bytes memory _in) internal pure returns (RLPItem memory) {
        uint256 ptr;
        assembly {
            ptr := add(_in, 32)
        }

        return RLPItem({ length: _in.length, ptr: ptr });
    }

    /**
     * Reads an RLP list value into a list of RLP items.
     * @param _in RLP list value.
     * @return Decoded RLP list items.
     */
    function readList(RLPItem memory _in) internal pure returns (RLPItem[] memory) {
        (uint256 listOffset, , RLPItemType itemType) = _decodeLength(_in);

        require(itemType == RLPItemType.LIST_ITEM, "Invalid RLP list value.");

        // Solidity in-memory arrays can't be increased in size, but *can* be decreased in size by
        // writing to the length. Since we can't know the number of RLP items without looping over
        // the entire input, we'd have to loop twice to accurately size this array. It's easier to
        // simply set a reasonable maximum list length and decrease the size before we finish.
        RLPItem[] memory out = new RLPItem[](MAX_LIST_LENGTH);

        uint256 itemCount = 0;
        uint256 offset = listOffset;
        while (offset < _in.length) {
            require(itemCount < MAX_LIST_LENGTH, "Provided RLP list exceeds max list length.");

            (uint256 itemOffset, uint256 itemLength, ) = _decodeLength(
                RLPItem({ length: _in.length - offset, ptr: _in.ptr + offset })
            );

            out[itemCount] = RLPItem({ length: itemLength + itemOffset, ptr: _in.ptr + offset });

            itemCount += 1;
            offset += itemOffset + itemLength;
        }

        // Decrease the array size to match the actual item count.
        assembly {
            mstore(out, itemCount)
        }

        return out;
    }

    /**
     * Reads an RLP list value into a list of RLP items.
     * @param _in RLP list value.
     * @return Decoded RLP list items.
     */
    function readList(bytes memory _in) internal pure returns (RLPItem[] memory) {
        return readList(toRLPItem(_in));
    }

    /**
     * Reads an RLP bytes value into bytes.
     * @param _in RLP bytes value.
     * @return Decoded bytes.
     */
    function readBytes(RLPItem memory _in) internal pure returns (bytes memory) {
        (uint256 itemOffset, uint256 itemLength, RLPItemType itemType) = _decodeLength(_in);

        require(itemType == RLPItemType.DATA_ITEM, "Invalid RLP bytes value.");

        return _copy(_in.ptr, itemOffset, itemLength);
    }

    /**
     * Reads an RLP bytes value into bytes.
     * @param _in RLP bytes value.
     * @return Decoded bytes.
     */
    function readBytes(bytes memory _in) internal pure returns (bytes memory) {
        return readBytes(toRLPItem(_in));
    }

    /**
     * Reads an RLP string value into a string.
     * @param _in RLP string value.
     * @return Decoded string.
     */
    function readString(RLPItem memory _in) internal pure returns (string memory) {
        return string(readBytes(_in));
    }

    /**
     * Reads an RLP string value into a string.
     * @param _in RLP string value.
     * @return Decoded string.
     */
    function readString(bytes memory _in) internal pure returns (string memory) {
        return readString(toRLPItem(_in));
    }

    /**
     * Reads an RLP bytes32 value into a bytes32.
     * @param _in RLP bytes32 value.
     * @return Decoded bytes32.
     */
    function readBytes32(RLPItem memory _in) internal pure returns (bytes32) {
        require(_in.length <= 33, "Invalid RLP bytes32 value.");

        (uint256 itemOffset, uint256 itemLength, RLPItemType itemType) = _decodeLength(_in);

        require(itemType == RLPItemType.DATA_ITEM, "Invalid RLP bytes32 value.");

        uint256 ptr = _in.ptr + itemOffset;
        bytes32 out;
        assembly {
            out := mload(ptr)

            // Shift the bytes over to match the item size.
            if lt(itemLength, 32) {
                out := div(out, exp(256, sub(32, itemLength)))
            }
        }

        return out;
    }

    /**
     * Reads an RLP bytes32 value into a bytes32.
     * @param _in RLP bytes32 value.
     * @return Decoded bytes32.
     */
    function readBytes32(bytes memory _in) internal pure returns (bytes32) {
        return readBytes32(toRLPItem(_in));
    }

    /**
     * Reads an RLP uint256 value into a uint256.
     * @param _in RLP uint256 value.
     * @return Decoded uint256.
     */
    function readUint256(RLPItem memory _in) internal pure returns (uint256) {
        return uint256(readBytes32(_in));
    }

    /**
     * Reads an RLP uint256 value into a uint256.
     * @param _in RLP uint256 value.
     * @return Decoded uint256.
     */
    function readUint256(bytes memory _in) internal pure returns (uint256) {
        return readUint256(toRLPItem(_in));
    }

    /**
     * Reads an RLP bool value into a bool.
     * @param _in RLP bool value.
     * @return Decoded bool.
     */
    function readBool(RLPItem memory _in) internal pure returns (bool) {
        require(_in.length == 1, "Invalid RLP boolean value.");

        uint256 ptr = _in.ptr;
        uint256 out;
        assembly {
            out := byte(0, mload(ptr))
        }

        require(out == 0 || out == 1, "Lib_RLPReader: Invalid RLP boolean value, must be 0 or 1");

        return out != 0;
    }

    /**
     * Reads an RLP bool value into a bool.
     * @param _in RLP bool value.
     * @return Decoded bool.
     */
    function readBool(bytes memory _in) internal pure returns (bool) {
        return readBool(toRLPItem(_in));
    }

    /**
     * Reads an RLP address value into a address.
     * @param _in RLP address value.
     * @return Decoded address.
     */
    function readAddress(RLPItem memory _in) internal pure returns (address) {
        if (_in.length == 1) {
            return address(0);
        }

        require(_in.length == 21, "Invalid RLP address value.");

        return address(uint160(readUint256(_in)));
    }

    /**
     * Reads an RLP address value into a address.
     * @param _in RLP address value.
     * @return Decoded address.
     */
    function readAddress(bytes memory _in) internal pure returns (address) {
        return readAddress(toRLPItem(_in));
    }

    /**
     * Reads the raw bytes of an RLP item.
     * @param _in RLP item to read.
     * @return Raw RLP bytes.
     */
    function readRawBytes(RLPItem memory _in) internal pure returns (bytes memory) {
        return _copy(_in);
    }

    /*********************
     * Private Functions *
     *********************/

    /**
     * Decodes the length of an RLP item.
     * @param _in RLP item to decode.
     * @return Offset of the encoded data.
     * @return Length of the encoded data.
     * @return RLP item type (LIST_ITEM or DATA_ITEM).
     */
    function _decodeLength(RLPItem memory _in)
        private
        pure
        returns (
            uint256,
            uint256,
            RLPItemType
        )
    {
        require(_in.length > 0, "RLP item cannot be null.");

        uint256 ptr = _in.ptr;
        uint256 prefix;
        assembly {
            prefix := byte(0, mload(ptr))
        }

        if (prefix <= 0x7f) {
            // Single byte.

            return (0, 1, RLPItemType.DATA_ITEM);
        } else if (prefix <= 0xb7) {
            // Short string.

            uint256 strLen = prefix - 0x80;

            require(_in.length > strLen, "Invalid RLP short string.");

            return (1, strLen, RLPItemType.DATA_ITEM);
        } else if (prefix <= 0xbf) {
            // Long string.
            uint256 lenOfStrLen = prefix - 0xb7;

            require(_in.length > lenOfStrLen, "Invalid RLP long string length.");

            uint256 strLen;
            assembly {
                // Pick out the string length.
                strLen := div(mload(add(ptr, 1)), exp(256, sub(32, lenOfStrLen)))
            }

            require(_in.length > lenOfStrLen + strLen, "Invalid RLP long string.");

            return (1 + lenOfStrLen, strLen, RLPItemType.DATA_ITEM);
        } else if (prefix <= 0xf7) {
            // Short list.
            uint256 listLen = prefix - 0xc0;

            require(_in.length > listLen, "Invalid RLP short list.");

            return (1, listLen, RLPItemType.LIST_ITEM);
        } else {
            // Long list.
            uint256 lenOfListLen = prefix - 0xf7;

            require(_in.length > lenOfListLen, "Invalid RLP long list length.");

            uint256 listLen;
            assembly {
                // Pick out the list length.
                listLen := div(mload(add(ptr, 1)), exp(256, sub(32, lenOfListLen)))
            }

            require(_in.length > lenOfListLen + listLen, "Invalid RLP long list.");

            return (1 + lenOfListLen, listLen, RLPItemType.LIST_ITEM);
        }
    }

    /**
     * Copies the bytes from a memory location.
     * @param _src Pointer to the location to read from.
     * @param _offset Offset to start reading from.
     * @param _length Number of bytes to read.
     * @return Copied bytes.
     */
    function _copy(
        uint256 _src,
        uint256 _offset,
        uint256 _length
    ) private pure returns (bytes memory) {
        bytes memory out = new bytes(_length);
        if (out.length == 0) {
            return out;
        }

        uint256 src = _src + _offset;
        uint256 dest;
        assembly {
            dest := add(out, 32)
        }

        // Copy over as many complete words as we can.
        for (uint256 i = 0; i < _length / 32; i++) {
            assembly {
                mstore(dest, mload(src))
            }

            src += 32;
            dest += 32;
        }

        // Pick out the remaining bytes.
        uint256 mask;
        unchecked {
            mask = 256**(32 - (_length % 32)) - 1;
        }

        assembly {
            mstore(dest, or(and(mload(src), not(mask)), and(mload(dest), mask)))
        }
        return out;
    }

    /**
     * Copies an RLP item into bytes.
     * @param _in RLP item to copy.
     * @return Copied bytes.
     */
    function _copy(RLPItem memory _in) private pure returns (bytes memory) {
        return _copy(_in.ptr, 0, _in.length);
    }
}


// File contracts/libraries/rlp/Lib_RLPWriter.sol

// : MIT
pragma solidity ^0.8.9;

/**
 * @title Lib_RLPWriter
 * @author Bakaoh (with modifications)
 */
library Lib_RLPWriter {
    /**********************
     * Internal Functions *
     **********************/

    /**
     * RLP encodes a byte string.
     * @param _in The byte string to encode.
     * @return The RLP encoded string in bytes.
     */
    function writeBytes(bytes memory _in) internal pure returns (bytes memory) {
        bytes memory encoded;

        if (_in.length == 1 && uint8(_in[0]) < 128) {
            encoded = _in;
        } else {
            encoded = abi.encodePacked(_writeLength(_in.length, 128), _in);
        }

        return encoded;
    }

    /**
     * RLP encodes a list of RLP encoded byte byte strings.
     * @param _in The list of RLP encoded byte strings.
     * @return The RLP encoded list of items in bytes.
     */
    function writeList(bytes[] memory _in) internal pure returns (bytes memory) {
        bytes memory list = _flatten(_in);
        return abi.encodePacked(_writeLength(list.length, 192), list);
    }

    /**
     * RLP encodes a string.
     * @param _in The string to encode.
     * @return The RLP encoded string in bytes.
     */
    function writeString(string memory _in) internal pure returns (bytes memory) {
        return writeBytes(bytes(_in));
    }

    /**
     * RLP encodes an address.
     * @param _in The address to encode.
     * @return The RLP encoded address in bytes.
     */
    function writeAddress(address _in) internal pure returns (bytes memory) {
        return writeBytes(abi.encodePacked(_in));
    }

    /**
     * RLP encodes a uint.
     * @param _in The uint256 to encode.
     * @return The RLP encoded uint256 in bytes.
     */
    function writeUint(uint256 _in) internal pure returns (bytes memory) {
        return writeBytes(_toBinary(_in));
    }

    /**
     * RLP encodes a bool.
     * @param _in The bool to encode.
     * @return The RLP encoded bool in bytes.
     */
    function writeBool(bool _in) internal pure returns (bytes memory) {
        bytes memory encoded = new bytes(1);
        encoded[0] = (_in ? bytes1(0x01) : bytes1(0x80));
        return encoded;
    }

    /*********************
     * Private Functions *
     *********************/

    /**
     * Encode the first byte, followed by the `len` in binary form if `length` is more than 55.
     * @param _len The length of the string or the payload.
     * @param _offset 128 if item is string, 192 if item is list.
     * @return RLP encoded bytes.
     */
    function _writeLength(uint256 _len, uint256 _offset) private pure returns (bytes memory) {
        bytes memory encoded;

        if (_len < 56) {
            encoded = new bytes(1);
            encoded[0] = bytes1(uint8(_len) + uint8(_offset));
        } else {
            uint256 lenLen;
            uint256 i = 1;
            while (_len / i != 0) {
                lenLen++;
                i *= 256;
            }

            encoded = new bytes(lenLen + 1);
            encoded[0] = bytes1(uint8(lenLen) + uint8(_offset) + 55);
            for (i = 1; i <= lenLen; i++) {
                encoded[i] = bytes1(uint8((_len / (256**(lenLen - i))) % 256));
            }
        }

        return encoded;
    }

    /**
     * Encode integer in big endian binary form with no leading zeroes.
     * @notice TODO: This should be optimized with assembly to save gas costs.
     * @param _x The integer to encode.
     * @return RLP encoded bytes.
     */
    function _toBinary(uint256 _x) private pure returns (bytes memory) {
        bytes memory b = abi.encodePacked(_x);

        uint256 i = 0;
        for (; i < 32; i++) {
            if (b[i] != 0) {
                break;
            }
        }

        bytes memory res = new bytes(32 - i);
        for (uint256 j = 0; j < res.length; j++) {
            res[j] = b[i++];
        }

        return res;
    }

    /**
     * Copies a piece of memory to another location.
     * @notice From: https://github.com/Arachnid/solidity-stringutils/blob/master/src/strings.sol.
     * @param _dest Destination location.
     * @param _src Source location.
     * @param _len Length of memory to copy.
     */
    function _memcpy(
        uint256 _dest,
        uint256 _src,
        uint256 _len
    ) private pure {
        uint256 dest = _dest;
        uint256 src = _src;
        uint256 len = _len;

        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        uint256 mask;
        unchecked {
            mask = 256**(32 - len) - 1;
        }
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /**
     * Flattens a list of byte strings into one byte string.
     * @notice From: https://github.com/sammayo/solidity-rlp-encoder/blob/master/RLPEncode.sol.
     * @param _list List of byte strings to flatten.
     * @return The flattened byte string.
     */
    function _flatten(bytes[] memory _list) private pure returns (bytes memory) {
        if (_list.length == 0) {
            return new bytes(0);
        }

        uint256 len;
        uint256 i = 0;
        for (; i < _list.length; i++) {
            len += _list[i].length;
        }

        bytes memory flattened = new bytes(len);
        uint256 flattenedPtr;
        assembly {
            flattenedPtr := add(flattened, 0x20)
        }

        for (i = 0; i < _list.length; i++) {
            bytes memory item = _list[i];

            uint256 listPtr;
            assembly {
                listPtr := add(item, 0x20)
            }

            _memcpy(flattenedPtr, listPtr, item.length);
            flattenedPtr += _list[i].length;
        }

        return flattened;
    }
}


// File contracts/libraries/utils/Lib_BytesUtils.sol

// : MIT
pragma solidity ^0.8.9;

/**
 * @title Lib_BytesUtils
 */
library Lib_BytesUtils {
    /**********************
     * Internal Functions *
     **********************/

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_start + _length >= _start, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)

                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function slice(bytes memory _bytes, uint256 _start) internal pure returns (bytes memory) {
        if (_start >= _bytes.length) {
            return bytes("");
        }

        return slice(_bytes, _start, _bytes.length - _start);
    }

    function toBytes32(bytes memory _bytes) internal pure returns (bytes32) {
        if (_bytes.length < 32) {
            bytes32 ret;
            assembly {
                ret := mload(add(_bytes, 32))
            }
            return ret;
        }

        return abi.decode(_bytes, (bytes32)); // will truncate if input length > 32 bytes
    }

    function toUint256(bytes memory _bytes) internal pure returns (uint256) {
        return uint256(toBytes32(_bytes));
    }

    function toNibbles(bytes memory _bytes) internal pure returns (bytes memory) {
        bytes memory nibbles = new bytes(_bytes.length * 2);

        for (uint256 i = 0; i < _bytes.length; i++) {
            nibbles[i * 2] = _bytes[i] >> 4;
            nibbles[i * 2 + 1] = bytes1(uint8(_bytes[i]) % 16);
        }

        return nibbles;
    }

    function fromNibbles(bytes memory _bytes) internal pure returns (bytes memory) {
        bytes memory ret = new bytes(_bytes.length / 2);

        for (uint256 i = 0; i < ret.length; i++) {
            ret[i] = (_bytes[i * 2] << 4) | (_bytes[i * 2 + 1]);
        }

        return ret;
    }

    function equal(bytes memory _bytes, bytes memory _other) internal pure returns (bool) {
        return keccak256(_bytes) == keccak256(_other);
    }
}


// File contracts/libraries/utils/Lib_Bytes32Utils.sol

// : MIT
pragma solidity ^0.8.9;

/**
 * @title Lib_Byte32Utils
 */
library Lib_Bytes32Utils {
    /**********************
     * Internal Functions *
     **********************/

    /**
     * Converts a bytes32 value to a boolean. Anything non-zero will be converted to "true."
     * @param _in Input bytes32 value.
     * @return Bytes32 as a boolean.
     */
    function toBool(bytes32 _in) internal pure returns (bool) {
        return _in != 0;
    }

    /**
     * Converts a boolean to a bytes32 value.
     * @param _in Input boolean value.
     * @return Boolean as a bytes32.
     */
    function fromBool(bool _in) internal pure returns (bytes32) {
        return bytes32(uint256(_in ? 1 : 0));
    }

    /**
     * Converts a bytes32 value to an address. Takes the *last* 20 bytes.
     * @param _in Input bytes32 value.
     * @return Bytes32 as an address.
     */
    function toAddress(bytes32 _in) internal pure returns (address) {
        return address(uint160(uint256(_in)));
    }

    /**
     * Converts an address to a bytes32.
     * @param _in Input address value.
     * @return Address as a bytes32.
     */
    function fromAddress(address _in) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_in)));
    }
}


// File contracts/libraries/codec/Lib_OVMCodec.sol

// : MIT
pragma solidity ^0.8.9;

/* Library Imports */




/**
 * @title Lib_OVMCodec
 */
library Lib_OVMCodec {
    /*********
     * Enums *
     *********/

    enum QueueOrigin {
        SEQUENCER_QUEUE,
        L1TOL2_QUEUE
    }

    /***********
     * Structs *
     ***********/

    struct EVMAccount {
        uint256 nonce;
        uint256 balance;
        bytes32 storageRoot;
        bytes32 codeHash;
    }

    struct ChainBatchHeader {
        uint256 batchIndex;
        bytes32 batchRoot;
        uint256 batchSize;
        uint256 prevTotalElements;
        bytes extraData;
    }

    struct ChainInclusionProof {
        uint256 index;
        bytes32[] siblings;
    }

    struct Transaction {
        uint256 timestamp;
        uint256 blockNumber;
        QueueOrigin l1QueueOrigin;
        address l1TxOrigin;
        address entrypoint;
        uint256 gasLimit;
        bytes data;
    }

    struct TransactionChainElement {
        bool isSequenced;
        uint256 queueIndex; // QUEUED TX ONLY
        uint256 timestamp; // SEQUENCER TX ONLY
        uint256 blockNumber; // SEQUENCER TX ONLY
        bytes txData; // SEQUENCER TX ONLY
    }

    struct QueueElement {
        bytes32 transactionHash;
        uint40 timestamp;
        uint40 blockNumber;
    }

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Encodes a standard OVM transaction.
     * @param _transaction OVM transaction to encode.
     * @return Encoded transaction bytes.
     */
    function encodeTransaction(Transaction memory _transaction)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                _transaction.timestamp,
                _transaction.blockNumber,
                _transaction.l1QueueOrigin,
                _transaction.l1TxOrigin,
                _transaction.entrypoint,
                _transaction.gasLimit,
                _transaction.data
            );
    }

    /**
     * Hashes a standard OVM transaction.
     * @param _transaction OVM transaction to encode.
     * @return Hashed transaction
     */
    function hashTransaction(Transaction memory _transaction) internal pure returns (bytes32) {
        return keccak256(encodeTransaction(_transaction));
    }

    /**
     * @notice Decodes an RLP-encoded account state into a useful struct.
     * @param _encoded RLP-encoded account state.
     * @return Account state struct.
     */
    function decodeEVMAccount(bytes memory _encoded) internal pure returns (EVMAccount memory) {
        Lib_RLPReader.RLPItem[] memory accountState = Lib_RLPReader.readList(_encoded);

        return
            EVMAccount({
                nonce: Lib_RLPReader.readUint256(accountState[0]),
                balance: Lib_RLPReader.readUint256(accountState[1]),
                storageRoot: Lib_RLPReader.readBytes32(accountState[2]),
                codeHash: Lib_RLPReader.readBytes32(accountState[3])
            });
    }

    /**
     * Calculates a hash for a given batch header.
     * @param _batchHeader Header to hash.
     * @return Hash of the header.
     */
    function hashBatchHeader(Lib_OVMCodec.ChainBatchHeader memory _batchHeader)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    _batchHeader.batchRoot,
                    _batchHeader.batchSize,
                    _batchHeader.prevTotalElements,
                    _batchHeader.extraData
                )
            );
    }
}


// File contracts/L1/rollup/IChainStorageContainer.sol

// : MIT
pragma solidity >0.5.0 <0.9.0;

/**
 * @title IChainStorageContainer
 */
interface IChainStorageContainer {
    /********************
     * Public Functions *
     ********************/

    /**
     * Sets the container's global metadata field. We're using `bytes27` here because we use five
     * bytes to maintain the length of the underlying data structure, meaning we have an extra
     * 27 bytes to store arbitrary data.
     * @param _globalMetadata New global metadata to set.
     */
    function setGlobalMetadata(bytes27 _globalMetadata) external;

    /**
     * Retrieves the container's global metadata field.
     * @return Container global metadata field.
     */
    function getGlobalMetadata() external view returns (bytes27);

    /**
     * Retrieves the number of objects stored in the container.
     * @return Number of objects in the container.
     */
    function length() external view returns (uint256);

    /**
     * Pushes an object into the container.
     * @param _object A 32 byte value to insert into the container.
     */
    function push(bytes32 _object) external;

    /**
     * Pushes an object into the container. Function allows setting the global metadata since
     * we'll need to touch the "length" storage slot anyway, which also contains the global
     * metadata (it's an optimization).
     * @param _object A 32 byte value to insert into the container.
     * @param _globalMetadata New global metadata for the container.
     */
    function push(bytes32 _object, bytes27 _globalMetadata) external;

    /**
     * Set an object into the container. Function allows setting the global metadata since
     * we'll need to touch the "length" storage slot anyway, which also contains the global
     * metadata (it's an optimization).
     * @param _index position.
     * @param _object A 32 byte value to insert into the container.
     */  
    function setByChainId(
        uint256 _chainId,
        uint256 _index,
        bytes32 _object
    )
        external;
        
    /**
     * Retrieves an object from the container.
     * @param _index Index of the particular object to access.
     * @return 32 byte object value.
     */
    function get(uint256 _index) external view returns (bytes32);

    /**
     * Removes all objects after and including a given index.
     * @param _index Object index to delete from.
     */
    function deleteElementsAfterInclusive(uint256 _index) external;

    /**
     * Removes all objects after and including a given index. Also allows setting the global
     * metadata field.
     * @param _index Object index to delete from.
     * @param _globalMetadata New global metadata for the container.
     */
    function deleteElementsAfterInclusive(uint256 _index, bytes27 _globalMetadata) external;

    /**
     * Sets the container's global metadata field. We're using `bytes27` here because we use five
     * bytes to maintain the length of the underlying data structure, meaning we have an extra
     * 27 bytes to store arbitrary data.
     * @param _chainId identity for the l2 chain.
     * @param _globalMetadata New global metadata to set.
     */
    function setGlobalMetadataByChainId(
        uint256 _chainId,
        bytes27 _globalMetadata
    )
        external;

    /**
     * Retrieves the container's global metadata field.
     * @param _chainId identity for the l2 chain.
     * @return Container global metadata field.
     */
    function getGlobalMetadataByChainId(
        uint256 _chainId
        )
        external
        view
        returns (
            bytes27
        );

    /**
     * Retrieves the number of objects stored in the container.
     * @param _chainId identity for the l2 chain.
     * @return Number of objects in the container.
     */
    function lengthByChainId(
        uint256 _chainId
        )
        external
        view
        returns (
            uint256
        );

    /**
     * Pushes an object into the container.
     * @param _chainId identity for the l2 chain.
     * @param _object A 32 byte value to insert into the container.
     */
    function pushByChainId(
        uint256 _chainId,
        bytes32 _object
    )
        external;

    /**
     * Pushes an object into the container. Function allows setting the global metadata since
     * we'll need to touch the "length" storage slot anyway, which also contains the global
     * metadata (it's an optimization).
     * @param _chainId identity for the l2 chain.
     * @param _object A 32 byte value to insert into the container.
     * @param _globalMetadata New global metadata for the container.
     */
    function pushByChainId(
        uint256 _chainId,
        bytes32 _object,
        bytes27 _globalMetadata
    )
        external;

    /**
     * Retrieves an object from the container.
     * @param _chainId identity for the l2 chain.
     * @param _index Index of the particular object to access.
     * @return 32 byte object value.
     */
    function getByChainId(
        uint256 _chainId,
        uint256 _index
    )
        external
        view
        returns (
            bytes32
        );

    /**
     * Removes all objects after and including a given index.
     * @param _chainId identity for the l2 chain.
     * @param _index Object index to delete from.
     */
    function deleteElementsAfterInclusiveByChainId(
        uint256 _chainId,
        uint256 _index
    )
        external;
        
    /**
     * Removes all objects after and including a given index. Also allows setting the global
     * metadata field.
     * @param _chainId identity for the l2 chain.
     * @param _index Object index to delete from.
     * @param _globalMetadata New global metadata for the container.
     */
    function deleteElementsAfterInclusiveByChainId(
        uint256 _chainId,
        uint256 _index,
        bytes27 _globalMetadata
    )
        external;
        
}


// File contracts/L1/rollup/ICanonicalTransactionChain.sol

// : MIT
pragma solidity >0.5.0 <0.9.0;

/* Library Imports */

/* Interface Imports */

/**
 * @title ICanonicalTransactionChain
 */
interface ICanonicalTransactionChain {
    /**********
     * Events *
     **********/
    event QueueGlobalMetadataSet(
        address _sender,
        uint256 _chainId,
        bytes27 _globalMetadata
    );
    
    event QueuePushed(
        address _sender,
        uint256 _chainId,
        Lib_OVMCodec.QueueElement _object
    );

    event QueueSetted(
        address _sender,
        uint256 _chainId,
        uint256 _index,
        Lib_OVMCodec.QueueElement _object
    );

    event QueueElementDeleted(
        address _sender,
        uint256 _chainId,
        uint256 _index,
        bytes27 _globalMetadata
    );

    event BatchesGlobalMetadataSet(
        address _sender,
        uint256 _chainId,
        bytes27 _globalMetadata
    );
    
    event BatchPushed(
        address _sender,
        uint256 _chainId,
        bytes32 _object,
        bytes27 _globalMetadata
    );

    event BatchSetted(
        address _sender,
        uint256 _chainId,
        uint256 _index,
        bytes32 _object
    );

    event BatchElementDeleted(
        address _sender,
        uint256 _chainId,
        uint256 _index,
        bytes27 _globalMetadata
    );

    event L2GasParamsUpdated(
        uint256 l2GasDiscountDivisor,
        uint256 enqueueGasCost,
        uint256 enqueueL2GasPrepaid
    );

    event TransactionEnqueued(
        uint256 _chainId,
        address indexed _l1TxOrigin,
        address indexed _target,
        uint256 _gasLimit,
        bytes _data,
        uint256 indexed _queueIndex,
        uint256 _timestamp
    );

    event QueueBatchAppended(
        uint256 _chainId,
        uint256 _startingQueueIndex,
        uint256 _numQueueElements,
        uint256 _totalElements
    );

    event SequencerBatchAppended(
        uint256 _chainId,
        uint256 _startingQueueIndex,
        uint256 _numQueueElements,
        uint256 _totalElements
    );

    event TransactionBatchAppended(
        uint256 _chainId,
        uint256 indexed _batchIndex,
        bytes32 _batchRoot,
        uint256 _batchSize,
        uint256 _prevTotalElements,
        bytes _extraData
    );

    /***********
     * Structs *
     ***********/

    struct BatchContext {
        uint256 numSequencedTransactions;
        uint256 numSubsequentQueueTransactions;
        uint256 timestamp;
        uint256 blockNumber;
    }

    /*******************************
     * Authorized Setter Functions *
     *******************************/

    /**
     * Allows the Burn Admin to update the parameters which determine the amount of gas to burn.
     * The value of enqueueL2GasPrepaid is immediately updated as well.
     */
    function setGasParams(uint256 _l2GasDiscountDivisor, uint256 _enqueueGasCost) external;

    /********************
     * Public Functions *
     ********************/

    /**
     * Accesses the batch storage container.
     * @return Reference to the batch storage container.
     */
    function batches() external view returns (IChainStorageContainer);

    /**
     * Accesses the queue storage container.
     * @return Reference to the queue storage container.
     */
    function queue() external view returns (IChainStorageContainer);

    /**
     * Retrieves the total number of elements submitted.
     * @return _totalElements Total submitted elements.
     */
    function getTotalElements() external view returns (uint256 _totalElements);

    /**
     * Retrieves the total number of batches submitted.
     * @return _totalBatches Total submitted batches.
     */
    function getTotalBatches() external view returns (uint256 _totalBatches);

    /**
     * Returns the index of the next element to be enqueued.
     * @return Index for the next queue element.
     */
    function getNextQueueIndex() external view returns (uint40);

    /**
     * Gets the queue element at a particular index.
     * @param _index Index of the queue element to access.
     * @return _element Queue element at the given index.
     */
    function getQueueElement(uint256 _index)
        external
        view
        returns (Lib_OVMCodec.QueueElement memory _element);

    /**
     * Returns the timestamp of the last transaction.
     * @return Timestamp for the last transaction.
     */
    function getLastTimestamp() external view returns (uint40);

    /**
     * Returns the blocknumber of the last transaction.
     * @return Blocknumber for the last transaction.
     */
    function getLastBlockNumber() external view returns (uint40);

    /**
     * Get the number of queue elements which have not yet been included.
     * @return Number of pending queue elements.
     */
    function getNumPendingQueueElements() external view returns (uint40);

    /**
     * Retrieves the length of the queue, including
     * both pending and canonical transactions.
     * @return Length of the queue.
     */
    function getQueueLength() external view returns (uint40);

    /**
     * Adds a transaction to the queue.
     * @param _target Target contract to send the transaction to.
     * @param _gasLimit Gas limit for the given transaction.
     * @param _data Transaction data.
     */
    function enqueue(
        address _target,
        uint256 _gasLimit,
        bytes memory _data
    ) external;

    /**
     * Allows the sequencer to append a batch of transactions.
     * @dev This function uses a custom encoding scheme for efficiency reasons.
     * .param _shouldStartAtElement Specific batch we expect to start appending to.
     * .param _totalElementsToAppend Total number of batch elements we expect to append.
     * .param _contexts Array of batch contexts.
     * .param _transactionDataFields Array of raw transaction data.
     */
    function appendSequencerBatch(
        // uint40 _shouldStartAtElement,
        // uint24 _totalElementsToAppend,
        // BatchContext[] _contexts,
        // bytes[] _transactionDataFields
    )
        external;
        
    //added chain id function
    
    /**
     * Retrieves the total number of elements submitted.
     * @param _chainId identity for the l2 chain.
     * @return _totalElements Total submitted elements.
     */
    function getTotalElementsByChainId(
        uint256 _chainId
        )
        external
        view
        returns (
            uint256 _totalElements
        );

    /**
     * Retrieves the total number of batches submitted.
     * @param _chainId identity for the l2 chain.
     * @return _totalBatches Total submitted batches.
     */
    function getTotalBatchesByChainId(
        uint256 _chainId
        )
        external
        view
        returns (
            uint256 _totalBatches
        );

    /**
     * Returns the index of the next element to be enqueued.
     * @param _chainId identity for the l2 chain.
     * @return Index for the next queue element.
     */
    function getNextQueueIndexByChainId(
        uint256 _chainId
        )
        external
        view
        returns (
            uint40
        );

    /**
     * Gets the queue element at a particular index.
     * @param _chainId identity for the l2 chain.
     * @param _index Index of the queue element to access.
     * @return _element Queue element at the given index.
     */
    function getQueueElementByChainId(
        uint256 _chainId,
        uint256 _index
    )
        external
        view
        returns (
            Lib_OVMCodec.QueueElement memory _element
        );

    /**
     * Returns the timestamp of the last transaction.
     * @param _chainId identity for the l2 chain.
     * @return Timestamp for the last transaction.
     */
    function getLastTimestampByChainId(
        uint256 _chainId
        )
        external
        view
        returns (
            uint40
        );

    /**
     * Returns the blocknumber of the last transaction.
     * @param _chainId identity for the l2 chain.
     * @return Blocknumber for the last transaction.
     */
    function getLastBlockNumberByChainId(
        uint256 _chainId
        )
        external
        view
        returns (
            uint40
        );

    /**
     * Get the number of queue elements which have not yet been included.
     * @param _chainId identity for the l2 chain.
     * @return Number of pending queue elements.
     */
    function getNumPendingQueueElementsByChainId(
        uint256 _chainId
        )
        external
        view
        returns (
            uint40
        );

    /**
     * Retrieves the length of the queue, including
     * both pending and canonical transactions.
     * @param _chainId identity for the l2 chain.
     * @return Length of the queue.
     */
    function getQueueLengthByChainId(
        uint256 _chainId
        )
        external
        view
        returns (
            uint40
        );


    /**
     * Adds a transaction to the queue.
     * @param _chainId identity for the l2 chain.
     * @param _target Target contract to send the transaction to.
     * @param _gasLimit Gas limit for the given transaction.
     * @param _data Transaction data.
     */
    function enqueueByChainId(
        uint256 _chainId,
        address _target,
        uint256 _gasLimit,
        bytes memory _data
    )
        external;
        
    /**
     * Allows the sequencer to append a batch of transactions.
     * @dev This function uses a custom encoding scheme for efficiency reasons.
     * .param _chainId identity for the l2 chain.
     * .param _shouldStartAtElement Specific batch we expect to start appending to.
     * .param _totalElementsToAppend Total number of batch elements we expect to append.
     * .param _contexts Array of batch contexts.
     * .param _transactionDataFields Array of raw transaction data.
     */
    function appendSequencerBatchByChainId(
        // uint256 _chainId,
        // uint40 _shouldStartAtElement,
        // uint24 _totalElementsToAppend,
        // BatchContext[] _contexts,
        // bytes[] _transactionDataFields
    )
        external;
    
    function pushQueueByChainId(
        uint256 _chainId,
        Lib_OVMCodec.QueueElement calldata _object
    )
        external;

    function setQueueByChainId(
        uint256 _chainId,
        uint256 _index,
        Lib_OVMCodec.QueueElement calldata _object
    )
        external;

    function setBatchGlobalMetadataByChainId(
        uint256 _chainId,
        bytes27 _globalMetadata
    )
        external;
    
    function getBatchGlobalMetadataByChainId(uint256 _chainId)
        external
        view
        returns (
            bytes27
        );
        
    function lengthBatchByChainId(uint256 _chainId)
        external
        view
        returns (
            uint256
        );
        
    function pushBatchByChainId(
        uint256 _chainId,
        bytes32 _object,
        bytes27 _globalMetadata
    )
        external;
    
    function setBatchByChainId(
        uint256 _chainId,
        uint256 _index,
        bytes32 _object
    )
        external;
        
    function getBatchByChainId(
        uint256 _chainId,
        uint256 _index
    )
        external
        view
        returns (
            bytes32
        );
        
    function deleteBatchElementsAfterInclusiveByChainId(
        uint256 _chainId,
        uint256 _index,
        bytes27 _globalMetadata
    )
        external;
}


// File contracts/libraries/utils/Lib_MerkleTree.sol

// : MIT
pragma solidity ^0.8.9;

/**
 * @title Lib_MerkleTree
 * @author River Keefer
 */
library Lib_MerkleTree {
    /**********************
     * Internal Functions *
     **********************/

    /**
     * Calculates a merkle root for a list of 32-byte leaf hashes.  WARNING: If the number
     * of leaves passed in is not a power of two, it pads out the tree with zero hashes.
     * If you do not know the original length of elements for the tree you are verifying, then
     * this may allow empty leaves past _elements.length to pass a verification check down the line.
     * Note that the _elements argument is modified, therefore it must not be used again afterwards
     * @param _elements Array of hashes from which to generate a merkle root.
     * @return Merkle root of the leaves, with zero hashes for non-powers-of-two (see above).
     */
    function getMerkleRoot(bytes32[] memory _elements) internal pure returns (bytes32) {
        require(_elements.length > 0, "Lib_MerkleTree: Must provide at least one leaf hash.");

        if (_elements.length == 1) {
            return _elements[0];
        }

        uint256[16] memory defaults = [
            0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563,
            0x633dc4d7da7256660a892f8f1604a44b5432649cc8ec5cb3ced4c4e6ac94dd1d,
            0x890740a8eb06ce9be422cb8da5cdafc2b58c0a5e24036c578de2a433c828ff7d,
            0x3b8ec09e026fdc305365dfc94e189a81b38c7597b3d941c279f042e8206e0bd8,
            0xecd50eee38e386bd62be9bedb990706951b65fe053bd9d8a521af753d139e2da,
            0xdefff6d330bb5403f63b14f33b578274160de3a50df4efecf0e0db73bcdd3da5,
            0x617bdd11f7c0a11f49db22f629387a12da7596f9d1704d7465177c63d88ec7d7,
            0x292c23a9aa1d8bea7e2435e555a4a60e379a5a35f3f452bae60121073fb6eead,
            0xe1cea92ed99acdcb045a6726b2f87107e8a61620a232cf4d7d5b5766b3952e10,
            0x7ad66c0a68c72cb89e4fb4303841966e4062a76ab97451e3b9fb526a5ceb7f82,
            0xe026cc5a4aed3c22a58cbd3d2ac754c9352c5436f638042dca99034e83636516,
            0x3d04cffd8b46a874edf5cfae63077de85f849a660426697b06a829c70dd1409c,
            0xad676aa337a485e4728a0b240d92b3ef7b3c372d06d189322bfd5f61f1e7203e,
            0xa2fca4a49658f9fab7aa63289c91b7c7b6c832a6d0e69334ff5b0a3483d09dab,
            0x4ebfd9cd7bca2505f7bef59cc1c12ecc708fff26ae4af19abe852afe9e20c862,
            0x2def10d13dd169f550f578bda343d9717a138562e0093b380a1120789d53cf10
        ];

        // Reserve memory space for our hashes.
        bytes memory buf = new bytes(64);

        // We'll need to keep track of left and right siblings.
        bytes32 leftSibling;
        bytes32 rightSibling;

        // Number of non-empty nodes at the current depth.
        uint256 rowSize = _elements.length;

        // Current depth, counting from 0 at the leaves
        uint256 depth = 0;

        // Common sub-expressions
        uint256 halfRowSize; // rowSize / 2
        bool rowSizeIsOdd; // rowSize % 2 == 1

        while (rowSize > 1) {
            halfRowSize = rowSize / 2;
            rowSizeIsOdd = rowSize % 2 == 1;

            for (uint256 i = 0; i < halfRowSize; i++) {
                leftSibling = _elements[(2 * i)];
                rightSibling = _elements[(2 * i) + 1];
                assembly {
                    mstore(add(buf, 32), leftSibling)
                    mstore(add(buf, 64), rightSibling)
                }

                _elements[i] = keccak256(buf);
            }

            if (rowSizeIsOdd) {
                leftSibling = _elements[rowSize - 1];
                rightSibling = bytes32(defaults[depth]);
                assembly {
                    mstore(add(buf, 32), leftSibling)
                    mstore(add(buf, 64), rightSibling)
                }

                _elements[halfRowSize] = keccak256(buf);
            }

            rowSize = halfRowSize + (rowSizeIsOdd ? 1 : 0);
            depth++;
        }

        return _elements[0];
    }

    /**
     * Verifies a merkle branch for the given leaf hash.  Assumes the original length
     * of leaves generated is a known, correct input, and does not return true for indices
     * extending past that index (even if _siblings would be otherwise valid.)
     * @param _root The Merkle root to verify against.
     * @param _leaf The leaf hash to verify inclusion of.
     * @param _index The index in the tree of this leaf.
     * @param _siblings Array of sibline nodes in the inclusion proof, starting from depth 0
     * (bottom of the tree).
     * @param _totalLeaves The total number of leaves originally passed into.
     * @return Whether or not the merkle branch and leaf passes verification.
     */
    function verify(
        bytes32 _root,
        bytes32 _leaf,
        uint256 _index,
        bytes32[] memory _siblings,
        uint256 _totalLeaves
    ) internal pure returns (bool) {
        require(_totalLeaves > 0, "Lib_MerkleTree: Total leaves must be greater than zero.");

        require(_index < _totalLeaves, "Lib_MerkleTree: Index out of bounds.");

        require(
            _siblings.length == _ceilLog2(_totalLeaves),
            "Lib_MerkleTree: Total siblings does not correctly correspond to total leaves."
        );

        bytes32 computedRoot = _leaf;

        for (uint256 i = 0; i < _siblings.length; i++) {
            if ((_index & 1) == 1) {
                computedRoot = keccak256(abi.encodePacked(_siblings[i], computedRoot));
            } else {
                computedRoot = keccak256(abi.encodePacked(computedRoot, _siblings[i]));
            }

            _index >>= 1;
        }

        return _root == computedRoot;
    }

    /*********************
     * Private Functions *
     *********************/

    /**
     * Calculates the integer ceiling of the log base 2 of an input.
     * @param _in Unsigned input to calculate the log.
     * @return ceil(log_base_2(_in))
     */
    function _ceilLog2(uint256 _in) private pure returns (uint256) {
        require(_in > 0, "Lib_MerkleTree: Cannot compute ceil(log_2) of 0.");

        if (_in == 1) {
            return 0;
        }

        // Find the highest set bit (will be floor(log_2)).
        // Borrowed with <3 from https://github.com/ethereum/solidity-examples
        uint256 val = _in;
        uint256 highest = 0;
        for (uint256 i = 128; i >= 1; i >>= 1) {
            if (val & (((uint256(1) << i) - 1) << i) != 0) {
                highest += i;
                val >>= i;
            }
        }

        // Increment by one if this is not a perfect logarithm.
        if ((uint256(1) << highest) != _in) {
            highest += 1;
        }

        return highest;
    }
}


// File contracts/L1/rollup/IStateCommitmentChain.sol

// : MIT
pragma solidity >0.5.0 <0.9.0;

/* Library Imports */


/**
 * @title IStateCommitmentChain
 */
interface IStateCommitmentChain {
    /**********
     * Events *
     **********/

    event StateBatchAppended(
        uint256 _chainId,
        uint256 indexed _batchIndex,
        bytes32 _batchRoot,
        uint256 _batchSize,
        uint256 _prevTotalElements,
        bytes _extraData
    );

    event StateBatchDeleted(
        uint256 _chainId,
        uint256 indexed _batchIndex,
        bytes32 _batchRoot
    );


    /********************
     * Public Functions *
     ********************/
    
    function batches() external view returns (IChainStorageContainer);
    
    /**
     * Retrieves the total number of elements submitted.
     * @return _totalElements Total submitted elements.
     */
    function getTotalElements() external view returns (uint256 _totalElements);

    /**
     * Retrieves the total number of batches submitted.
     * @return _totalBatches Total submitted batches.
     */
    function getTotalBatches() external view returns (uint256 _totalBatches);

    /**
     * Retrieves the timestamp of the last batch submitted by the sequencer.
     * @return _lastSequencerTimestamp Last sequencer batch timestamp.
     */
    function getLastSequencerTimestamp() external view returns (uint256 _lastSequencerTimestamp);

    /**
     * Appends a batch of state roots to the chain.
     * @param _batch Batch of state roots.
     * @param _shouldStartAtElement Index of the element at which this batch should start.
     */
    function appendStateBatch(bytes32[] calldata _batch, uint256 _shouldStartAtElement) external;

    /**
     * Deletes all state roots after (and including) a given batch.
     * @param _batchHeader Header of the batch to start deleting from.
     */
    function deleteStateBatch(Lib_OVMCodec.ChainBatchHeader memory _batchHeader) external;

    /**
     * Verifies a batch inclusion proof.
     * @param _element Hash of the element to verify a proof for.
     * @param _batchHeader Header of the batch in which the element was included.
     * @param _proof Merkle inclusion proof for the element.
     */
    function verifyStateCommitment(
        bytes32 _element,
        Lib_OVMCodec.ChainBatchHeader memory _batchHeader,
        Lib_OVMCodec.ChainInclusionProof memory _proof
    ) external view returns (bool _verified);

    /**
     * Checks whether a given batch is still inside its fraud proof window.
     * @param _batchHeader Header of the batch to check.
     * @return _inside Whether or not the batch is inside the fraud proof window.
     */
    function insideFraudProofWindow(Lib_OVMCodec.ChainBatchHeader memory _batchHeader)
        external
        view
        returns (
            bool _inside
        );
        
        
        
     /********************
     * chain id added func *
     ********************/

    /**
     * Retrieves the total number of elements submitted.
     * @param _chainId identity for the l2 chain.
     * @return _totalElements Total submitted elements.
     */
    function getTotalElementsByChainId(uint256 _chainId)
        external
        view
        returns (
            uint256 _totalElements
        );

    /**
     * Retrieves the total number of batches submitted.
     * @param _chainId identity for the l2 chain.
     * @return _totalBatches Total submitted batches.
     */
    function getTotalBatchesByChainId(uint256 _chainId)
        external
        view
        returns (
            uint256 _totalBatches
        );

    /**
     * Retrieves the timestamp of the last batch submitted by the sequencer.
     * @param _chainId identity for the l2 chain.
     * @return _lastSequencerTimestamp Last sequencer batch timestamp.
     */
    function getLastSequencerTimestampByChainId(uint256 _chainId)
        external
        view
        returns (
            uint256 _lastSequencerTimestamp
        );
        
    /**
     * Appends a batch of state roots to the chain.
     * @param _chainId identity for the l2 chain.
     * @param _batch Batch of state roots.
     * @param _shouldStartAtElement Index of the element at which this batch should start.
     */
    function appendStateBatchByChainId(
        uint256 _chainId,
        bytes32[] calldata _batch,
        uint256 _shouldStartAtElement,
        string calldata proposer
    )
        external;

    /**
     * Deletes all state roots after (and including) a given batch.
     * @param _chainId identity for the l2 chain.
     * @param _batchHeader Header of the batch to start deleting from.
     */
    function deleteStateBatchByChainId(
        uint256 _chainId,
        Lib_OVMCodec.ChainBatchHeader memory _batchHeader
    )
        external;

    /**
     * Verifies a batch inclusion proof.
     * @param _chainId identity for the l2 chain.
     * @param _element Hash of the element to verify a proof for.
     * @param _batchHeader Header of the batch in which the element was included.
     * @param _proof Merkle inclusion proof for the element.
     */
    function verifyStateCommitmentByChainId(
        uint256 _chainId,
        bytes32 _element,
        Lib_OVMCodec.ChainBatchHeader memory _batchHeader,
        Lib_OVMCodec.ChainInclusionProof memory _proof
    )
        external
        view
        returns (
            bool _verified
        );

    /**
     * Checks whether a given batch is still inside its fraud proof window.
     * @param _chainId identity for the l2 chain.
     * @param _batchHeader Header of the batch to check.
     * @return _inside Whether or not the batch is inside the fraud proof window.
     */
    function insideFraudProofWindowByChainId(
        uint256 _chainId,
        Lib_OVMCodec.ChainBatchHeader memory _batchHeader
    )
        external
        view
        returns (
            bool _inside
        );
}


// File contracts/L1/verification/IBondManager.sol

// : MIT
pragma solidity ^0.8.9;

/**
 * @title IBondManager
 */
interface IBondManager {
    /********************
     * Public Functions *
     ********************/

    function isCollateralized(address _who) external view returns (bool);
    function isCollateralizedByChainId(
        uint256 _chainId,
        address _who,
        address _prop
    ) external view returns (bool);
}


// File contracts/L1/rollup/StateCommitmentChain.sol

// : MIT
pragma solidity ^0.8.9;

/* Library Imports */



/* Interface Imports */




/**
 * @title StateCommitmentChain
 * @dev The State Commitment Chain (SCC) contract contains a list of proposed state roots which
 * Proposers assert to be a result of each transaction in the Canonical Transaction Chain (CTC).
 * Elements here have a 1:1 correspondence with transactions in the CTC, and should be the unique
 * state root calculated off-chain by applying the canonical transactions one by one.
 *
 * Runtime target: EVM
 */
contract StateCommitmentChain is IStateCommitmentChain, Lib_AddressResolver {

    /*************
     * Constants *
     *************/

    uint256 public FRAUD_PROOF_WINDOW;
    uint256 public SEQUENCER_PUBLISH_WINDOW;
    
    
    uint256 public DEFAULT_CHAINID = 1088;


    /***************
     * Constructor *
     ***************/

    /**
     * @param _libAddressManager Address of the Address Manager.
     */
    constructor(
        address _libAddressManager,
        uint256 _fraudProofWindow,
        uint256 _sequencerPublishWindow
    )
        Lib_AddressResolver(_libAddressManager)
    {
        FRAUD_PROOF_WINDOW = _fraudProofWindow;
        SEQUENCER_PUBLISH_WINDOW = _sequencerPublishWindow;
    }
    
    function setFraudProofWindow (uint256 window) public {
        require (msg.sender == resolve("METIS_MANAGER"), "now allowed");
        FRAUD_PROOF_WINDOW = window;
    }

    /********************
     * Public Functions *
     ********************/

    /**
     * Accesses the batch storage container.
     * @return Reference to the batch storage container.
     */
    function batches() public view returns (IChainStorageContainer) {
        return IChainStorageContainer(resolve("ChainStorageContainer-SCC-batches"));
    }

    /**
     * @inheritdoc IStateCommitmentChain
     */
    function getTotalElements() public view returns (uint256 _totalElements) {
        return getTotalElementsByChainId(DEFAULT_CHAINID);
    }

    /**
     * @inheritdoc IStateCommitmentChain
     */
    function getTotalBatches() public view returns (uint256 _totalBatches) {
        return getTotalBatchesByChainId(DEFAULT_CHAINID);
    }

    /**
     * @inheritdoc IStateCommitmentChain
     */
    function getLastSequencerTimestamp() public view returns (uint256 _lastSequencerTimestamp) {
        return getLastSequencerTimestampByChainId(DEFAULT_CHAINID);
    }

    /**
     * @inheritdoc IStateCommitmentChain
     */
    function appendStateBatch(bytes32[] memory _batch, uint256 _shouldStartAtElement) public {
        require (1==0, "don't use");
        //appendStateBatchByChainId(DEFAULT_CHAINID, _batch, _shouldStartAtElement, "1088_MVM_Proposer");
    }
    
    /**
     * @inheritdoc IStateCommitmentChain
     */
    function deleteStateBatch(Lib_OVMCodec.ChainBatchHeader memory _batchHeader) public {
        deleteStateBatchByChainId(DEFAULT_CHAINID, _batchHeader);
    }

    /**
     * @inheritdoc IStateCommitmentChain
     */
    function verifyStateCommitment(
        bytes32 _element,
        Lib_OVMCodec.ChainBatchHeader memory _batchHeader,
        Lib_OVMCodec.ChainInclusionProof memory _proof
    ) public view returns (bool) {
        return verifyStateCommitmentByChainId(DEFAULT_CHAINID, _element, _batchHeader, _proof);
    }

    /**
     * @inheritdoc IStateCommitmentChain
     */
    function insideFraudProofWindow(Lib_OVMCodec.ChainBatchHeader memory _batchHeader)
        public
        view
        returns (bool _inside)
    {
        (uint256 timestamp, ) = abi.decode(_batchHeader.extraData, (uint256, address));

        require(timestamp != 0, "Batch header timestamp cannot be zero");
        return (timestamp + FRAUD_PROOF_WINDOW) > block.timestamp;
    }

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Parses the batch context from the extra data.
     * @return Total number of elements submitted.
     * @return Timestamp of the last batch submitted by the sequencer.
     */
    function _getBatchExtraData() internal view returns (uint40, uint40) {
        bytes27 extraData = batches().getGlobalMetadata();

        // solhint-disable max-line-length
        uint40 totalElements;
        uint40 lastSequencerTimestamp;
        assembly {
            extraData := shr(40, extraData)
            totalElements := and(
                extraData,
                0x000000000000000000000000000000000000000000000000000000FFFFFFFFFF
            )
            lastSequencerTimestamp := shr(
                40,
                and(extraData, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000)
            )
        }
        // solhint-enable max-line-length

        return (totalElements, lastSequencerTimestamp);
    }

    /**
     * Encodes the batch context for the extra data.
     * @param _totalElements Total number of elements submitted.
     * @param _lastSequencerTimestamp Timestamp of the last batch submitted by the sequencer.
     * @return Encoded batch context.
     */
    function _makeBatchExtraData(uint40 _totalElements, uint40 _lastSequencerTimestamp)
        internal
        pure
        returns (bytes27)
    {
        bytes27 extraData;
        assembly {
            extraData := _totalElements
            extraData := or(extraData, shl(40, _lastSequencerTimestamp))
            extraData := shl(40, extraData)
        }

        return extraData;
    }

    /**
     * @inheritdoc IStateCommitmentChain
     */
    function getTotalElementsByChainId(
        uint256 _chainId
        )
        override
        public
        view
        returns (
            uint256 _totalElements
        )
    {
        (uint40 totalElements, ) = _getBatchExtraDataByChainId(_chainId);
        return uint256(totalElements);
    }

    /**
     * @inheritdoc IStateCommitmentChain
     */
    function getTotalBatchesByChainId(
        uint256 _chainId
        )
        override
        public
        view
        returns (
            uint256 _totalBatches
        )
    {
        return batches().lengthByChainId(_chainId);
    }

    /**
     * @inheritdoc IStateCommitmentChain
     */
    function getLastSequencerTimestampByChainId(
        uint256 _chainId
        )
        override
        public
        view
        returns (
            uint256 _lastSequencerTimestamp
        )
    {
        (, uint40 lastSequencerTimestamp) = _getBatchExtraDataByChainId(_chainId);
        return uint256(lastSequencerTimestamp);
    }
    
    /**
     * @inheritdoc IStateCommitmentChain
     */
    function appendStateBatchByChainId(
        uint256 _chainId,
        bytes32[] calldata _batch,
        uint256 _shouldStartAtElement,
        string calldata proposer
    )
        override
        public
    {
        // Fail fast in to make sure our batch roots aren't accidentally made fraudulent by the
        // publication of batches by some other user.
        require(
            _shouldStartAtElement == getTotalElementsByChainId(_chainId),
            "Actual batch start index does not match expected start index."
        );
        
        address proposerAddr = resolve(proposer);

        // Proposers must have previously staked at the BondManager
        require(
            IBondManager(resolve("BondManager")).isCollateralizedByChainId(_chainId,msg.sender,proposerAddr),
            "Proposer does not have enough collateral posted"
        );

        require(
            _batch.length > 0,
            "Cannot submit an empty state batch."
        );

        require(
            getTotalElementsByChainId(_chainId) + _batch.length <= ICanonicalTransactionChain(resolve("CanonicalTransactionChain")).getTotalElementsByChainId(_chainId),
            "Number of state roots cannot exceed the number of canonical transactions."
        );

        // Pass the block's timestamp and the publisher of the data
        // to be used in the fraud proofs
        _appendBatchByChainId(
            _chainId,
            _batch,
            abi.encode(block.timestamp, msg.sender),
            proposerAddr
        );
    }

    /**
     * @inheritdoc IStateCommitmentChain
     */
    function deleteStateBatchByChainId(
        uint256 _chainId,
        Lib_OVMCodec.ChainBatchHeader memory _batchHeader
    )
        override
        public
    {
        require(
            msg.sender == resolve(
              string(abi.encodePacked(uint2str(_chainId),"_MVM_FraudVerifier"))),
            "State batches can only be deleted by the MVM_FraudVerifier."
        );

        require(
            _isValidBatchHeaderByChainId(_chainId,_batchHeader),
            "Invalid batch header."
        );

        require(
            insideFraudProofWindowByChainId(_chainId,_batchHeader),
            "State batches can only be deleted within the fraud proof window."
        );

        _deleteBatchByChainId(_chainId,_batchHeader);
    }

    /**
     * @inheritdoc IStateCommitmentChain
     */
    function verifyStateCommitmentByChainId(
        uint256 _chainId,
        bytes32 _element,
        Lib_OVMCodec.ChainBatchHeader memory _batchHeader,
        Lib_OVMCodec.ChainInclusionProof memory _proof
    )
        override
        public
        view
        returns (
            bool
        )
    {
        require(
            _isValidBatchHeaderByChainId(_chainId,_batchHeader),
            "Invalid batch header."
        );

        require(
            Lib_MerkleTree.verify(
                _batchHeader.batchRoot,
                _element,
                _proof.index,
                _proof.siblings,
                _batchHeader.batchSize
            ),
            "Invalid inclusion proof."
        );

        return true;
    }

    /**
     * @inheritdoc IStateCommitmentChain
     */
    function insideFraudProofWindowByChainId(
        uint256 _chainId,
        Lib_OVMCodec.ChainBatchHeader memory _batchHeader
    )
        override
        public
        view
        returns (
            bool _inside
        )
    {
        (uint256 timestamp,) = abi.decode(
            _batchHeader.extraData,
            (uint256, address)
        );

        require(
            timestamp != 0,
            "Batch header timestamp cannot be zero"
        );
        return timestamp + FRAUD_PROOF_WINDOW > block.timestamp;
    }
    

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Parses the batch context from the extra data.
     * @return Total number of elements submitted.
     * @return Timestamp of the last batch submitted by the sequencer.
     */
    function _getBatchExtraDataByChainId(
        uint256 _chainId
        )
        internal
        view
        returns (
            uint40,
            uint40
        )
    {
        bytes27 extraData = batches().getGlobalMetadataByChainId(_chainId);

        uint40 totalElements;
        uint40 lastSequencerTimestamp;
        assembly {
            extraData              := shr(40, extraData)
            totalElements          :=         and(extraData, 0x000000000000000000000000000000000000000000000000000000FFFFFFFFFF)
            lastSequencerTimestamp := shr(40, and(extraData, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000))
        }

        return (
            totalElements,
            lastSequencerTimestamp
        );
    }

    /**
     * Encodes the batch context for the extra data.
     * @param _totalElements Total number of elements submitted.
     * @param _lastSequencerTimestamp Timestamp of the last batch submitted by the sequencer.
     * @return Encoded batch context.
     */
    function _makeBatchExtraDataByChainId(
        uint256 _chainId,
        uint40 _totalElements,
        uint40 _lastSequencerTimestamp
    )
        internal
        pure
        returns (
            bytes27
        )
    {
        bytes27 extraData;
        assembly {
            extraData := _totalElements
            extraData := or(extraData, shl(40, _lastSequencerTimestamp))
            extraData := shl(40, extraData)
        }

        return extraData;
    }

    /**
     * Appends a batch to the chain.
     * @param _batch Elements within the batch.
     * @param _extraData Any extra data to append to the batch.
     */
    function _appendBatchByChainId(
        uint256 _chainId,
        bytes32[] memory _batch,
        bytes memory _extraData,
        address proposer
    )
        internal
    {
        (uint40 totalElements, uint40 lastSequencerTimestamp) = _getBatchExtraDataByChainId(_chainId);

        if (msg.sender == proposer) {
            lastSequencerTimestamp = uint40(block.timestamp);
        } else {
            // We keep track of the last batch submitted by the sequencer so there's a window in
            // which only the sequencer can publish state roots. A window like this just reduces
            // the chance of "system breaking" state roots being published while we're still in
            // testing mode. This window should be removed or significantly reduced in the future.
            require(
                lastSequencerTimestamp + SEQUENCER_PUBLISH_WINDOW < block.timestamp,
                "Cannot publish state roots within the sequencer publication window."
            );
        }

        // For efficiency reasons getMerkleRoot modifies the `_batch` argument in place
        // while calculating the root hash therefore any arguments passed to it must not
        // be used again afterwards
        Lib_OVMCodec.ChainBatchHeader memory batchHeader = Lib_OVMCodec.ChainBatchHeader({
            batchIndex: getTotalBatchesByChainId(_chainId),
            batchRoot: Lib_MerkleTree.getMerkleRoot(_batch),
            batchSize: _batch.length,
            prevTotalElements: totalElements,
            extraData: _extraData
        });

        emit StateBatchAppended(
            _chainId,
            batchHeader.batchIndex,
            batchHeader.batchRoot,
            batchHeader.batchSize,
            batchHeader.prevTotalElements,
            batchHeader.extraData
        );

        batches().pushByChainId(
            _chainId,
            Lib_OVMCodec.hashBatchHeader(batchHeader),
            _makeBatchExtraDataByChainId(
                _chainId,
                uint40(batchHeader.prevTotalElements + batchHeader.batchSize),
                lastSequencerTimestamp
            )
        );
    }

    /**
     * Removes a batch and all subsequent batches from the chain.
     * @param _batchHeader Header of the batch to remove.
     */
    function _deleteBatchByChainId(
        uint256 _chainId,
        Lib_OVMCodec.ChainBatchHeader memory _batchHeader
    )
        internal
    {
        require(
            _batchHeader.batchIndex < batches().lengthByChainId(_chainId),
            "Invalid batch index."
        );

        require(
            _isValidBatchHeaderByChainId(_chainId,_batchHeader),
            "Invalid batch header."
        );

        batches().deleteElementsAfterInclusiveByChainId(
            _chainId,
            _batchHeader.batchIndex,
            _makeBatchExtraDataByChainId(
                _chainId,
                uint40(_batchHeader.prevTotalElements),
                0
            )
        );

        emit StateBatchDeleted(
            _chainId,
            _batchHeader.batchIndex,
            _batchHeader.batchRoot
        );
    }

    /**
     * Checks that a batch header matches the stored hash for the given index.
     * @param _batchHeader Batch header to validate.
     * @return Whether or not the header matches the stored one.
     */
    function _isValidBatchHeaderByChainId(
        uint256 _chainId,
        Lib_OVMCodec.ChainBatchHeader memory _batchHeader
    )
        internal
        view
        returns (
            bool
        )
    {
        return Lib_OVMCodec.hashBatchHeader(_batchHeader) == batches().getByChainId(_chainId,_batchHeader.batchIndex);
    }
    
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}


// File contracts/MVM/MVM_CanonicalTransaction.sol

// : MIT
pragma solidity ^0.8.9;

/* Library Imports */

/* Interface Imports */





contract MVM_CanonicalTransaction is iMVM_CanonicalTransaction, Lib_AddressResolver{
    /*************
     * Constants *
     *************/

    string constant public CONFIG_OWNER_KEY = "METIS_MANAGER";

    // lock seconds when begin to submit batch tx data slice
    uint256 constant public TXDATA_SUBMIT_TIMEOUT = 1800;

    /*************
     * Variables *
     *************/

    // submit tx data slice size (in bytes)
    uint256 public txDataSliceSize;
    // stake duration seconds for sequencer submit batch tx data
    uint256 public stakeSeqSeconds;
    // verifier stake base cost for a batch tx data requirement (in ETH)
    uint256 public stakeBaseCost;
    // submit tx data slice count (a whole tx batch)
    uint256 public txDataSliceCount;
    // submit tx batch size (in bytes)
    uint256 public txBatchSize;
    // verifier stake unit cost for a batch tx data requirement (in ETH)
    uint256 public stakeUnitCost;

    bool useWhiteList;

    /***************
     * Queue State *
     ***************/

    // white list
    mapping (address => bool) public whitelist;

    // mapping(address => uint256) private addressChains;

    // verifier stakes statistic
    mapping(address => uint256) private verifierStakes;

    // batch element information for validation queue
    mapping(uint256 => mapping(uint256 => BatchElement)) queueBatchElement;

    // tx data request stake queue
    mapping(uint256 => mapping(uint256 => TxDataRequestStake)) queueTxDataRequestStake;

    // tx data for verification queue
    mapping(uint256 => mapping(uint256 => TxDataSlice)) queueTxData;

    /***************
     * Constructor *
     ***************/

    constructor() Lib_AddressResolver(address(0)) {}

    /**********************
     * Function Modifiers *
     **********************/

    modifier onlyManager {
        require(
            msg.sender == resolve(CONFIG_OWNER_KEY),
            "MVM_CanonicalTransaction: Function can only be called by the METIS_MANAGER."
        );
        _;
    }

    modifier onlyWhitelisted {
        require(isWhiteListed(msg.sender), "only whitelisted verifiers can call");
        _;
    }

    /********************
     * Public Functions *
     ********************/
    /**
    receive() external payable {
        // msg.sender
        if (msg.sender == resolve('MVM_DiscountOracle')) {
            uint256 _chainId = getAddressChainId(msg.sender);
            if (_chainId > 0) {
                address _to = resolve(string(abi.encodePacked(uint2str(_chainId),"_MVM_Sequencer_Wrapper")));
                if (_to != address(0) && _to != address(this)) {
                    _to.call{value: msg.value}("");
                }
            }
        }
    }

    function setAddressChainId(address _address, uint256 _chainId)  override public onlyManager {
        require(_address != address(0), "address not available");
        require(_chainId > 0, "chainId not available");
        require(addressChains[_address] != _chainId, "no change");
        addressChains[_address] = _chainId;
    }

    function getAddressChainId(address _address) override public view returns (uint256) {
        return addressChains[_address];
    }
    */

    function setStakeBaseCost(uint256 _stakeBaseCost) override public onlyManager {
        // 1e16 = 0.01 ether
        // require(_stakeBaseCost >= 1e16, "stake base cost should gte 1e16");
        stakeBaseCost = _stakeBaseCost;
    }

    function getStakeBaseCost() override public view returns (uint256) {
        return stakeBaseCost;
    }

    function setStakeUnitCost(uint256 _stakeUnitCost) override public onlyManager {
        // 1e16 = 0.01 ether
        stakeUnitCost = _stakeUnitCost;
    }

    function getStakeUnitCost() override public view returns (uint256) {
        return stakeUnitCost;
    }

    function getStakeCostByBatch(uint256 _chainId, uint256 _batchIndex) override public view returns (uint256) {
        require(stakeBaseCost > 0, "stake base cost not config yet");
        require(queueBatchElement[_chainId][_batchIndex].txBatchTime > 0, "batch element does not exist");
        return stakeBaseCost + queueBatchElement[_chainId][_batchIndex].txBatchSize * stakeUnitCost;
    }

    function setTxDataSliceSize(uint256 _size) override public onlyManager {
        require(_size > 0, "slice size should gt 0");
        require(_size != txDataSliceSize, "slice size has not changed");
        txDataSliceSize = _size;
    }

    function getTxDataSliceSize() override public view returns (uint256) {
        return txDataSliceSize;
    }

    function setTxDataSliceCount(uint256 _count) override public onlyManager {
        require(_count > 0, "slice count should gt 0");
        require(_count != txDataSliceCount, "slice count has not changed");
        txDataSliceCount = _count;
    }

    function getTxDataSliceCount() override public view returns (uint256) {
        return txDataSliceCount;
    }

    function setTxBatchSize(uint256 _size) override public onlyManager {
        require(_size > 0, "batch size should gt 0");
        require(_size != txBatchSize, "batch size has not changed");
        txBatchSize = _size;
    }

    function getTxBatchSize() override public view returns (uint256) {
        return txBatchSize;
    }

    function setStakeSeqSeconds(uint256 _seconds) override public onlyManager {
        require(_seconds > 0, "seconds should gt 0");
        require(_seconds != stakeSeqSeconds, "seconds has not changed");
        stakeSeqSeconds = _seconds;
    }

    function getStakeSeqSeconds() override public view returns (uint256) {
        return stakeSeqSeconds;
    }

    function isWhiteListed(address _verifier) override public view returns(bool){
        return !useWhiteList || whitelist[_verifier];
    }

    function setWhiteList(address _verifier, bool _allowed) override public onlyManager {
        whitelist[_verifier] = _allowed;
        useWhiteList = true;
    }

    function disableWhiteList() override public onlyManager {
        useWhiteList = false;
    }

    function appendSequencerBatchByChainId() override public {
        uint256 _chainId;
        uint40 shouldStartAtElement;
        uint24 totalElementsToAppend;
        uint24 numContexts;
        uint256 batchTime;
        uint256 _dataSize;
        uint256 txSize;
        bytes32 root;
        assembly {
            _dataSize             := calldatasize()
            _chainId              := calldataload(4)
            shouldStartAtElement  := shr(216, calldataload(36))
            totalElementsToAppend := shr(232, calldataload(41))
            numContexts           := shr(232, calldataload(44))
        }
        require(
            msg.sender == resolve(string(abi.encodePacked(uint2str(_chainId),"_MVM_Sequencer_Wrapper"))),
            "Function can only be called by the Sequencer."
        );
        uint256 posTs =  47 + 16 * numContexts;
        if (_dataSize > posTs) {
            // when tx count = 0, there is no hash!
            // string len: [13]{milliseconds}-[1]{0}-[8]{sizeOfData}-[64]{hash}-[64]{root}
            uint256 posTxSize = 7 + posTs;
            uint256 posRoot =  11 + posTs;
            assembly {
                batchTime := shr(204, calldataload(posTs))
                txSize := shr(224, calldataload(posTxSize))
                root := calldataload(posRoot)
            }

            // check batch size
            require(txSize / 2 <= txBatchSize, "size of tx data is too large");
        }

        address ctc = resolve("CanonicalTransactionChain");
        IChainStorageContainer batchesRef = ICanonicalTransactionChain(ctc).batches();
        uint256 batchIndex = batchesRef.lengthByChainId(_chainId);
        {
            // ctc call
            (bool success, bytes memory result) = ctc.call(msg.data);
            if (success == false) {
                assembly {
                    let ptr := mload(0x40)
                    let size := returndatasize()
                    returndatacopy(ptr, 0, size)
                    revert(ptr, size)
                }
            }
        }

        // save
        queueBatchElement[_chainId][batchIndex] = BatchElement({
            shouldStartAtElement:  shouldStartAtElement,
            totalElementsToAppend: totalElementsToAppend,
            txBatchSize:           txSize,
            txBatchTime:           batchTime,
            root:                  root,
            timestamp:             block.timestamp
        });

        emit AppendBatchElement(
            _chainId,
            batchIndex,
            shouldStartAtElement,
            totalElementsToAppend,
            txSize,
            batchTime,
            root
        );
    }

    function setBatchTxDataForStake(
        uint256 _chainId,
        uint256 _batchIndex,
        uint256 _blockNumber,
        bytes memory _data,
        uint256 _leafIndex,
        uint256 _totalLeaves,
        bytes32[] memory _proof
    )
        override
        public
    {
        require(
            msg.sender == resolve(string(abi.encodePacked(uint2str(_chainId),"_MVM_Sequencer_Wrapper"))),
            "Function can only be called by the Sequencer."
        );
        // check stake
        require(queueTxDataRequestStake[_chainId][_blockNumber].timestamp > 0, "there is no stake for this block number");
        require(queueTxDataRequestStake[_chainId][_blockNumber].batchIndex == _batchIndex, "incorrect batch index");
        require(queueTxDataRequestStake[_chainId][_blockNumber].status == STAKESTATUS.INIT, "not allowed to submit");
        // sequencer can submit at any time
        // require(queueTxDataRequestStake[_chainId][_blockNumber].endtime >= block.timestamp, "can not submit out of sequencer submit protection");

        _setBatchTxData(_chainId, _batchIndex, _blockNumber, _data, _leafIndex, _totalLeaves,  _proof,  true);

        if (queueTxDataRequestStake[_chainId][_blockNumber].status == STAKESTATUS.INIT) {
            require(
                queueTxDataRequestStake[_chainId][_blockNumber].amount <= verifierStakes[queueTxDataRequestStake[_chainId][_blockNumber].sender],
                "insufficient stake"
            );
            require(
                queueTxDataRequestStake[_chainId][_blockNumber].amount <= address(this).balance,
                "insufficient balance"
            );
            queueTxDataRequestStake[_chainId][_blockNumber].status = STAKESTATUS.SEQ_SET;
            if (queueTxDataRequestStake[_chainId][_blockNumber].amount > 0){
                verifierStakes[queueTxDataRequestStake[_chainId][_blockNumber].sender] -= queueTxDataRequestStake[_chainId][_blockNumber].amount;
                // transfer from contract to sender ETHER and record
                (bool success, ) = payable(msg.sender).call{value: queueTxDataRequestStake[_chainId][_blockNumber].amount}("");
                require(success, "insufficient balance");
                queueTxDataRequestStake[_chainId][_blockNumber].amount = 0;
            }
        }

        emit SetBatchTxData(
            msg.sender,
            _chainId,
            _batchIndex,
            _blockNumber,
            queueTxDataRequestStake[_chainId][_blockNumber].amount,
            true,
            true
        );
    }

    function setBatchTxDataForVerifier(
        uint256 _chainId,
        uint256 _batchIndex,
        uint256 _blockNumber,
        bytes memory _data
    )
        override
        public
    {
         require(
            msg.sender != resolve(string(abi.encodePacked(uint2str(_chainId),"_MVM_Sequencer_Wrapper"))),
            "Function can not be called by the Sequencer."
        );
        // check stake
        require(queueTxDataRequestStake[_chainId][_blockNumber].timestamp > 0, "there is no stake for this block number");
        require(queueTxDataRequestStake[_chainId][_blockNumber].batchIndex == _batchIndex, "incorrect batch index");
        // require(queueTxDataRequestStake[_chainId][_blockNumber].status == STAKESTATUS.INIT, "not allowed to submit");
        // require(queueTxDataRequestStake[_chainId][_blockNumber].sender == msg.sender, "can not submit with other's stake");
        require(queueTxDataRequestStake[_chainId][_blockNumber].endtime < block.timestamp, "can not submit during sequencer submit protection");
        if (queueTxDataRequestStake[_chainId][_blockNumber].sender != msg.sender) {
            // other verifier can submit in double window times
            require(queueTxDataRequestStake[_chainId][_blockNumber].endtime + stakeSeqSeconds < block.timestamp, "can not submit during staker submit protection");
        }

        _setBatchTxData(_chainId, _batchIndex, _blockNumber, _data, 0, 0, new bytes32[](0), false);

        if (queueTxDataRequestStake[_chainId][_blockNumber].status == STAKESTATUS.INIT) {
            queueTxDataRequestStake[_chainId][_blockNumber].status = STAKESTATUS.VERIFIER_SET;

            address claimer = queueTxDataRequestStake[_chainId][_blockNumber].sender;
            if (queueTxDataRequestStake[_chainId][_blockNumber].amount <= verifierStakes[claimer] && queueTxDataRequestStake[_chainId][_blockNumber].amount > 0) {
                require(
                    queueTxDataRequestStake[_chainId][_blockNumber].amount <= address(this).balance,
                    "insufficient balance"
                );
                verifierStakes[claimer] -= queueTxDataRequestStake[_chainId][_blockNumber].amount;
                // transfer from contract to sender ETHER and record
                (bool success, ) = payable(claimer).call{value: queueTxDataRequestStake[_chainId][_blockNumber].amount}("");
                require(success, "insufficient balance");
                queueTxDataRequestStake[_chainId][_blockNumber].amount = 0;
            }
        }

        emit SetBatchTxData(
            msg.sender,
            _chainId,
            _batchIndex,
            _blockNumber,
            queueTxDataRequestStake[_chainId][_blockNumber].amount,
            false,
            false
        );
    }

    function _setBatchTxData(
        uint256 _chainId,
        uint256 _batchIndex,
        uint256 _blockNumber,
        bytes memory _data,
        uint256 _leafIndex,
        uint256 _totalLeaves,
        bytes32[] memory _proof,
        bool _requireVerify
    )
        internal
    {
        require(_data.length > 0, "empty data");
        // check queue BatchElement
        require(queueBatchElement[_chainId][_batchIndex].txBatchTime > 0, "batch element does not exist");
        require(queueBatchElement[_chainId][_batchIndex].totalElementsToAppend > 0, "batch total element to append should not be zero");
       
        // sequencer protect
        if (queueTxData[_chainId][_blockNumber].timestamp > 0) {
            require(queueTxData[_chainId][_blockNumber].verified == false, "tx data verified");
            if (queueTxData[_chainId][_blockNumber].sender != msg.sender) {
                require(queueTxData[_chainId][_blockNumber].timestamp + TXDATA_SUBMIT_TIMEOUT > block.timestamp, "in submitting");

                // change sumbitter
                queueTxData[_chainId][_blockNumber].sender = msg.sender;
                queueTxData[_chainId][_blockNumber].blockNumber = _blockNumber;
                queueTxData[_chainId][_blockNumber].batchIndex = _batchIndex;
                queueTxData[_chainId][_blockNumber].timestamp = block.timestamp;
                queueTxData[_chainId][_blockNumber].txData = _data;
                queueTxData[_chainId][_blockNumber].verified = false;
            }
            else {
                queueTxData[_chainId][_blockNumber].txData = _data;
                // verified restore to false
                queueTxData[_chainId][_blockNumber].verified = false;
            }
        }
        else {
            queueTxData[_chainId][_blockNumber] = TxDataSlice({
                sender:         msg.sender,
                blockNumber:    _blockNumber,
                batchIndex:    _batchIndex,
                timestamp:      block.timestamp,
                txData:         _data,
                verified:       false
            });
        }
        if (_requireVerify) {
            bytes32 currLeaf = keccak256(abi.encodePacked(_blockNumber, _data));
            bool verified = Lib_MerkleTree.verify(queueBatchElement[_chainId][_batchIndex].root, currLeaf, _leafIndex, _proof, _totalLeaves);
            require(verified == true, "tx data verify failed");

            // save verified status
            queueTxData[_chainId][_blockNumber].verified = true;
        }
    }

    function getBatchTxData(
        uint256 _chainId,
        uint256 _batchIndex,
        uint256 _blockNumber
    )
        override
        external
        view
        returns (
            bytes memory txData,
            bool verified
        )
    {
        require(queueTxData[_chainId][_blockNumber].timestamp != 0, "tx data does not exist");
        require(queueTxData[_chainId][_blockNumber].batchIndex == _batchIndex, "incorrect batch index");
        return (
            queueTxData[_chainId][_blockNumber].txData,
            queueTxData[_chainId][_blockNumber].verified
        );
    }

    function checkBatchTxHash(
        uint256 _chainId,
        uint256 _batchIndex,
        uint256 _blockNumber,
        bytes memory _data
    )
        override
        external
        view
        returns (
            bytes32 txHash,
            bool verified
        )
    {
        require(queueTxData[_chainId][_blockNumber].timestamp != 0, "tx data does not exist");
        require(queueTxData[_chainId][_blockNumber].batchIndex == _batchIndex, "incorrect batch index");
        return (
            keccak256(abi.encodePacked(_blockNumber, _data)),
            queueTxData[_chainId][_blockNumber].verified
        );
    }

    function setBatchTxDataVerified(
        uint256 _chainId,
        uint256 _batchIndex,
        uint256 _blockNumber,
        bool _verified
    )
        override
        public
        onlyManager
    {
        require(queueTxData[_chainId][_blockNumber].timestamp != 0, "tx data does not exist");
        require(queueTxData[_chainId][_blockNumber].batchIndex == _batchIndex, "incorrect batch index");
        require(queueTxData[_chainId][_blockNumber].verified != _verified, "verified status not change");

        queueTxData[_chainId][_blockNumber].verified = _verified;
    }

    function verifierStake(
        uint256 _chainId,
        uint256 _batchIndex,
        uint256 _blockNumber
    )
        override
        public
        payable
        onlyWhitelisted
    {
        uint256 _amount = msg.value;
        uint256 stakeCost = getStakeCostByBatch(_chainId, _batchIndex);
        require(stakeBaseCost > 0, "stake base cost not config yet");
        require(stakeCost == _amount, "stake cost incorrect");
        require(stakeSeqSeconds > 0, "sequencer submit seconds not config yet");
        // check queue BatchElement
        require(queueBatchElement[_chainId][_batchIndex].txBatchTime > 0, "batch element does not exist");
        // check block number in batch range, block number = index + 1
        require(queueBatchElement[_chainId][_batchIndex].totalElementsToAppend + queueBatchElement[_chainId][_batchIndex].shouldStartAtElement >= _blockNumber && queueBatchElement[_chainId][_batchIndex].shouldStartAtElement < _blockNumber, "block number is not in this batch");
        if (queueTxDataRequestStake[_chainId][_blockNumber].timestamp > 0) {
            require(queueTxDataRequestStake[_chainId][_blockNumber].status == STAKESTATUS.PAYBACK, "there is a stake for this batch index");
        }

        //check window
        StateCommitmentChain stateChain = StateCommitmentChain(resolve("StateCommitmentChain"));
        require(queueBatchElement[_chainId][_batchIndex].timestamp + stateChain.FRAUD_PROOF_WINDOW() > block.timestamp, "the batch is outside of the fraud proof window");

        queueTxDataRequestStake[_chainId][_blockNumber] = TxDataRequestStake({
            sender:      msg.sender,
            blockNumber: _blockNumber,
            batchIndex:  _batchIndex,
            timestamp:   block.timestamp,
            endtime:     block.timestamp + stakeSeqSeconds,
            amount:      _amount,
            status:      STAKESTATUS.INIT
        });
        verifierStakes[msg.sender] += _amount;

        emit VerifierStake(msg.sender, _chainId, _batchIndex, _blockNumber, _amount);
    }

    function withdrawStake(
        uint256 _chainId,
        uint256 _batchIndex,
        uint256 _blockNumber
    )
        override
        public
    {
        require(queueTxDataRequestStake[_chainId][_blockNumber].timestamp > 0, "there is no stake for this batch index");
        require(queueTxDataRequestStake[_chainId][_blockNumber].amount > 0, "stake amount is zero");
        require(queueTxDataRequestStake[_chainId][_blockNumber].status == STAKESTATUS.INIT, "withdrawals are not allowed");
        require(queueTxDataRequestStake[_chainId][_blockNumber].sender == msg.sender, "can not withdraw other's stake");
        require(queueTxDataRequestStake[_chainId][_blockNumber].endtime < block.timestamp, "can not withdraw during submit protection");
        require(queueTxDataRequestStake[_chainId][_blockNumber].amount <= verifierStakes[msg.sender], "insufficient stake");

        require(
            queueTxDataRequestStake[_chainId][_blockNumber].amount <= address(this).balance,
            "insufficient balance"
        );
        queueTxDataRequestStake[_chainId][_blockNumber].status = STAKESTATUS.PAYBACK;
        verifierStakes[msg.sender] -= queueTxDataRequestStake[_chainId][_blockNumber].amount;
        // transfer from contract to sender ETHER and record
        (bool success, ) = payable(msg.sender).call{value: queueTxDataRequestStake[_chainId][_blockNumber].amount}("");
        require(success, "insufficient balance");
        queueTxDataRequestStake[_chainId][_blockNumber].amount = 0;
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}