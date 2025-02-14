// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;


interface RocketStorageInterface {

    // Getters
    function getAddress(bytes32 _key) external view returns (address);
    function getUint(bytes32 _key) external view returns (uint);
    function getString(bytes32 _key) external view returns (string memory);
    function getBytes(bytes32 _key) external view returns (bytes memory);
    function getBool(bytes32 _key) external view returns (bool);
    function getInt(bytes32 _key) external view returns (int);
    function getBytes32(bytes32 _key) external view returns (bytes32);

    // Setters
    function setAddress(bytes32 _key, address _value) external;
    function setUint(bytes32 _key, uint _value) external;
    function setString(bytes32 _key, string calldata _value) external;
    function setBytes(bytes32 _key, bytes calldata _value) external;
    function setBool(bytes32 _key, bool _value) external;
    function setInt(bytes32 _key, int _value) external;
    function setBytes32(bytes32 _key, bytes32 _value) external;

    // Deleters
    function deleteAddress(bytes32 _key) external;
    function deleteUint(bytes32 _key) external;
    function deleteString(bytes32 _key) external;
    function deleteBytes(bytes32 _key) external;
    function deleteBool(bytes32 _key) external;
    function deleteInt(bytes32 _key) external;
    function deleteBytes32(bytes32 _key) external;

}



/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}



/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}




/// @title Base settings / modifiers for each contract in Rocket Pool
/// @author David Rugendyke

abstract contract RocketBase {


    // Version of the contract
    uint8 public version;

    // The main storage contract where primary persistant storage is maintained
    RocketStorageInterface rocketStorage = RocketStorageInterface(0);


    /*** Modifiers **********************************************************/

    /**
    * @dev Throws if called by any sender that doesn't match a Rocket Pool network contract
    */
    modifier onlyLatestNetworkContract() {
        require(getBool(keccak256(abi.encodePacked("contract.exists", msg.sender))), "Invalid or outdated network contract");
        _;
    }

    /**
    * @dev Throws if called by any sender that doesn't match one of the supplied contract or is the latest version of that contract
    */
    modifier onlyLatestContract(string memory _contractName, address _contractAddress) {
        require(_contractAddress == getAddress(keccak256(abi.encodePacked("contract.address", _contractName))), "Invalid or outdated contract");
        _;
    }

    /**
    * @dev Throws if called by any sender that isn't a registered node
    */
    modifier onlyRegisteredNode(address _nodeAddress) {
        require(getBool(keccak256(abi.encodePacked("node.exists", _nodeAddress))), "Invalid node");
        _;
    }

    /**
    * @dev Throws if called by any sender that isn't a trusted node DAO member
    */
    modifier onlyTrustedNode(address _nodeAddress) {
        require(getBool(keccak256(abi.encodePacked("dao.trustednodes", "member", _nodeAddress))), "Invalid trusted node");
        _;
    }

    /**
    * @dev Throws if called by any sender that isn't a registered minipool
    */
    modifier onlyRegisteredMinipool(address _minipoolAddress) {
        require(getBool(keccak256(abi.encodePacked("minipool.exists", _minipoolAddress))), "Invalid minipool");
        _;
    }
    

    /**
    * @dev Throws if called by any account other than a guardian account (temporary account allowed access to settings before DAO is fully enabled)
    */
    modifier onlyGuardian() {
        require(getBool(keccak256(abi.encodePacked("access.role", "guardian", msg.sender))), "Account is not a temporary guardian");
        _;
    }




    /*** Methods **********************************************************/

    /// @dev Set the main Rocket Storage address
    constructor(address _rocketStorageAddress) {
        // Update the contract address
        rocketStorage = RocketStorageInterface(_rocketStorageAddress);
    }


    /// @dev Get the address of a network contract by name
    function getContractAddress(string memory _contractName) internal view returns (address) {
        // Get the current contract address
        address contractAddress = getAddress(keccak256(abi.encodePacked("contract.address", _contractName)));
        // Check it
        require(contractAddress != address(0x0), "Contract not found");
        // Return
        return contractAddress;
    }


    /// @dev Get the name of a network contract by address
    function getContractName(address _contractAddress) internal view returns (string memory) {
        // Get the contract name
        string memory contractName = getString(keccak256(abi.encodePacked("contract.name", _contractAddress)));
        // Check it
        require(keccak256(abi.encodePacked(contractName)) != keccak256(abi.encodePacked("")), "Contract not found");
        // Return
        return contractName;
    }

    /// @dev Get revert error message from a .call method
    function getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return 'Transaction reverted silently';
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }



    /*** Rocket Storage Methods ****************************************/

    // Note: Unused helpers have been removed to keep contract sizes down

    /// @dev Storage get methods
    function getAddress(bytes32 _key) internal view returns (address) { return rocketStorage.getAddress(_key); }
    function getUint(bytes32 _key) internal view returns (uint) { return rocketStorage.getUint(_key); }
    function getString(bytes32 _key) internal view returns (string memory) { return rocketStorage.getString(_key); }
    function getBytes(bytes32 _key) internal view returns (bytes memory) { return rocketStorage.getBytes(_key); }
    function getBool(bytes32 _key) internal view returns (bool) { return rocketStorage.getBool(_key); }
    function getInt(bytes32 _key) internal view returns (int) { return rocketStorage.getInt(_key); }
    function getBytes32(bytes32 _key) internal view returns (bytes32) { return rocketStorage.getBytes32(_key); }
    function getAddressS(string memory _key) internal view returns (address) { return rocketStorage.getAddress(keccak256(abi.encodePacked(_key))); }
    function getUintS(string memory _key) internal view returns (uint) { return rocketStorage.getUint(keccak256(abi.encodePacked(_key))); }
    function getBytesS(string memory _key) internal view returns (bytes memory) { return rocketStorage.getBytes(keccak256(abi.encodePacked(_key))); }
    function getBoolS(string memory _key) internal view returns (bool) { return rocketStorage.getBool(keccak256(abi.encodePacked(_key))); }


    /// @dev Storage set methods
    function setAddress(bytes32 _key, address _value) internal { rocketStorage.setAddress(_key, _value); }
    function setUint(bytes32 _key, uint _value) internal { rocketStorage.setUint(_key, _value); }
    function setString(bytes32 _key, string memory _value) internal { rocketStorage.setString(_key, _value); }
    function setBytes(bytes32 _key, bytes memory _value) internal { rocketStorage.setBytes(_key, _value); }
    function setBool(bytes32 _key, bool _value) internal { rocketStorage.setBool(_key, _value); }
    function setInt(bytes32 _key, int _value) internal { rocketStorage.setInt(_key, _value); }
    function setBytes32(bytes32 _key, bytes32 _value) internal { rocketStorage.setBytes32(_key, _value); }
    function setAddressS(string memory _key, address _value) internal { rocketStorage.setAddress(keccak256(abi.encodePacked(_key)), _value); }
    function setUintS(string memory _key, uint _value) internal { rocketStorage.setUint(keccak256(abi.encodePacked(_key)), _value); }
    function setBytesS(string memory _key, bytes memory _value) internal { rocketStorage.setBytes(keccak256(abi.encodePacked(_key)), _value); }
    function setBoolS(string memory _key, bool _value) internal { rocketStorage.setBool(keccak256(abi.encodePacked(_key)), _value); }

    /// @dev Storage delete methods
    function deleteAddress(bytes32 _key) internal { rocketStorage.deleteAddress(_key); }
    function deleteUint(bytes32 _key) internal { rocketStorage.deleteUint(_key); }
    function deleteString(bytes32 _key) internal { rocketStorage.deleteString(_key); }
    function deleteBytes(bytes32 _key) internal { rocketStorage.deleteBytes(_key); }
    function deleteBool(bytes32 _key) internal { rocketStorage.deleteBool(_key); }
    function deleteInt(bytes32 _key) internal { rocketStorage.deleteInt(_key); }
    function deleteBytes32(bytes32 _key) internal { rocketStorage.deleteBytes32(_key); }


}




interface RocketMinipoolManagerInterface {
    function getMinipoolCount() external view returns (uint256);
    function getMinipoolAt(uint256 _index) external view returns (address);
    function getNodeMinipoolCount(address _nodeAddress) external view returns (uint256);
    function getNodeMinipoolAt(address _nodeAddress, uint256 _index) external view returns (address);
    function getNodeValidatingMinipoolCount(address _nodeAddress) external view returns (uint256);
    function getNodeValidatingMinipoolAt(address _nodeAddress, uint256 _index) external view returns (address);
    function getMinipoolByPubkey(bytes calldata _pubkey) external view returns (address);
    function getMinipoolExists(address _minipoolAddress) external view returns (bool);
    function getMinipoolPubkey(address _minipoolAddress) external view returns (bytes memory);
    function getMinipoolWithdrawalTotalBalance(address _minipoolAddress) external view returns (uint256);
    function getMinipoolWithdrawalNodeBalance(address _minipoolAddress) external view returns (uint256);
    function getMinipoolWithdrawable(address _minipoolAddress) external view returns (bool);
    function getMinipoolWithdrawalProcessed(address _minipoolAddress) external view returns (bool);
    function createMinipool(address _nodeAddress, MinipoolDeposit _depositType) external returns (address);
    function destroyMinipool() external;
    function setMinipoolPubkey(bytes calldata _pubkey) external;
    function setMinipoolWithdrawalBalances(address _minipoolAddress, uint256 _total, uint256 _node) external;
    function setMinipoolWithdrawalProcessed(address _minipoolAddress) external;
}



interface RocketNetworkPricesInterface {
    function getPricesBlock() external view returns (uint256);
    function getRPLPrice() external view returns (uint256);
    function submitPrices(uint256 _block, uint256 _rplPrice) external;
}



interface RocketNodeStakingInterface {
    function getTotalRPLStake() external view returns (uint256);
    function getNodeRPLStake(address _nodeAddress) external view returns (uint256);
    function getNodeRPLStakedBlock(address _nodeAddress) external view returns (uint256);
    function getTotalEffectiveRPLStake() external view returns (uint256);
    function getNodeEffectiveRPLStake(address _nodeAddress) external view returns (uint256);
    function getNodeMinimumRPLStake(address _nodeAddress) external view returns (uint256);
    function getNodeMinipoolLimit(address _nodeAddress) external view returns (uint256);
    function stakeRPL(uint256 _amount) external;
    function withdrawRPL(uint256 _amount) external;
    function slashRPL(address _nodeAddress, uint256 _ethSlashAmount) external;
}



interface RocketDAOProtocolSettingsRewardsInterface {
    function setSettingRewardsClaimer(string memory _contractName, uint256 _perc) external;
    function getRewardsClaimerPerc(string memory _contractName) external view returns (uint256);
    function getRewardsClaimerPercBlockUpdated(string memory _contractName) external view returns (uint256);
    function getRewardsClaimersPercTotal() external view returns (uint256);
    function getRewardsClaimIntervalBlocks() external view returns (uint256);
}




interface RocketDAOProtocolSettingsMinipoolInterface {
    function getLaunchBalance() external view returns (uint256);
    function getDepositNodeAmount(MinipoolDeposit _depositType) external view returns (uint256);
    function getFullDepositNodeAmount() external view returns (uint256);
    function getHalfDepositNodeAmount() external view returns (uint256);
    function getEmptyDepositNodeAmount() external view returns (uint256);
    function getDepositUserAmount(MinipoolDeposit _depositType) external view returns (uint256);
    function getFullDepositUserAmount() external view returns (uint256);
    function getHalfDepositUserAmount() external view returns (uint256);
    function getEmptyDepositUserAmount() external view returns (uint256);
    function getSubmitWithdrawableEnabled() external view returns (bool);
    function getLaunchTimeout() external view returns (uint256);
    function getWithdrawalDelay() external view returns (uint256);
}



interface RocketDAOProtocolSettingsNodeInterface {
    function getRegistrationEnabled() external view returns (bool);
    function getDepositEnabled() external view returns (bool);
    function getMinimumPerMinipoolStake() external view returns (uint256);
    function getMaximumPerMinipoolStake() external view returns (uint256);
}



interface RocketVaultInterface {
    function balanceOf(string memory _networkContractName) external view returns (uint256);
    function depositEther() external payable;
    function withdrawEther(uint256 _amount) external;
    function depositToken(string memory _networkContractName, address _tokenAddress, uint256 _amount) external returns (bool);
    function withdrawToken(address _withdrawalAddress, address _tokenAddress, uint256 _amount) external returns (bool);
    function balanceOfToken(string memory _networkContractName, address _tokenAddress) external view returns (uint256);
    function transferToken(string memory _networkContractName, address _tokenAddress, uint256 _amount) external returns (bool);
}





// Handles node deposits and minipool creation

contract RocketNodeStaking is RocketBase, RocketNodeStakingInterface {

    // Libs
    using SafeMath for uint;

    // Events
    event RPLStaked(address indexed from, uint256 amount, uint256 time);
    event RPLWithdrawn(address indexed to, uint256 amount, uint256 time);
    event RPLSlashed(address indexed node, uint256 amount, uint256 ethValue, uint256 time);

    // Construct
    constructor(address _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        version = 1;
    }

    // Get/set the total RPL stake amount
    function getTotalRPLStake() override public view returns (uint256) {
        return getUintS("rpl.staked.total.amount");
    }
    function setTotalRPLStake(uint256 _amount) private {
        setUintS("rpl.staked.total.amount", _amount);
    }
    function increaseTotalRPLStake(uint256 _amount) private {
        setTotalRPLStake(getTotalRPLStake().add(_amount));
    }
    function decreaseTotalRPLStake(uint256 _amount) private {
        setTotalRPLStake(getTotalRPLStake().sub(_amount));
    }

    // Get/set a node's RPL stake amount
    function getNodeRPLStake(address _nodeAddress) override public view returns (uint256) {
        return getUint(keccak256(abi.encodePacked("rpl.staked.node.amount", _nodeAddress)));
    }
    function setNodeRPLStake(address _nodeAddress, uint256 _amount) private {
        setUint(keccak256(abi.encodePacked("rpl.staked.node.amount", _nodeAddress)), _amount);
    }
    function increaseNodeRPLStake(address _nodeAddress, uint256 _amount) private {
        setNodeRPLStake(_nodeAddress, getNodeRPLStake(_nodeAddress).add(_amount));
    }
    function decreaseNodeRPLStake(address _nodeAddress, uint256 _amount) private {
        setNodeRPLStake(_nodeAddress, getNodeRPLStake(_nodeAddress).sub(_amount));
    }

    // Get/set the block a node last staked RPL at
    function getNodeRPLStakedBlock(address _nodeAddress) override public view returns (uint256) {
        return getUint(keccak256(abi.encodePacked("rpl.staked.node.block", _nodeAddress)));
    }
    function setNodeRPLStakedBlock(address _nodeAddress, uint256 _block) private {
        setUint(keccak256(abi.encodePacked("rpl.staked.node.block", _nodeAddress)), _block);
    }

    // Get the total effective RPL stake amount
    function getTotalEffectiveRPLStake() override public view returns (uint256) {
        // Load contracts
        RocketMinipoolManagerInterface rocketMinipoolManager = RocketMinipoolManagerInterface(getContractAddress("rocketMinipoolManager"));
        RocketDAOProtocolSettingsMinipoolInterface rocketDAOProtocolSettingsMinipool = RocketDAOProtocolSettingsMinipoolInterface(getContractAddress("rocketDAOProtocolSettingsMinipool"));
        RocketNetworkPricesInterface rocketNetworkPrices = RocketNetworkPricesInterface(getContractAddress("rocketNetworkPrices"));
        RocketDAOProtocolSettingsNodeInterface rocketDAOProtocolSettingsNode = RocketDAOProtocolSettingsNodeInterface(getContractAddress("rocketDAOProtocolSettingsNode"));
        // Get current total RPL stake
        uint256 rplStake = getTotalRPLStake();
        // Calculate maximum total RPL stake
        uint256 maxRplStake = rocketDAOProtocolSettingsMinipool.getHalfDepositUserAmount()
            .mul(rocketDAOProtocolSettingsNode.getMaximumPerMinipoolStake())
            .mul(rocketMinipoolManager.getMinipoolCount())
            .div(rocketNetworkPrices.getRPLPrice());
        // Return effective stake amount
        if (rplStake < maxRplStake) { return rplStake; }
        else { return maxRplStake; }
    }

    // Get a node's effective RPL stake amount
    function getNodeEffectiveRPLStake(address _nodeAddress) override public view returns (uint256) {
        // Load contracts
        RocketMinipoolManagerInterface rocketMinipoolManager = RocketMinipoolManagerInterface(getContractAddress("rocketMinipoolManager"));
        RocketDAOProtocolSettingsMinipoolInterface rocketDAOProtocolSettingsMinipool = RocketDAOProtocolSettingsMinipoolInterface(getContractAddress("rocketDAOProtocolSettingsMinipool"));
        RocketNetworkPricesInterface rocketNetworkPrices = RocketNetworkPricesInterface(getContractAddress("rocketNetworkPrices"));
        RocketDAOProtocolSettingsNodeInterface rocketDAOProtocolSettingsNode = RocketDAOProtocolSettingsNodeInterface(getContractAddress("rocketDAOProtocolSettingsNode"));
        // Get node's current RPL stake
        uint256 rplStake = getNodeRPLStake(_nodeAddress);
        // Calculate node's maximum RPL stake
        uint256 maxRplStake = rocketDAOProtocolSettingsMinipool.getHalfDepositUserAmount()
            .mul(rocketDAOProtocolSettingsNode.getMaximumPerMinipoolStake())
            .mul(rocketMinipoolManager.getNodeMinipoolCount(_nodeAddress))
            .div(rocketNetworkPrices.getRPLPrice());
        // Return effective stake amount
        if (rplStake < maxRplStake) { return rplStake; }
        else { return maxRplStake; }
    }

    // Get a node's minimum RPL stake to collateralize their minipools
    function getNodeMinimumRPLStake(address _nodeAddress) override public view returns (uint256) {
        // Load contracts
        RocketMinipoolManagerInterface rocketMinipoolManager = RocketMinipoolManagerInterface(getContractAddress("rocketMinipoolManager"));
        RocketDAOProtocolSettingsMinipoolInterface rocketDAOProtocolSettingsMinipool = RocketDAOProtocolSettingsMinipoolInterface(getContractAddress("rocketDAOProtocolSettingsMinipool"));
        RocketNetworkPricesInterface rocketNetworkPrices = RocketNetworkPricesInterface(getContractAddress("rocketNetworkPrices"));
        RocketDAOProtocolSettingsNodeInterface rocketDAOProtocolSettingsNode = RocketDAOProtocolSettingsNodeInterface(getContractAddress("rocketDAOProtocolSettingsNode"));
        // Calculate minimum RPL stake
        return rocketDAOProtocolSettingsMinipool.getHalfDepositUserAmount()
            .mul(rocketDAOProtocolSettingsNode.getMinimumPerMinipoolStake())
            .mul(rocketMinipoolManager.getNodeMinipoolCount(_nodeAddress))
            .div(rocketNetworkPrices.getRPLPrice());
    }

    // Get a node's minipool limit based on RPL stake
    function getNodeMinipoolLimit(address _nodeAddress) override public view returns (uint256) {
        // Load contracts
        RocketDAOProtocolSettingsMinipoolInterface rocketDAOProtocolSettingsMinipool = RocketDAOProtocolSettingsMinipoolInterface(getContractAddress("rocketDAOProtocolSettingsMinipool"));
        RocketNetworkPricesInterface rocketNetworkPrices = RocketNetworkPricesInterface(getContractAddress("rocketNetworkPrices"));
        RocketDAOProtocolSettingsNodeInterface rocketDAOProtocolSettingsNode = RocketDAOProtocolSettingsNodeInterface(getContractAddress("rocketDAOProtocolSettingsNode"));
        // Calculate & return minipool limit
        return getNodeRPLStake(_nodeAddress)
            .mul(rocketNetworkPrices.getRPLPrice())
            .div(
                rocketDAOProtocolSettingsMinipool.getHalfDepositUserAmount()
                .mul(rocketDAOProtocolSettingsNode.getMinimumPerMinipoolStake())
            );
    }

    // Accept an RPL stake
    // Only accepts calls from registered nodes
    function stakeRPL(uint256 _amount) override external onlyLatestContract("rocketNodeStaking", address(this)) onlyRegisteredNode(msg.sender) {
        // Load contracts
        address rplTokenAddress = getContractAddress("rocketTokenRPL");
        address rocketVaultAddress = getContractAddress("rocketVault");
        IERC20 rplToken = IERC20(rplTokenAddress);
        RocketVaultInterface rocketVault = RocketVaultInterface(rocketVaultAddress);
        // Transfer RPL tokens
        require(rplToken.transferFrom(msg.sender, address(this), _amount), "Could not transfer RPL to staking contract");
        // Deposit RPL tokens to vault
        require(rplToken.approve(rocketVaultAddress, _amount), "Could not approve vault RPL deposit");
        // SWC-Unchecked Call Return Value: L150
        rocketVault.depositToken("rocketNodeStaking", rplTokenAddress, _amount);
        // Update RPL stake amounts & node RPL staked block
        increaseTotalRPLStake(_amount);
        increaseNodeRPLStake(msg.sender, _amount);
        setNodeRPLStakedBlock(msg.sender, block.number);
        // Emit RPL staked event
        emit RPLStaked(msg.sender, _amount, block.timestamp);
    }

    // Withdraw staked RPL back to the node account
    // Only accepts calls from registered nodes
    function withdrawRPL(uint256 _amount) override external onlyLatestContract("rocketNodeStaking", address(this)) onlyRegisteredNode(msg.sender) {
        // Load contracts
        RocketDAOProtocolSettingsRewardsInterface rocketDAOProtocolSettingsRewards = RocketDAOProtocolSettingsRewardsInterface(getContractAddress("rocketDAOProtocolSettingsRewards"));
        RocketVaultInterface rocketVault = RocketVaultInterface(getContractAddress("rocketVault"));
        // Check cooldown period (one claim period) has passed since RPL last staked
        // SWC-Transaction Order Dependence: L166
        require(block.number.sub(getNodeRPLStakedBlock(msg.sender)) >= rocketDAOProtocolSettingsRewards.getRewardsClaimIntervalBlocks(), "The withdrawal cooldown period has not passed");
        // Get & check node's current RPL stake
        uint256 rplStake = getNodeRPLStake(msg.sender);
        require(rplStake >= _amount, "Withdrawal amount exceeds node's staked RPL balance");
        // Check withdrawal would not undercollateralize node
        require(rplStake.sub(_amount) >= getNodeMinimumRPLStake(msg.sender), "Node's staked RPL balance after withdrawal is less than minimum balance");
        // Transfer RPL tokens to node address
        rocketVault.withdrawToken(msg.sender, getContractAddress("rocketTokenRPL"), _amount);
        // Update RPL stake amounts
        decreaseTotalRPLStake(_amount);
        decreaseNodeRPLStake(msg.sender, _amount);
        // Emit RPL withdrawn event
        emit RPLWithdrawn(msg.sender, _amount, block.timestamp);
    }

    // Slash a node's RPL by an ETH amount
    // Only accepts calls from the RocketMinipoolStatus contract
    function slashRPL(address _nodeAddress, uint256 _ethSlashAmount) override external onlyLatestContract("rocketNodeStaking", address(this)) onlyLatestContract("rocketMinipoolStatus", msg.sender) {
        // Load contracts
        RocketNetworkPricesInterface rocketNetworkPrices = RocketNetworkPricesInterface(getContractAddress("rocketNetworkPrices"));
        RocketVaultInterface rocketVault = RocketVaultInterface(getContractAddress("rocketVault"));
        // Calculate RPL amount to slash
        uint256 calcBase = 1 ether;
        uint256 rplSlashAmount = calcBase.mul(_ethSlashAmount).div(rocketNetworkPrices.getRPLPrice());
        // Cap slashed amount to node's RPL stake
        uint256 rplStake = getNodeRPLStake(_nodeAddress);
        if (rplSlashAmount > rplStake) { rplSlashAmount = rplStake; }
        // Transfer slashed amount to auction contract
        rocketVault.transferToken("rocketAuctionManager", getContractAddress("rocketTokenRPL"), rplSlashAmount);
        // Update RPL stake amounts
        decreaseTotalRPLStake(rplSlashAmount);
        decreaseNodeRPLStake(_nodeAddress, rplSlashAmount);
        // Emit RPL slashed event
        emit RPLSlashed(_nodeAddress, rplSlashAmount, _ethSlashAmount, block.timestamp);
    }

}
