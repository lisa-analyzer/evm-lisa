// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AnyswapV6ERC20 is ERC20Permit {
    using SafeERC20 for IERC20;

    uint8 private _tokenDecimals;

    address public immutable underlying;
    bool public constant underlyingIsMinted = false;

    // init flag for setting immediate vault, needed for CREATE2 support
    bool private _init;

    // flag to enable/disable swapout vs vault.burn so multiple events are triggered
    bool private _vaultOnly;

    // delay for timelock functions
    uint public constant DELAY = 2 days;

    // set of minters, can be this bridge or other bridges
    mapping(address => bool) public isMinter;
    address[] public minters;

    // primary controller of the token contract
    address public vault;

    address public pendingMinter;
    uint public delayMinter;

    address public pendingVault;
    uint public delayVault;

    modifier onlyAuth() {
        require(isMinter[msg.sender], "AnyswapV6ERC20: FORBIDDEN");
        _;
    }

    modifier onlyVault() {
        require(msg.sender == vault, "AnyswapV6ERC20: FORBIDDEN");
        _;
    }

    function owner() external view returns (address) {
        return vault;
    }

    function mpc() external view returns (address) {
        return vault;
    }

    function setVaultOnly(bool enabled) external onlyVault {
        _vaultOnly = enabled;
    }

    function initVault(address _vault) external onlyVault {
        require(!_init);
        _init = true;
        vault = _vault;
        isMinter[_vault] = true;
        minters.push(_vault);
    }

    function setVault(address _vault) external onlyVault {
        require(_vault != address(0), "AnyswapV6ERC20: address(0)");
        pendingVault = _vault;
        delayVault = block.timestamp + DELAY;
    }

    function applyVault() external onlyVault {
        require(pendingVault != address(0) && block.timestamp >= delayVault);
        vault = pendingVault;

        pendingVault = address(0);
        delayVault = 0;
    }

    function setMinter(address _auth) external onlyVault {
        require(_auth != address(0), "AnyswapV6ERC20: address(0)");
        pendingMinter = _auth;
        delayMinter = block.timestamp + DELAY;
    }

    function applyMinter() external onlyVault {
        require(pendingMinter != address(0) && block.timestamp >= delayMinter);
        isMinter[pendingMinter] = true;
        minters.push(pendingMinter);

        pendingMinter = address(0);
        delayMinter = 0;
    }

    // No time delay revoke minter emergency function
    function revokeMinter(address _auth) external onlyVault {
        isMinter[_auth] = false;
    }

    function getAllMinters() external view returns (address[] memory) {
        return minters;
    }

    function changeVault(address newVault) external onlyVault returns (bool) {
        require(newVault != address(0), "AnyswapV6ERC20: address(0)");
        emit LogChangeVault(vault, newVault, block.timestamp);
        vault = newVault;
        pendingVault = address(0);
        delayVault = 0;
        return true;
    }

    function mint(address to, uint256 amount) external onlyAuth returns (bool) {
        _mint(to, amount);
        return true;
    }

    function burn(address from, uint256 amount) external onlyAuth returns (bool) {
        _burn(from, amount);
        return true;
    }

    function Swapin(bytes32 txhash, address account, uint256 amount) external onlyAuth returns (bool) {
        if (underlying != address(0) && IERC20(underlying).balanceOf(address(this)) >= amount) {
            IERC20(underlying).safeTransfer(account, amount);
        } else {
            _mint(account, amount);
        }
        emit LogSwapin(txhash, account, amount);
        return true;
    }

    function Swapout(uint256 amount, address bindaddr) external returns (bool) {
        require(!_vaultOnly, "AnyswapV6ERC20: vaultOnly");
        require(bindaddr != address(0), "AnyswapV6ERC20: address(0)");
        if (underlying != address(0) && balanceOf(msg.sender) < amount) {
            IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
        } else {
            _burn(msg.sender, amount);
        }
        emit LogSwapout(msg.sender, bindaddr, amount);
        return true;
    }

    event LogChangeVault(address indexed oldVault, address indexed newVault, uint indexed effectiveTime);
    event LogSwapin(bytes32 indexed txhash, address indexed account, uint amount);
    event LogSwapout(address indexed account, address indexed bindaddr, uint amount);

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _underlying,
        address _vault
    ) ERC20Permit(_name) ERC20(_name, _symbol) {
        _tokenDecimals = _decimals;
        underlying = _underlying;
        if (_underlying != address(0)) {
            require(_decimals == IERC20Metadata(_underlying).decimals());
        }

        vault = _vault;
    }

    function decimals() public view override returns (uint8) {
        return _tokenDecimals;
    }

    function deposit() external returns (uint) {
        uint _amount = IERC20(underlying).balanceOf(msg.sender);
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), _amount);
        return _deposit(_amount, msg.sender);
    }

    function deposit(uint amount) external returns (uint) {
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
        return _deposit(amount, msg.sender);
    }

    function deposit(uint amount, address to) external returns (uint) {
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
        return _deposit(amount, to);
    }

    function depositVault(uint amount, address to) external onlyVault returns (uint) {
        return _deposit(amount, to);
    }

    function _deposit(uint amount, address to) internal returns (uint) {
        require(!underlyingIsMinted);
        require(underlying != address(0) && underlying != address(this));
        _mint(to, amount);
        return amount;
    }

    function withdraw() external returns (uint) {
        return _withdraw(msg.sender, balanceOf(msg.sender), msg.sender);
    }

    function withdraw(uint amount) external returns (uint) {
        return _withdraw(msg.sender, amount, msg.sender);
    }

    function withdraw(uint amount, address to) external returns (uint) {
        return _withdraw(msg.sender, amount, to);
    }

    function withdrawVault(address from, uint amount, address to) external onlyVault returns (uint) {
        return _withdraw(from, amount, to);
    }

    function _withdraw(address from, uint amount, address to) internal returns (uint) {
        require(!underlyingIsMinted);
        require(underlying != address(0) && underlying != address(this));
        _burn(from, amount);
        IERC20(underlying).safeTransfer(to, amount);
        return amount;
    }
}
