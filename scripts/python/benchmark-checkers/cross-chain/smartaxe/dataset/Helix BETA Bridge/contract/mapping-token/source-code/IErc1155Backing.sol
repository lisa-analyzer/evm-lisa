// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

interface IErc1155Backing {
    function unlockFromRemote(
        address originalToken,
        address recipient,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external;
}
