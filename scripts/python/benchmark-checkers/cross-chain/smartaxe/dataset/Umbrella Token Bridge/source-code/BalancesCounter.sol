// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @dev Astro pool
interface IStakingLockable {
    struct Balance {
        // total supply of UMB = 500_000_000e18, it can be saved using 89bits, so we good with 96 and above
        // user UMB balance
        uint96 umbBalance;
        // amount locked + virtual balance generated using multiplier when locking
        uint96 lockedWithBonus;
        uint32 nextLockIndex;
        uint160 userRewardPerTokenPaid;
        uint96 rewards;
    }

    function balances(address _account) external view returns (Balance memory);
}

/// @dev helper contract for snapshot voting
/// sums up balance of users UMB tokens in different locations
/// For snapshot purposes it must follow ERC20 interface
contract BalancesCounter is ERC20, Ownable {
    // token which we want to track
    IERC20 public immutable mainToken;
    
    IStakingLockable public immutable astro;

    // token which we want to track
    IERC20[] public tokens;

    /// @param _mainToken token for which we calculating balances eg. UMB token
    /// @param _tokens list of contracts that has UMB tokens and returns balance per user when called for `balanceOf`
    /// @param _astro Astro contract (optional)
    constructor(IERC20 _mainToken, IERC20[] memory _tokens, IStakingLockable _astro)
        ERC20("BalancesCounter", "BalancesCounter")
    {
        // make sure we can access balance
        _mainToken.balanceOf(address(this));
        mainToken = _mainToken;

        for (uint256 i; i < _tokens.length; i++) {
            // make sure we can access balance
            _tokens[i].balanceOf(address(this));
        }

        tokens = _tokens;

        if (address(_astro) != address(0)) {
            // make sure we can access balances
            _astro.balances(address(this));
        }

        astro = _astro;
    }

    /// @dev add token to the list
    function addToken(IERC20 _token) external onlyOwner {
        // make sure we can access balance
        _token.balanceOf(address(this));
        tokens.push(_token);
    }

    /// @dev remove token from the list
    function removeToken(uint256 _id) external onlyOwner {
        uint256 lastId = tokens.length - 1;

        if (lastId != _id) {
            tokens[_id] = tokens[lastId];
        }

        tokens.pop();
    }

    function allTokens() external view returns (IERC20[] memory) {
        return tokens;
    }

    function astroUmbBalanceOf(address _account) public view returns (uint96 umbBalance) {
        if (address(astro) == address(0)) return 0;

        IStakingLockable.Balance memory balances = astro.balances(_account);
        return balances.umbBalance;
    }

    function totalSupply() public view override returns (uint256) {
        return mainToken.totalSupply();
    }

    /// @return total amount of UMB tokens for `_account` that is present in all defined `tokens` and in Astro pool
    function balanceOf(address _account) public view override returns (uint256 total) {
        total = astroUmbBalanceOf(_account);

        uint256 count = tokens.length;

        for (uint256 i; i < count; i++) {
            total += tokens[i].balanceOf(_account);
        }
    }

    function _beforeTokenTransfer(address, address, uint256) internal pure override {
        revert("this is oly view contract");
    }
}