// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

interface IErc721Backing {
    function unlockFromRemote(
        address originalToken,
        address recipient,
        uint256[] calldata ids,
        bytes[] calldata attrs
    ) external;
}
