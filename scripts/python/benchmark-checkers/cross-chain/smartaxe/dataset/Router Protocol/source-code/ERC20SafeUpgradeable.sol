// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

// import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./RouterERC20Upgradable.sol";

/**
    @title Manages deposited ERC20s.
    @author Router Protocol.
    @notice This contract is intended to be used with ERC20Handler contract.
 */
contract ERC20SafeUpgradeable is Initializable, ContextUpgradeable, AccessControlUpgradeable {
    // using SafeCastUpgradeable for *;
    using AddressUpgradeable for address;

    bytes32 public constant ERC20HANDLER_ROLE = keccak256("ERC20HANDLER_ROLE");

    function __ERC20SafeUpgradeable_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __ERC20SafeUpgradeable_init_unchained() internal initializer {}

    /**
        @notice Used to transfer tokens into the safe to fund proposals.
        @param tokenAddress Address of ERC20 to transfer.
        @param owner Address of current token owner.
        @param amount Amount of tokens to transfer.
     */
    function fundERC20(
        address tokenAddress,
        address owner,
        uint256 amount
    ) public onlyRole(ERC20HANDLER_ROLE) {
        IERC20Upgradeable erc20 = IERC20Upgradeable(tokenAddress);
        _safeTransferFrom(erc20, owner, address(this), amount);
    }

    /**
        @notice Used to gain custody of deposited token.
        @param tokenAddress Address of ERC20 to transfer.
        @param owner Address of current token owner.
        @param recipient Address to transfer tokens to.
        @param amount Amount of tokens to transfer.
     */
    function lockERC20(
        address tokenAddress,
        address owner,
        address recipient,
        uint256 amount
    ) public onlyRole(ERC20HANDLER_ROLE) {
        IERC20Upgradeable erc20 = IERC20Upgradeable(tokenAddress);
        _safeTransferFrom(erc20, owner, recipient, amount);
    }

    /**
        @notice Transfers custody of token to recipient.
        @param tokenAddress Address of ERC20 to transfer.
        @param recipient Address to transfer tokens to.
        @param amount Amount of tokens to transfer.
     */
    function releaseERC20(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) public onlyRole(ERC20HANDLER_ROLE) {
        IERC20Upgradeable erc20 = IERC20Upgradeable(tokenAddress);
        _safeTransfer(erc20, recipient, amount);
    }

    /**
        @notice Used to create new ERC20s.
        @param tokenAddress Address of ERC20 to transfer.
        @param recipient Address to mint token to.
        @param amount Amount of token to mint.
     */
    function mintERC20(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) public onlyRole(ERC20HANDLER_ROLE) {
        bytes memory data = abi.encodeWithSelector(0x40c10f19, recipient, amount); //mint(address,uint256)
        bytes memory returndata = tokenAddress.functionCall(data, "SafeERC20: low-level mint call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }

    /**
        @notice Used to burn ERC20s.
        @param tokenAddress Address of ERC20 to burn.
        @param owner Current owner of tokens.
        @param amount Amount of tokens to burn.
     */
    function burnERC20(
        address tokenAddress,
        address owner,
        uint256 amount
    ) public onlyRole(ERC20HANDLER_ROLE) {
        bytes memory data = abi.encodeWithSelector(0x9dc29fac, owner, amount); //burn(address,uint256)
        bytes memory returndata = tokenAddress.functionCall(data, "SafeERC20: low-level burn call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }

    /**
        @notice used to transfer ERC20s safely
        @param token Token instance to transfer
        @param to Address to transfer token to
        @param value Amount of token to transfer
     */
    function _safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _safeCall(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
        @notice used to transfer ERC20s safely
        @param token Token instance to transfer
        @param from Address to transfer token from
        @param to Address to transfer token to
        @param value Amount of token to transfer
     */
    function _safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _safeCall(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
        @notice used to make calls to ERC20s safely
        @param token Token instance call targets
        @param data encoded call data
     */
    function _safeCall(IERC20Upgradeable token, bytes memory data) internal {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }

    function safeTransferETH(address to, uint256 value) public onlyRole(ERC20HANDLER_ROLE) {
        require(to != address(0), "safeTransferETH: transfer to address 0");
        (bool success, ) = to.call{ value: value }(new bytes(0));
        require(success, "safeTransferETH: ETH transfer failed");
    }
}