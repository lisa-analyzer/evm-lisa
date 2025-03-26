// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

// Interfaces/Libraries/Inheriting Contracts:
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ITokenConfig.sol";

contract Bridge {
    // Variables:
    address public admin;
    ITokenConfig public configToken;

    // Mappings:

    // 1.) address(sender) => uint(nonce) => bool
    mapping(address => mapping(uint256 => bool)) public processedTxNonce;

    // Enums:
    enum BridgeSteps {
        BURN,
        MINT
    }

    // Events:
    event Transfer(
        address from,
        address to,
        uint256 amount,
        uint256 nonce,
        uint256 date,
        bytes signature,
        BridgeSteps indexed step
    );

    // Modifiers:
    modifier validateProcessedNonce(uint256 _nonce) {
        require(
            processedTxNonce[msg.sender][_nonce] == false,
            "transfer has already been processed"
        );

        // If not processed yet:
        processedTxNonce[msg.sender][_nonce] = true;
        _;
    }

    constructor(address _token) {
        admin == msg.sender;
        configToken = ITokenConfig(_token);
    }

    // Functions:

    function burn(
        address _to,
        uint256 _amount,
        uint256 _nonce,
        bytes calldata _signature
    ) external validateProcessedNonce(_nonce) {
        // Bool mapped to nonce already set to true inside validateProcessedNonce Modifier:
        configToken.burnToken(msg.sender, _amount);

        emit Transfer(
            msg.sender,
            _to,
            _amount,
            _nonce,
            block.timestamp,
            _signature,
            BridgeSteps.BURN
        );
    }

    function mint(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _nonce,
        bytes calldata _signature
    ) external {
        // Hash the following parameters to compare signature given:
        bytes32 message = prefixed(
            keccak256(abi.encodePacked(_from, _to, _amount, _nonce))
        );

        // Validate signer from his signature and message hashed above:
        require(recoverSigner(message, _signature) == _from, "wrong signature");

        // Validate processed Nonce to check if transfer is already done previously:
        require(
            processedTxNonce[_from][_nonce] == false,
            "transfer has already been processed"
        );

        processedTxNonce[_from][_nonce] = true;
        configToken.mintToken(_to, _amount);

        emit Transfer(
            _from,
            _to,
            _amount,
            block.timestamp,
            _nonce,
            _signature,
            BridgeSteps.MINT
        );
    }

    // Encoding/Decoding Functions

    // HASHING PARAMETERS (TOTAL 4): _from Address, _to Address, _amount Unit, _nonce Unit
    // PREFIX HASH WITH THE SIGNED MESSAGE:
    function prefixed(bytes32 _hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
            );
    }

    // DECODING FUNCTION TO UNCOVER SIGNER:
    // Calls another internal function splitSignature(bytes memory _signature) to recover v, r, s
    // Using v , r , s => ecrecover(message, v, r, s) to uncover signer' address
    function recoverSigner(bytes32 _message, bytes memory _signature)
        internal
        pure
        returns (address)
    {
        // Instantiate v, r, s, variables of the signature to be extracted:
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(_signature);

        return ecrecover(_message, v, r, s);
    }

    // DECODING SIGNATURE FUNCTION TO RETRIEVE v , r, s:
    function splitSignature(bytes memory _signature)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        // Validate signature length:
        require(_signature.length == 65, "invalid signature");

        uint8 v;
        bytes32 r;
        bytes32 s;

        // Using assembly to extract from signature:
        assembly {
            //first32 bytes, after length prefix:
            r := mload(add(_signature, 32))

            // next 32 bytes:
            s := mload(add(_signature, 64))

            // final byte aka first byte of the next 32 bytes:
            v := byte(0, mload(add(_signature, 96)))
        }

        return (v, r, s);
    }
}
