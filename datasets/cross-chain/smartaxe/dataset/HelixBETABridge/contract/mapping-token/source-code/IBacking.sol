// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

interface IBacking {
    function unlockFromRemote(
        address originalToken,
        address recipient,
        uint256 amount) external;
}

interface IBackingSupportNative {
    function unlockFromRemoteNative(
        address recipient,
        uint256 amount) external;
}
