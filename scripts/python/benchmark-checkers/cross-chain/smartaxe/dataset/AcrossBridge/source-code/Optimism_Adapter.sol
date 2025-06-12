// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "./AdapterInterface.sol";
import "./WETH9.sol";

// @dev Use local modified CrossDomainEnabled contract instead of one exported by eth-optimism because we need
// this contract's state variables to be `immutable` because of the delegateCall call.
import "./CrossDomainEnabled.sol";
import "./IL1StandardBridge.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";

/**
 * @notice Contract containing logic to send messages from L1 to Optimism.
 * @dev Public functions calling external contracts do not guard against reentrancy because they are expected to be
 * called via delegatecall, which will execute this contract's logic within the context of the originating contract.
 * For example, the HubPool will delegatecall these functions, therefore its only necessary that the HubPool's methods
 * that call this contract's logic guard against reentrancy.
 */

// solhint-disable-next-line contract-name-camelcase
contract Optimism_Adapter is CrossDomainEnabled, AdapterInterface {
    using SafeERC20 for IERC20;
    uint32 public immutable l2GasLimit = 2_000_000;

    WETH9 public immutable l1Weth;

    IL1StandardBridge public immutable l1StandardBridge;

    // Optimism has the ability to support "custom" bridges. These bridges are not supported by the canonical bridge
    // and so we need to store the address of the custom token and the associated bridge. In the event we want to
    // support a new token that is not supported by Optimism, we can add a new custom bridge for it and re-deploy the
    // adapter. A full list of custom optimism tokens and their associated bridges can be found here:
    // https://github.com/ethereum-optimism/ethereum-optimism.github.io/blob/master/optimism.tokenlist.json
    address public immutable dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public immutable daiOptimismBridge = 0x10E6593CDda8c58a1d0f14C5164B376352a55f2F;
    address public immutable snx = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;
    address public immutable snxOptimismBridge = 0xCd9D4988C0AE61887B075bA77f08cbFAd2b65068;

    /**
     * @notice Constructs new Adapter.
     * @param _l1Weth WETH address on L1.
     * @param _crossDomainMessenger XDomainMessenger Optimism system contract.
     * @param _l1StandardBridge Standard bridge contract.
     */
    constructor(
        WETH9 _l1Weth,
        address _crossDomainMessenger,
        IL1StandardBridge _l1StandardBridge
    ) CrossDomainEnabled(_crossDomainMessenger) {
        l1Weth = _l1Weth;
        l1StandardBridge = _l1StandardBridge;
    }

    /**
     * @notice Send cross-chain message to target on Optimism.
     * @param target Contract on Optimism that will receive message.
     * @param message Data to send to target.
     */
    function relayMessage(address target, bytes calldata message) external payable override {
        sendCrossDomainMessage(target, uint32(l2GasLimit), message);
        emit MessageRelayed(target, message);
    }

    /**
     * @notice Bridge tokens to Optimism.
     * @param l1Token L1 token to deposit.
     * @param l2Token L2 token to receive.
     * @param amount Amount of L1 tokens to deposit and L2 tokens to receive.
     * @param to Bridge recipient.
     */
    function relayTokens(
        address l1Token,
        address l2Token,
        uint256 amount,
        address to
    ) external payable override {
        // If the l1Token is weth then unwrap it to ETH then send the ETH to the standard bridge.
        if (l1Token == address(l1Weth)) {
            l1Weth.withdraw(amount);
            l1StandardBridge.depositETHTo{ value: amount }(to, l2GasLimit, "");
        } else {
            IL1StandardBridge _l1StandardBridge = l1StandardBridge;

            // Check if the L1 token requires a custom bridge. If so, use that bridge over the standard bridge.
            if (l1Token == dai) _l1StandardBridge = IL1StandardBridge(daiOptimismBridge); // 1. DAI
            if (l1Token == snx) _l1StandardBridge = IL1StandardBridge(snxOptimismBridge); // 2. SNX

            IERC20(l1Token).safeIncreaseAllowance(address(_l1StandardBridge), amount);
            _l1StandardBridge.depositERC20To(l1Token, l2Token, to, amount, l2GasLimit, "");
        }
        emit TokensRelayed(l1Token, l2Token, amount, to);
    }
}