// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ILiFi } from "../Interfaces/ILiFi.sol";
import { LibAsset } from "../Libraries/LibAsset.sol";
import { LibSwap } from "../Libraries/LibSwap.sol";
import { LibUtil } from "../Libraries/LibUtil.sol";

contract GenericBridgeFacet is ILiFi {
    /* ========== Types ========== */

    struct BridgeData {
        uint256 amount;
        address assetId;
        address callTo;
        bytes callData;
    }

    /* ========== Public Bridge Functions ========== */

    /**
     * @notice Bridges tokens via Generic Bridge
     * @param _lifiData data used purely for tracking and analytics
     * @param _bridgeData data used for bridging via various contracts
     */
    function startBridgeTokensGeneric(LiFiData memory _lifiData, BridgeData memory _bridgeData) public payable {
        LibAsset.transferFromERC20(_bridgeData.assetId, msg.sender, address(this), _bridgeData.amount);

        _startBridge(_bridgeData);

        emit LiFiTransferStarted(
            _lifiData.transactionId,
            _lifiData.integrator,
            _lifiData.referrer,
            _lifiData.sendingAssetId,
            _lifiData.receivingAssetId,
            _lifiData.receiver,
            _lifiData.amount,
            _lifiData.destinationChainId,
            block.timestamp
        );
    }

    /**
     * @notice Performs a swap before bridging via Hop Protocol
     * @param _lifiData data used purely for tracking and analytics
     * @param _swapData an array of swap related data for performing swaps before bridging
     * @param _bridgeData data used for bridging via various contracts
     */
    function swapAndStartBridgeTokensGeneric(
        LiFiData memory _lifiData,
        LibSwap.SwapData[] calldata _swapData,
        BridgeData memory _bridgeData
    ) public payable {
        uint256 _fromTokenBalance = LibAsset.getOwnBalance(_bridgeData.assetId);

        // Swap
        for (uint8 i; i < _swapData.length; i++) {
            LibSwap.swap(_lifiData.transactionId, _swapData[i]);
        }

        require(
            LibAsset.getOwnBalance(_bridgeData.assetId) - _fromTokenBalance >= _bridgeData.amount,
            "ERR_INVALID_AMOUNT"
        );

        _startBridge(_bridgeData);

        emit LiFiTransferStarted(
            _lifiData.transactionId,
            _lifiData.integrator,
            _lifiData.referrer,
            _lifiData.sendingAssetId,
            _lifiData.receivingAssetId,
            _lifiData.receiver,
            _lifiData.amount,
            _lifiData.destinationChainId,
            block.timestamp
        );
    }

    /* ========== Internal Functions ========== */

    /**
     * @dev Conatains the business logic for the bridge via Hop Protocol
     */
    function _startBridge(BridgeData memory _bridgeData) internal {
        LibAsset.approveERC20(IERC20(_bridgeData.assetId), _bridgeData.callTo, _bridgeData.amount);
        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory res) = _bridgeData.callTo.call{ value: msg.value }(_bridgeData.callData);
        if (!success) {
            string memory reason = LibUtil.getRevertMsg(res);
            revert(reason);
        }
    }
}
