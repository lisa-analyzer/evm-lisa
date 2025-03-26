// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

import "@zeppelin-solidity/contracts/access/Ownable.sol";
import "../interfaces/IErc721AttrSerializer.sol";
import "../interfaces/IErc721MappingToken.sol";
import "../v2/erc721-mapping-protocol/Erc721MappingToken.sol";

contract Erc721MonkeyAttributeSerializer is IErc721AttrSerializer {
    // some changable attributes
    struct Attributes {
        uint age;
        uint weight;
    }
    mapping(uint256 => Attributes) private _attributes;

    function setAttr(uint256 id, uint age, uint weight) external {
        _attributes[id] = Attributes(age, weight);
    }

    function getAge(uint256 id) external view returns(uint) {
        return _attributes[id].age;
    }

    function getWeight(uint256 id) external view returns(uint) {
        return _attributes[id].weight;
    }

    function name() external pure returns(string memory) {
        return "Monkey";
    }

    function symbol() external pure returns(string memory) {
        return "MKY";
    }

    function tokenURI(uint256) external pure returns(string memory) {
        return "";
    }

    function serialize(uint256 id) external view returns(bytes memory) {
        return abi.encode(_attributes[id]);
    }

    function deserialize(uint256 id, bytes memory data) external {
        Attributes memory attr = abi.decode(data, (Attributes));
        _attributes[id] = attr;
    }
}

