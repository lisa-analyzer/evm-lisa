pragma solidity 0.5.9;



interface IRandom {
    function getCurrentSeed() external view returns(uint256);
}


interface IValidatorSet {
    function initialize(
        address,
        address,
        address,
        address[] calldata,
        address[] calldata,
        bool
    ) external;
    function newValidatorSet() external returns(bool, uint256);
    function setStakingAddress(address, address) external;
    function blockRewardContract() external view returns(address);
    function changeRequestCount() external view returns(uint256);
    function emitInitiateChangeCallable() external view returns(bool);
    function getPendingValidators() external view returns(address[] memory);
    function getPreviousValidators() external view returns(address[] memory);
    function getValidators() external view returns(address[] memory);
    function isReportValidatorValid(address) external view returns(bool);
    function isValidator(address) external view returns(bool);
    function isValidatorBanned(address) external view returns(bool);
    function MAX_VALIDATORS() external view returns(uint256); // solhint-disable-line func-name-mixedcase
    function miningByStakingAddress(address) external view returns(address);
    function randomContract() external view returns(address);
    function stakingByMiningAddress(address) external view returns(address);
    function stakingContract() external view returns(address);
    function unremovableValidator() external view returns(address);
    function validatorIndex(address) external view returns(uint256);
    function validatorSetApplyBlock() external view returns(uint256);
}



/// @dev This contract holds all the necessary state variables to carry out the storage of any upgradable contract
/// and to support the upgrade functionality.
contract EternalStorage {

    // An address of the owner of the contract
    address internal _owner;

    // Storage mappings
    mapping(bytes32 => uint256) internal uintStorage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => bytes) internal bytesStorage;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => int256) internal intStorage;
    mapping(bytes32 => bytes32) internal bytes32Storage;

    mapping(bytes32 => uint256[]) internal uintArrayStorage;
    mapping(bytes32 => string[]) internal stringArrayStorage;
    mapping(bytes32 => address[]) internal addressArrayStorage;
    mapping(bytes32 => bytes[]) internal bytesArrayStorage;
    mapping(bytes32 => bool[]) internal boolArrayStorage;
    mapping(bytes32 => int256[]) internal intArrayStorage;
    mapping(bytes32 => bytes32[]) internal bytes32ArrayStorage;

}


/// @dev Provides access control functionality and extends the `EternalStorage` contract.
/// Using the `onlyOwner` modifier, a function can be restricted so that it can only be 
/// called by the owner of the contract. The owner of a contract can irrevocably transfer 
/// ownership using the `EternalStorageProxy.transferOwnership` function.
contract OwnedEternalStorage is EternalStorage {

    /// @dev Access check: revert unless `msg.sender` is the owner of the contract.
    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}


/// @dev The base contract for the RandomAuRa and RandomHBBFT contracts.
contract RandomBase is OwnedEternalStorage, IRandom {
    using SafeMath for uint256;

    // ============================================== Modifiers =======================================================

    /// @dev Ensures the `initialize` function was called before.
    modifier onlyInitialized {
        require(isInitialized());
        _;
    }

    /// @dev Ensures the caller is the ValidatorSet contract address
    /// (EternalStorageProxy proxy contract for ValidatorSet).
    //SWC-Code With No Effects: L24-L27
    modifier onlyValidatorSetContract() {
        require(msg.sender == address(validatorSetContract()));
        _;
    }

    // =============================================== Getters ========================================================

    /// @dev Returns the current random seed accumulated during RANDAO or another process (depending on
    /// implementation). This getter can only be called by the `ValidatorSet` contract.
    function getCurrentSeed() external onlyValidatorSetContract view returns(uint256) {
        return _getCurrentSeed();
    }

    /// @dev Returns a boolean flag indicating if the `initialize` function has been called.
    function isInitialized() public view returns(bool) {
        return addressStorage[VALIDATOR_SET_CONTRACT] != address(0);
    }

    /// @dev Returns the address of the `ValidatorSet` contract.
    function validatorSetContract() public view returns(IValidatorSet) {
        return IValidatorSet(addressStorage[VALIDATOR_SET_CONTRACT]);
    }

    // =============================================== Private ========================================================

    bytes32 internal constant CURRENT_SEED = keccak256("currentSeed");
    bytes32 internal constant VALIDATOR_SET_CONTRACT = keccak256("validatorSetContract");

    /// @dev Initializes the network parameters. Used by the `initialize` function of a child contract.
    /// @param _validatorSet The address of the `ValidatorSet` contract.
    function _initialize(address _validatorSet) internal {
        require(!isInitialized());
        require(_validatorSet != address(0));
        addressStorage[VALIDATOR_SET_CONTRACT] = _validatorSet;
    }

    /// @dev Updates the current random seed.
    /// @param _seed A new random seed.
    function _setCurrentSeed(uint256 _seed) internal {
        uintStorage[CURRENT_SEED] = _seed;
    }

    /// @dev Reads the current random seed from the state.
    function _getCurrentSeed() internal view returns(uint256) {
        return uintStorage[CURRENT_SEED];
    }

}
