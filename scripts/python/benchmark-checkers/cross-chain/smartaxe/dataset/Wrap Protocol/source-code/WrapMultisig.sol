pragma solidity >=0.5.0 <0.7.0;
import "./base/WrapManager.sol";
import "./external/SafeMath.sol";
import "./interfaces/ERC721TokenReceiver.sol";

contract WrapMultisig
    is MultisigManager, ERC721TokenReceiver {

    using SafeMath for uint256;

    string public constant NAME = "Wrap multisig";
    string public constant VERSION = "1.0.0";

    bytes4 private constant ERC20_TRANSFER_SELECTOR = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));

    bytes4 private constant ERC721_SAFE_TRANSFER_SELECTOR = bytes4(keccak256(bytes('safeTransferFrom(address,address,uint256)')));

    //keccak256(
    //    "EIP712Domain(address verifyingContract)"
    //);
    bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH = 0x035aff83d86937d35b32e04f0ddc6ff469290eef2f1b692d8a815c89404d4749;

    //keccak256(
    //    "WrapTx(address to,uint256 value,bytes data,string tezosOperation)"
    //);
    bytes32 private constant UNWRAP_TX_TYPEHASH = 0x987804e036e2c4c5e32f45ccae87d65fb92de3f7d16998a7fa3910a01da2ab53;

    mapping(string => bool) internal tezosOperations;

    event ExecutionFailure(
            bytes32 txHash
    );
    event ExecutionSuccess(
        bytes32 txHash
    );
    event ERC20WrapAsked(
        address user,
        address token,
        uint256 amount,
        string tezosDestinationAddress
    );
    event ERC721WrapAsked(
        address user,
        address token,
        uint256 tokenId,
        string tezosDestinationAddress
    );

    bytes32 public domainSeparator;

    constructor(address _administrator) public {
        require(_administrator != address(0), "WRAP: INVALID_ADMINISTRATOR_PROVIDED");
        administrator = _administrator;
    }

    function setup(
        address[] calldata owners,
        uint256 threshold
    )
        external
        authorized
    {
        require(domainSeparator == 0, "WRAP: DOMAIN_SEPARATOR_ALREADY_SET");
        domainSeparator = keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, this));
        _setup(owners, threshold);
    }

    function wrapERC20(
        address token,
        uint256 amount,
        string calldata tezosAddress
    )
        external
        returns (bool success)
    {
        require(amount > 0, "WRAP: INVALID_AMOUNT");
        _erc20SafeTransferFrom(token, msg.sender, address(this), amount);
        emit ERC20WrapAsked(msg.sender, token, amount, tezosAddress);
        return true;
    }

    function _erc20SafeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(ERC20_TRANSFER_SELECTOR, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'WRAP: ERC20_TRANSFER_FAILED');
    }

    function wrapERC721(
        address token,
        uint256 tokenId,
        string calldata tezosAddress
    )
        external
        returns (bool success)
    {
        _erc721SafeTransferFrom(token, msg.sender, address(this), tokenId);
        emit ERC721WrapAsked(msg.sender, token, tokenId, tezosAddress);
        return true;
    }

    function _erc721SafeTransferFrom(
        address token,
        address from,
        address to,
        uint256 tokenId
    ) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(ERC721_SAFE_TRANSFER_SELECTOR, from, to, tokenId));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'WRAP: ERC721_TRANSFER_FAILED');
    }

    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        string calldata tezosOperation,
        bytes calldata signatures
    )
        external
        returns (bool success)
    {
        require(tezosOperations[tezosOperation] == false, 'WRAP: TRANSACTION_ALREADY_PROCESSED');
        tezosOperations[tezosOperation] = true;
        bytes memory txHashData = encodeTransactionData(
            to, value, data,
            tezosOperation
        );
        bytes32 txHash = keccak256(txHashData);
        _checkSignatures(txHash, signatures);
        success = _execute(to, value, data, gasleft());
        if (success) emit ExecutionSuccess(txHash);
        else emit ExecutionFailure(txHash);
    }

    function _execute(
        address to,
        uint256 value,
        bytes memory data,
        uint256 txGas
    )
        internal
        returns (bool success)
    {
        assembly {
            success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
        }
    }

    function _signatureSplit(
        bytes memory signatures,
        uint256 pos
    )
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
        // Here we are loading the last 32 bytes, including 31 bytes
        // of 's'. There is no 'mload8' to do this.
        //
        // 'byte' is not working due to the Solidity parser, so lets
        // use the second best option, 'and'
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }

    function _checkSignatures(
        bytes32 dataHash,
        bytes memory signatures
    )
        internal
        view
    {
        uint256 _threshold = threshold;
        require(_threshold > 0, "WRAP: THRESHOLD_NOT_DEFINED");
        require(signatures.length >= _threshold.mul(65), "WRAP: SIGNATURES_DATA_TOO_SHORT");
        address lastOwner = address(0);
        address currentOwner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;
        for (i = 0; i < _threshold; i++) {
            (v, r, s) = _signatureSplit(signatures, i);
            currentOwner = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)), v, r, s);
            require (
                currentOwner > lastOwner && owners[currentOwner] != address(0) && currentOwner != SENTINEL_OWNERS,
                "WRAP: INVALID_OWNER_PROVIDED"
            );
            lastOwner = currentOwner;
        }
    }

    function encodeTransactionData(
        address to,
        uint256 value,
        bytes memory data,
        string memory tezosOperation
    )
        public
        view
        returns (bytes memory)
    {
        bytes32 wrapTxHash = keccak256(
            abi.encode(UNWRAP_TX_TYPEHASH, to, value, keccak256(data), tezosOperation)
        );
        return abi.encodePacked(byte(0x19), byte(0x01), domainSeparator, wrapTxHash);
    }

    function getTransactionHash(
        address to,
        uint256 value,
        bytes memory data,
        string memory tezosOperation
    )
        public
        view
        returns (bytes32)
    {
        return keccak256(encodeTransactionData(to, value, data, tezosOperation));
    }

    function isTezosOperationProcessed(
        string memory tezosOperation
    )
        public
        view
        returns (bool)
    {
        return tezosOperations[tezosOperation];
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    )
        external
        returns(bytes4)
    {
        return 0x150b7a02;
    }
}
