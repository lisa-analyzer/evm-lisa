pragma solidity ^0.8.7;

import "./Address.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

import "./DummyCallProxy.sol";
import "./IDeBridgeGate.sol";
import "./Flags.sol";

contract DummyBridge {
    using SafeERC20 for IERC20;

    DummyCallProxy callProxy;

    constructor(DummyCallProxy _callProxy) {
        callProxy = _callProxy;
    }

    function getChainId() public view virtual returns (uint256 cid) {
        assembly {
            cid := chainid()
        }
    }

    function send(
        address _tokenAddress,
        uint256 _amount,
        uint256 _chainIdTo,
        bytes memory _receiver,
        bytes memory _permit,
        bool _useAssetFee,
        uint32 _referralCode,
        bytes calldata _autoParams
    ) external {
        IERC20 tokenAddress = IERC20(_tokenAddress);

        IDeBridgeGate.SubmissionAutoParamsTo memory autoParams;
        if (_autoParams.length > 0) {
            autoParams = abi.decode(
                _autoParams,
                (IDeBridgeGate.SubmissionAutoParamsTo)
            );
        }

        if (_amount > 0) {
            tokenAddress.safeTransferFrom(msg.sender, address(this), _amount);
        }

        address receiver;
        assembly {
            receiver := mload(add(_receiver, 20))
        }

        address fallbackAddress;
        bytes memory fb = autoParams.fallbackAddress;
        assembly {
            fallbackAddress := mload(add(fb, 20))
        }

        if (autoParams.data.length > 0) {
            if (_amount > 0) {
                uint256 fee = (_amount * 10) / 10000;
                _amount -= fee;
                tokenAddress.safeTransfer(address(callProxy), _amount);
            }

            callProxy.callERC20(
                _tokenAddress,
                fallbackAddress,
                receiver,
                autoParams.data,
                autoParams.flags,
                abi.encodePacked(msg.sender),
                getChainId()
            );
        } else {
            if (_amount > 0) {
                uint256 fee = (_amount * 10) / 10000;
                _amount -= fee;
                tokenAddress.safeTransfer(receiver, _amount);
            }
        }
    }
}