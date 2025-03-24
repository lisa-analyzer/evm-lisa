// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.10;

import "./AnyswapV6Router-simple.sol";

contract AnyswapV6RouterWithProof is AnyswapV6Router {
    mapping(address => bool) public isProofSigner;
    mapping(bytes32 => bool) public proofConsumed;

    address[] public proofSigners;

    bool public disableCheckCompletion;
    mapping(string => bool) public completedSwapin;
    modifier checkCompletion(string memory swapID) {
        require(
            !completedSwapin[swapID] || disableCheckCompletion,
            "swap is completed"
        );
        _;
    }

    event AddProofSigner(address signer);
    event RemoveProofSigner(address signer);

    event LogAnySwapInWithProof(
        string swapID,
        address indexed token,
        address indexed to,
        uint amount,
        uint fromChainID,
        uint toChainID,
        bytes32 proofID
    );

    constructor(
        address _wNATIVE,
        address _mpc
    ) AnyswapV6Router(_wNATIVE, _mpc) {
        _addProofSigners(_mpc);
    }

    // swaps `amount` `token` in `fromChainID` to `to` on this chainID
    function _anySwapInWithProof(
        string memory swapID,
        address token,
        address to,
        uint amount,
        uint fromChainID,
        bytes calldata _proof
    ) internal checkCompletion(swapID) {
        completedSwapin[swapID] = true;
        bytes32 proofID = keccak256(
            abi.encode(swapID, token, to, amount, fromChainID)
        );
        require(!proofConsumed[proofID], "proof comsumed");
        proofConsumed[proofID] = true;

        bytes32 r = bytes32(_proof[0:32]);
        bytes32 s = bytes32(_proof[32:64]);
        uint8 v = uint8(_proof[64]);
        address signer = ecrecover(proofID, v, r, s);
        require(signer != address(0) && isProofSigner[signer], "wrong proof");

        AnyswapV1ERC20(token).mint(to, amount);
        emit LogAnySwapInWithProof(
            swapID,
            token,
            to,
            amount,
            fromChainID,
            cID(),
            proofID
        );
    }

    // swaps `amount` `token` in `fromChainID` to `to` on this chainID
    // triggered by `anySwapOut`
    function anySwapInWithProof(
        string memory swapID,
        address token,
        address to,
        uint amount,
        uint fromChainID,
        bytes calldata _proof
    ) external {
        _anySwapInWithProof(swapID, token, to, amount, fromChainID, _proof);
    }

    // swaps `amount` `token` in `fromChainID` to `to` on this chainID with `to` receiving `underlying`
    function anySwapInUnderlyingWithProof(
        string memory swapID,
        address token,
        address to,
        uint amount,
        uint fromChainID,
        bytes calldata _proof
    ) external {
        address _underlying = AnyswapV1ERC20(token).underlying();
        require(_underlying != address(0), "AnyswapV6Router: no underlying");
        _anySwapInWithProof(swapID, token, to, amount, fromChainID, _proof);
        AnyswapV1ERC20(token).withdrawVault(to, amount, to);
    }

    // swaps `amount` `token` in `fromChainID` to `to` on this chainID with `to` receiving `underlying` if possible
    function anySwapInAutoWithProof(
        string memory swapID,
        address token,
        address to,
        uint amount,
        uint fromChainID,
        bytes calldata _proof
    ) external {
        _anySwapInWithProof(swapID, token, to, amount, fromChainID, _proof);
        AnyswapV1ERC20 _anyToken = AnyswapV1ERC20(token);
        address _underlying = _anyToken.underlying();
        if (
            _underlying != address(0) &&
            IERC20(_underlying).balanceOf(token) >= amount
        ) {
            if (_underlying == wNATIVE) {
                _anyToken.withdrawVault(to, amount, address(this));
                IwNATIVE(wNATIVE).withdraw(amount);
                TransferHelper.safeTransferNative(to, amount);
            } else {
                _anyToken.withdrawVault(to, amount, to);
            }
        }
    }

    /// @notice get all proof signers
    function getAllProofSigners() external view returns (address[] memory) {
        return proofSigners;
    }

    /// @notice set check completion flag
    function setCheckCompletion(bool enable) external onlyMPC {
        disableCheckCompletion = !enable;
    }

    /// @notice add proof signers
    function addProofSigners(address[] calldata signers) external onlyMPC {
        for (uint i = 0; i < signers.length; i++) {
            _addProofSigners(signers[i]);
        }
    }

    /// @notice remove proof signers
    function removeProofSigners(address[] calldata signers) external onlyMPC {
        for (uint i = 0; i < signers.length; i++) {
            _removeProofSigners(signers[i]);
        }
    }

    function _addProofSigners(address _signer) internal {
        require(_signer != address(0), "zero signer address");
        require(!isProofSigner[_signer], "signer already exist");
        isProofSigner[_signer] = true;
        proofSigners.push(_signer);
        emit AddProofSigner(_signer);
    }

    function _removeProofSigners(address _signer) internal {
        require(isProofSigner[_signer], "signer not exist");
        isProofSigner[_signer] = false;
        _popProofSigner(_signer);
        emit RemoveProofSigner(_signer);
    }

    function _popProofSigner(address _signer) internal {
        uint256 length = proofSigners.length;
        for (uint256 i = 0; i < length - 1; i++) {
            if (proofSigners[i] == _signer) {
                proofSigners[i] = proofSigners[length - 1];
                break;
            }
        }
        proofSigners.pop();
    }
}
