// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./IBridge.sol";
import "./BridgeToken.sol";
import "./BridgeTokenFactory.sol";

import "./Utils.sol";

contract Bridge is IBridge, Ownable {
    using SafeMath for uint256;

    address private constant NULL_ADDRESS = address(0);
    bytes32 private constant NULL_HASH = bytes32(0);

    uint256 private feePercentage = 30;
    uint256 public constant feePercentageDivider = 10000; // Porcentage with up to 2 decimals

    string public symbolPrefix;

    mapping(bytes32 => bool) public processed; // ProcessedHash => true

    IBridgeTokenFactory public tokenFactory;
    address public erc20XDAG;

    constructor() {}

    function init(address _factory, string memory _symbolPrefix) public {
        require(
            _factory != NULL_ADDRESS,
            "Bridge: BridgeTokenFactory is empty"
        );
        tokenFactory = IBridgeTokenFactory(_factory);
        symbolPrefix = _symbolPrefix;

        _createERC20XDAG();
    }

    function _createERC20XDAG() internal returns (bool) {
        string memory newSymbol =
            string(abi.encodePacked(symbolPrefix, "XDAG"));
        erc20XDAG = tokenFactory.createBridgeToken(newSymbol, newSymbol, 18);
        emit ERC20XDAGCreated(erc20XDAG, newSymbol, 18);
        return true;
    }

    function getPrefix() external view override returns (string memory) {
        return symbolPrefix;
    }

    // Cross XDAG to ERC20
    function acceptTransfer(
        address receiver,
        uint256 amount,
        bytes32 blockHash,
        bytes32 transactionHash,
        uint32 logIndex
    ) external override returns (bool) {
        require(receiver != NULL_ADDRESS, "Bridge: Receiver is null");
        require(amount > 0, "Bridge: Amount 0");
        require(blockHash != NULL_HASH, "Bridge: BlockHash is null");
        require(transactionHash != NULL_HASH, "Bridge: Transaction is null");

        bytes32 compiledId =
            getTransactionId(
                blockHash,
                transactionHash,
                receiver,
                amount,
                logIndex
            );
        require(!processed[compiledId], "Bridge: Already processed");

        processed[compiledId] = true;
        BridgeToken(erc20XDAG).mint(receiver, amount); //fixme: need fix issue of decimals

        return true;
    }

    function getTransactionId(
        bytes32 _blockHash,
        bytes32 _transactionHash,
        address _receiver,
        uint256 _amount,
        uint32 _logIndex
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _blockHash,
                    _transactionHash,
                    _receiver,
                    _amount,
                    _logIndex
                )
            );
    }

    //Crosss ERC20 to XDAG
    function receiveTokens(uint256 amount, string memory to)
        external
        override
        returns (bool)
    {
        address sender = _msgSender();
        BridgeToken(erc20XDAG).transferFrom(
            _msgSender(),
            address(this),
            amount
        );

        // todo: handle fee
        // uint256 fee = 0;
        // if(feePercentage > 0) {
        //     fee = amount.mul(feePercentage).div(feePercentageDivider);
        //     BridgeToken(erc20XDAG).transfer(owner(), fee);
        // }
        // uint256 burnAmount = amount - fee;

        uint256 burnAmount = amount - 0;

        BridgeToken(erc20XDAG).burn(address(this), burnAmount);

        emit CrossERC20XDAG(sender, burnAmount, to);
        return true;
    }

    function setFeePercentage(uint256 amount) external onlyOwner {
        require(
            amount < (feePercentageDivider / 10),
            "Bridge: bigger than 10%"
        );
        feePercentage = amount;
        emit FeeChanged(feePercentage);
    }

    function getFeePercentage() external view override returns (uint256) {
        return feePercentage;
    }
}
