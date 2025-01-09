pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;


/**
 * @notice Model library for PaymentExit
 */
library PaymentExitDataModel {
    uint8 constant public MAX_INPUT_NUM = 4;
    uint8 constant public MAX_OUTPUT_NUM = 4;

    /**
     * @dev Exit model for a standard exit
     * @param exitable Boolean that defines whether exit is possible. Used by the challenge game to flag the result.
     * @param utxoPos The UTXO position of the transaction's exiting output
     * @param outputId The output identifier, in OutputId format
     * @param exitTarget The address to which the exit withdraws funds
     * @param amount The amount of funds to withdraw with this exit
     * @param bondSize The size of the bond put up for this exit to start, and which is used to cover the cost of challenges
     */
    struct StandardExit {
        bool exitable;
        uint192 utxoPos;
        bytes32 outputId;
        address payable exitTarget;
        uint256 amount;
        uint256 bondSize;
    }

    /**
     * @dev Mapping of (exitId => StandardExit) that stores all standard exit data
     */
    struct StandardExitMap {
        mapping (uint192 => PaymentExitDataModel.StandardExit) exits;
    }

    /**
     * @dev The necessary data needed for processExit for in-flight exit inputs/outputs
     */
    struct WithdrawData {
        bytes32 outputId;
        address payable exitTarget;
        address token;
        uint256 amount;
        uint256 piggybackBondSize;
    }

    /**
     * @dev Exit model for an in-flight exit
     * @param isCanonical A boolean that defines whether the exit is canonical
     *                    A canonical exit withdraws the outputs while a non-canonical exit withdraws the  inputs
     * @param exitStartTimestamp Timestamp for the start of the exit
     * @param exitMap A bitmap that stores piggyback flags
     * @param position The position of the youngest input of the in-flight exit transaction
     * @param inputs Fixed-size array of data required to withdraw inputs (if undefined, the default value is empty)
     * @param outputs Fixed-size array of data required to withdraw outputs (if undefined, the default value is empty)
     * @param bondOwner Recipient of the bond, when the in-flight exit is processed
     * @param bondSize The size of the bond put up for this exit to start. Used to cover the cost of challenges.
     * @param oldestCompetitorPosition The position of the oldest competing transaction
     *                                 The exiting transaction is only canonical if all competing transactions are younger.
     */
    struct InFlightExit {
        // Canonicity is assumed at start, and can be challenged and set to `false` after start
        // Response to non-canonical challenge can set it back to `true`
        bool isCanonical;
        uint64 exitStartTimestamp;

        /**
         * exit map Stores piggybacks and finalized exits
         * right most 0 ~ MAX_INPUT bits is flagged when input is piggybacked
         * right most MAX_INPUT ~ MAX_INPUT + MAX_OUTPUT bits is flagged when output is piggybacked
         */
        uint256 exitMap;
        uint256 position;
        WithdrawData[MAX_INPUT_NUM] inputs;
        WithdrawData[MAX_OUTPUT_NUM] outputs;
        address payable bondOwner;
        uint256 bondSize;
        uint256 oldestCompetitorPosition;
    }

    /**
     * @dev Mapping of (exitId => InFlightExit) that stores all in-flight exit data
     */
    struct InFlightExitMap {
        mapping (uint160 => PaymentExitDataModel.InFlightExit) exits;
    }
}

library PaymentStandardExitRouterArgs {
    /**
     * @notice Wraps arguments for startStandardExit
     * @param utxoPos Position of the exiting output
     * @param rlpOutputTx The RLP-encoded transaction that creates the exiting output
     * @param outputGuardPreimage (Optional) Output guard preimage data
     * @param outputTxInclusionProof A Merkle proof showing that the transaction was included
    */
    struct StartStandardExitArgs {
        uint192 utxoPos;
        bytes rlpOutputTx;
        bytes outputGuardPreimage;
        bytes outputTxInclusionProof;
    }

    /**
     * @notice Input args data for challengeStandardExit
     * @param exitId Identifier of the standard exit to challenge
     * @param exitingTx RLP-encoded transaction that creates the exiting output
     * @param challengeTx RLP-encoded transaction that spends the exiting output
     * @param inputIndex Input of the challenging tx, corresponding to the exiting output
     * @param witness Witness data that proves the exiting output is spent
     * @param spendingConditionOptionalArgs (Optional) Additional data for the spending condition
     * @param outputGuardPreimage (Optional) The output guard preimage for the challenge tx to use the output
     * @param challengeTxPos (Optional) The position of a MVP protocol challenge tx
     * @param challengeTxInclusionProof (Optional) Provides inclusion proof for a MVP protocol challenge tx
     * @param challengeTxConfirmSig (Optional) Provides the confirm signature of a MVP protocol challenge tx
     */
    struct ChallengeStandardExitArgs {
        uint160 exitId;
        bytes exitingTx;
        bytes challengeTx;
        uint16 inputIndex;
        bytes witness;
        bytes spendingConditionOptionalArgs;
        bytes outputGuardPreimage;
        uint256 challengeTxPos;
        bytes challengeTxInclusionProof;
        bytes challengeTxConfirmSig;
    }
}
//pragma pragma

//pragma pragma

library OutputGuardModel {
    /**
     * @dev The data structure used for IOutputGuardHandler, containing essential data related to output guard
     * @param guard The output guard inside an output
     * @param preimage Original data of the output guard
     */
    struct Data {
        bytes20 guard;
        bytes preimage;
    }
}

/**
 * @notice An interface for utils functions needed to process and get essential data from output guard field.
 * @dev This is required since there are multiple ways of using the field 'output guard'. For instance, in normal
 *      payments the output guard field holds the owner's address directly while for DEX deposits, it uses
 *      the privacy deposit mechanism and becomes hash of output type and preimage.
 */
interface IOutputGuardHandler {
    /**
    * @notice Checks a given output guard data
    */
    function isValid(OutputGuardModel.Data calldata object) external view returns (bool);

    /**
    * @notice Gets the 'exit target' from the data set
    */
    function getExitTarget(OutputGuardModel.Data calldata object) external view returns (address payable);

    /**
    * @notice Gets the 'confirm signature address' from the data set. Returns address(0) if none.
    */
    function getConfirmSigAddress(OutputGuardModel.Data calldata object) external view returns (address);
}
//pragma pragma


//pragma pragma



library BlockModel {
    /**
     * @notice Block data structure that is stored in the contract
     * @param root The Merkle root block hash of the Plasma blocks
     * @param timestamp The timestamp, in seconds, when the block is saved
     */
    struct Block {
        bytes32 root;
        uint256 timestamp;
    }
}


/**
 * @notice Provides a way to quarantine (disable) contracts for a specified period of time
 * @dev The immunitiesRemaining member allows deployment to the platform with some
 * pre-verified contracts that don't get quarantined
 */
library Quarantine {
    struct Data {
        mapping(address => uint256) store;
        uint256 quarantinePeriod;
        uint256 immunitiesRemaining;
    }

    /**
     * @notice Checks whether a contract is quarantined
     */
    function isQuarantined(Data storage _self, address _contractAddress) internal view returns (bool) {
        return block.timestamp < _self.store[_contractAddress];
    }

    /**
     * @notice Places a contract into quarantine
     * @param _contractAddress The address of the contract
     */
    function quarantine(Data storage _self, address _contractAddress) internal {
        require(_contractAddress != address(0), "An empty address cannot be quarantined");
        require(_self.store[_contractAddress] == 0, "The contract is already quarantined");

        if (_self.immunitiesRemaining == 0) {
            _self.store[_contractAddress] = block.timestamp + _self.quarantinePeriod;
        } else {
            _self.immunitiesRemaining--;
        }
    }
}

contract OnlyFromAddress {

    modifier onlyFrom(address caller) {
        require(msg.sender == caller, "Caller address is unauthorized");
        _;
    }
}

contract VaultRegistry is OnlyFromAddress {
    using Quarantine for Quarantine.Data;

    mapping(uint256 => address) private _vaults; // vault id => vault address
    mapping(address => uint256) private _vaultToId; // vault address => vault id
    Quarantine.Data private _vaultQuarantine;

    event VaultRegistered(
        uint256 vaultId,
        address vaultAddress
    );

    /**
     * @dev It takes at least 1 minExitPeriod for each new vault contract to start protecting deposit transaction in mempool
     *      see: https://github.com/omisego/plasma-contracts/issues/173
     */
    constructor(uint256 _minExitPeriod, uint256 _initialImmuneVaults)
        public
    {
        _vaultQuarantine.quarantinePeriod = _minExitPeriod;
        _vaultQuarantine.immunitiesRemaining = _initialImmuneVaults;
    }

    /**
     * @notice interface to get the 'maintainer' address.
     * @dev see discussion here: https://git.io/Je8is
     */
    function getMaintainer() public view returns (address);

    /**
     * @notice A modifier to check that the call is from a non-quarantined vault
     */
    modifier onlyFromNonQuarantinedVault() {
        require(_vaultToId[msg.sender] > 0, "The call is not from a registered vault");
        require(!_vaultQuarantine.isQuarantined(msg.sender), "Vault is quarantined");
        _;
    }

    /**
     * @notice Register a vault within the PlasmaFramework. Only a maintainer can make the call.
     * @dev emits VaultRegistered event to notify clients
     * @param _vaultId The ID for the vault contract to register
     * @param _vaultAddress Address of the vault contract
     */
    function registerVault(uint256 _vaultId, address _vaultAddress) public onlyFrom(getMaintainer()) {
        require(_vaultId != 0, "Should not register with vault ID 0");
        require(_vaultAddress != address(0), "Should not register an empty vault address");
        require(_vaults[_vaultId] == address(0), "The vault ID is already registered");
        require(_vaultToId[_vaultAddress] == 0, "The vault contract is already registered");

        _vaults[_vaultId] = _vaultAddress;
        _vaultToId[_vaultAddress] = _vaultId;
        _vaultQuarantine.quarantine(_vaultAddress);

        emit VaultRegistered(_vaultId, _vaultAddress);
    }

    /**
     * @notice Public getter for retrieving vault address with vault ID
     */
    function vaults(uint256 _vaultId) public view returns (address) {
        return _vaults[_vaultId];
    }

    /**
     * @notice Public getter for retrieving vault ID with vault address
     */
    function vaultToId(address _vaultAddress) public view returns (uint256) {
        return _vaultToId[_vaultAddress];
    }
}

/**
* @notice Controls the logic and functions for block submissions in PlasmaFramework
* @dev There are two types of blocks: child block and deposit block
*      Each child block has an interval of 'childBlockInterval'
*      The interval is preserved for deposits. Each deposit results in one deposit block.
*      For instance, a child block would be in block 1000 and the next deposit would result in block 1001.
*
*      Only the authority address can perform a block submission.
*      Details on limitations for the authority address can be found here: https://github.com/omisego/elixir-omg#managing-the-operator-address
*/
contract BlockController is OnlyFromAddress, VaultRegistry {
    address public authority;
    uint256 public childBlockInterval;
    uint256 public nextChildBlock;
    uint256 public nextDeposit;
    bool public isChildChainActivated;

    mapping (uint256 => BlockModel.Block) public blocks; // block number => Block data

    event BlockSubmitted(
        uint256 blockNumber
    );

    event ChildChainActivated(
        address authority
    );

    constructor(
        uint256 _interval,
        uint256 _minExitPeriod,
        uint256 _initialImmuneVaults,
        address _authority
    )
        public
        VaultRegistry(_minExitPeriod, _initialImmuneVaults)
    {
        authority = _authority;
        childBlockInterval = _interval;
        nextChildBlock = childBlockInterval;
        nextDeposit = 1;
        isChildChainActivated = false;
    }

    /**
     * @notice Activates the child chain so that child chain can start to submit child blocks to root chain
     * @notice Can only be called once by the authority.
     * @notice Sets isChildChainActivated to true and emits the ChildChainActivated event.
     * @dev This is a preserved action for authority account to start its nonce with 1.
     *      Child chain rely ethereum nonce to protect re-org: https://git.io/JecDG
     *      see discussion: https://git.io/JenaT, https://git.io/JecDO
     */
    function activateChildChain() external onlyFrom(authority) {
        require(isChildChainActivated == false, "Child chain already activated");
        isChildChainActivated = true;
        emit ChildChainActivated(authority);
    }

    /**
     * @notice Allows the operator to set a new authority address, enabling implementation of mechanical
     * re-org protection mechanism described here: https://github.com/omisego/plasma-contracts/issues/118
     * @param newAuthority Address of new authority, which cannot be blank
     */
    function setAuthority(address newAuthority) external onlyFrom(authority) {
        require(newAuthority != address(0), "Authority address cannot be zero");
        authority = newAuthority;
    }

    /**
     * @notice Allows the authority to submit the Merkle root of a Plasma block
     * @dev emit BlockSubmitted event
     * @dev Block number jumps 'childBlockInterval' per submission
     * @dev See discussion in https://github.com/omisego/plasma-contracts/issues/233
     * @param _blockRoot Merkle root of the Plasma block
     */
    function submitBlock(bytes32 _blockRoot) external onlyFrom(authority) {
        require(isChildChainActivated == true, "Child chain has not been activated by authority address yet");
        uint256 submittedBlockNumber = nextChildBlock;

        blocks[submittedBlockNumber] = BlockModel.Block({
            root: _blockRoot,
            timestamp: block.timestamp
        });

        nextChildBlock += childBlockInterval;
        nextDeposit = 1;

        emit BlockSubmitted(submittedBlockNumber);
    }

    /**
     * @notice Submits a block for deposit
     * @dev Block number adds 1 per submission; it's possible to have at most 'childBlockInterval' deposit blocks between two child chain blocks
     * @param _blockRoot Merkle root of the Plasma block
     * @return The deposit block number
     */
    function submitDepositBlock(bytes32 _blockRoot) public onlyFromNonQuarantinedVault returns (uint256) {
        require(isChildChainActivated == true, "Child chain has not been activated by authority address yet");
        require(nextDeposit < childBlockInterval, "Exceeded limit of deposits per child block interval");

        uint256 blknum = nextDepositBlock();
        blocks[blknum] = BlockModel.Block({
            root : _blockRoot,
            timestamp : block.timestamp
        });

        nextDeposit++;
        return blknum;
    }

    function nextDepositBlock() public view returns (uint256) {
        return nextChildBlock - childBlockInterval + nextDeposit;
    }
}
//pragma pragma


/**
 * @dev An interface that allows custom logic to process exits for different requirements.
 *      This interface is used to dispatch to each custom processor when 'processExits' is called on PlasmaFramework.
 */
interface IExitProcessor {
    /**
     * @dev Function interface for processing exits.
     * @param exitId Unique ID for exit per tx type
     * @param vaultId ID of the vault that funds the exit
     * @param token Address of the token contract
     */
    function processExit(uint160 exitId, uint256 vaultId, address token) external;
}


/**
 * @notice Protocols for the PlasmaFramework
 */
library Protocol {
    uint8 constant internal MVP_VALUE = 1;
    uint8 constant internal MORE_VP_VALUE = 2;

    // solhint-disable-next-line func-name-mixedcase
    function MVP() internal pure returns (uint8) {
        return MVP_VALUE;
    }

    // solhint-disable-next-line func-name-mixedcase
    function MORE_VP() internal pure returns (uint8) {
        return MORE_VP_VALUE;
    }

    function isValidProtocol(uint8 protocol) internal pure returns (bool) {
        return protocol == MVP_VALUE || protocol == MORE_VP_VALUE;
    }
}

contract ExitGameRegistry is OnlyFromAddress {
    using Quarantine for Quarantine.Data;

    mapping(uint256 => address) private _exitGames; // txType => exit game contract address
    mapping(address => uint256) private _exitGameToTxType; // exit game contract address => tx type
    mapping(uint256 => uint8) private _protocols; // tx type => protocol (MVP/MORE_VP)
    Quarantine.Data private _exitGameQuarantine;

    event ExitGameRegistered(
        uint256 txType,
        address exitGameAddress,
        uint8 protocol
    );

    /**
     * @dev It takes at least 3 * minExitPeriod before each new exit game contract is able to start protecting existing transactions
     *      see: https://github.com/omisego/plasma-contracts/issues/172
     *           https://github.com/omisego/plasma-contracts/issues/197
     */
    constructor (uint256 _minExitPeriod, uint256 _initialImmuneExitGames)
        public
    {
        _exitGameQuarantine.quarantinePeriod = 3 * _minExitPeriod;
        _exitGameQuarantine.immunitiesRemaining = _initialImmuneExitGames;
    }

    /**
     * @notice A modifier to verify that the call is from a non-quarantined exit game
     */
    modifier onlyFromNonQuarantinedExitGame() {
        require(_exitGameToTxType[msg.sender] != 0, "The call is not from a registered exit game contract");
        require(!_exitGameQuarantine.isQuarantined(msg.sender), "ExitGame is quarantined");
        _;
    }

    /**
     * @notice interface to get the 'maintainer' address.
     * @dev see discussion here: https://git.io/Je8is
     */
    function getMaintainer() public view returns (address);

    /**
     * @notice Checks whether the contract is safe to use and is not under quarantine
     * @dev Exposes information about exit games quarantine
     * @param _contract Address of the exit game contract
     * @return boolean Whether the contract is safe to use and is not under quarantine
     */
    function isExitGameSafeToUse(address _contract) public view returns (bool) {
        return _exitGameToTxType[_contract] != 0 && !_exitGameQuarantine.isQuarantined(_contract);
    }

    /**
     * @notice Registers an exit game within the PlasmaFramework. Only the maintainer can call the function.
     * @dev Emits ExitGameRegistered event to notify clients
     * @param _txType The tx type where the exit game wants to register
     * @param _contract Address of the exit game contract
     * @param _protocol The transaction protocol, either 1 for MVP or 2 for MoreVP
     */
    function registerExitGame(uint256 _txType, address _contract, uint8 _protocol) public onlyFrom(getMaintainer()) {
        require(_txType != 0, "Should not register with tx type 0");
        require(_contract != address(0), "Should not register with an empty exit game address");
        require(_exitGames[_txType] == address(0), "The tx type is already registered");
        require(_exitGameToTxType[_contract] == 0, "The exit game contract is already registered");
        require(Protocol.isValidProtocol(_protocol), "Invalid protocol value");

        _exitGames[_txType] = _contract;
        _exitGameToTxType[_contract] = _txType;
        _protocols[_txType] = _protocol;
        _exitGameQuarantine.quarantine(_contract);

        emit ExitGameRegistered(_txType, _contract, _protocol);
    }

    /**
     * @notice Public getter for retrieving protocol with tx type
     */
    function protocols(uint256 _txType) public view returns (uint8) {
        return _protocols[_txType];
    }

    /**
     * @notice Public getter for retrieving exit game address with tx type
     */
    function exitGames(uint256 _txType) public view returns (address) {
        return _exitGames[_txType];
    }

    /**
     * @notice Public getter for retrieving tx type with exit game address
     */
    function exitGameToTxType(address _exitGame) public view returns (uint256) {
        return _exitGameToTxType[_exitGame];
    }
}




/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title PriorityQueue
 * @dev Min-heap priority queue implementation
 */
contract PriorityQueue is OnlyFromAddress {
    using SafeMath for uint256;

    struct Queue {
        uint256[] heapList;
        uint256 currentSize;
    }

    Queue private queue;
    address private framework;

    constructor() public {
        queue.heapList = [0];
        queue.currentSize = 0;

        // it is expected that this should be called by PlasmaFramework
        // and only PlasmaFramework contract can add things to the queue
        framework = msg.sender;
    }

    /**
     * @notice Gets num of elements in the queue
     */
    function currentSize() external view returns (uint256) {
        return queue.currentSize;
    }

    /**
     * @notice Gets all elements in the queue
     */
    function heapList() external view returns (uint256[] memory) {
        return queue.heapList;
    }

    /**
     * @notice Inserts an element into the queue by the owner
     * @dev Does not perform deduplication
     */
    function insert(uint256 _element) external onlyFrom(framework) {
        queue.heapList.push(_element);
        queue.currentSize = queue.currentSize.add(1);
        percUp(queue, queue.currentSize);
    }

    /**
     * @notice Deletes the smallest element from the queue
     * @return The smallest element in the priority queue
     */
    function delMin() external onlyFrom(framework) returns (uint256) {
        uint256 retVal = queue.heapList[1];
        queue.heapList[1] = queue.heapList[queue.currentSize];
        delete queue.heapList[queue.currentSize];
        queue.currentSize = queue.currentSize.sub(1);
        percDown(queue, 1);
        queue.heapList.length = queue.heapList.length.sub(1);
        return retVal;
    }

    /**
     * @notice Returns the smallest element from the queue
     * @dev Fails when queue is empty
     * @return The smallest element in the priority queue
     */
    function getMin() external view returns (uint256) {
        return queue.heapList[1];
    }

    function percUp(Queue storage self, uint256 pointer) private {
        uint256 i = pointer;
        uint256 j = i;
        uint256 newVal = self.heapList[i];
        while (newVal < self.heapList[i.div(2)]) {
            self.heapList[i] = self.heapList[i.div(2)];
            i = i.div(2);
        }
        if (i != j) {
            self.heapList[i] = newVal;
        }
    }

    function percDown(Queue storage self, uint256 pointer) private {
        uint256 i = pointer;
        uint256 j = i;
        uint256 newVal = self.heapList[i];
        uint256 mc = minChild(self, i);
        while (mc <= self.currentSize && newVal > self.heapList[mc]) {
            self.heapList[i] = self.heapList[mc];
            i = mc;
            mc = minChild(self, i);
        }
        if (i != j) {
            self.heapList[i] = newVal;
        }
    }

    function minChild(Queue storage self, uint256 i) private view returns (uint256) {
        if (i.mul(2).add(1) > self.currentSize) {
            return i.mul(2);
        } else {
            if (self.heapList[i.mul(2)] < self.heapList[i.mul(2).add(1)]) {
                return i.mul(2);
            } else {
                return i.mul(2).add(1);
            }
        }
    }
}


/**
 * @dev Transaction position = (blockNumber * BLOCK_OFFSET_FOR_TX_POS + txIndex)
 */
library TxPosLib {
    struct TxPos {
        uint256 value;
    }

    uint256 constant internal BLOCK_OFFSET_FOR_TX_POS = 1000000000 / 10000;

    /**
     * @notice Returns the block number for a given a tx position
     * @param _txPos Position of the transaction
     * @return Block number of the output
     */
    function blockNum(TxPos memory _txPos)
        internal
        pure
        returns (uint256)
    {
        return _txPos.value / BLOCK_OFFSET_FOR_TX_POS;
    }

    /**
     * @notice Returns the transaction index for a given tx position
     * @param _txPos Position of the transaction
     * @return Transaction index of the output
     */
    function txIndex(TxPos memory _txPos)
        internal
        pure
        returns (uint256)
    {
        return _txPos.value % BLOCK_OFFSET_FOR_TX_POS;
    }
}

library ExitPriority {

    /**
     * @dev Returns an exit priority for a given UTXO position and a unique ID.
     * The priority for Plasma M(ore)VP protocol is a combination of 'exitableAt' and 'txPos'.
     * Since 'exitableAt' only provides granularity of block, add 'txPos' to provide priority for a transaction.
     * @notice Detailed explanation on field lengths can be found at https://github.com/omisego/plasma-contracts/pull/303#discussion_r328850572
     * @param exitId Unique exit identifier
     * @return An exit priority
     *   Anatomy of returned value, most significant bits first
     *   42 bits  - timestamp in seconds (exitable_at); we can represent dates until year 141431
     *   54 bits  - blknum * CHILD_BLOCK_INTERVAL * 10^5 + txindex; 54 bits represent all transactions for 85 years. We are assuming CHILD_BLOCK_INTERVAL = 1000.
     *   160 bits - exit id
     */
    function computePriority(uint64 exitableAt, TxPosLib.TxPos memory txPos, uint160 exitId)
        internal
        pure
        returns (uint256)
    {
        return (uint256(exitableAt) << 214) | (txPos.value << 160) | uint256(exitId);
    }

    function parseExitableAt(uint256 priority) internal pure returns (uint64) {
        return uint64(priority >> 214);
    }

    function parseExitId(uint256 priority) internal pure returns (uint160) {
        // Exit ID uses only 160 least significant bits
        return uint160(priority);
    }
}

/**
 * @notice Controls the logic and functions for ExitGame to interact with the PlasmaFramework
 *         Plasma M(ore)VP relies on exit priority to secure the user from invalid transactions
 *         The priority queue ensures the exit is processed with the exit priority
 *         For details, see the Plasma MVP spec: https://ethresear.ch/t/minimal-viable-plasma/426
 */
contract ExitGameController is ExitGameRegistry {
    // exit priority => IExitProcessor
    mapping (uint256 => IExitProcessor) public delegations;
    // hashed (vault id, token) => PriorityQueue
    mapping (bytes32 => PriorityQueue) public exitsQueues;
    // outputId => bool
    mapping (bytes32 => bool) public isOutputSpent;
    bool private mutex = false;

    event ExitQueueAdded(
        uint256 vaultId,
        address token
    );

    event ProcessedExitsNum(
        uint256 processedNum,
        uint256 vaultId,
        address token
    );

    event ExitQueued(
        uint160 indexed exitId,
        uint256 priority
    );

    constructor(uint256 _minExitPeriod, uint256 _initialImmuneExitGames)
        public
        ExitGameRegistry(_minExitPeriod, _initialImmuneExitGames)
    {
    }

    /**
     * @dev Prevents reentrant calls by using a mutex.
     */
    modifier nonReentrant() {
        require(!mutex, "Reentrant call");
        mutex = true;
        _;
        require(mutex, "Not locked");
        mutex = false;
    }

    /**
     * @notice Activates non reentrancy mode
     *         Guards against reentering into publicly accessible code that modifies state related to exits
     * @dev Accessible only from non quarantined exit games, uses a mutex
     */
    function activateNonReentrant() external onlyFromNonQuarantinedExitGame() {
        require(!mutex, "Reentrant call");
        mutex = true;
    }

    /**
     * @notice Deactivates non reentrancy mode
     * @dev Accessible only from non quarantined exit games, uses a mutex
     */
    function deactivateNonReentrant() external onlyFromNonQuarantinedExitGame() {
        require(mutex, "Not locked");
        mutex = false;
    }

    /**
     * @notice Checks if the queue for a specified token was created
     * @param vaultId ID of the vault that handles the token
     * @param token Address of the token
     * @return bool Defines whether the queue for a token was created
     */
    function hasExitQueue(uint256 vaultId, address token) public view returns (bool) {
        bytes32 key = exitQueueKey(vaultId, token);
        return hasExitQueue(key);
    }

    /**
     * @notice Adds queue to the Plasma framework
     * @dev The queue is created as a new contract instance
     * @param vaultId ID of the vault
     * @param token Address of the token
     */
    function addExitQueue(uint256 vaultId, address token) external {
        require(vaultId != 0, "Vault ID must not be 0");
        bytes32 key = exitQueueKey(vaultId, token);
        require(!hasExitQueue(key), "Exit queue exists");
        exitsQueues[key] = new PriorityQueue();
        emit ExitQueueAdded(vaultId, token);
    }

    /**
     * @notice Enqueue exits from exit game contracts is a function that places the exit into the
     *         priority queue to enforce the priority of exit during 'processExits'
     * @dev emits ExitQueued event, which can be used to back trace the priority inside the queue
     * @dev Caller of this function should add "pragma experimental ABIEncoderV2;" on top of file
     * @param vaultId Vault ID of the vault that stores exiting funds
     * @param token Token for the exit
     * @param exitableAt The earliest time a specified exit can be processed
     * @param txPos Transaction position for the exit priority. For SE it should be the exit tx, for IFE it should be the youngest input tx position.
     * @param exitId ID used by the exit processor contract to determine how to process the exit
     * @param exitProcessor The exit processor contract, called during "processExits"
     * @return A unique priority number computed for the exit
     */
    function enqueue(
        uint256 vaultId,
        address token,
        uint64 exitableAt,
        TxPosLib.TxPos calldata txPos,
        uint160 exitId,
        IExitProcessor exitProcessor
    )
        external
        onlyFromNonQuarantinedExitGame
        returns (uint256)
    {
        bytes32 key = exitQueueKey(vaultId, token);
        require(hasExitQueue(key), "The queue for the (vaultId, token) pair is not yet added to the Plasma framework");
        PriorityQueue queue = exitsQueues[key];

        uint256 priority = ExitPriority.computePriority(exitableAt, txPos, exitId);

        queue.insert(priority);
        delegations[priority] = exitProcessor;

        emit ExitQueued(exitId, priority);
        return priority;
    }

    /**
     * @notice Processes any exits that have completed the challenge period. Exits are processed according to the exit priority.
     * @dev Emits ProcessedExitsNum event
     * @param vaultId Vault ID of the vault that stores exiting funds
     * @param token The token type to process
     * @param topExitId Unique identifier for prioritizing the first exit to process. Set to zero to skip this check.
     * @param maxExitsToProcess Maximum number of exits to process
     * @return Total number of processed exits
     */
    function processExits(uint256 vaultId, address token, uint160 topExitId, uint256 maxExitsToProcess) external nonReentrant {
        bytes32 key = exitQueueKey(vaultId, token);
        require(hasExitQueue(key), "The token is not yet added to the Plasma framework");
        PriorityQueue queue = exitsQueues[key];
        require(queue.currentSize() > 0, "Exit queue is empty");

        uint256 uniquePriority = queue.getMin();
        uint160 exitId = ExitPriority.parseExitId(uniquePriority);
        require(topExitId == 0 || exitId == topExitId,
            "Top exit ID of the queue is different to the one specified");

        IExitProcessor processor = delegations[uniquePriority];
        uint256 processedNum = 0;

        while (processedNum < maxExitsToProcess && ExitPriority.parseExitableAt(uniquePriority) < block.timestamp) {
            delete delegations[uniquePriority];
            queue.delMin();
            processedNum++;

            processor.processExit(exitId, vaultId, token);

            if (queue.currentSize() == 0) {
                break;
            }

            uniquePriority = queue.getMin();
            exitId = ExitPriority.parseExitId(uniquePriority);
            processor = delegations[uniquePriority];
        }

        emit ProcessedExitsNum(processedNum, vaultId, token);
    }

    /**
     * @notice Checks whether any of the output with the given outputIds is already spent
     * @param _outputIds Output IDs to check
     */
    function isAnyOutputsSpent(bytes32[] calldata _outputIds) external view returns (bool) {
        for (uint i = 0; i < _outputIds.length; i++) {
            if (isOutputSpent[_outputIds[i]] == true) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Batch flags already spent outputs
     * @param _outputIds Output IDs to flag
     */
    function batchFlagOutputsSpent(bytes32[] calldata _outputIds) external onlyFromNonQuarantinedExitGame {
        for (uint i = 0; i < _outputIds.length; i++) {
            require(_outputIds[i] != bytes32(""), "Should not flag with empty outputId");
            isOutputSpent[_outputIds[i]] = true;
        }
    }

    /**
     * @notice Flags a single output as spent
     * @param _outputId The output ID to flag as spent
     */
    function flagOutputSpent(bytes32 _outputId) external onlyFromNonQuarantinedExitGame {
        require(_outputId != bytes32(""), "Should not flag with empty outputId");
        isOutputSpent[_outputId] = true;
    }

    function getNextExit(uint256 vaultId, address token) external view returns (uint256) {
        bytes32 key = exitQueueKey(vaultId, token);
        return exitsQueues[key].getMin();
    }

    function exitQueueKey(uint256 vaultId, address token) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(vaultId, token));
    }

    function hasExitQueue(bytes32 queueKey) private view returns (bool) {
        return address(exitsQueues[queueKey]) != address(0);
    }
}
// SWC-Code With No Effects: L7
// SWC-Code With No Effects: L10
contract PlasmaFramework is VaultRegistry, ExitGameRegistry, ExitGameController, BlockController {
    uint256 public constant CHILD_BLOCK_INTERVAL = 1000;

    /**
     * The minimum finalization period is the Plasma guarantee that all exits are safe provided the user takes action within the specified time period
     * When the child chain is rogue, user should start their exit and challenge any invalid exit within this period
     * An exit can be processed/finalized after minimum two finalization periods from its inclusion position, unless it is an exit for a deposit,
     * which would use one finalization period, instead of two
     *
     * For the Abstract Layer Design, OmiseGO also uses some multitude of this period to update its framework
     * See also ExitGameRegistry.sol, VaultRegistry.sol, and Vault.sol for more information on the update waiting time (the quarantined period)
     *
     * MVP: https://ethresear.ch/t/minimal-viable-plasma/426
     * MoreVP: https://github.com/omisego/elixir-omg/blob/master/docs/morevp.md#timeline
     * Special period for deposit: https://git.io/JecCV
     */
    uint256 public minExitPeriod;
    address private maintainer;

    constructor(
        uint256 _minExitPeriod,
        uint256 _initialImmuneVaults,
        uint256 _initialImmuneExitGames,
        address _authority,
        address _maintainer
    )
        public
        BlockController(CHILD_BLOCK_INTERVAL, _minExitPeriod, _initialImmuneVaults, _authority)
        ExitGameController(_minExitPeriod, _initialImmuneExitGames)
    {
        minExitPeriod = _minExitPeriod;
        maintainer = _maintainer;
    }

    function getMaintainer() public view returns (address) {
        return maintainer;
    }
}

library TxFinalizationModel {
    /**
     * @param framework Plasma framework contract
     * @param protocol Either MVP or MoreVp. See 'Protocol.sol' for the representive value
     * @param txBytes Encoded transaction, in bytes, which checks the finalization
     * @param txPos (Optional) Tx position of the transaction
     * @param inclusionProof (Optional) Inclusion proof for the Merkle path of the transaction
     * @param confirmSig (Optional) Confirm signature of the transaction
     * @param confirmSigAddress (Optional) Confirm signature address to check with
     */
    struct Data {
        PlasmaFramework framework;
        uint8 protocol;
        bytes txBytes;
        TxPosLib.TxPos txPos;
        bytes inclusionProof;
        bytes confirmSig;
        address confirmSigAddress;
    }

    function moreVpData(
        PlasmaFramework framework,
        bytes memory txBytes,
        TxPosLib.TxPos memory txPos,
        bytes memory inclusionProof
    )
        internal
        pure
        returns (Data memory)
    {
        // MoreVP protocol does not require check on confirm signature, thus putting empty value for related field.
        return Data({
            framework: framework,
            protocol: Protocol.MORE_VP(),
            txBytes: txBytes,
            txPos: txPos,
            inclusionProof: inclusionProof,
            confirmSig: bytes(""),
            confirmSigAddress: address(0)
        });
    }
}

/**
 * @notice Interface for the code that checks the finalization status of a transaction
 * @dev We define two kinds of finalization: Protocol and Standard
 *      1. Protocol Finalization: A transaction is considered finalized for the protocol to spend its input transaction.
 *      2. Standard Finalization: A protocol finalized transaction has a clear position (being mined) in the Plasma block
 *      > For MVP:
 *         a. Protocol finalized: Confirm signature must be present. Since confirm signature requires the transaction to be mined in a block,
 *            it will also have a clear position. Thus, protocol finalization would be same as standard finalization for MVP protocol.
 *         b. Standard finalized: Confirm signature must be present, and the transaction is mined in a Plasma block
 *      > For MoreVp:
 *         a. Protocol finalized: Since MoreVP allows in-flight transactions, any existing transaction
 *         b. Standard finalized: The transaction is mined in a Plasma block
 *
 * @dev We've chosen to use an interface in our first deployment cycle since there will be no MVP protocol transactions. This means we can remain open to how we will handle MVP in future. For example, we can check the confirm sig by block root hash, or (block root hash, block number) pair, or even with EIP712 format. Keeping this upgradeable provides flexibility and allows us to test with our real MVP transactions in future.

 *      See: https://github.com/omisego/plasma-contracts/issues/301#issuecomment-535430135
 */
interface ITxFinalizationVerifier {
    /**
    * @notice Checks whether a transaction is "standard finalized"
    * @dev MVP: Requires that both inclusion proof and confirm signature is verified
    * @dev MoreVp: Checks inclusion proof
    */
    function isStandardFinalized(Model.Data calldata self) external view returns (bool);

    /**
    * @notice Checks whether a transaction is "protocol finalized"
    * @dev MVP: Must be standard finalized
    * @dev MoreVp: Allows in-flight tx, so only checks that the transaction exists
    */
    function isProtocolFinalized(Model.Data calldata self) external view returns (bool);
}



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

/**
 * @title OutputGuardHandlerRegistry
 * @notice The registry contracts of outputGuard handler
 * @dev This is designed to renounce the ownership before injecting the registry contract to the ExitGame contracts
 *      After registering all the essential condition contracts, the owner should renounce its ownership to
 *      ensure no further conditions are registered for an ExitGame contract.
 *      https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/ownership/Ownable.sol#L55
 */
contract OutputGuardHandlerRegistry is Ownable {
    // mapping of outputType to IOutputGuardHandler
    mapping(uint256 => IOutputGuardHandler) public outputGuardHandlers;

    /**
     * @notice Register the output guard handler
     * @param outputType The output type registered with the parser
     * @param handler The output guard handler contract
     */
    function registerOutputGuardHandler(uint256 outputType, IOutputGuardHandler handler)
        public
        onlyOwner
    {
        require(outputType != 0, "Registration not possible with output type 0");
        require(address(handler) != address(0), "Registration not possible with an empty address");
        require(address(outputGuardHandlers[outputType]) == address(0), "Output type already registered");

        outputGuardHandlers[outputType] = handler;
    }
}



/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

library ExitableTimestamp {
    struct Calculator {
        uint256 minExitPeriod;
    }

    /**
     * @notice Calculates the exitable timestamp for a mined transaction
     * @dev This is the main function when asking for exitable timestamp in most cases.
     *      The only exception is to calculate the exitable timestamp for a deposit output in standard exit.
     *      Should use the function 'calculateDepositTxOutputExitableTimestamp' for that case.
     */
    function calculateTxExitableTimestamp(
        Calculator memory _calculator,
        uint256 _now,
        uint256 _blockTimestamp
    )
        internal
        pure
        returns (uint64)
    {
        return uint64(Math.max(_blockTimestamp + (_calculator.minExitPeriod * 2), _now + _calculator.minExitPeriod));
    }

    /**
     * @notice Calculates the exitable timestamp for deposit transaction output for standard exit
     * @dev This function should only be used in standard exit for calculating exitable timestamp of a deposit output.
     *      For in-fight exit, the priority of a input tx which is a deposit tx should still be using the another function 'calculateTxExitableTimestamp'.
     *      See discussion here: https://git.io/Je4N5
     *      Reason of deposit output has different exitable timestamp: https://git.io/JecCV
     */
    function calculateDepositTxOutputExitableTimestamp(
        Calculator memory _calculator,
        uint256 _now
    )
        internal
        pure
        returns (uint64)
    {
        return uint64(_now + _calculator.minExitPeriod);
    }
}


/**
 * @title Bits
 * @dev Operations on individual bits of a word
 */
library Bits {
    /*
     * Storage
     */

    uint constant internal ONE = uint(1);

    /*
     * Internal functions
     */
    /**
     * @dev Sets the bit at the given '_index' in '_self' to '1'
     * @param _self Uint to modify
     * @param _index Index of the bit to set
     * @return The modified value
     */
    function setBit(uint _self, uint8 _index)
        internal
        pure
        returns (uint)
    {
        return _self | ONE << _index;
    }

    /**
     * @dev Sets the bit at the given '_index' in '_self' to '0'
     * @param _self Uint to modify
     * @param _index Index of the bit to set
     * @return The modified value
     */
    function clearBit(uint _self, uint8 _index)
        internal
        pure
        returns (uint)
    {
        return _self & ~(ONE << _index);
    }

    /**
     * @dev Returns the bit at the given '_index' in '_self'
     * @param _self Uint to check
     * @param _index Index of the bit to retrieve
     * @return The value of the bit at '_index'
     */
    function getBit(uint _self, uint8 _index)
        internal
        pure
        returns (uint8)
    {
        return uint8(_self >> _index & 1);
    }

    /**
     * @dev Checks if the bit at the given '_index' in '_self' is '1'
     * @param _self Uint to check
     * @param _index Index of the bit to check
     * @return True, if the bit is '0'; otherwise, False
     */
    function bitSet(uint _self, uint8 _index)
        internal
        pure
        returns (bool)
    {
        return getBit(_self, _index) == 1;
    }
}



/**
 * @dev UTXO position = (blockNumber * BLOCK_OFFSET + txIndex * TX_OFFSET + outputIndex).
 */
library UtxoPosLib {
    using SafeMath for uint256;

    struct UtxoPos {
        uint256 value;
    }

    uint256 constant internal BLOCK_OFFSET = 1000000000;
    uint256 constant internal TX_OFFSET = 10000;

    /**
     * @notice Returns the UTXO struct for a given txPos and outputIndex
     * @param txPos Transaction position
     * @param outputIndex Transaction index of the output
     * @return UtxoPos of the relevant value
     */
    function build(TxPosLib.TxPos memory txPos, uint16 outputIndex)
        internal
        pure
        returns (UtxoPos memory)
    {
        return UtxoPos(txPos.value.mul(TX_OFFSET).add(outputIndex));
    }

    /**
     * @notice Returns the block number of a given UTXO position
     * @param _utxoPos UTXO position identifier for the output
     * @return The block number of the output
     */
    function blockNum(UtxoPos memory _utxoPos)
        internal
        pure
        returns (uint256)
    {
        return _utxoPos.value / BLOCK_OFFSET;
    }

    /**
     * @notice Returns the transaction index of a given UTXO position
     * @param _utxoPos UTXO position identifier for the output
     * @return Transaction index of the output
     */
    function txIndex(UtxoPos memory _utxoPos)
        internal
        pure
        returns (uint256)
    {
        return (_utxoPos.value % BLOCK_OFFSET) / TX_OFFSET;
    }

    /**
     * @notice Returns the output index of a given UTXO position
     * @param _utxoPos UTXO position identifier for the output
     * @return Index of the output
     */
    function outputIndex(UtxoPos memory _utxoPos)
        internal
        pure
        returns (uint16)
    {
        return uint16(_utxoPos.value % TX_OFFSET);
    }

    /**
     * @notice Returns the transaction position of a given UTXO position
     * @param _utxoPos UTXO position identifier for the output
     * @return Position of the transaction
     */
    function txPos(UtxoPos memory _utxoPos)
        internal
        pure
        returns (TxPosLib.TxPos memory)
    {
        return TxPosLib.TxPos(_utxoPos.value / TX_OFFSET);
    }
}

library ExitId {
    using UtxoPosLib for UtxoPosLib.UtxoPos;
    using Bits for uint160;
    using Bits for uint256;

    /**
     * @notice Checks whether exitId is a standard exit ID
     */
    function isStandardExit(uint160 _exitId) internal pure returns (bool) {
        return _exitId.getBit(151) == 0;
    }

    /**
     * @notice Given transaction bytes and UTXO position, returns its exit ID
     * @dev Computation of a depost ID is different to any other tx because txBytes of a deposit tx can be a non-unique value
     * @notice Output index must be within range 0 - 255
     * @param _isDeposit Defines whether the tx for the exitId is a deposit tx
     * @param _txBytes Transaction bytes
     * @param _utxoPos UTXO position of the exiting output
     * @return _standardExitId Unique ID of the standard exit
     *     Anatomy of returned value, most significant bits first:
     *     8-bits - output index
     *     1-bit - in-flight flag (0 for standard exit)
     *     151-bits - hash(tx) or hash(tx|utxo) for deposit
     */
    function getStandardExitId(
        bool _isDeposit,
        bytes memory _txBytes,
        UtxoPosLib.UtxoPos memory _utxoPos
    )
        internal
        pure
        returns (uint160)
    {
        if (_isDeposit) {
            bytes32 hashData = keccak256(abi.encodePacked(_txBytes, _utxoPos.value));
            return _computeStandardExitId(hashData, _utxoPos.outputIndex());
        }

        return _computeStandardExitId(keccak256(_txBytes), _utxoPos.outputIndex());
    }

    /**
    * @notice Given transaction bytes, returns in-flight exit ID
    * @param _txBytes Transaction bytes
    * @return Unique in-flight exit ID
    */
    function getInFlightExitId(bytes memory _txBytes) internal pure returns (uint160) {
        return uint160((uint256(keccak256(_txBytes)) >> 105).setBit(151));
    }

    function _computeStandardExitId(bytes32 _txhash, uint16 _outputIndex)
        private
        pure
        returns (uint160)
    {
        uint256 exitId = (uint256(_txhash) >> 105) | (uint256(_outputIndex) << 152);
        uint160 croppedExitId = uint160(exitId);

        require(uint256(croppedExitId) == exitId, "ExitId overflows");

        return croppedExitId;
    }
}

library OutputId {
    /**
     * @notice Computes the output ID for a deposit tx
     * @dev Deposit tx bytes might not be unique because all inputs are empty
     *      Two deposits with the same output value would result in the same tx bytes
     *      As a result, we need to hash with utxoPos to ensure uniqueness
     * @param _txBytes Transaction bytes
     * @param _outputIndex Output index of the output
     * @param _utxoPosValue (Optional) UTXO position of the deposit output
     */
    function computeDepositOutputId(bytes memory _txBytes, uint256 _outputIndex, uint256 _utxoPosValue)
        internal
        pure
        returns(bytes32)
    {
        return keccak256(abi.encodePacked(_txBytes, _outputIndex, _utxoPosValue));
    }

    /**
     * @notice Computes the output ID for normal (non-deposit) tx
     * @dev Since txBytes for non-deposit tx is unique, directly hash the txBytes with outputIndex
     * @param _txBytes Transaction bytes
     * @param _outputIndex Output index of the output
     */
    function computeNormalOutputId(bytes memory _txBytes, uint256 _outputIndex)
        internal
        pure
        returns(bytes32)
    {
        return keccak256(abi.encodePacked(_txBytes, _outputIndex));
    }
}

//pragma pragma

/*
* @author Hamdi Allam hamdi.allam97@gmail.com
* Please reach out with any questions or concerns
*/

library RLPReader {
    uint8 constant internal STRING_SHORT_START = 0x80;
    uint8 constant internal STRING_LONG_START  = 0xb8;
    uint8 constant internal LIST_SHORT_START   = 0xc0;
    uint8 constant internal LIST_LONG_START    = 0xf8;
    uint8 constant internal MAX_SHORT_LEN      = 55;
    uint8 constant internal WORD_SIZE = 32;

    struct RLPItem {
        uint len;
        uint memPtr;
    }

    /*
    * @param item RLP encoded bytes
    */
    function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
        uint memPtr;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            memPtr := add(item, 0x20)
        }

        return RLPItem(item.length, memPtr);
    }

    /*
    * @param item RLP encoded list in bytes
    */
    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory) {
        require(isList(item), "Item is not a list");

        uint itemLen = _itemLength(item.memPtr);
        require(itemLen <= item.len, "Length is larger than data");

        uint items = numItems(item);
        RLPItem[] memory result = new RLPItem[](items);

        uint memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint dataLen;
        uint lengthSum;
        for (uint i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            lengthSum += dataLen;
            require(lengthSum < item.len, "Invalid rlp item length");
            result[i] = RLPItem(dataLen, memPtr);
            memPtr = memPtr + dataLen;
        }

        return result;
    }

    // @return indicator whether encoded payload is a list. negate this function call for isData.
    function isList(RLPItem memory item) internal pure returns (bool) {
        if (item.len == 0) return false;

        uint8 byte0;
        uint memPtr = item.memPtr;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < LIST_SHORT_START)
            return false;
        return true;
    }

    /** RLPItem conversions into data types **/
    // @returns raw rlp encoding in bytes
    function toRlpBytes(RLPItem memory item) internal pure returns (bytes memory) {
        bytes memory result = new bytes(item.len);
        if (result.length == 0) return result;
        
        uint ptr;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ptr := add(0x20, result)
        }

        copy(item.memPtr, ptr, item.len);
        return result;
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
        // 1 byte for the length prefix
        require(item.len == 21, "Item length must be == 21");

        return address(toUint(item));
    }

    function toUint(RLPItem memory item) internal pure returns (uint) {
        require(item.len > 0 && item.len <= 33, "Item length must be <= 33");
        
        uint itemLen = _itemLength(item.memPtr);
        require(itemLen <= item.len, "Length is larger than data");

        uint offset = _payloadOffset(item.memPtr);
        uint len = itemLen - offset;

        uint result;
        uint memPtr = item.memPtr + offset;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            result := mload(memPtr)

            // shfit to the correct location if neccesary
            // TODO audit prep, can this overflow?
            if lt(len, 32) {
                result := div(result, exp(256, sub(32, len)))
            }
        }

        return result;
    }

    /*
    * Private Helpers
    */
    // @return number of payload items inside an encoded list.
    function numItems(RLPItem memory item) private pure returns (uint) {
        if (item.len == 0) return 0;

        uint count = 0;
        uint currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
            currPtr = currPtr + _itemLength(currPtr); // skip over an item
            require(currPtr <= endPtr, "Invalid rlp item length");
            count++;
        }

        return count;
    }

    // @return entire rlp item byte length
    function _itemLength(uint memPtr) private pure returns (uint) {
        uint itemLen;
        uint byte0;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) {
            itemLen = 1;
        } else if (byte0 < STRING_LONG_START) {
            itemLen = byte0 - STRING_SHORT_START + 1;
            uint byte1;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                memPtr := add(memPtr, 1)
                byte1 := byte(0, mload(memPtr))
            }
            if (itemLen == 2) {
                // Check that the value is valid for a short string
                require(byte1 >= STRING_SHORT_START, "Invalid rlp encoding");
            }
        } else if (byte0 < LIST_SHORT_START) {
            uint dataLen;
            uint byte1;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                memPtr := add(memPtr, 1) // skip over the first byte

                byte1 := byte(0, mload(memPtr))
                
                /* 32 byte word size */
                // TODO audit prep, check this shifting for overflow, etc
                dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
                itemLen := add(dataLen, add(byteLen, 1))
            }
            // Check valid long string i.e. value of length > MAX_SHORT_LEN with no leading zeros
            require(byte1 != 0, "Invalid rlp encoding");
            require(dataLen > MAX_SHORT_LEN, "Invalid rlp encoding");
        } else if (byte0 < LIST_LONG_START) {
            itemLen = byte0 - LIST_SHORT_START + 1;
        } else {
            uint dataLen;
            uint byte1;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let lengthLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)

                byte1 := byte(0, mload(memPtr))

                // TODO audit prep, check this shifting for overflow, etc
                dataLen := div(mload(memPtr), exp(256, sub(32, lengthLen))) // right shifting to the correct length
                itemLen := add(dataLen, add(lengthLen, 1))
            }
            // Check valid long list i.e. value of length > MAX_SHORT_LEN with no leading zeros
            require(byte1 != 0, "Invalid rlp encoding");
            require(dataLen > MAX_SHORT_LEN, "Invalid rlp encoding");
        }

        return itemLen;
    }

    // @return number of bytes until the data
    function _payloadOffset(uint memPtr) private pure returns (uint) {
        uint byte0;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) {
            return 0;
        } else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START)) {
            return 1;
        } else if (byte0 < LIST_SHORT_START) {  // being explicit
            return byte0 - (STRING_LONG_START - 1) + 1;
        } else {
            return byte0 - (LIST_LONG_START - 1) + 1;
        } 
    }

    /*
    * @param src Pointer to source
    * @param dest Pointer to destination
    * @param len Amount of memory to copy from the source
    */
    function copy(uint src, uint dest, uint len) private pure {
        if (len == 0) return;

        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        // left over bytes. Mask is used to remove unwanted bytes from the word
        uint mask = 256 ** (WORD_SIZE - len) - 1;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let srcpart := and(mload(src), not(mask)) // zero out src
            let destpart := and(mload(dest), mask) // retrieve the bytes
            mstore(dest, or(destpart, srcpart))
        }
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
        require(item.len > 0, "Item length must be > 0");

        uint itemLen = _itemLength(item.memPtr);
        require(itemLen <= item.len, "Length is larger than data");

        uint offset = _payloadOffset(item.memPtr);
        uint len = itemLen - offset; // data length
        bytes memory result = new bytes(len);

        uint destPtr;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            destPtr := add(0x20, result)
        }

        copy(item.memPtr + offset, destPtr, len);
        return result;
    }

}

library AddressPayable {

    /**
     * @notice Converts an `address` into `address payable`
     * @dev Note that this is simply a type cast; the actual underlying value remains the same
     */
    function convert(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
}

/**
 * @notice Data structure and its decode function for payment output
 */
library PaymentOutputModel {

    using RLPReader for RLPReader.RLPItem;

    struct Output {
        uint256 outputType;
        bytes20 outputGuard;
        address token;
        uint256 amount;
    }

    /**
     * @notice Retrieve the 'owner' from the output, assuming the 
     *         'outputGuard' field directly holds the owner's address
     * @dev It's possible that 'outputGuard' can be a hash of preimage that holds the owner information,
     *       but this should not and cannot be handled here.
     */
    function owner(Output memory _output) internal pure returns (address payable) {
        return AddressPayable.convert(address(uint160(_output.outputGuard)));
    }

    function decode(RLPReader.RLPItem memory encoded) internal pure returns (Output memory) {
        RLPReader.RLPItem[] memory rlpEncoded = encoded.toList();
        require(rlpEncoded.length == 4, "Invalid output encoding");

        Output memory output = Output({
            outputType: rlpEncoded[0].toUint(),
            outputGuard: bytes20(rlpEncoded[1].toAddress()),
            token: rlpEncoded[2].toAddress(),
            amount: rlpEncoded[3].toUint()
        });

        return output;
    }
}

/**
 * @notice Data structure and its decode function for Payment transaction
 */
library PaymentTransactionModel {

    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;
    using PaymentOutputModel for PaymentOutputModel.Output;

    uint8 constant public MAX_INPUT_NUM = 4;
    uint8 constant public MAX_OUTPUT_NUM = 4;

    uint8 constant private ENCODED_LENGTH = 4;

    struct Transaction {
        uint256 txType;
        bytes32[] inputs;
        PaymentOutputModel.Output[] outputs;
        bytes32 metaData;
    }

    function decode(bytes memory _tx) internal pure returns (PaymentTransactionModel.Transaction memory) {
        RLPReader.RLPItem[] memory rlpTx = _tx.toRlpItem().toList();
        require(rlpTx.length == ENCODED_LENGTH, "Invalid encoding of transaction");

        RLPReader.RLPItem[] memory rlpInputs = rlpTx[1].toList();
        require(rlpInputs.length <= MAX_INPUT_NUM, "Transaction inputs num exceeds limit");

        RLPReader.RLPItem[] memory rlpOutputs = rlpTx[2].toList();
        require(rlpOutputs.length <= MAX_OUTPUT_NUM, "Transaction outputs num exceeds limit");

        uint txType = rlpTx[0].toUint();

        bytes32[] memory inputs = new bytes32[](rlpInputs.length);
        for (uint i = 0; i < rlpInputs.length; i++) {
            bytes32 input = bytes32(rlpInputs[i].toUint());
            inputs[i] = input;
        }

        PaymentOutputModel.Output[] memory outputs = new PaymentOutputModel.Output[](rlpOutputs.length);
        for (uint i = 0; i < rlpOutputs.length; i++) {
            PaymentOutputModel.Output memory output = PaymentOutputModel.decode(rlpOutputs[i]);
            outputs[i] = output;
        }

        bytes32 metaData = bytes32(rlpTx[3].toUint());

        return Transaction({txType: txType, inputs: inputs, outputs: outputs, metaData: metaData});
    }
}

library IsDeposit {
    struct Predicate {
        uint256 childBlockInterval;
    }

    /**
     * @notice Tests whether the given block number belongs to a deposit block
     */
    function test(Predicate memory _predicate, uint256 _blockNum) internal pure returns (bool) {
        return _blockNum % _predicate.childBlockInterval != 0;
    }
}

library PaymentStartStandardExit {
    using ExitableTimestamp for ExitableTimestamp.Calculator;
    using IsDeposit for IsDeposit.Predicate;
    using PaymentOutputModel for PaymentOutputModel.Output;
    using UtxoPosLib for UtxoPosLib.UtxoPos;

    struct Controller {
        IExitProcessor exitProcessor;
        PlasmaFramework framework;
        IsDeposit.Predicate isDeposit;
        ExitableTimestamp.Calculator exitableTimestampCalculator;
        OutputGuardHandlerRegistry outputGuardHandlerRegistry;
        ITxFinalizationVerifier txFinalizationVerifier;
        uint256 ethVaultId;
        uint256 erc20VaultId;
    }

    /**
     * @dev Data to be passed around startStandardExit helper functions
     */
    struct StartStandardExitData {
        Controller controller;
        PaymentStandardExitRouterArgs.StartStandardExitArgs args;
        UtxoPosLib.UtxoPos utxoPos;
        PaymentTransactionModel.Transaction outputTx;
        PaymentOutputModel.Output output;
        IOutputGuardHandler outputGuardHandler;
        OutputGuardModel.Data outputGuardData;
        uint160 exitId;
        bool isTxDeposit;
        uint256 txBlockTimeStamp;
        bytes32 outputId;
        TxFinalizationModel.Data finalizationData;
    }

    event ExitStarted(
        address indexed owner,
        uint160 exitId
    );

    /**
     * @notice Function that builds the controller struct
     * @return Controller struct of PaymentStartStandardExit
     */
    function buildController(
        IExitProcessor exitProcessor,
        PlasmaFramework framework,
        OutputGuardHandlerRegistry outputGuardHandlerRegistry,
        ITxFinalizationVerifier txFinalizationVerifier,
        uint256 ethVaultId,
        uint256 erc20VaultId
    )
        public
        view
        returns (Controller memory)
    {
        return Controller({
            exitProcessor: exitProcessor,
            framework: framework,
            isDeposit: IsDeposit.Predicate(framework.CHILD_BLOCK_INTERVAL()),
            exitableTimestampCalculator: ExitableTimestamp.Calculator(framework.minExitPeriod()),
            outputGuardHandlerRegistry: outputGuardHandlerRegistry,
            txFinalizationVerifier: txFinalizationVerifier,
            ethVaultId: ethVaultId,
            erc20VaultId: erc20VaultId
        });
    }

    /**
     * @notice Main logic function to start standard exit
     * @dev emits ExitStarted event on success
     * @param self The controller struct
     * @param exitMap The storage of all standard exit data
     * @param args Arguments of start standard exit function from client
     */
    function run(
        Controller memory self,
        PaymentExitDataModel.StandardExitMap storage exitMap,
        PaymentStandardExitRouterArgs.StartStandardExitArgs memory args
    )
        public
    {
        StartStandardExitData memory data = setupStartStandardExitData(self, args);
        verifyStartStandardExitData(self, data, exitMap);
        saveStandardExitData(data, exitMap);
        enqueueStandardExit(data);

        emit ExitStarted(msg.sender, data.exitId);
    }

    function setupStartStandardExitData(
        Controller memory controller,
        PaymentStandardExitRouterArgs.StartStandardExitArgs memory args
    )
        private
        view
        returns (StartStandardExitData memory)
    {
        UtxoPosLib.UtxoPos memory utxoPos = UtxoPosLib.UtxoPos(args.utxoPos);
        PaymentTransactionModel.Transaction memory outputTx = PaymentTransactionModel.decode(args.rlpOutputTx);
        PaymentOutputModel.Output memory output = outputTx.outputs[utxoPos.outputIndex()];
        bool isTxDeposit = controller.isDeposit.test(utxoPos.blockNum());
        uint160 exitId = ExitId.getStandardExitId(isTxDeposit, args.rlpOutputTx, utxoPos);
        // SWC-Block values as a proxy for time: L124
        (, uint256 blockTimestamp) = controller.framework.blocks(utxoPos.blockNum());

        OutputGuardModel.Data memory outputGuardData = OutputGuardModel.Data({
            guard: output.outputGuard,
            preimage: args.outputGuardPreimage
        });

        IOutputGuardHandler outputGuardHandler = controller.outputGuardHandlerRegistry.outputGuardHandlers(output.outputType);

        TxFinalizationModel.Data memory finalizationData = TxFinalizationModel.moreVpData(
            controller.framework,
            args.rlpOutputTx,
            utxoPos.txPos(),
            args.outputTxInclusionProof
        );

        bytes32 outputId = isTxDeposit
            ? OutputId.computeDepositOutputId(args.rlpOutputTx, utxoPos.outputIndex(), utxoPos.value)
            : OutputId.computeNormalOutputId(args.rlpOutputTx, utxoPos.outputIndex());

        return StartStandardExitData({
            controller: controller,
            args: args,
            utxoPos: utxoPos,
            outputTx: outputTx,
            output: output,
            outputGuardHandler: outputGuardHandler,
            outputGuardData: outputGuardData,
            exitId: exitId,
            isTxDeposit: isTxDeposit,
            txBlockTimeStamp: blockTimestamp,
            outputId: outputId,
            finalizationData: finalizationData
        });
    }

    function verifyStartStandardExitData(
        Controller memory self,
        StartStandardExitData memory data,
        PaymentExitDataModel.StandardExitMap storage exitMap
    )
        private
        view
    {
        require(data.output.amount > 0, "Should not exit with amount 0");

        require(address(data.outputGuardHandler) != address(0), "Failed to get the output guard handler for the output type");
        require(data.outputGuardHandler.isValid(data.outputGuardData), "Some output guard information is invalid");
        require(data.outputGuardHandler.getExitTarget(data.outputGuardData) == msg.sender, "Only exit target can start an exit");

        require(data.controller.txFinalizationVerifier.isStandardFinalized(data.finalizationData), "The transaction must be standard finalized");
        require(exitMap.exits[data.exitId].exitable == false, "Exit has already started");

        require(self.framework.isOutputSpent(data.outputId) == false, "Output is already spent");
    }

    function saveStandardExitData(
        StartStandardExitData memory data,
        PaymentExitDataModel.StandardExitMap storage exitMap
    )
        private
    {
        exitMap.exits[data.exitId] = PaymentExitDataModel.StandardExit({
            exitable: true,
            utxoPos: uint192(data.utxoPos.value),
            outputId: data.outputId,
            exitTarget: msg.sender,
            amount: data.output.amount,
            bondSize: msg.value
        });
    }

    function enqueueStandardExit(StartStandardExitData memory data) private {

        uint64 exitableAt;
        ExitableTimestamp.Calculator memory exitableTimestampCalculator = data.controller.exitableTimestampCalculator;

        if (data.isTxDeposit){
            exitableAt = exitableTimestampCalculator.calculateDepositTxOutputExitableTimestamp(block.timestamp);
        } else {
            exitableAt = exitableTimestampCalculator.calculateTxExitableTimestamp(block.timestamp, data.txBlockTimeStamp);
        }

        uint256 vaultId;
        if (data.output.token == address(0)) {
            vaultId = data.controller.ethVaultId;
        } else {
            vaultId = data.controller.erc20VaultId;
        }

        data.controller.framework.enqueue(
            vaultId, data.output.token, exitableAt, data.utxoPos.txPos(),
            data.exitId, data.controller.exitProcessor
        );
    }
}
