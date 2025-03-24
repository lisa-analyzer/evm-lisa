// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "./AnyCallApp.sol";
import "./interfaces/IDecimal.sol";
import "./interfaces/IERC677Gateway.sol";

interface IERC677 {
    function transferAndCall(address receiver, uint amount, bytes memory data) external returns (bool success);
}

abstract contract ERC677Gateway is IERC677Gateway, AnyCallApp {
    address public token;
    mapping(uint256 => uint8) public decimals;
    uint256 public swapoutSeq;

    constructor (address anyCallProxy, uint256 flag, address token_) AnyCallApp(anyCallProxy, flag) {
        setAdmin(msg.sender);
        token = token_;
    }

    function _swapout(uint256 amount, address sender) internal virtual returns (bool);
    function _swapin(uint256 amount, address receiver) internal virtual returns (bool);

    event LogAnySwapOut(uint256 amount, address sender, address receiver, uint256 toChainID, uint256 swapoutSeq);

    function setDecimals(uint256[] memory chainIDs, uint8[] memory decimals_) external onlyAdmin {
        for (uint i = 0; i < chainIDs.length; i++) {
            decimals[chainIDs[i]] = decimals_[i];
        }
    }

    function decimal(uint256 chainID) external view returns(uint8) {
        return (decimals[chainID] > 0 ? decimals[chainID] : IDecimal(token).decimals());
    }

    function convertDecimal(uint256 fromChain, uint256 amount) public view returns (uint256) {
        uint8 d_0 = this.decimal(fromChain);
        uint8 d_1 = IDecimal(token).decimals();
        if (d_0 > d_1) {
            for (uint8 i = 0; i < (d_0 - d_1); i++) {
                amount = amount / 10;
            }
        } else {
            for (uint8 i = 0; i < (d_1 - d_0); i++) {
                amount = amount * 10;
            }
        }
        return amount;
    }

    /// @dev called by sender contract
    function SwapOut_and_call(SwapOutArgs memory swapArgs, bytes memory boundMessage) external payable returns (uint256 swapoutSeq) {
        require(_swapout(swapArgs.amount, msg.sender));
        swapoutSeq++;
        bytes memory data = abi.encode(swapArgs, msg.sender, boundMessage, swapoutSeq);
        _anyCall(peer[swapArgs.toChainID], data, address(0), swapArgs.toChainID);
        emit LogAnySwapOut(swapArgs.amount, msg.sender, swapArgs.receiver, swapArgs.toChainID, swapoutSeq);
        return swapoutSeq;
    }

    // allow ERC677 receiver verify the message sender
    address public sender;

    function _anyExecute(uint256 fromChainID, bytes calldata data) internal override returns (bool success, bytes memory result) {
        // sender_ is the caller of SwapOut_and_call
        (SwapOutArgs memory swapArgs, address sender_, bytes memory boundMessage, uint256 nonce) = abi.decode(
            data,
            (SwapOutArgs, address, bytes, uint256)
        );
        swapArgs.amount = convertDecimal(fromChainID, swapArgs.amount);

        bool swapSucc = _swapin(swapArgs.amount, address(this));
        require(swapSucc, "swap failed");

        sender = sender_;

        bool callSucc = IERC677(this.token()).transferAndCall(swapArgs.receiver, swapArgs.amount, boundMessage);
        require(callSucc, "call failed");

        sender = address(0);

        return (true, "");
    }
}