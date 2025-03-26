// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";

contract FeeManagerGenericUpgradeable is Initializable, ContextUpgradeable, AccessControlUpgradeable {

    struct Fees {
        uint256 _bridgeFee;
        uint256 _feeFactor;
        bool accepted;
    }

    address private handler;

    mapping(uint8 => mapping(address => Fees)) private _fees; // ChainID - FeeToken - Fees

    mapping(uint8 => mapping(address => bool)) private _feeTokenWhitelisted;

    mapping(uint8 => address[]) private _chainFeeTokens;

    modifier isHandler() {
        require(handler == msg.sender, "Fee Manager : Only Router Handlers can set Fees");
        _;
    }

    function __FeeManagerUpgradeable_init(address handlerAddress) internal initializer {
        __AccessControl_init();
        __Context_init_unchained();

        handler = handlerAddress;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function initialize(address handlerAddress) external initializer {
        __FeeManagerUpgradeable_init(handlerAddress);
    }

    function __FeeManagerUpgradeable_init_unchained() internal initializer {}

    event FeeUpdated(
        uint8 destinationChainID,
        address feeTokenAddress,
        uint256 feeFactor,
        uint256 bridgeFee,
        bool accepted
    );

    /**
        @notice Used to fetch handler address.
        @notice Only callable by admin or Fee Setter.
     */
    function fetchHandler() public view returns (address) {
        return handler;
    }

    /**
        @notice Used to setup handler address.
        @notice Only callable by admin or Fee Setter.
        @param  _handler Address of the new handler.
     */
    function setHandler(address _handler) public onlyRole(DEFAULT_ADMIN_ROLE) {
        handler = _handler;
    }

    /**
        @notice Used to set deposit fee.
        @notice Only callable by admin or Fee Setter.
        @param  destinationChainID id of the destination chain.
        @param  feeTokenAddress address of the fee token.
        @param  feeFactor Value {feeFactor} will be updated to.
        @param  accepted accepted status of the token as fee.
     */
    function setFee(
        uint8 destinationChainID,
        address feeTokenAddress,
        uint256 feeFactor,
        uint256 bridgeFee,
        bool accepted
    ) public isHandler {
        require(feeTokenAddress != address(0), "setFee: address can't be null");
        Fees storage fees = _fees[destinationChainID][feeTokenAddress];
        fees._feeFactor = feeFactor;
        fees._bridgeFee = bridgeFee;
        fees.accepted = accepted;
        if(!_feeTokenWhitelisted[destinationChainID][feeTokenAddress]){
            _feeTokenWhitelisted[destinationChainID][feeTokenAddress] = true;
            _chainFeeTokens[destinationChainID].push(feeTokenAddress);
        }
        emit FeeUpdated(destinationChainID, feeTokenAddress, fees._feeFactor, fees._bridgeFee , fees.accepted);
    }

    /**
        @notice Used to get deposit fee.
        @param  destinationChainID id of the destination chain.
        @param  feeTokenAddress address of the fee token.
    */
    function getFee(uint8 destinationChainID, address feeTokenAddress) public view virtual returns ( uint256 , uint256 ) {
        require(_fees[destinationChainID][feeTokenAddress].accepted, "FeeManager: fees not set for this token");
        Fees storage fees = _fees[destinationChainID][feeTokenAddress];
        return ( fees._feeFactor , fees._bridgeFee );
    }

    /**
        @notice Used to get deposit fee.
        @param  destChainId id of the destination chain.
        @param  feeToken address of the fee token.
    */
    function getFeeSafe(uint8 destChainId, address feeToken) public view virtual returns (uint256, uint256 , bool) {
        Fees storage fees = _fees[destChainId][feeToken];
        return (fees._feeFactor, fees._bridgeFee ,fees.accepted);
    }


    /**
        @notice Used to get listed fee tokens for given chain.
        @param  destChainId id of the destination chain.
    **/
    function getChainFeeTokens(uint8 destChainId) public view virtual returns (address [] memory) {
        return _chainFeeTokens[destChainId];
    }


    /**
        @notice Function used to withdraw fee tokens from fee manager.
        @param  tokenAddress Fee Token address.
        @param  recipient Address of the recipient.
        @param  amount Amount of token to be withdrawn.
    **/
    function withdrawFee(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) external isHandler {
        IERC20Upgradeable(tokenAddress).transfer(recipient, amount);
    }
}