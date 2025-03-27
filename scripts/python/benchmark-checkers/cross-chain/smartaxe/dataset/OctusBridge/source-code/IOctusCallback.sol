// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;

import "./IMultiVaultFacetWithdraw.sol";


interface IOctusCallbackNative {
    function onNativeWithdrawal(
        IMultiVaultFacetWithdraw.NativeWithdrawalParams memory payload,
        uint256 withdrawAmount
    ) external;
}

interface IOctusCallbackAlien {
    function onAlienWithdrawal(
        IMultiVaultFacetWithdraw.AlienWithdrawalParams memory payload,
        uint256 withdrawAmount
    ) external;
    function onAlienWithdrawalPendingCreated(
        IMultiVaultFacetWithdraw.AlienWithdrawalParams memory _payload,
        uint pendingWithdrawalId
    ) external;
}