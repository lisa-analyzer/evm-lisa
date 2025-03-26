// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
import "@zeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "../../interfaces/IERC20.sol";

contract Erc20Sub2SubMigration {
    using SafeMath for uint256;

    address public deprecatedToken;
    address public migrationToken;

    constructor( address _deprecatedToken, address _migrationToken) {
        deprecatedToken = _deprecatedToken;
        migrationToken = _migrationToken;
    }

    function migrate(uint256 amount) public {
        require(IERC20(deprecatedToken).transferFrom(msg.sender, address(this), amount), "Erc20Sub2SubMigration: transfer token failed");
        uint8 deprecatedDecimals = IERC20(deprecatedToken).decimals();
        uint8 migrationDecimals = IERC20(migrationToken).decimals();
        if (migrationDecimals > deprecatedDecimals) {
            uint256 migrationAmount = amount.mul(10**(migrationDecimals - deprecatedDecimals));
            require(IERC20(migrationToken).transfer(msg.sender, migrationAmount), "Erc20Sub2SubMigration: migrate token failed");
        } else {
            uint256 migrationAmount = amount.div(10**(deprecatedDecimals - migrationDecimals));
            require(IERC20(migrationToken).transfer(msg.sender, migrationAmount), "Erc20Sub2SubMigration: migrate token failed");
        }
    }

    function migrateAll() external {
        uint256 balance = IERC20(deprecatedToken).balanceOf(msg.sender);
        migrate(balance);
    }

    function burnDeprecatedTokens() external {
        uint256 balance = IERC20(deprecatedToken).balanceOf(address(this));
        IERC20(deprecatedToken).burn(address(this), balance);
    }
}

