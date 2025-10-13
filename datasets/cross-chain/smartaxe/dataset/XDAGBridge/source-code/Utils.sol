// SPDX-License-Identifier: MIT

// Modified from Utils.sol in rsk token bridge. LGPL
pragma solidity ^0.8.0;

library Utils {

    function getTokenInfo(address tokenToUse) external view returns (uint8 decimals, string memory symbol) {
        decimals = getDecimals(tokenToUse);
        symbol = getSymbol(tokenToUse);
    }

    function getSymbol(address tokenToUse) public view returns (string memory symbol) {
        //support 32 bytes or string symbol
        (bool success, bytes memory data) = tokenToUse.staticcall(abi.encodeWithSignature("symbol()"));
        require(success, "Utils: Token hasn't symbol()");
        if (data.length == 32) {
            symbol = bytes32ToString(abi.decode(data, (bytes32)));
        } else {
            symbol = abi.decode(data, (string));
        }
        require(bytes(symbol).length > 0, "Utils: Token empty symbol");
        return symbol;
    }

    function getDecimals(address tokenToUse) public view returns (uint8) {
        //support decimals as uint256 or uint8
        (bool success, bytes memory data) = tokenToUse.staticcall(abi.encodeWithSignature("decimals()"));
        require(success, "Utils: No decimals");
        require(data.length == 32, "Utils: Decimals not uint<M>");
        // uint<M>: enc(X) is the big-endian encoding of X,
        //padded on the higher-order (left) side with zero-bytes such that the length is 32 bytes.
        uint256 decimalsDecoded = abi.decode(data, (uint256));
        require(decimalsDecoded <= 18, "Utils: Decimals not in 0 to 18");
        return uint8(decimalsDecoded);
    }

    /* bytes32 (fixed-size array) to string (dynamically-sized array) */
    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

}
