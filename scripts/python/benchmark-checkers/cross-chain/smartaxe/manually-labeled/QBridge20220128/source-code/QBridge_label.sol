// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___       ___       ___       ___       ___
     /\  \     /\__\     /\  \     /\  \     /\  \
    /::\  \   /:/ _/_   /::\  \   _\:\  \    \:\  \
    \:\:\__\ /:/_/\__\ /::\:\__\ /\/::\__\   /::\__\
     \::/  / \:\/:/  / \:\::/  / \::/\/__/  /:/\/__/
     /:/  /   \::/  /   \::/  /   \:\__\    \/__/
     \/__/     \/__/     \/__/     \/__/

*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IQBridgeHandler.sol";
import "../library/PausableUpgradeable.sol";
import "../library/AccessControlIndexUpgradeable.sol";
import "../library/SafeToken.sol";


contract QBridge is PausableUpgradeable, AccessControlIndexUpgradeable {
    using SafeMath for uint;
    using SafeToken for address;

    /* ========== CONSTANT VARIABLES ========== */

    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");

    uint public constant MAX_RELAYERS = 200;

    enum ProposalStatus {Inactive, Active, Passed, Executed, Cancelled}

    struct Proposal {
        ProposalStatus _status;
        uint200 _yesVotes;      // bitmap, 200 maximum votes
        uint8 _yesVotesTotal;
        uint40 _proposedBlock; // 1099511627775 maximum block
    }

    /* ========== STATE VARIABLES ========== */

    uint8 public domainID;
    uint8 public relayerThreshold;
    uint128 public fee;
    uint40 public expiry;

    mapping(uint8 => uint64) public _depositCounts; // destinationDomainID => number of deposits
    mapping(bytes32 => address) public resourceIDToHandlerAddress; // resourceID => handler address
    mapping(uint72 => mapping(bytes32 => Proposal)) private _proposals; // destinationDomainID + depositNonce => dataHash => Proposal

    /* ========== EVENTS ========== */

    event RelayerThresholdChanged(uint256 newThreshold);
    event RelayerAdded(address relayer);
    event RelayerRemoved(address relayer);
    event Deposit(uint8 destinationDomainID, bytes32 resourceID, uint64 depositNonce, address indexed user, bytes data);
    event ProposalEvent(uint8 originDomainID, uint64 depositNonce, ProposalStatus status, bytes32 dataHash);
    event ProposalVote(uint8 originDomainID, uint64 depositNonce, ProposalStatus status, bytes32 dataHash);
    event FailedHandlerExecution(bytes lowLevelData);

    /* ========== INITIALIZER ========== */

    function initialize(uint8 _domainID, uint8 _relayerThreshold, uint128 _fee, uint40 _expiry) external initializer {
        __PausableUpgradeable_init();
        __AccessControl_init();

        domainID = _domainID;
        relayerThreshold = _relayerThreshold;
        fee = _fee;
        expiry = _expiry;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyRelayers() {
        require(hasRole(RELAYER_ROLE, msg.sender), "QBridge: caller is not the relayer");
        _;
    }

    modifier onlyOwnerOrRelayers() {
        require(owner() == msg.sender || hasRole(RELAYER_ROLE, msg.sender), "QBridge: caller is not the owner or relayer");
        _;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setRelayerThreshold(uint8 newThreshold) external onlyOwner {
        relayerThreshold = newThreshold;
        emit RelayerThresholdChanged(newThreshold);
    }

    function addRelayer(address relayer) external onlyOwner {
        require(!hasRole(RELAYER_ROLE, relayer), "QBridge: duplicated relayer");
        require(totalRelayers() < MAX_RELAYERS, "QBridge: relayers limit reached");
        grantRole(RELAYER_ROLE, relayer);
        emit RelayerAdded(relayer);
    }

    function removeRelayer(address relayer) external onlyOwner {
        require(hasRole(RELAYER_ROLE, relayer), "QBridge: invalid relayer");
        revokeRole(RELAYER_ROLE, relayer);
        emit RelayerRemoved(relayer);
    }

    function setResource(address handlerAddress, bytes32 resourceID, address tokenAddress) external onlyOwner {
        resourceIDToHandlerAddress[resourceID] = handlerAddress;
        IQBridgeHandler(handlerAddress).setResource(resourceID, tokenAddress);
    }

    function setBurnable(address handlerAddress, address tokenAddress) external onlyOwner {
        IQBridgeHandler(handlerAddress).setBurnable(tokenAddress);
    }

    function setDepositNonce(uint8 _domainID, uint64 nonce) external onlyOwner {
        require(nonce > _depositCounts[_domainID], "QBridge: decrements not allowed");
        _depositCounts[_domainID] = nonce;
    }

    function setFee(uint128 newFee) external onlyOwner {
        fee = newFee;
    }

    function manualRelease(address handlerAddress, address tokenAddress, address recipient, uint amount) external onlyOwner {
        IQBridgeHandler(handlerAddress).withdraw(tokenAddress, recipient, amount);
    }

    function sweep() external onlyOwner {
        SafeToken.safeTransferETH(msg.sender, address(this).balance);
    }

    /* ========== VIEWS ========== */

    function isRelayer(address relayer) external view returns (bool) {
        return hasRole(RELAYER_ROLE, relayer);
    }

    function totalRelayers() public view returns (uint) {
        return AccessControlIndexUpgradeable.getRoleMemberCount(RELAYER_ROLE);
    }

    /**
        @notice Returns a proposalID.
        @param _domainID Chain ID.
        @param nonce ID of proposal generated by proposal's origin Bridge contract.
     */
    function combinedProposalId(uint8 _domainID, uint64 nonce) public pure returns (uint72 proposalID) {
        proposalID = (uint72(nonce) << 8) | uint72(_domainID);
    }

    /**
        @notice Returns a proposal.
        @param originDomainID Chain ID deposit originated from.
        @param depositNonce ID of proposal generated by proposal's origin Bridge contract.
        @param dataHash Hash of data to be provided when deposit proposal is executed.
     */
    function getProposal(uint8 originDomainID, uint64 depositNonce, bytes32 dataHash, address relayer) external view returns (Proposal memory proposal, bool hasVoted) {
        uint72 proposalID = combinedProposalId(originDomainID, depositNonce);
        proposal = _proposals[proposalID][dataHash];
        hasVoted = _hasVoted(proposal, relayer);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
        @notice Initiates a transfer using a specified handler contract.
        @notice Only callable when Bridge is not paused.
        @param destinationDomainID ID of chain deposit will be bridged to.
        @param resourceID ResourceID used to find address of handler to be used for deposit.
        @param data Additional data to be passed to specified handler.
        @notice Emits {Deposit} event with all necessary parameters
     */
     //1.Access control inconsistency between paths
     //3.lack of check on supportness
    function deposit(uint8 destinationDomainID, bytes32 resourceID, bytes calldata data) external payable notPaused {
        require(msg.value == fee, "QBridge: invalid fee");

        address handler = resourceIDToHandlerAddress[resourceID];
        require(handler != address(0), "QBridge: invalid resourceID");

        uint64 depositNonce = ++_depositCounts[destinationDomainID];

        IQBridgeHandler(handler).deposit(resourceID, msg.sender, data);
        //2.semantic inconsistency
        emit Deposit(destinationDomainID, resourceID, depositNonce, msg.sender, data);
    }
    //1.Access control inconsistency between paths
    function depositETH(uint8 destinationDomainID, bytes32 resourceID, bytes calldata data) external payable notPaused {
        uint option;
        uint amount;
        (option, amount) = abi.decode(data, (uint, uint));

        require(msg.value == amount.add(fee), "QBridge: invalid fee");

        address handler = resourceIDToHandlerAddress[resourceID];
        require(handler != address(0), "QBridge: invalid resourceID");

        uint64 depositNonce = ++_depositCounts[destinationDomainID];

        IQBridgeHandler(handler).depositETH{value:amount}(resourceID, msg.sender, data);
        //2.semantic inconsistency
        emit Deposit(destinationDomainID, resourceID, depositNonce, msg.sender, data);
    }

    /**
        @notice When called, {msg.sender} will be marked as voting in favor of proposal.
        @notice Only callable by relayers when Bridge is not paused.
        @param originDomainID ID of chain deposit originated from.
        @param depositNonce ID of deposited generated by origin Bridge contract.
        @param data Data originally provided when deposit was made.
        @notice Proposal must not have already been passed or executed.
        @notice {msg.sender} must not have already voted on proposal.
        @notice Emits {ProposalEvent} event with status indicating the proposal status.
        @notice Emits {ProposalVote} event.
     */
    function voteProposal(uint8 originDomainID, uint64 depositNonce, bytes32 resourceID, bytes calldata data) external onlyRelayers notPaused {
        address handlerAddress = resourceIDToHandlerAddress[resourceID];
        require(handlerAddress != address(0), "QBridge: invalid handler");

        uint72 proposalID = combinedProposalId(originDomainID, depositNonce);
        bytes32 dataHash = keccak256(abi.encodePacked(handlerAddress, data));
        Proposal memory proposal = _proposals[proposalID][dataHash];

        if (proposal._status == ProposalStatus.Passed) {
            executeProposal(originDomainID, depositNonce, resourceID, data, true);
            return;
        }

        require(uint(proposal._status) <= 1, "QBridge: proposal already executed/cancelled");
        require(!_hasVoted(proposal, msg.sender), "QBridge: relayer already voted");

        if (proposal._status == ProposalStatus.Inactive) {
            proposal = Proposal({_status : ProposalStatus.Active, _yesVotes : 0, _yesVotesTotal : 0, _proposedBlock : uint40(block.number)});
            emit ProposalEvent(originDomainID, depositNonce, ProposalStatus.Active, dataHash);
        } else if (uint40(block.number.sub(proposal._proposedBlock)) > expiry) {
            proposal._status = ProposalStatus.Cancelled;
            emit ProposalEvent(originDomainID, depositNonce, ProposalStatus.Cancelled, dataHash);
        }

        if (proposal._status != ProposalStatus.Cancelled) {
            proposal._yesVotes = _bitmap(proposal._yesVotes, _relayerBit(msg.sender));
            proposal._yesVotesTotal++;
            emit ProposalVote(originDomainID, depositNonce, proposal._status, dataHash);

            if (proposal._yesVotesTotal >= relayerThreshold) {
                proposal._status = ProposalStatus.Passed;
                emit ProposalEvent(originDomainID, depositNonce, ProposalStatus.Passed, dataHash);
            }
        }
        _proposals[proposalID][dataHash] = proposal;

        if (proposal._status == ProposalStatus.Passed) {
            executeProposal(originDomainID, depositNonce, resourceID, data, false);
        }
    }

    /**
        @notice Executes a deposit proposal that is considered passed using a specified handler contract.
        @notice Only callable by relayers when Bridge is not paused.
        @param originDomainID ID of chain deposit originated from.
        @param depositNonce ID of deposited generated by origin Bridge contract.
        @param resourceID ResourceID to be used when making deposits.
        @param data Data originally provided when deposit was made.
        @param revertOnFail Decision if the transaction should be reverted in case of handler's executeProposal is reverted or not.
        @notice Proposal must have Passed status.
        @notice Hash of {data} must equal proposal's {dataHash}.
        @notice Emits {ProposalEvent} event with status {Executed}.
        @notice Emits {FailedExecution} event with the failed reason.
     */
    function executeProposal(uint8 originDomainID, uint64 depositNonce, bytes32 resourceID, bytes calldata data, bool revertOnFail) public onlyRelayers notPaused {
        address handlerAddress = resourceIDToHandlerAddress[resourceID];
        uint72 proposalID = combinedProposalId(originDomainID, depositNonce);
        bytes32 dataHash = keccak256(abi.encodePacked(handlerAddress, data));
        Proposal storage proposal = _proposals[proposalID][dataHash];

        require(proposal._status == ProposalStatus.Passed, "QBridge: Proposal must have Passed status");

        proposal._status = ProposalStatus.Executed;
        IQBridgeHandler handler = IQBridgeHandler(handlerAddress);

        if (revertOnFail) {
            handler.executeProposal(resourceID, data);
        } else {
            try handler.executeProposal(resourceID, data) {
            } catch (bytes memory lowLevelData) {
                proposal._status = ProposalStatus.Passed;
                emit FailedHandlerExecution(lowLevelData);
                return;
            }
        }
        emit ProposalEvent(originDomainID, depositNonce, ProposalStatus.Executed, dataHash);
    }

    /**
        @notice Cancels a deposit proposal that has not been executed yet.
        @notice Only callable by relayers when Bridge is not paused.
        @param originDomainID ID of chain deposit originated from.
        @param depositNonce ID of deposited generated by origin Bridge contract.
        @param dataHash Hash of data originally provided when deposit was made.
        @notice Proposal must be past expiry threshold.
        @notice Emits {ProposalEvent} event with status {Cancelled}.
     */
    function cancelProposal(uint8 originDomainID, uint64 depositNonce, bytes32 dataHash) public onlyOwnerOrRelayers {
        uint72 proposalID = combinedProposalId(originDomainID, depositNonce);
        Proposal memory proposal = _proposals[proposalID][dataHash];
        ProposalStatus currentStatus = proposal._status;

        require(currentStatus == ProposalStatus.Active || currentStatus == ProposalStatus.Passed, "QBridge: cannot be cancelled");
        require(uint40(block.number.sub(proposal._proposedBlock)) > expiry, "QBridge: not at expiry threshold");

        proposal._status = ProposalStatus.Cancelled;
        _proposals[proposalID][dataHash] = proposal;
        emit ProposalEvent(originDomainID, depositNonce, ProposalStatus.Cancelled, dataHash);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _relayerBit(address relayer) private view returns (uint) {
        if (relayer == address(0)) return 0;
        return uint(1) << AccessControlIndexUpgradeable.getRoleMemberIndex(RELAYER_ROLE, relayer).sub(1);
    }

    function _hasVoted(Proposal memory proposal, address relayer) private view returns (bool) {
        return (_relayerBit(relayer) & uint(proposal._yesVotes)) > 0;
    }

    function _bitmap(uint200 source, uint bit) internal pure returns (uint200) {
        uint value = source | bit;
        require(value < 2 ** 200, "QBridge: value does not fit in 200 bits");
        return uint200(value);
    }
}