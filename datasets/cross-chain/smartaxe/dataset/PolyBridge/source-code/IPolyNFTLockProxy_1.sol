// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IPolyNFTLockProxy {
    function managerProxyContract() external view returns (address);
    function proxyHashMap(uint64) external view returns (bytes memory);
    function assetHashMap(address, uint64) external view returns (bytes memory);
    function setManagerProxy(
        address eccmpAddr
    ) external;
    
    function bindProxyHash(
        uint64 toChainId, 
        bytes calldata targetProxyHash
    ) external returns (bool);

    function bindAssetHash(
        address fromAssetHash, 
        uint64 toChainId, 
        bytes calldata toAssetHash
    ) external returns (bool);
}