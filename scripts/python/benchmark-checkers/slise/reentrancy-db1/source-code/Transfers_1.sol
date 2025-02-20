// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.5.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function decimals() external view returns (uint8);
}



/// @title  Transfers
library Transfers {
    /// @notice         Performs an ERC20 `transfer` call and checks return data
    /// @param  token   ERC20 token to transfer
    /// @param  to      Recipient of the ERC20 token
    /// @param  value   Amount of ERC20 to transfer
    // SWC-Unchecked Call Return Value: L13 - L22
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory returnData) = address(token).call(
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
        require(success && (returnData.length == 0 || abi.decode(returnData, (bool))), "Transfer fail");
    }
}
