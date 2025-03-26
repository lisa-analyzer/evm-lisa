// SPDX-License-Identifier: MPL-2.0

pragma solidity 0.6.6;

import "./erc20/ITokenRecipient.sol";
import "./erc20/MinterRole.sol";

interface IStrudel {
  function mint(address account, uint256 amount) external returns (bool);

  function burnFrom(address _account, uint256 _amount) external;

  function renounceMinter() external;
}

/// @title  Strudel Token.
/// @notice This is the Strudel ERC20 contract.
contract StrudelWrapper is ITokenRecipient, MinterRole {
  event LogSwapin(bytes32 indexed txhash, address indexed account, uint256 amount);
  event LogSwapout(address indexed account, address indexed bindaddr, uint256 amount);

  address public strdlAddr;

  constructor(address _strdlAddr) public {
    __Ownable_init();
    strdlAddr = _strdlAddr;
  }

  function mint(address to, uint256 amount) external onlyMinter returns (bool) {
    IStrudel(strdlAddr).mint(to, amount);
    return true;
  }

  function burn(address from, uint256 amount) external onlyMinter returns (bool) {
    require(from != address(0), "StrudelWrapper: address(0x0)");
    IStrudel(strdlAddr).burnFrom(from, amount);
    return true;
  }

  function Swapin(
    bytes32 txhash,
    address account,
    uint256 amount
  ) public onlyMinter returns (bool) {
    IStrudel(strdlAddr).mint(account, amount);
    emit LogSwapin(txhash, account, amount);
    return true;
  }

  function Swapout(uint256 amount, address bindaddr) public returns (bool) {
    require(bindaddr != address(0), "StrudelWrapper: address(0x0)");
    IStrudel(strdlAddr).burnFrom(msg.sender, amount);
    emit LogSwapout(msg.sender, bindaddr, amount);
    return true;
  }

  function getAddr(bytes memory _extraData) internal returns (address) {
    address addr;
    assembly {
      addr := mload(add(_extraData, 20))
    }
    return addr;
  }

  function receiveApproval(
    address _from,
    uint256 _value,
    address _token,
    bytes calldata _extraData
  ) external override {
    require(msg.sender == strdlAddr, "StrudelWrapper: onlyAuth");
    require(_token == strdlAddr, "StrudelWrapper: onlyAuth");
    address bindaddr = getAddr(_extraData);
    require(bindaddr != address(0), "StrudelWrapper: address(0x0)");
    IStrudel(strdlAddr).burnFrom(_from, _value);
    emit LogSwapout(_from, bindaddr, _value);
  }
}