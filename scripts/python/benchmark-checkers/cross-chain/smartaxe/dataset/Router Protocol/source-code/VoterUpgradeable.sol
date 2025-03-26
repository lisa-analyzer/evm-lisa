// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
    @author Router Protocol
    @title VoterUpgradeable Contract
*/
contract VoterUpgradeable is Initializable, AccessControlUpgradeable, ERC20Upgradeable, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _IssueCtr;

    address public bridge;

    enum ProposalStatus {
        Inactive,
        Active,
        Passed,
        Executed,
        Cancelled
    }

    mapping(uint256 => issueStruct) private issueMap;

    struct issueStruct {
        ProposalStatus status;
        uint256 startBlock;
        uint256 endBlock;
        uint64 quorum;
        uint256 maxVotes;
        uint8 resultOption;
    }

    // IssueID -> address -> hasVoted - bool
    mapping(uint256 => mapping(address => hasVotedStruct)) private hasVoted;

    struct hasVotedStruct {
        bool voted;
        uint8 option;
    }

    // IssueID -> vote option -> weight
    mapping(uint256 => mapping(uint8 => uint256)) private voteWeight;

    modifier isBridge() {
        require(msg.sender == bridge);
        _;
    }

    modifier isvalidIssue(uint256 _issue) {
        require(
            issueMap[_issue].status == ProposalStatus.Active,
            "ERC-1202: Not a valid proposal to vote on or voting on proposal is complete"
        );
        _;
    }

    modifier isNotvalidIssue(uint256 _issue) {
        require(issueMap[_issue].status == ProposalStatus.Inactive, "ERC-1202: A valid proposal");
        _;
    }

    modifier isNotEnded(uint256 _issue) {
        require(
            (block.number < issueMap[_issue].endBlock) && (issueMap[_issue].status == ProposalStatus.Active),
            "ERC-1202: Voting has ended"
        );
        _;
    }

    modifier isVotingNotEnded(uint256 _issue) {
        require (block.number < issueMap[_issue].endBlock, "Proposal expired");
        require (!(issueMap[_issue].status == ProposalStatus.Executed 
        || issueMap[_issue].status == ProposalStatus.Cancelled), "Proposal executed");
        _;
    }

    modifier isNotVoted(uint256 _issue, address relayer) {
        require(!hasVoted[_issue][relayer].voted, "ERC-1202: User has Voted");
        _;
    }

    modifier isValidOption(uint8 _opts) {
        require((_opts == 1) || (_opts == 2), "ERC-1202: Is not valid option");
        _;
    }

    modifier isValidbalance(address relayer) {
        require(balanceOf(relayer) == 1 ether, "ERC-1202: Is not valid balance");
        _;
    }

    modifier isValidquorum(uint64 quorum) {
        require((quorum > 0) && (quorum <= 10000), "ERC-1202: Is not valid quorum");
        _;
    }

    modifier isPassed(uint256 id) {
        require(issueMap[id].status == ProposalStatus.Passed, "ERC-1202: Proposal is not passed");
        _;
    }

    /**
        @notice OnCreateIssue Event
        @notice Creates a event when a new proposal is created to be voted upon.
        @param issueId ID of the proposal.
    */
    event OnCreateIssue(uint256 issueId);

    /**
        @notice OnVote Event
        @notice Creates a event when a proposal is voted upon.
        @param issueId ID of the proposal.
        @param _from Address of the voter.
        @param _value Voting power of the voter.
    */
    event OnVote(uint256 issueId, address indexed _from, uint256 _value);

    /**
        @notice OnStatusChange Event
        @notice Creates a event when a status of the Proposal is changed.
        @param issueId ID of the proposal.
        @param Status Status of the proposal.
    */
    event OnStatusChange(uint256 issueId, ProposalStatus Status);

    /**
        @notice RelayerAdded Event
        @notice Creates a event when Relayer Role is granted.
        @param relayer Address of relayer.
    */
    event RelayerAdded(address relayer);

    /**
        @notice RelayerRemoved Event
        @notice Creates a event when Relayer Role is revoked.
        @param relayer Address of relayer.
    */
    event RelayerRemoved(address relayer);

    /**
        @notice Initializer Function
        @notice Can be called only once and acts like constructor for UUPS based upgradeable contracts.
    */
    function __VoterUpgradeable_init() internal initializer {
        __AccessControl_init();
        __ERC20_init_unchained("Relayer Vote Token ", "RRT");
        __VoterUpgradeable_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
        @notice Shadow function to Initializer Function
        @notice Can be called only once and acts like constructor for UUPS based upgradeable contracts.
    */
    function __VoterUpgradeable_init_unchained() internal initializer {}

    function initialize() external initializer {
        __VoterUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function setBridge(address _b) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_b != address(0), "RouterProtocol_VOTER::Bridge Address can not be zero address.");
        require(_b != address(this), "RouterProtocol_VOTER::Bridge Address can not be Voter address.");
        require(!hasRole(DEFAULT_ADMIN_ROLE, _b));
        bridge = _b;
    }

    /**
        @notice mint function
        @dev Grants VOting Token
        @param account address to which role is being revoked
    */
    function mint(address account) public virtual isBridge {
        _mint(account, 1 ether);
    }

    /**
        @notice burn function
        @dev Revokes Voting Token
        @param account address to which role is being revoked
    */
    function burn(address account) public virtual isBridge {
        _burn(account, 1 ether);
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the token tranfer amongst users must not happen.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        //        revert("ERC20 Non Transferable: This token is not transferable");
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(sender, recipient, amount);
        revert("ERC20 Non Transferable: This token is not transferable");
    }

    /**
    @notice createProposal function
    @notice Creates a new proposal.
    @notice Preconditon1 - Function is external and can be accessed by BRIDGE_ROLE only.
    @notice Preconditon2 - Proposal quorum must be valid integer
    @param endBlock End block number for proposal to end.
    @param quorum quorum percentage for the proposal.
*/
    function createProposal(uint256 endBlock, uint64 quorum)
        public
        virtual
        isBridge
        isValidquorum(quorum)
        returns (uint256 id)
    {
        _IssueCtr.increment();
        uint256 ctr = _IssueCtr.current();
        issueMap[ctr] = issueStruct(ProposalStatus.Active, block.number, endBlock, quorum, 0, 0);
        emit OnCreateIssue(ctr);
        emit OnStatusChange(ctr, issueMap[ctr].status);
        return ctr;
    }

    /**
        @notice vote function
        @notice Vote on a new proposal.
        @notice Preconditon1 - Function is external and can be accessed by BRIDGE_ROLE only.
        @notice Preconditon2 - Checks weather issue / proposal ID is valid
        @notice Preconditon3 - Current voter must not have voted on proposal
        @notice Preconditon4 - Options entered for voting must be valid (ie. - Option must be either 1 - yes or 2 - no )
        @notice Preconditon5 - Voting for the current proposal / issue must not have ended
        @notice Preconditon6 - Members must have valid balances to vote.
        @param issueId Issue ID or proposal ID for casting vote
        @param option Option selected by the user
        @return success Boolean value to denote successfull completion of function
    */
    function vote(
        uint256 issueId,
        uint8 option,
        address relayer
    )
        public
        virtual
        isBridge
        isvalidIssue(issueId)
        isNotVoted(issueId, relayer)
        isValidOption(option)
        isNotEnded(issueId)
        isValidbalance(relayer)
        returns (bool success)
    {
        uint256 balance = balanceOf(relayer);
        hasVoted[issueId][relayer] = hasVotedStruct(true, option);
        voteWeight[issueId][option] = voteWeight[issueId][option] + balance;
        issueMap[issueId].maxVotes = issueMap[issueId].maxVotes + balance;
        uint256 yes = voteWeight[issueId][1];
        uint256 yesPercent = (yes * (10000)) / (totalSupply()); // YesPercent = yes*10000/totalSupply
        if (yesPercent > issueMap[issueId].quorum) _setStatus(issueId, 1, ProposalStatus.Passed);

        emit OnVote(issueId, relayer, balance);
        return true;
    }

    /**
        @notice setStatus function
        @notice Updates the status of the proposal
        @notice Preconditon1 - Function is external and can be accessed by BRIDGE_ROLE only.
        @notice Preconditon2 - Proposal must have ended its voting duration
        @param issueId Issue ID or proposal ID for changing the status
        @return success Boolean value to denote successfull completion of function
    */
    function setStatus(uint256 issueId) public virtual isVotingNotEnded(issueId) isBridge returns (bool success) {
        uint256 yes = voteWeight[issueId][1];
        uint256 yesPercent = (yes * (10000)) / (totalSupply()); // YesPercent = yes*10000/maxvotes
        if (yesPercent > issueMap[issueId].quorum) {
            return _setStatus(issueId, 1, ProposalStatus.Passed);
        }
        return _setStatus(issueId, 2, ProposalStatus.Cancelled);
    }

    function _setStatus(
        uint256 issueId,
        uint8 option,
        ProposalStatus status
    ) internal returns (bool success) {
        issueMap[issueId].resultOption = option;
        issueMap[issueId].status = status;

        emit OnStatusChange(issueId, issueMap[issueId].status);
        return true;
    }

    /**
        @notice executeProposal function
        @notice Marks the status of the proposal as executed.
        @notice Preconditon1 - Function is external and can be accessed by BRIDGE_ROLE only.
        @notice Preconditon2 - Proposal must be with statue of passed
        @param issueId Issue ID or proposal ID for changing the status
        @return success Boolean value to denote successfull completion of function
    */
    function executeProposal(uint256 issueId) public virtual isPassed(issueId) isBridge returns (bool success) {
        issueMap[issueId].status = ProposalStatus.Executed;
        emit OnStatusChange(issueId, issueMap[issueId].status);
        return true;
    }

    /**
        @notice ballotOf function
        @notice Fetches the casted vote of the user.
        @notice Preconditon1 - Function is public and open to all.
        @param issueId Issue ID or proposal ID
        @param addr Address of the person casting vote
        @return option Option casted by the voter
    */
    function ballotOf(uint256 issueId, address addr) public view virtual returns (uint8 option) {
        return hasVoted[issueId][addr].option;
    }

    function Voted(uint256 issueId, address addr) public view virtual returns (bool) {
        return hasVoted[issueId][addr].voted;
    }

    function GetProposalHash(
        uint8 chainID,
        uint64 depositNonce,
        bytes32 dataHash
    ) public pure virtual returns (bytes32) {
        bytes32 proposalHash = keccak256(abi.encodePacked(chainID, depositNonce, dataHash));
        return proposalHash;
    }

    /**
        @notice weightOf function
        @notice Fetches the vote weight of the user.
        @notice Preconditon1 - Function is public and open to all.
        @param addr Address of the person casting vote
        @return weight Vote weight of the voter
    */
    function weightOf(address addr) public view virtual returns (uint256 weight) {
        return balanceOf(addr);
    }

    /**
        @notice getStatus function
        @notice Fetches the status of the proposal.
        @notice Preconditon1 - Function is public and open to all.
        @param issueId Issue ID or proposal ID
        @return status Proposal status of the user
    */
    function getStatus(uint256 issueId) public view virtual returns (ProposalStatus status) {
        return issueMap[issueId].status;
    }

    /**
        @notice weightedVoteCountsOf function
        @notice Fetches the Wieight of the option for a proposal.
        @notice Preconditon1 - Function is public and open to all.
        @param issueId Issue ID or proposal ID
        @param option Option selected by the voters
        @return count Total Count of the option
    */
    function weightedVoteCountsOf(uint256 issueId, uint8 option) public view virtual returns (uint256 count) {
        return voteWeight[issueId][option];
    }

    /**
        @notice fetchIssueMap function
        @notice Fetches the Issue Status.
        @notice Preconditon1 - Function is public and open to all.
        @return issue Details of the issue
    */
    function fetchIssueMap(uint256 _issue) public view virtual returns (issueStruct memory issue) {
        return issueMap[_issue];
    }

    /**
        @notice fetchIsExpired function
        @notice Fetches the Issue is active or inactive.
        @notice Preconditon1 - Function is public and open to all.
        @return status Status of issue
    */
    function fetchIsExpired(uint256 _issue) public view virtual returns (bool status) {
        return block.number >= issueMap[_issue].endBlock;
    }

    /**
        @notice fetchCtr function
        @notice Fetches the Current counters.
        @notice Preconditon1 - Function is public and open to all.
        @return counter Counter for number of proposals
    */
    function fetchCtr() public view virtual returns (uint256 counter) {
        return _IssueCtr.current();
    }
}