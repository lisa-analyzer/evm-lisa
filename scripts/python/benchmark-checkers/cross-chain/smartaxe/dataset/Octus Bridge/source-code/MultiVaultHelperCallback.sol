// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../../interfaces/multivault/IMultiVaultFacetWithdraw.sol";
import "../../interfaces/multivault/IOctusCallback.sol";

abstract contract MultiVaultHelperCallback {
    modifier checkCallbackRecipient(address recipient) {
        require(recipient != address(this));

        if (recipient != address(0)) {
            _;
        }
    }

    function _callbackNativeWithdrawal(
        IMultiVaultFacetWithdraw.NativeWithdrawalParams memory withdrawal,
        uint256 _withdrawAmount
    ) internal checkCallbackRecipient(withdrawal.callback.recipient) {
        bytes memory data = abi.encodeWithSelector(
            IOctusCallbackNative.onNativeWithdrawal.selector,
            withdrawal,
            _withdrawAmount
        );

        _execute(
            withdrawal.callback.recipient,
            data,
            withdrawal.callback.strict
        );
    }

    function _callbackAlienWithdrawal(
        IMultiVaultFacetWithdraw.AlienWithdrawalParams memory _withdrawal,
        uint256 _withdrawAmount
    ) internal checkCallbackRecipient(_withdrawal.callback.recipient) {
        bytes memory data = abi.encodeWithSelector(
            IOctusCallbackAlien.onAlienWithdrawal.selector,
            _withdrawal,
            _withdrawAmount
        );

        _execute(
            _withdrawal.callback.recipient,
            data,
            _withdrawal.callback.strict
        );
    }

    function _callbackAlienWithdrawalPendingCreated(
        IMultiVaultFacetWithdraw.AlienWithdrawalParams memory _withdrawal,
        uint _pendingWithdrawalId
    ) checkCallbackRecipient(_withdrawal.callback.recipient) internal {
        bytes memory data = abi.encodeWithSelector(
            IOctusCallbackAlien.onAlienWithdrawalPendingCreated.selector,
            _withdrawal,
            _pendingWithdrawalId
        );

        _execute(
            _withdrawal.callback.recipient,
            data,
            _withdrawal.callback.strict
        );
    }

    function _execute(
        address recipient,
        bytes memory data,
        bool strict
    ) internal {
        (bool success, ) = recipient.call(data);

        if (strict) require(success);
    }
}