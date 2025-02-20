pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;



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
