// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@zeppelin-solidity/contracts/token/ERC20/IERC20.sol";

library LnBridgeHelper {
    // the time(seconds) for liquidity provider to delivery message
    // if timeout, slasher can work.
    uint256 constant public SLASH_EXPIRE_TIME = 60 * 60;
    bytes32 constant public INIT_SLASH_TRANSFER_ID = bytes32(uint256(1));
    // liquidity fee base rate
    // liquidityFee = liquidityFeeRate / LIQUIDITY_FEE_RATE_BASE * sendAmount
    uint256 constant public LIQUIDITY_FEE_RATE_BASE = 100000;

    struct TransferParameter {
        bytes32 previousTransferId;
        address provider;
        address sourceToken;
        address targetToken;
        uint112 amount;
        uint256 timestamp;
        address receiver;
    }

    // sourceToken and targetToken is the pair of erc20 token(or native) addresses
    // if sourceToken == address(0), then it's native token
    // if targetToken == address(0), then remote is native token
    // * `protocolFee` is the protocol fee charged by system
    // * `penaltyLnCollateral` is penalty from lnProvider when the transfer slashed, if we adjust this value, it'll not affect the old transfers.
    struct TokenInfo {
        uint112 protocolFee;
        uint112 penaltyLnCollateral;
        uint8 sourceDecimals;
        uint8 targetDecimals;
        bool isRegistered;
    }

    function sourceAmountToTargetAmount(
        TokenInfo memory tokenInfo,
        uint112 amount
    ) internal pure returns(uint112) {
        uint256 targetAmount = uint256(amount) * 10**tokenInfo.targetDecimals / 10**tokenInfo.sourceDecimals;
        require(targetAmount < type(uint112).max, "overflow amount");
        return uint112(targetAmount);
    }

    function calculateProviderFee(uint112 baseFee, uint16 liquidityFeeRate, uint112 amount) internal pure returns(uint112) {
        uint256 fee = uint256(baseFee) + uint256(liquidityFeeRate) * uint256(amount) / LIQUIDITY_FEE_RATE_BASE;
        require(fee < type(uint112).max, "overflow fee");
        return uint112(fee);
    }

    function safeTransfer(
        address token,
        address receiver,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(
            IERC20.transfer.selector,
            receiver,
            amount
        ));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "lnBridgeHelper:transfer token failed");
    }

    function safeTransferFrom(
        address token,
        address sender,
        address receiver,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(
            IERC20.transferFrom.selector,
            sender,
            receiver,
            amount
        ));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "lnBridgeHelper:transferFrom token failed");
    }

    function safeTransferNative(
        address receiver,
        uint256 amount
    ) internal {
        (bool success,) = payable(receiver).call{value: amount}("");
        require(success, "lnBridgeHelper:transfer native token failed");
    }

    function getProviderKey(uint256 remoteChainId, address provider, address sourceToken, address targetToken) pure internal returns(bytes32) {
        return keccak256(abi.encodePacked(
            remoteChainId,
            provider,
            sourceToken,
            targetToken
        ));
    }

    function getTokenKey(uint256 remoteChainId, address sourceToken, address targetToken) pure internal returns(bytes32) {
        return keccak256(abi.encodePacked(
            remoteChainId,
            sourceToken,
            targetToken
        ));
    }
}

