// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./ERC20.sol";
import "./TonUtils.sol";


abstract contract WrappedTON is ERC20, TonUtils {
    bool public allowBurn;

    function mint(SwapData memory sd) internal {
      _mint(sd.receiver, sd.amount);
      emit SwapTonToEth(sd.tx.address_.workchain, sd.tx.address_.address_hash, sd.tx.tx_hash, sd.tx.lt, sd.receiver, sd.amount);
    }

    /**
     * @dev Destroys `amount` tokens from the caller and request transfer to `addr` on TON network
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount, TonAddress memory addr) external {
      require(allowBurn, "Burn is currently disabled");
      _burn(msg.sender, amount);
      emit SwapEthToTon(msg.sender, addr.workchain, addr.address_hash, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance and request transfer to `addr`
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount, TonAddress memory addr) external {
        require(allowBurn, "Burn is currently disabled");
        uint256 currentAllowance = allowance(account,msg.sender);
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(account, msg.sender, currentAllowance - amount);
        _burn(account, amount);
        emit SwapEthToTon(account, addr.workchain, addr.address_hash, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 9;
    }

    event SwapEthToTon(
        address indexed from, // sender user EVM-network
        int8 to_wc, // workchain of receiver user in TON-network
        bytes32 indexed to_addr_hash, // // address of receiver user in TON-network
        uint256 value // amount in nanotons
    );
    event SwapTonToEth(
        int8 workchain, // sender user workchain in TON network
        bytes32 indexed ton_address_hash, // sender user address in TON network
        bytes32 indexed ton_tx_hash, // transaction hash on TON bridge smart contract
        uint64 lt, // transaction LT (logical time) on TON bridge smart contract
        address indexed to, // user's EVM-address to receive wrapped TONs
        uint256 value // nanotons amount to receive in EVM-network
    );
}
