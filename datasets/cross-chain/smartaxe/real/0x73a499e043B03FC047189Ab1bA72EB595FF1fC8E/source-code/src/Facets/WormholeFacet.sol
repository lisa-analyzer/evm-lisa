// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ILiFi } from "../Interfaces/ILiFi.sol";
import { IWormholeRouter } from "../Interfaces/IWormholeRouter.sol";
import { LibDiamond } from "../Libraries/LibDiamond.sol";
import { LibAsset } from "../Libraries/LibAsset.sol";
import { LibSwap } from "../Libraries/LibSwap.sol";

contract WormholeFacet is ILiFi {
    /* ========== Storage ========== */

    bytes32 internal constant NAMESPACE = keccak256("com.lifi.facets.wormhole");
    struct Storage {
        address wormholeRouter;
    }

    /* ========== Types ========== */

    struct WormholeData {
        address token;
        uint256 amount;
        address recipient;
        uint16 toChainId;
        uint32 nonce;
    }

    /* ========== Init ========== */

    function initWormhole(address _wormholeRouter) external {
        Storage storage s = getStorage();
        LibDiamond.enforceIsContractOwner();
        s.wormholeRouter = _wormholeRouter;
    }

    /* ========== Public Bridge Functions ========== */

    /**
     * @notice Bridges tokens via Wormhole
     * @param _lifiData data used purely for tracking and analytics
     * @param _wormholeData data specific to Wormhole
     */
    function startBridgeTokensViaWormhole(LiFiData memory _lifiData, WormholeData calldata _wormholeData)
        public
        payable
    {
        uint256 _fromTokenBalance = LibAsset.getOwnBalance(_wormholeData.token);

        LibAsset.transferFromERC20(_wormholeData.token, msg.sender, address(this), _wormholeData.amount);

        require(
            LibAsset.getOwnBalance(_wormholeData.token) - _fromTokenBalance == _wormholeData.amount,
            "ERR_INVALID_AMOUNT"
        );

        _startBridge(_wormholeData);

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
     * @notice Performs a swap before bridging via Wormhole
     * @param _lifiData data used purely for tracking and analytics
     * @param _swapData an array of swap related data for performing swaps before bridging
     * @param _wormholeData data specific to Wormhole
     */
    function swapAndStartBridgeTokensViaWormhole(
        LiFiData memory _lifiData,
        LibSwap.SwapData[] calldata _swapData,
        WormholeData memory _wormholeData
    ) public payable {
        uint256 _fromTokenBalance = LibAsset.getOwnBalance(_wormholeData.token);

        // Swap
        for (uint8 i; i < _swapData.length; i++) {
            LibSwap.swap(_lifiData.transactionId, _swapData[i]);
        }

        require(
            LibAsset.getOwnBalance(_wormholeData.token) - _fromTokenBalance >= _wormholeData.amount,
            "ERR_INVALID_AMOUNT"
        );

        uint256 _postSwapBalance = LibAsset.getOwnBalance(_wormholeData.token) - _fromTokenBalance;

        require(_postSwapBalance > 0, "ERR_INVALID_AMOUNT");

        _wormholeData.amount = _postSwapBalance;

        _startBridge(_wormholeData);

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

    /* ========== External Config Functions ========== */

    /**
     * @dev Changes address of Wormhole router
     * @param _newRouter address of the new router
     */
    function changeWormholeRouter(address _newRouter) external {
        Storage storage s = getStorage();
        LibDiamond.enforceIsContractOwner();
        s.wormholeRouter = _newRouter;
    }

    /* ========== Internal Functions ========== */

    /**
     * @dev Conatains the business logic for the bridge via Wormhole
     * @param _wormholeData data specific to Wormhole
     */
    function _startBridge(WormholeData memory _wormholeData) internal {
        Storage storage s = getStorage();

        // Check chain id
        require(block.chainid != _wormholeData.toChainId, "Cannot bridge to the same network.");

        // Give Anyswap approval to bridge tokens
        LibAsset.approveERC20(IERC20(_wormholeData.token), s.wormholeRouter, _wormholeData.amount);

        IWormholeRouter(s.wormholeRouter).transferTokens(
            _wormholeData.token,
            _wormholeData.amount,
            _wormholeData.toChainId,
            bytes32(uint256(uint160(_wormholeData.recipient))),
            0,
            _wormholeData.nonce
        );
    }

    function getStorage() internal pure returns (Storage storage s) {
        bytes32 namespace = NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }
}
