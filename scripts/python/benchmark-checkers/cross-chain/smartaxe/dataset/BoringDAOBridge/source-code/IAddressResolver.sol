// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IAddressResolver {
    
    function key2address(bytes32 key) external view returns(address);
    function address2key(address addr) external view returns(bytes32);
    function requireAndKey2Address(bytes32 name, string calldata reason) external view returns(address);

    function setAddress(bytes32 key, address addr) external;
    function setMultiAddress(bytes32[] memory keys, address[] memory addrs) external;
    
    function setKkAddr(bytes32 k1, bytes32 k2, address addr) external;
    function setMultiKKAddr(bytes32[] memory k1s, bytes32[] memory k2s, address[] memory addrs) external;

    function kk2addr(bytes32 k1, bytes32 k2) external view returns(address);
    function requireKKAddrs(bytes32 k1, bytes32 k2, string calldata reason) external view returns(address);
}