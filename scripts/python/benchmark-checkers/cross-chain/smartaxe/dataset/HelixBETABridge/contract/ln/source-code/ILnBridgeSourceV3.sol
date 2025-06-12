// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface ILnBridgeSourceV3 {
    function slash(
        uint256 _remoteChainId,
        bytes32 _transferId,
        address _lnProvider,
        address _slasher
    ) external;
    function withdrawLiquidity(
        bytes32[] calldata _transferIds,
        uint256 _remoteChainId,
        address _provider
    ) external;
}
