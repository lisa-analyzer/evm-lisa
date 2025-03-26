// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "../utils/RevertMessageParser.sol";

/**
 * @title A contract that implements the chain of the calls on different contracts
 * @dev All function calls are currently implemented without side effects
 */
contract MulticallRouter is Context {
    /**
     * @notice Implements a chain of external calls
     * @param _amountIn input amount
     * @param _calldata array of encoded methods
     * @param _receiveSides array of contracts on which methods executions will take place
     * @param _path path of tokens
     * @param _offset array of shifts to patch the amount to calldata
     * @param _to address to send the dest token
     */
    function multicall(
        uint256 _amountIn,
        bytes[] memory _calldata,
        address[] memory _receiveSides,
        address[] memory _path,
        uint256[] memory _offset,
        address _to
    ) external {
        TransferHelper.safeTransferFrom(_path[0], _msgSender(), address(this), _amountIn);

        for (uint256 i = 0; i < _calldata.length; i++) {
            uint256 currentAmountIn = IERC20(_path[i]).balanceOf(address(this));
            bytes memory currentCalldata = _calldata[i];

            uint256 offset = _offset[i];
            assembly {
                mstore(add(currentCalldata, offset), currentAmountIn)
            }

            _lazyApprove(_path[i], _receiveSides[i], currentAmountIn);
            (bool success, bytes memory data) = _receiveSides[i].call(currentCalldata);
            if (!success) {
                revert(RevertMessageParser.getRevertMessage(data, "MulticallRouter: call failed"));
            }
        }

        uint256 finalAmountOut = IERC20(_path[_path.length - 1]).balanceOf(address(this));
        if (finalAmountOut != 0) {
            TransferHelper.safeTransfer(_path[_path.length - 1], _to, finalAmountOut);
        }
    }

    /**
     * @notice Implements approve
     * @dev Internal function used to approve the token spending
     * @param _token token address
     * @param _to address to approve
     * @param _amount amount for which approve will be given
     */
    function _lazyApprove(address _token, address _to, uint256 _amount) internal {
        if (IERC20(_token).allowance(address(this), _to) < _amount) {
            TransferHelper.safeApprove(_token, _to, type(uint256).max);
        }
    }
}