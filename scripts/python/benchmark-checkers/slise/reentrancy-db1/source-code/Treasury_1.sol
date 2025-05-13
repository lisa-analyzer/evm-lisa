// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IERC20 {
    function symbol() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    // Note this is non standard but nearly all ERC20 have exposed decimal functions
    function decimals() external view returns (uint8);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// This contract is currently a scaffold, meaning it is unimplemented and
// just designed to show the shape of future code. The naming and other
// conventions are 'soft' and more of suggestions that the implementer
// has full ability to change. Changes which break interface compatibility though
// should be double checked with the rest of the team.



// This contract is designed to hold the erc20 and eth reserves of the dao
// and will likely control a large amount of funds. It is designed to be
// flexible, secure and simple
contract Treasury {
    // the governance address
    address _governance;

    // A constant which represents ether
    address internal constant _ETH_CONSTANT =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /// @dev Modifier checks if the msg.sender is the governance contract.
    modifier onlyGovernance() {
        require(msg.sender == _governance, "!governance");
        _;
    }

    /// @notice constructor.
    /// @param __governance Governance contract address.
    constructor(address __governance) {
        _governance = __governance;
    }

    ///@notice Sends funds from the treasury to an address.
    ///@param _token Either (1) An ERC20 token address
    /// or (2) the _ETH_CONSTANT to use transfer ETH.
    ///@param _amount The amount of ETH or ERC20 to send.
    ///@param _recipient The recipient of this value.
    function sendFunds(
        address _token,
        uint256 _amount,
        address _recipient
    ) external onlyGovernance {
        if (_token == _ETH_CONSTANT) {
            payable(_recipient).transfer(_amount);
        } else {
            // onlyGovernance should protect from reentrancy
            IERC20(_token).transfer(_recipient, _amount);
        }
    }

    ///@notice Sets an ERC20 allowance from this contract to a _spender.
    ///@param _token The ERC20 token address.
    ///@param _spender The recipient of the allowance.
    ///@param _amount The amount of the allowance.
    function approve(
        address _token,
        address _spender,
        uint256 _amount
    ) external onlyGovernance {
        IERC20(_token).approve(_spender, _amount);
    }

    ///@notice Performs a generic call from this contract.
    ///@param _target The target address where the call will be performed.
    ///@param _callData The execution calldata to pass.
    // SWC-Unchecked Call Return Value: L73
    function genericCall(address _target, bytes calldata _callData)
        external
        onlyGovernance
    {
        _target.call(_callData);
    }

    fallback() external payable {}
}
