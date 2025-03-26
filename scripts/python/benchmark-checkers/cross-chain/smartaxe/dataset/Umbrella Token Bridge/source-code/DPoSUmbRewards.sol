//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./DPoSCore.sol";

/// @author  umb.network
/// @dev claiming reward is token agnostic, contract only keep track of total reward paid
/// so we can pay in UMB, rUmb1, rUmb2 or any other token
contract DPoSUmbRewards is DPoSCore {
    RewardStatus public rewardStatus;

    /// @dev user => reward paid so far
    mapping(address => uint256) public rewardsPaid;
    
    event LimitChanged(uint256 limit);

    event TransferringStatus(bool active);

    event MintingStatus(bool active);

    constructor(address _rewardSigner) DPoSCore(_rewardSigner) {
        //
    }
    
    function setLimit(uint96 _limit) external onlyOwner {
        uint96 totalPaid = rewardStatus.totalPaid;

        if (_limit < totalPaid) {
            _limit = totalPaid;
        }

        rewardStatus.totalLimit = _limit;
        emit LimitChanged(_limit);
    }

    function setStatuses(bool _transferringActive, bool _mintingActive) external {
        setTransferringStatus(_transferringActive);
        setMintingStatus(_mintingActive);
    }

    /// @param _token token that will be transferred to recipient
    /// @param _recipient user for whom rewards will be claimed (no need to be same user who execute this tx)
    /// @param _totalAmount total (ever increasing) amount of reward collected by user in DPoS
    /// @param _signature rewardSigner signature
    function transferReward(IERC20 _token, address _recipient, uint256 _totalAmount, bytes memory _signature) external {
        require(rewardStatus.transferringActive, "transferring NOT active");

        uint256 rewardToClaim = _executeClaim(
            rewardStatus,
            rewardsPaid,
            address(_token),
            _recipient,
            _totalAmount,
            _signature
        );

        require(_token.transfer(_recipient, rewardToClaim), "umbrella token transfer failed");
    }

    /// @dev same as `transferReward` but for minting on demand so eg. rUmb2
    function mintReward(Token _token, address _recipient, uint256 _totalAmount, bytes memory _signature) external {
        require(rewardStatus.mintingActive, "minting NOT active");

        uint256 rewardToClaim = _executeClaim(
            rewardStatus,
            rewardsPaid,
            address(_token),
            _recipient,
            _totalAmount,
            _signature
        );

        _token.mint(_recipient, rewardToClaim);
    }

    function setMintingStatus(bool _active) public onlyOwner {
        rewardStatus.mintingActive = _active;
        emit MintingStatus(_active);
    }

    function setTransferringStatus(bool _active) public onlyOwner {
        rewardStatus.transferringActive = _active;
        emit TransferringStatus(_active);
    }
}