// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

import "./Initializable.sol";
import "./ContextUpgradeable.sol";
import "./AccessControlUpgradeable.sol";

import "./IWETH.sol";
import "./IOneSplitWrap.sol";
import "./ERC20SafeUpgradeable.sol";

import "./IEthHandler.sol";

contract HandlerReserveUpgradeable is
    Initializable,
    ContextUpgradeable,
    AccessControlUpgradeable,
    ERC20SafeUpgradeable
{
    // token lp address => contract address
    mapping(address => address) public _lpToContract;

    // token contract address => lp address
    mapping(address => address) public _contractToLP;

    //Middleman for handling eth (Istanbul fix)
    IEthHandler private _ethHandler;

    function __HandlerReserveUpgradeable_init(address handler) internal initializer {
        __Context_init_unchained();
        __AccessControl_init();
        __ERC20SafeUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ERC20HANDLER_ROLE, handler);
    }

    function __HandlerReserveUpgradeable_init_unchained() internal initializer {}

    function initialize(address handler) external initializer {
        __HandlerReserveUpgradeable_init(handler);
    }

    receive() external payable {}

    /// @dev Set the address of the ethHandler contract.
    function setEthHandler(IEthHandler ethHandler) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _ethHandler = ethHandler;
    }

    function deductFee(
        address feeTokenAddress,
        address depositor,
        uint256 requiredFee,
        bool _isFeeEnabled,
        address _feeManager
    ) external onlyRole(ERC20HANDLER_ROLE) {
        if (requiredFee > 0 && _isFeeEnabled) {
            lockERC20(feeTokenAddress, depositor, _feeManager, requiredFee);
        }
    }

    function mintWrappedERC20(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) public onlyRole(ERC20HANDLER_ROLE) {
        require(_contractToLP[tokenAddress] != address(0), "ERC20Handler: Liquidity pool not found");
        mintERC20(_contractToLP[tokenAddress], recipient, amount);
    }

    function stake(
        address depositor,
        address tokenAddress,
        uint256 amount
    ) external virtual onlyRole(ERC20HANDLER_ROLE) {
        require(_contractToLP[tokenAddress] != address(0), "ERC20Handler: Liquidity pool not created");
        lockERC20(tokenAddress, depositor, address(this), amount);
        mintERC20(_contractToLP[tokenAddress], depositor, amount);
    }

    function stakeETH(
        address depositor,
        address tokenAddress,
        uint256 amount
    ) external virtual onlyRole(ERC20HANDLER_ROLE) {
        require(_contractToLP[tokenAddress] != address(0), "ERC20Handler: Liquidity pool not created");
        mintERC20(_contractToLP[tokenAddress], depositor, amount);
    }

    /**
        @notice Staking should be done by using bridge contract.
        @param unstaker removes liquidity from the pool.
        @param tokenAddress staking token of which liquidity needs to be removed.
        @param amount Amount that needs to be unstaked.
     */

    function unstake(
        address unstaker,
        address tokenAddress,
        uint256 amount
    ) external virtual onlyRole(ERC20HANDLER_ROLE) {
        require(_contractToLP[tokenAddress] != address(0), "ERC20Handler: Liquidity pool not created");
        burnERC20(_contractToLP[tokenAddress], unstaker, amount);
        releaseERC20(tokenAddress, unstaker, amount);
    }

    function unstakeETH(
        address unstaker,
        address tokenAddress,
        uint256 amount,
        address WETH
    ) external virtual onlyRole(ERC20HANDLER_ROLE) {
        require(_contractToLP[tokenAddress] != address(0), "ERC20Handler: Liquidity pool not created");
        burnERC20(_contractToLP[tokenAddress], unstaker, amount);

        IWETH(WETH).transfer(address(_ethHandler), amount);
        _ethHandler.withdraw(WETH, amount);
        safeTransferETH(unstaker, amount);
    }

    function getStakedRecord(address account, address tokenAddress) external view virtual returns (uint256) {
        if(_contractToLP[tokenAddress] != address(0)){
            return RouterERC20Upgradable(_contractToLP[tokenAddress]).balanceOf(account);
        }
        return 0;
    }

    function withdrawWETH(address WETH, uint256 amount) external onlyRole(ERC20HANDLER_ROLE) {
        IWETH(WETH).transfer(address(_ethHandler), amount);
        _ethHandler.withdraw(WETH, amount);
    }

    function _setLiquidityPoolOwner(
        address newOwner,
        address tokenAddress,
        address lpAddress
    ) external virtual onlyRole(ERC20HANDLER_ROLE) {
        require(newOwner != address(0), "ERC20Handler: new owner cannot be null");
        require(tokenAddress != address(0), "ERC20Handler: tokenAddress cannot be null");
        require(lpAddress != address(0), "ERC20Handler: lpAddress cannot be null");

        RouterERC20Upgradable token = RouterERC20Upgradable(lpAddress);
        _lpToContract[lpAddress] = tokenAddress;
        _contractToLP[tokenAddress] = lpAddress;
        token.grantRole(DEFAULT_ADMIN_ROLE, newOwner);
    }

    function _setLiquidityPool(
        string memory name,
        string memory symbol,
        uint8 decimals,
        address contractAddress,
        address lpAddress
    ) external virtual onlyRole(ERC20HANDLER_ROLE) returns (address) {
        require(_contractToLP[contractAddress] == address(0), "ERC20Handler: pool already deployed");

        address newLPAddress;
        if (lpAddress == address(0)) {
            //TODO Why we need upgradeable here ?
            RouterERC20Upgradable newLPAddr = new RouterERC20Upgradable(name, symbol, decimals);
            // newLPAddr.initialize(name, symbol, decimals);
            newLPAddress = address(newLPAddr);
        } else {
            newLPAddress = lpAddress;
        }
        _lpToContract[newLPAddress] = contractAddress;
        _contractToLP[contractAddress] = newLPAddress;
        return newLPAddress;
    }

    function resetLP(
        address contractAddress,
        address lpAddress
    ) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _lpToContract[lpAddress] = address(0);
        _contractToLP[contractAddress] = address(0);
    }

    function swap(
        address oneSplitAddress,
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 minReturn,
        uint256 flags,
        bytes memory dataTx
    ) external onlyRole(ERC20HANDLER_ROLE) returns (uint256 returnAmount) {
        IOneSplitWrap oneSplitWrap = IOneSplitWrap(oneSplitAddress);
        returnAmount = oneSplitWrap.swap(fromToken, destToken, amount, minReturn, flags, dataTx, true);
        return returnAmount;
    }

    function swapMulti(
        address oneSplitAddress,
        address[] memory tokens,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory flags,
        bytes[] memory dataTx
    ) external onlyRole(ERC20HANDLER_ROLE) returns (uint256 returnAmount) {
        IOneSplitWrap oneSplitWrap = IOneSplitWrap(oneSplitAddress);
        returnAmount = oneSplitWrap.swapMulti(tokens, amount, minReturn, flags, dataTx, true);
        return returnAmount;
    }

    function getExpectedReturn(
        address oneSplitAddress,
        address fromToken,
        address toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) public view virtual returns (uint256 returnAmount, uint256[] memory distribution) {
        IOneSplitWrap oneSplitWrap = IOneSplitWrap(oneSplitAddress);
        return oneSplitWrap.getExpectedReturn(fromToken, toToken, amount, parts, flags);
    }

    function getExpectedReturnWithGas(
        address oneSplitAddress,
        address fromToken,
        address toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 toTokenEthPriceTimesGasPrice
    )
        public
        view
        virtual
        returns (
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        IOneSplitWrap oneSplitWrap = IOneSplitWrap(oneSplitAddress);
        return
            oneSplitWrap.getExpectedReturnWithGas(
                fromToken,
                toToken,
                amount,
                parts,
                flags,
                toTokenEthPriceTimesGasPrice
            );
    }

    function getExpectedReturnWithGasMulti(
        address oneSplitAddress,
        address[] memory tokens,
        uint256 amount,
        uint256[] memory parts,
        uint256[] memory flags,
        uint256[] memory destTokenEthPriceTimesGasPrices
    )
        public
        view
        virtual
        returns (
            uint256[] memory returnAmounts,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        IOneSplitWrap oneSplitWrap = IOneSplitWrap(oneSplitAddress);
        return
            oneSplitWrap.getExpectedReturnWithGasMulti(tokens, amount, parts, flags, destTokenEthPriceTimesGasPrices);
    }
}