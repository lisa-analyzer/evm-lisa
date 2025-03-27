/**
 *Submitted for verification at Etherscan.io on 2022-04-27
*/

// Sources flattened with hardhat v2.6.1 https://hardhat.org

// File @openzeppelin/contracts/utils/Context.sol@v4.3.2

//  SPDX-License-Identifier: MIT

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

//   MIT

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


// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v4.3.2

//   MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/MVM/iMVM_DiscountOracle.sol

//   MIT
pragma solidity ^0.8.9;

interface iMVM_DiscountOracle{

    function setDiscount(
        uint256 _discount
    ) external;
    
    function setMinL2Gas(
        uint256 _minL2Gas
    ) external;
    
    function setWhitelistedXDomainSender(
        address _sender,
        bool _isWhitelisted
    ) external;
    
    function isXDomainSenderAllowed(
        address _sender
    ) view external returns(bool);
    
    function setAllowAllXDomainSenders(
        bool _allowAllXDomainSenders
    ) external;
    
    function getMinL2Gas() view external returns(uint256);
    function getDiscount() view external returns(uint256);
    function processL2SeqGas(address sender, uint256 _chainId) external payable;
}


// File contracts/libraries/resolver/Lib_AddressManager.sol

//   MIT
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

//   MIT
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


// File contracts/libraries/rlp/Lib_RLPReader.sol

//   MIT
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

//   MIT
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

//   MIT
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

//   MIT
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

//   MIT
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


// File contracts/libraries/utils/Lib_MerkleTree.sol

//   MIT
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


// File contracts/L1/rollup/IChainStorageContainer.sol

//   MIT
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


// File contracts/L1/rollup/IStateCommitmentChain.sol

//   MIT
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


// File contracts/MVM/MVM_Verifier.sol

//   MIT
pragma solidity ^0.8.9;
/* Contract Imports */
/* External Imports */







contract MVM_Verifier is Lib_AddressResolver{
    // second slot
    address public metis;

    enum SETTLEMENT {NOT_ENOUGH_VERIFIER, SAME_ROOT, AGREE, DISAGREE, PASS}

    event NewChallenge(uint256 cIndex, uint256 chainID, Lib_OVMCodec.ChainBatchHeader header, uint256 timestamp);
    event Verify1(uint256 cIndex, address verifier);
    event Verify2(uint256 cIndex, address verifier);
    event Finalize(uint256 cIndex, address sender, SETTLEMENT result);
    event Penalize(address sender, uint256 stakeLost);
    event Reward(address target, uint256 amount);
    event Claim(address sender, uint256 amount);
    event Withdraw(address sender, uint256 amount);
    event Stake(address verifier, uint256 amount);
    event SlashSequencer(uint256 chainID, address seq);

    /*************
     * Constants *
     *************/
    string constant public CONFIG_OWNER_KEY = "METIS_MANAGER";

    //challenge info
    struct Challenge {
       address challenger;
       uint256 chainID;
       uint256 index;
       Lib_OVMCodec.ChainBatchHeader header;
       uint256 timestamp;
       uint256 numQualifiedVerifiers;
       uint256 numVerifiers;
       address[] verifiers;
       bool done;
    }

    mapping (address => uint256) public verifier_stakes;
    mapping (uint256 => mapping (address=>bytes)) private challenge_keys;
    mapping (uint256 => mapping (address=>bytes)) private challenge_key_hashes;
    mapping (uint256 => mapping (address=>bytes)) private challenge_hashes;

    mapping (address => uint256) public rewards;
    mapping (address => uint8) public absence_strikes;
    mapping (address => uint8) public consensus_strikes;

    // only one active challenge for each chain  chainid=>cIndex
    mapping (uint256 => uint256) public chain_under_challenge;

    // white list
    mapping (address => bool) public whitelist;
    bool useWhiteList;

    address[] public verifiers;
    Challenge[] public challenges;

    uint public verifyWindow = 3600 * 24; // 24 hours of window to complete the each verify phase
    uint public activeChallenges;

    uint256 public minStake;
    uint256 public seqStake;

    uint256 public numQualifiedVerifiers;

    uint FAIL_THRESHOLD = 2;  // 1 time grace
    uint ABSENCE_THRESHOLD = 4;  // 2 times grace

    modifier onlyManager {
        require(
            msg.sender == resolve(CONFIG_OWNER_KEY),
            "MVM_Verifier: Function can only be called by the METIS_MANAGER."
        );
        _;
    }

    modifier onlyWhitelisted {
        require(isWhiteListed(msg.sender), "only whitelisted verifiers can call");
        _;
    }

    modifier onlyStaked {
        require(isSufficientlyStaked(msg.sender), "insufficient stake");
        _;
    }

    constructor(
    )
      Lib_AddressResolver(address(0))
    {
    }

    // add stake as a verifier
    function verifierStake(uint256 stake) public onlyWhitelisted{
       require(activeChallenges == 0, "stake is currently prohibited"); //ongoing challenge
       require(stake > 0, "zero stake not allowed");
       require(IERC20(metis).transferFrom(msg.sender, address(this), stake), "transfer metis failed");

       uint256 previousBalance = verifier_stakes[msg.sender];
       verifier_stakes[msg.sender] += stake;

       require(isSufficientlyStaked(msg.sender), "insufficient stake to qualify as a verifier");

       if (previousBalance == 0) {
          numQualifiedVerifiers++;
          verifiers.push(msg.sender);
       }

       emit Stake(msg.sender, stake);
    }

    // start a new challenge
    // @param chainID chainid
    // @param header chainbatch header
    // @param proposedHash encrypted hash of the correct state
    // @param keyhash hash of the decryption key
    //
    // @dev why do we ask for key and keyhash? because we want verifiers compute the state instead
    // of just copying from other verifiers.
    function newChallenge(uint256 chainID, Lib_OVMCodec.ChainBatchHeader calldata header, bytes calldata proposedHash, bytes calldata keyhash)
       public onlyWhitelisted onlyStaked {

       uint tempIndex = chain_under_challenge[chainID] - 1;
       require(tempIndex == 0 || block.timestamp - challenges[tempIndex].timestamp > verifyWindow * 2, "there is an ongoing challenge");
       if (tempIndex > 0) {
          finalize(tempIndex);
       }
       IStateCommitmentChain stateChain = IStateCommitmentChain(resolve("StateCommitmentChain"));

       // while the root is encrypted, the timestamp is available in the extradata field of the header
       require(stateChain.insideFraudProofWindow(header), "the batch is outside of the fraud proof window");

       Challenge memory c;
       c.chainID = chainID;
       c.challenger = msg.sender;
       c.timestamp = block.timestamp;
       c.header = header;

       challenges.push(c);
       uint cIndex = challenges.length - 1;

       // house keeping
       challenge_hashes[cIndex][msg.sender] = proposedHash;
       challenge_key_hashes[cIndex][msg.sender] = keyhash;
       challenges[cIndex].numVerifiers++; // the challenger

       // this will prevent stake change
       activeChallenges++;

       chain_under_challenge[chainID] = cIndex + 1; // +1 because 0 means no in-progress challenge
       emit NewChallenge(cIndex, chainID, header, block.timestamp);
    }

    // phase 1 of the verify, provide an encrypted hash and the hash of the decryption key
    // @param cIndex index of the challenge
    // @param hash encrypted hash of the correct state (for the index referred in the challenge)
    // @param keyhash hash of the decryption key
    function verify1(uint256 cIndex, bytes calldata hash, bytes calldata keyhash) public onlyWhitelisted onlyStaked{
       require(challenge_hashes[cIndex][msg.sender].length == 0, "verify1 already completed for the sender");
       challenge_hashes[cIndex][msg.sender] = hash;
       challenge_key_hashes[cIndex][msg.sender] = keyhash;
       challenges[cIndex].numVerifiers++;
       emit Verify1(cIndex, msg.sender);
    }

    // phase 2 of the verify, provide the actual key to decrypt the hash
    // @param cIndex index of the challenge
    // @param key the decryption key
    function verify2(uint256 cIndex, bytes calldata key) public onlyStaked onlyWhitelisted{
        require(challenges[cIndex].numVerifiers == numQualifiedVerifiers
               || block.timestamp - challenges[cIndex].timestamp > verifyWindow, "phase 2 not ready");
        require(challenge_hashes[cIndex][msg.sender].length > 0, "you didn't participate in phase 1");
        if (challenge_keys[cIndex][msg.sender].length > 0) {
            finalize(cIndex);
            return;
        }

        //verify whether the key matches the keyhash initially provided.
        require(sha256(key) == bytes32(challenge_key_hashes[cIndex][msg.sender]), "key and keyhash don't match");

        if (msg.sender == challenges[cIndex].challenger) {
            //decode the root in the header too
            challenges[cIndex].header.batchRoot = bytes32(decrypt(abi.encodePacked(challenges[cIndex].header.batchRoot), key));
        }
        challenge_keys[cIndex][msg.sender] = key;
        challenge_hashes[cIndex][msg.sender] = decrypt(challenge_hashes[cIndex][msg.sender], key);
        challenges[cIndex].verifiers.push(msg.sender);
        emit Verify2(cIndex, msg.sender);

        finalize(cIndex);
    }

    function finalize(uint256 cIndex) internal {

        Challenge storage challenge = challenges[cIndex];

        require(challenge.done == false, "challenge is closed");

        if (challenge.verifiers.length != challenge.numVerifiers
           && block.timestamp - challenge.timestamp < verifyWindow * 2) {
           // not ready to finalize. do nothing
           return;
        }

        IStateCommitmentChain stateChain = IStateCommitmentChain(resolve("StateCommitmentChain"));
        bytes32 proposedHash = bytes32(challenge_hashes[cIndex][challenge.challenger]);

        uint reward = 0;

        address[] memory agrees = new address[](challenge.verifiers.length);
        uint numAgrees = 0;
        address[] memory disagrees = new address[](challenge.verifiers.length);
        uint numDisagrees = 0;

        for (uint256 i = 0; i < verifiers.length; i++) {
            if (!isSufficientlyStaked(verifiers[i]) || !isWhiteListed(verifiers[i])) {
                // not qualified as a verifier
                continue;
            }

            //record the agreement
            if (bytes32(challenge_hashes[cIndex][verifiers[i]]) == proposedHash) {
                //agree with the challenger
                if (absence_strikes[verifiers[i]] > 0) {
                    absence_strikes[verifiers[i]] -= 1; // slowly clear the strike
                }
                agrees[numAgrees] = verifiers[i];
                numAgrees++;
            } else if (challenge_keys[cIndex][verifiers[i]].length == 0) {
                //absent
                absence_strikes[verifiers[i]] += 2;
                if (absence_strikes[verifiers[i]] > ABSENCE_THRESHOLD) {
                    reward += penalize(verifiers[i]);
                }
            } else {
                //disagree with the challenger
                if (absence_strikes[verifiers[i]] > 0) {
                    absence_strikes[verifiers[i]] -= 1; // slowly clear the strike
                }
                disagrees[numDisagrees] = verifiers[i];
                numDisagrees++;
            }
        }

        if (Lib_OVMCodec.hashBatchHeader(challenge.header) !=
                stateChain.batches().getByChainId(challenge.chainID, challenge.header.batchIndex)) {
            // wrong header, penalize the challenger
            reward += penalize(challenge.challenger);

            // reward the disagrees. but no penalty on agrees because the input
            // is garbage.
            distributeReward(reward, disagrees, challenge.verifiers.length - 1);
            emit Finalize(cIndex, msg.sender, SETTLEMENT.DISAGREE);

        } else if (challenge.verifiers.length < numQualifiedVerifiers * 75 / 100) {
            // the absent verifiers get a absense strike. no other penalties. already done
            emit Finalize(cIndex, msg.sender, SETTLEMENT.NOT_ENOUGH_VERIFIER);
        }
        else if (proposedHash != challenge.header.batchRoot) {
            if (numAgrees <= numDisagrees) {
               // no consensus, challenge failed.
               for (uint i = 0; i < numAgrees; i++) {
                    consensus_strikes[agrees[i]] += 2;
                    if (consensus_strikes[agrees[i]] > FAIL_THRESHOLD) {
                        reward += penalize(agrees[i]);
                    }
               }
               distributeReward(reward, disagrees, disagrees.length);
               emit Finalize(cIndex, msg.sender, SETTLEMENT.DISAGREE);
            } else {
               // reached agreement. delete the batch root and slash the sequencer if the header is still valid
               if(stateChain.insideFraudProofWindow(challenge.header)) {
                    // this header needs to be within the window
                    stateChain.deleteStateBatchByChainId(challenge.chainID, challenge.header);

                    // temporary for the p1 of the decentralization roadmap
                    if (seqStake > 0) {
                        reward += seqStake;

                        for (uint i = 0; i < numDisagrees; i++) {
                            consensus_strikes[disagrees[i]] += 2;
                            if (consensus_strikes[disagrees[i]] > FAIL_THRESHOLD) {
                                reward += penalize(disagrees[i]);
                            }
                        }
                        distributeReward(reward, agrees, agrees.length);
                    }
                    emit Finalize(cIndex, msg.sender, SETTLEMENT.AGREE);
                } else {
                    //not in the window anymore. let it pass... no penalty
                    emit Finalize(cIndex, msg.sender, SETTLEMENT.PASS);
                }
            }
        } else {
            //wasteful challenge, add consensus_strikes to the challenger
            consensus_strikes[challenge.challenger] += 2;
            if (consensus_strikes[challenge.challenger] > FAIL_THRESHOLD) {
                reward += penalize(challenge.challenger);
            }
            distributeReward(reward, challenge.verifiers, challenge.verifiers.length - 1);
            emit Finalize(cIndex, msg.sender, SETTLEMENT.SAME_ROOT);
        }

        challenge.done = true;
        activeChallenges--;
        chain_under_challenge[challenge.chainID] = 0;
    }

    function depositSeqStake(uint256 amount) public onlyManager {
        require(IERC20(metis).transferFrom(msg.sender, address(this), amount), "transfer metis failed");
        seqStake += amount;
        emit Stake(msg.sender, amount);
    }

    function withdrawSeqStake(address to) public onlyManager {
        require(seqStake > 0, "no stake");
        emit Withdraw(msg.sender, seqStake);
        uint256 amount = seqStake;
        seqStake = 0;

        require(IERC20(metis).transfer(to, amount), "transfer metis failed");
    }

    function claim() public {
       require(rewards[msg.sender] > 0, "no reward to claim");
       uint256 amount = rewards[msg.sender];
       rewards[msg.sender] = 0;

       require(IERC20(metis).transfer(msg.sender, amount), "token transfer failed");

       emit Claim(msg.sender, amount);
    }

    function withdraw(uint256 amount) public {
       require(activeChallenges == 0, "withdraw is currently prohibited"); //ongoing challenge

       uint256 balance = verifier_stakes[msg.sender];
       require(balance >= amount, "insufficient stake to withdraw");

       if (balance - amount < minStake && balance >= minStake) {
           numQualifiedVerifiers--;
           deleteVerifier(msg.sender);
       }
       verifier_stakes[msg.sender] -= amount;

       require(IERC20(metis).transfer(msg.sender, amount), "token transfer failed");
    }

    function setMinStake(
        uint256 _minStake
    )
        public
        onlyManager
    {
        minStake = _minStake;
        uint num = 0;
        if (verifiers.length > 0) {
            address[] memory arr = new address[](verifiers.length);
            for (uint i = 0; i < verifiers.length; ++i) {
                if (verifier_stakes[verifiers[i]] >= minStake) {
                    arr[num] = verifiers[i];
                    num++;
                }
            }
            if (num < verifiers.length) {
                delete verifiers;
                for (uint i = 0; i < num; i++) {
                    verifiers.push(arr[i]);
                }
            }
        }
        numQualifiedVerifiers = num;
    }

    // helper
    function isWhiteListed(address verifier) view public returns(bool){
        return !useWhiteList || whitelist[verifier];
    }
    function isSufficientlyStaked (address target) view public returns(bool) {
       return (verifier_stakes[target] >= minStake);
    }

    // set the length of the time windows for each verification phase
    function setVerifyWindow (uint256 window) onlyManager public {
        verifyWindow = window;
    }

    // add the verifier to the whitelist
    function setWhiteList(address verifier, bool allowed) public onlyManager {
        whitelist[verifier] = allowed;
        useWhiteList = true;
    }

    // allow everyone to be the verifier
    function disableWhiteList() public onlyManager {
        useWhiteList = false;
    }

    function setThreshold(uint absence_threshold, uint fail_threshold) public onlyManager {
        ABSENCE_THRESHOLD = absence_threshold;
        FAIL_THRESHOLD = fail_threshold;
    }

    function getMerkleRoot(bytes32[] calldata elements) pure public returns (bytes32) {
        return Lib_MerkleTree.getMerkleRoot(elements);
    }

    //helper fucntion to encrypt data
    function encrypt(bytes calldata data, bytes calldata key) pure public returns (bytes memory) {
      bytes memory encryptedData = data;
      uint j = 0;

      for (uint i = 0; i < encryptedData.length; i++) {
          if (j == key.length) {
             j = 0;
          }
          encryptedData[i] = encryptByte(encryptedData[i], uint8(key[j]));
          j++;
      }

      return encryptedData;
    }

    function encryptByte(bytes1 b, uint8 k) pure internal returns (bytes1) {
      uint16 temp16 = uint16(uint8(b));
      temp16 += k;

      if (temp16 > 255) {
         temp16 -= 256;
      }
      return bytes1(uint8(temp16));
    }

    // helper fucntion to decrypt the data
    function decrypt(bytes memory data, bytes memory key) pure public returns (bytes memory) {
      bytes memory decryptedData = data;
      uint j = 0;

      for (uint i = 0; i < decryptedData.length; i++) {
          if (j == key.length) {
             j = 0;
          }

          decryptedData[i] = decryptByte(decryptedData[i], uint8(key[j]));

          j++;
      }

      return decryptedData;
    }

    function decryptByte(bytes1 b, uint8 k) pure internal returns (bytes1) {
      uint16 temp16 = uint16(uint8(b));
      if (temp16 > k) {
         temp16 -= k;
      } else {
         temp16 = 256 - k;
      }

      return bytes1(uint8(temp16));
    }

    // calculate the rewards
    function distributeReward(uint256 amount, address[] memory list, uint num) internal {
        uint reward = amount / num;
        if (reward == 0) {
            return;
        }
        uint total = 0;
        for (uint i; i < list.length; i++) {
            if (isSufficientlyStaked(list[i])) {
               rewards[list[i]] += reward;
               total += reward;
               emit Reward(list[i], reward);
            }
        }

        if (total < amount) {
            if (isSufficientlyStaked(list[0])) {
                rewards[list[0]] += total - amount;
                emit Reward(list[0], total - amount);
            } else {
                rewards[list[1]] += total - amount;
                emit Reward(list[1], total - amount);
            }
        }
    }

    // slash the verifier stake
    function penalize(address target) internal returns(uint256) {
        uint256 stake = verifier_stakes[target];
        verifier_stakes[target] = 0;
        numQualifiedVerifiers--;
        deleteVerifier(target);
        emit Penalize(target, stake);

        return stake;
    }

    function deleteVerifier(address target) internal {
        bool hasVerifier = false;
        uint pos = 0;
        for (uint i = 0; i < verifiers.length; i++){
            if (verifiers[i] == target) {
                hasVerifier = true;
                pos = i;
                break;
            }
        }
        if (hasVerifier) {
            for (uint i = pos; i < verifiers.length-1; i++) {
                verifiers[i] = verifiers[i+1];
            }
            verifiers.pop();
        }
    }

}