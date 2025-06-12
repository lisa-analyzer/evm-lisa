//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./SwapCalldataUtils.sol";

contract TargetTokenHolder {
    using SafeERC20 for IERC20;
    using SwapCalldataUtils for bytes;

    address targetToken;

    constructor(address targetToken_) {
        targetToken = targetToken_;
    }

    // called for any calldata (see SAMPLE_CALLDATA in src/SwapCalldataParser.js)
    // thus emulating real-world pool/router behavior
    fallback (bytes calldata _input) external returns (bytes memory) {
        (uint256 amount, bool success) = _input.getAmount();
        if (success) {
            IERC20(targetToken).transferFrom(msg.sender, address(this), amount);
        }
    }

    function obtain(address _wrappedToken) external {
        IERC20 wrappedToken = IERC20(_wrappedToken);
        wrappedToken.transferFrom(
            msg.sender,
            address(this),
            wrappedToken.balanceOf(msg.sender)
        );
    }
}