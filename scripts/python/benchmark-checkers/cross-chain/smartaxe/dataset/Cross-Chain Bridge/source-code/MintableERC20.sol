// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import '../utils/MyPausable.sol';

/**
 * @title MintableERC20
 * This is the base contract for LP tokens that are created by the CrossChainBridgeERC20 contract
 */
contract MintableERC20 is ERC20Burnable, MyPausable, Ownable {
  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
  string contractName;
  string contractSymbol;
  uint8 private _decimals;

  /**
   * @notice Constructor that sets name and symbol
   * @param _name full name of the token
   * @param _symbol token symbol
   */
  constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) MyPausable() Ownable() {
    contractName = _name;
    contractSymbol = _symbol;
    // set up admin roles
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(MINTER_ROLE, _msgSender());
    _decimals = 18;
  }

  /**
   * @notice Mints (creates new) tokens and sends them to the given address
   *
   * @dev can only be called by MINTER_ROLE
   * @param to the address of the receiver the tokens should be minted to
   * @param amount the amount of tokens to be minted
   */
  function mint(address to, uint256 amount) public whenNotPaused {
    require(hasRole(MINTER_ROLE, _msgSender()), 'MintableERC20: must have MINTER_ROLE to mint');
    _mint(to, amount);
  }

  /**
   * @notice This function (or hook) is called before every token transfer
   *
   * @dev for further information on hooks see https://docs.openzeppelin.com/contracts/3.x/extending-contracts#using-hooks
   * @param from the address of the sender of the token transfer
   * @param to the address of the recipient of the token transfer
   * @param amount the amount of tokens that will be transfered
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override whenNotPaused {
    super._beforeTokenTransfer(from, to, amount);
  }

  /**
   * @notice Returns the name of this token
   */
  function name() public view override returns (string memory) {
    return contractName;
  }

  /**
   * @notice Returns the symbol of this token
   */
  function symbol() public view override returns (string memory) {
    return contractSymbol;
  }

  /**
   * @notice Updates name and symbol of this token
   *
   * can only be called by the owner of this token (=the LiquidityManager contract)
   * @param newName the new name of the token
   * @param newSymbol the new symbol of the token
   * @param newDecimals the new number of decimals of the token
   * @dev to update a token's name and symbol, please use setNameAndSymbolOfLpToken() in LiquidityManager contract
   */
  function setNameAndSymbolAndDecimals(
    string memory newName,
    string memory newSymbol,
    uint8 newDecimals
  ) external onlyOwner {
    contractName = newName;
    contractSymbol = newSymbol;
    _decimals = newDecimals;
  }

  /**
   * @notice Returns the number of decimals this token has
   */
  function decimals() public view virtual override returns (uint8) {
    return _decimals;
  }
}