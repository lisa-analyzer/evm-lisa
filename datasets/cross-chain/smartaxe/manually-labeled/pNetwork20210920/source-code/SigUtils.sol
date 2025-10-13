pragma solidity ^0.4.24;


contract SigUtils {
    
    /**
     * @notice Recovers r, s and v from a signature
     * @param _sig signature
     */
    function splitSignature(bytes _sig)
        internal
        pure
        returns (uint8, bytes32, bytes32)
    {
        require(_sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(_sig, 32))
            // second 32 bytes
            s := mload(add(_sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(_sig, 96)))
        }

        return (v, r, s);
    }

    /**
     * @notice Recovers the signer from a _sig given an hashed message
     * @param _message hashed message
     * @param _sig signature
     */
    function recoverSigner(bytes32 _message, bytes _sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(_sig);

        return ecrecover(_message, v, r, s);
    }

    /**
     * @notice Add Ethereum specific signature prefix
     * @param _hash hash
     */
    function prefixed(bytes32 _hash) internal pure returns (bytes32) {
        return keccak256("\x19Ethereum Signed Message:\n32", _hash);
    }
}