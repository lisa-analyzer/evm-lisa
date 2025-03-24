// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ILiFi } from "../Interfaces/ILiFi.sol";
import { IBiconomyRouter } from "../Interfaces/IBiconomyRouter.sol";
import { LibDiamond } from "../Libraries/LibDiamond.sol";
import { LibAsset } from "../Libraries/LibAsset.sol";
import { LibSwap } from "../Libraries/LibSwap.sol";

contract BiconomyFacet is ILiFi {
    /* ========== Storage ========== */

    bytes32 internal constant NAMESPACE = keccak256("com.lifi.facets.biconomy");
    struct Storage {
        address biconomyRouter;
    }

    /* ========== Types ========== */

    struct BiconomyData {
        address token;
        uint256 amount;
        address recipient;
        uint256 toChainId;
    }

    /* ========== Init ========== */

    function initBiconomy(address _biconomyRouter) external {
        Storage storage s = getStorage();
        LibDiamond.enforceIsContractOwner();
        s.biconomyRouter = _biconomyRouter;
    }

    /* ========== Public Bridge Functions ========== */

    /**
     * @notice Bridges tokens via Biconomy
     * @param _lifiData data used purely for tracking and analytics
     * @param _biconomyData data specific to Biconomy
     */
    function startBridgeTokensViaBiconomy(LiFiData memory _lifiData, BiconomyData calldata _biconomyData)
        public
        payable
    {
        if (_biconomyData.token != address(0)) {
            uint256 _fromTokenBalance = LibAsset.getOwnBalance(_biconomyData.token);

            LibAsset.transferFromERC20(_biconomyData.token, msg.sender, address(this), _biconomyData.amount);

            require(
                LibAsset.getOwnBalance(_biconomyData.token) - _fromTokenBalance == _biconomyData.amount,
                "ERR_INVALID_AMOUNT"
            );
        } else {
            require(msg.value == _biconomyData.amount, "ERR_INVALID_AMOUNT");
        }

        _startBridge(_biconomyData);

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
     * @notice Performs a swap before bridging via Biconomy
     * @param _lifiData data used purely for tracking and analytics
     * @param _swapData an array of swap related data for performing swaps before bridging
     * @param _biconomyData data specific to Biconomy
     */
    function swapAndStartBridgeTokensViaBiconomy(
        LiFiData memory _lifiData,
        LibSwap.SwapData[] calldata _swapData,
        BiconomyData memory _biconomyData
    ) public payable {
        if (_biconomyData.token != address(0)) {
            uint256 _fromTokenBalance = LibAsset.getOwnBalance(_biconomyData.token);

            // Swap
            for (uint8 i; i < _swapData.length; i++) {
                LibSwap.swap(_lifiData.transactionId, _swapData[i]);
            }

            uint256 _postSwapBalance = LibAsset.getOwnBalance(_biconomyData.token) - _fromTokenBalance;

            require(_postSwapBalance > 0, "ERR_INVALID_AMOUNT");

            _biconomyData.amount = _postSwapBalance;
        } else {
            uint256 _fromBalance = address(this).balance;

            // Swap
            for (uint8 i; i < _swapData.length; i++) {
                LibSwap.swap(_lifiData.transactionId, _swapData[i]);
            }

            uint256 _postSwapBalance = address(this).balance - _fromBalance;

            require(_postSwapBalance > 0, "ERR_INVALID_AMOUNT");

            _biconomyData.amount = _postSwapBalance;
        }
        _startBridge(_biconomyData);

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
     * @dev Changes address of Biconomy router
     * @param _newRouter address of the new router
     */
    function changeBiconomyRouter(address _newRouter) external {
        Storage storage s = getStorage();
        LibDiamond.enforceIsContractOwner();
        s.biconomyRouter = _newRouter;
    }

    /* ========== Internal Functions ========== */

    /**
     * @dev Conatains the business logic for the bridge via Biconomy
     * @param _biconomyData data specific to Biconomy
     */
    function _startBridge(BiconomyData memory _biconomyData) internal {
        Storage storage s = getStorage();

        // Check chain id
        require(block.chainid != _biconomyData.toChainId, "Cannot bridge to the same network.");

        if (_biconomyData.token != address(0)) {
            // Give Anyswap approval to bridge tokens
            LibAsset.approveERC20(IERC20(_biconomyData.token), s.biconomyRouter, _biconomyData.amount);

            IBiconomyRouter(s.biconomyRouter).depositErc20(
                _biconomyData.token,
                _biconomyData.recipient,
                _biconomyData.amount,
                _biconomyData.toChainId
            );
        } else {
            IBiconomyRouter(s.biconomyRouter).depositNative{ value: _biconomyData.amount }(
                _biconomyData.recipient,
                _biconomyData.toChainId
            );
        }
    }

    function getStorage() internal pure returns (Storage storage s) {
        bytes32 namespace = NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }
}