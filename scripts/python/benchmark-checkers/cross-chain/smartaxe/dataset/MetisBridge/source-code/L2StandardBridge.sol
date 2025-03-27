// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/* Interface Imports */
import { IL1StandardBridge } from "../../L1/messaging/IL1StandardBridge.sol";
import { IL1ERC20Bridge } from "../../L1/messaging/IL1ERC20Bridge.sol";
import { IL2ERC20Bridge } from "./IL2ERC20Bridge.sol";

/* Library Imports */
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import { CrossDomainEnabled } from "../../libraries/bridge/CrossDomainEnabled.sol";
import { Lib_PredeployAddresses } from "../../libraries/constants/Lib_PredeployAddresses.sol";

/* Contract Imports */
import { IL2StandardERC20 } from "../../standards/IL2StandardERC20.sol";
import { OVM_GasPriceOracle } from "../predeploys/OVM_GasPriceOracle.sol";

/**
 * @title L2StandardBridge
 * @dev The L2 Standard bridge is a contract which works together with the L1 Standard bridge to
 * enable ETH and ERC20 transitions between L1 and L2.
 * This contract acts as a minter for new tokens when it hears about deposits into the L1 Standard
 * bridge.
 * This contract also acts as a burner of the tokens intended for withdrawal, informing the L1
 * bridge to release L1 funds.
 */
contract L2StandardBridge is IL2ERC20Bridge, CrossDomainEnabled {
    /********************************
     * External Contract References *
     ********************************/

    address public l1TokenBridge;

    /***************
     * Constructor *
     ***************/

    /**
     * @param _l2CrossDomainMessenger Cross-domain messenger used by this contract.
     * @param _l1TokenBridge Address of the L1 bridge deployed to the main chain.
     */
    constructor(address _l2CrossDomainMessenger, address _l1TokenBridge)
        CrossDomainEnabled(_l2CrossDomainMessenger)
    {
        l1TokenBridge = _l1TokenBridge;
    }
    
    function getChainID() internal view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /***************
     * Withdrawing *
     ***************/

    /**
     * @inheritdoc IL2ERC20Bridge
     */
    function withdraw(
        address _l2Token,
        uint256 _amount,
        uint32 _l1Gas,
        bytes calldata _data
    ) external payable virtual {
        _initiateWithdrawal(_l2Token, msg.sender, msg.sender, _amount, _l1Gas, _data);
    }
    
    function withdrawMetis(
        uint256 _amount,
        uint32 _l1Gas,
        bytes calldata _data
    ) external payable virtual {
        _initiateWithdrawal(Lib_PredeployAddresses.MVM_COINBASE, msg.sender, msg.sender, _amount, _l1Gas, _data);
    }

    /**
     * @inheritdoc IL2ERC20Bridge
     */
    function withdrawTo(
        address _l2Token,
        address _to,
        uint256 _amount,
        uint32 _l1Gas,
        bytes calldata _data
    ) external payable virtual {
        _initiateWithdrawal(_l2Token, msg.sender, _to, _amount, _l1Gas, _data);
    }
    
    function withdrawMetisTo(
        address _to,
        uint256 _amount,
        uint32 _l1Gas,
        bytes calldata _data
    ) external payable virtual {
        _initiateWithdrawal(Lib_PredeployAddresses.MVM_COINBASE, msg.sender, _to, _amount, _l1Gas, _data);
    }

    /**
     * @dev Performs the logic for deposits by storing the token and informing the L2 token Gateway
     * of the deposit.
     * @param _l2Token Address of L2 token where withdrawal was initiated.
     * @param _from Account to pull the deposit from on L2.
     * @param _to Account to give the withdrawal to on L1.
     * @param _amount Amount of the token to withdraw.
     * param _l1Gas Unused, but included for potential forward compatibility considerations.
     * @param _data Optional data to forward to L1. This data is provided
     *        solely as a convenience for external contracts. Aside from enforcing a maximum
     *        length, these contracts provide no guarantees about its content.
     */
    function _initiateWithdrawal(
        address _l2Token,
        address _from,
        address _to,
        uint256 _amount,
        uint32 _l1Gas,
        bytes calldata _data
    ) internal {
        uint256 minL1Gas = OVM_GasPriceOracle(Lib_PredeployAddresses.OVM_GASPRICE_ORACLE).minErc20BridgeCost();
        
        // require minimum gas unless, the metis manager is the sender
        require (msg.value >= minL1Gas ||
                    _from == Lib_PredeployAddresses.SEQUENCER_FEE_WALLET, 
                 string(abi.encodePacked("insufficient withdrawal fee supplied. need at least ", uint2str(minL1Gas))));
        
        // When a withdrawal is initiated, we burn the withdrawer's funds to prevent subsequent L2
        // usage
        IL2StandardERC20(_l2Token).burn(msg.sender, _amount);

        // Construct calldata for l1TokenBridge.finalizeERC20Withdrawal(_to, _amount)
        address l1Token = IL2StandardERC20(_l2Token).l1Token();
        bytes memory message;

        if (_l2Token == Lib_PredeployAddresses.OVM_ETH) {
            message = abi.encodeWithSelector(
                        IL1StandardBridge.finalizeETHWithdrawalByChainId.selector,
                        getChainID(),
                        _from,
                        _to,
                        _amount,
                        _data
                    );
        } else if (_l2Token == Lib_PredeployAddresses.MVM_COINBASE) {
            message = abi.encodeWithSelector(
                        IL1ERC20Bridge.finalizeMetisWithdrawalByChainId.selector,
                        getChainID(),
                        _from,
                        _to,
                        _amount,
                        _data
                    );
        } else {
            message = abi.encodeWithSelector(
                        IL1ERC20Bridge.finalizeERC20WithdrawalByChainId.selector,
                        getChainID(),
                        l1Token,
                        _l2Token,
                        _from,
                        _to,
                        _amount,
                        _data
                    );
        }

        // Send message up to L1 bridge
        sendCrossDomainMessage(
            l1TokenBridge,
            _l1Gas,
            message,
            msg.value  // send all value as fees to cover relayer cost
        );

        emit WithdrawalInitiated(l1Token, _l2Token, msg.sender, _to, _amount, _data);
    }

    /************************************
     * Cross-chain Function: Depositing *
     ************************************/

    /**
     * @inheritdoc IL2ERC20Bridge
     */
    function finalizeDeposit(
        address _l1Token,
        address _l2Token,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external virtual onlyFromCrossDomainAccount(l1TokenBridge) {
        // Check the target token is compliant and
        // verify the deposited token on L1 matches the L2 deposited token representation here
        if (
            ERC165Checker.supportsInterface(_l2Token, 0x1d1d8b63) &&
            _l1Token == IL2StandardERC20(_l2Token).l1Token()
        ) {
            // When a deposit is finalized, we credit the account on L2 with the same amount of
            // tokens.
            IL2StandardERC20(_l2Token).mint(_to, _amount);
            emit DepositFinalized(_l1Token, _l2Token, _from, _to, _amount, _data);
        } else {
            // disable because the mechanism is incompatible with the new xdomain fee structure.
            
            // Either the L2 token which is being deposited-into disagrees about the correct address
            // of its L1 token, or does not support the correct interface.
            // This should only happen if there is a  malicious L2 token, or if a user somehow
            // specified the wrong L2 token address to deposit into.
            // In either case, we stop the process here and construct a withdrawal
            // message so that users can get their funds out in some cases.
            // There is no way to prevent malicious token contracts altogether, but this does limit
            // user error and mitigate some forms of malicious contract behavior.
            //bytes memory message = abi.encodeWithSelector(
            //    iOVM_L1ERC20Bridge.finalizeERC20Withdrawal.selector,
            //    _l1Token,
            //    _l2Token,
            //    _to,   // switched the _to and _from here to bounce back the deposit to the sender
            //    _from,
            //    _amount,
            //    _data
            //);

            // Send message up to L1 bridge
            //sendCrossDomainMessage(
            //    l1TokenBridge,
            //    0,
            //    message,
            //    0 
            //);
            emit DepositFailed(_l1Token, _l2Token, _from, _to, _amount, _data);

        }
    }
    
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    
    
}