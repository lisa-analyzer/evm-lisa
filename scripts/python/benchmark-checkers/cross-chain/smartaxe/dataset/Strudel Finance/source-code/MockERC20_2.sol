pragma solidity 0.6.6;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20UpgradeSafe {
  constructor(
    string memory name,
    string memory symbol,
    uint8 decimals,
    uint256 supply
  ) public {
    _mint(msg.sender, supply);
    __ERC20_init(name, symbol);
    _setupDecimals(decimals);
  }

  /**
   * @dev See {ERC20-_mint}.
   *
   * Requirements:
   *
   * - the caller must have the {MinterRole}.
   */
  function mint(address account, uint256 amount) external returns (bool) {
    _mint(account, amount);
    return true;
  }

  /// @dev Destroys `amount` tokens from `msg.sender`, reducing the
  /// total supply.
  /// @param _amount   The amount of tokens that will be burnt.
  function burn(uint256 _amount) external {
    _burn(msg.sender, _amount);
  }

  function renounceMinter() public {
    // do nothing
  }
}