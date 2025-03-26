//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/V4/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/V4/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/V4/access/Ownable.sol";
import "@openzeppelin/contracts/V4/utils/cryptography/ECDSA.sol";

interface Token {
    function mint(address _holder, uint256 _amount) external;
}

/// @author  umb.network
/// @dev claiming reward is token agnostic, contract only keep track of total reward paid
/// so we can pay in UMB, rUmb1, rUmb2 or any other token
abstract contract DPoSCore is Ownable {
    using SafeERC20 for IERC20;

    /// @dev rewards settings for token, in case of Umbrella tokens (UMB, rUmb) it will be same setting, we treat
    /// Umb tokens as one
    /// total supply of UMB = 500_000_000e18, it can be saved using 89bits, so we good with 96 and above
    /// for other tokens total supply might be unlimited, but we do not expect to give away 500 millions
    /// so we can keep optimisation and use same data type as for UMB
    struct RewardStatus {
        /// @dev total rewards claimed by users so far
        uint96 totalPaid;

        /// @dev total limit for rewards, `totalPaid` can not be higher than `totalLimit`
        /// this allow us to set some limit and then contract can mint on demand up to this limit
        /// this is more efficient than transferring tokens beforehand:
        /// - minting is less gas
        /// - no need to withdraw unnecessary tokens
        /// - it will not affect total supply
        uint96 totalLimit;

        bool transferringActive;

        bool mintingActive;
    }

    bytes constant private _ETH_PREFIX = "\x19Ethereum Signed Message:\n32";

    /// @dev BE signer
    address public rewardSigner;

    event RewardPaid(address indexed token, address indexed user, uint256 amount);

    event NewRewardSigner(address rewardSigner);

    constructor(address _rewardSigner) {
        _setRewardSigner(_rewardSigner);
    }

    /// @dev this method can be used to rescue tokens or simply withdraw them
    function withdrawTokens(IERC20 _token, address _recipient, uint256 _amount) external onlyOwner {
        _token.safeTransfer(_recipient, _amount);
    }

    function setRewardSigner(address _rewardSigner) external onlyOwner {
        _setRewardSigner(_rewardSigner);
    }

    function getChainId() public view returns (uint256 id) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
        }
    }

    function recover(address _token, address _recipient, uint256 _totalAmount, bytes memory _signature)
        public
        view
        returns (address)
    {
        bytes32 hash = keccak256(abi.encodePacked(getChainId(), _token, _recipient, _totalAmount));
        bytes32 prefixedHash = keccak256(abi.encodePacked(_ETH_PREFIX, hash));
        return ECDSA.recover(prefixedHash, _signature);
    }

    function _setRewardSigner(address _rewardSigner) internal {
        require(_rewardSigner != address(0), "empty reward signer");

        rewardSigner = _rewardSigner;
        emit NewRewardSigner(_rewardSigner);
    }

    function _executeClaim(
        RewardStatus storage _rewardStatus,
        mapping(address => uint256) storage _rewardsPaid,
        address _token,
        address _recipient,
        uint256 _totalAmount,
        bytes memory _signature
    )
        internal
        returns (uint256 rewardToClaim)
    {
        require(_totalAmount != 0, "totalAmount is zero");
        require(_recipient != address(0), "empty recipient");
        require(_token != address(0), "empty token");

        uint256 paid = _rewardsPaid[_recipient];

        require(paid < _totalAmount, "there is nothing to claim");
        require(rewardSigner == recover(_token, _recipient, _totalAmount, _signature), "invalid signature");

        unchecked {
            // underflow not possible because of require(paid < _totalAmount)
            rewardToClaim = _totalAmount - paid;
            RewardStatus memory status = _rewardStatus;
            // overflow `status.totalPaid + rewardToClaim` not possible because: in order to overflow `rewardToClaim`
            // needs to be at least `MAX(uint96) - status.totalPaid`, that basically means, contract will be asked
            // either to mint or to transfer `rewardToClaim`, in that case:
            // - on mint: we revert, because it will overflow on totalSupply
            // - on transfer: we revert, because contract will not have such an amount, because it is impossible to mint
            // for every other scenario, with values that are not close to MAX, we are protected by below requirement
            require(status.totalPaid + rewardToClaim <= status.totalLimit, "reward limit");

            // overflow not possible because of require(r.totalPaid + rewardToClaim <= r.totalLimit)
            _rewardStatus.totalPaid = uint96(status.totalPaid + rewardToClaim);
            _rewardsPaid[_recipient] = paid + rewardToClaim;
        }

        emit RewardPaid(_token, _recipient, rewardToClaim);
    }
}