// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

import "./Ownable.sol";
import "./IErc1155Metadata.sol";
import "./IErc1155MappingToken.sol";

contract Erc1155MaterialMetadata is IErc1155Metadata {
    function uri(uint256) external pure returns(string memory) {
        return "";
    }
}

