// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.9.0;

/**
 * @title IL1StandardBridge
 */
interface IL1StandardBridge {
    /********************
     * Public Functions *
     ********************/

    function messenger() external view returns (address);

    /**
     * @dev Deposit an amount of ETH to a recipient's balance on L2.
     * @param _to L2 address to credit the withdrawal to.
     * @param _l2Gas Gas limit required to complete the deposit on L2.
     * @param _data Optional data to forward to L2. This data is provided
     *        solely as a convenience for external contracts. Aside from enforcing a maximum
     *        length, these contracts provide no guarantees about its content.
     */
    function depositETHTo(
        address _to,
        uint32 _l2Gas,
        bytes calldata _data
    ) external payable;

    /*************************
     * Cross-chain Functions *
     *************************/
}
