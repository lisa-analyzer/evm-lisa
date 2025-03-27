// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IBridgedToken.sol";
import "./SignatureLibrary.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IRadarBridgeFeeManager.sol";

contract RadarBridge {

    using SafeERC20 for IERC20;

    address private owner;
    address private pendingOwner;
    address private feeManager;
    bytes32 private CHAIN;

    mapping(bytes32 => bool) private doubleSpendingProtection;
    mapping(bytes32 => bool) private nonceDoubleSpendingProtection;

    mapping(address => bool) private isSupportedToken;
    mapping(address => bool) private tokenToHandlerType; // 0 - transfers, 1 - mint/burn, BridgedToken
    mapping(bytes32 => address) private idToToken;
    mapping(address => bytes32) private tokenToId;
    mapping(bytes32 => address) private idToRouter;

    address[] private supportedTokens;

    event SupportedTokenAdded(address token, bool handlerType, bytes32 tokenId, address router);
    event SupportedTokenRemoved(address token, bytes32 tokenId);

    event TokensBridged(
        bytes32 tokenId,
        uint256 amount,
        bytes32 destinationChain,
        address destinationAddress,
        uint256 timestamp,
        uint256 feeAmount,
        uint256 receiveAmount
    );
    event TokensClaimed(
        bytes32 tokenId,
        uint256 amount,
        bytes32 sourceChain,
        uint256 bridgeTimestamp,
        bytes32 nonce,
        address destinationAddress
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized");
        _;
    }

    // Management
    function initialize(bytes32 _chain) public {
        require(owner == address(0), "Contract already initialized");
        require(implementation() != address(0), "Only delegates can call this");
        CHAIN = _chain;
        owner = msg.sender;
    }

    function upgrade(address _newRadarBridge) external onlyOwner {
        assembly {
            // solium-disable-line
            sstore(
                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc,
                _newRadarBridge
            )
        }
    }

    function sendOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid Owner Address");
        pendingOwner = _newOwner;
    }

    function acceptOwnership() external {
        require(msg.sender == pendingOwner, "Unauthorized");
        owner = pendingOwner;
        pendingOwner = address(0);
    }

    function addSupportedToken(address _token, bool _handlerType, bytes32 _tokenID, address _router) external onlyOwner {
        require(!isSupportedToken[_token] && tokenToId[_token] == "", "Token already exists");
        require(idToToken[_tokenID] == address(0), "Token ID already being used");

        if (_handlerType) {
            require(IBridgedToken(_token).getBridge() == address(this), "Bridge doesn't have permissions on BridgedToken");
        }

        isSupportedToken[_token] = true;
        supportedTokens.push(_token);
        tokenToHandlerType[_token] = _handlerType;
        tokenToId[_token] = _tokenID;
        idToToken[_tokenID] = _token;
        idToRouter[_tokenID] = _router;
        emit SupportedTokenAdded(_token, _handlerType, _tokenID, _router);
    }

    function removeSupportedToken(address _token) external onlyOwner {
        require(isSupportedToken[_token], "Token is not supported");

        isSupportedToken[_token] = false;
        uint256 _length = supportedTokens.length;
        for (uint256 i = 0; i < _length; i++) {
            if (supportedTokens[i] == _token) {
                if (i < _length - 1) {
                    supportedTokens[i] = supportedTokens[_length - 1];
                }
                supportedTokens.pop();
                break;
            }
        }
        bytes32 _tokenId = tokenToId[_token];
        tokenToId[_token] = "";
        idToToken[_tokenId] = address(0);
        idToRouter[_tokenId] = address(0);
        emit SupportedTokenRemoved(_token, _tokenId);
    }

    function changeTokenRouter(bytes32 _tokenId, address _newRouter, bytes memory signature) external {
        require(isSupportedToken[idToToken[_tokenId]], "Token not supported");

        // Verify Signature
        bytes32 message = keccak256(abi.encodePacked(bytes32("PASS OWNERSHIP"), _tokenId, _newRouter, CHAIN));
        require(SignatureLibrary.verify(message, signature, idToRouter[_tokenId]) == true, "Invalid Signature");

        // Change Router
        idToRouter[_tokenId] = _newRouter;
    }

    function changeFeeManager(address _newFeeManager) external onlyOwner {
        feeManager = _newFeeManager;
    }
    
    // Bridge Functions
    function bridgeTokens(
        address _token,
        uint256 _amount,
        bytes32 _destChain,
        address _destAddress
    ) external {
        require(isSupportedToken[_token], "Token not supported");
        require(IERC20(_token).balanceOf(msg.sender) >= _amount, "Not enough tokens");
        require(_destChain != CHAIN, "Cannot send to same chain");

        bytes32 _tokenId = tokenToId[_token];
        bool _handlerType = tokenToHandlerType[_token];
        uint256 _fee = 0;

        if (feeManager != address(0)) {
            uint256 _userFee;
            uint256 _feeBase;

            // Use try/catch to prvevent rogue bridge locking
            try IRadarBridgeFeeManager(feeManager).getBridgeFee(_token, msg.sender, _amount, _destChain, _destAddress) returns (uint256 _val) {
                _userFee = _val;
            } catch {
                _userFee = 0;
            }

            if (_userFee != 0) {
                try IRadarBridgeFeeManager(feeManager).getFeeBase() returns (uint256 _val2) {
                    _feeBase = _val2;
                } catch {
                    _feeBase = 0;
                }
                
                // fee cannot be larger than 10%
                if (_feeBase != 0 && (_userFee * 10) <= _feeBase) {
                    _fee = (_amount * _userFee) / _feeBase;
                }
            }
        }

        // Transfer tokens
        if (_handlerType) {
            // burn
            IBridgedToken(_token).burn(msg.sender, _amount);
            if (_fee != 0) {
                IBridgedToken(_token).mint(feeManager, _fee);
            }
        } else {
            // transfer
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
            if (_fee != 0) {
                IERC20(_token).safeTransfer(feeManager, _fee);
            }
        }

        emit TokensBridged(
            _tokenId,
            _amount,
            _destChain,
            _destAddress,
            block.timestamp,
            _fee,
            _amount-_fee
        );
    }

    function claimTokens(
        bytes32 _tokenId,
        uint256 _amount,
        bytes32 _srcChain,
        bytes32 _destChain,
        uint256 _srcTimestamp,
        bytes32 _nonce,
        address _destAddress,
        bytes calldata _signature
    ) external {
        address _token = idToToken[_tokenId];

        require(_token != address(0) && isSupportedToken[_token], "Token not supported.");
        require(_destChain == CHAIN, "Claiming tokens on wrong chain");

        bytes32 message = keccak256(abi.encodePacked(
            _tokenId,
            _amount,
            _srcChain,
            _destChain,
            _srcTimestamp,
            _nonce,
            _destAddress
        ));
        require(doubleSpendingProtection[message] == false, "Double Spending");
        require(nonceDoubleSpendingProtection[_nonce] == false, "Nonce Double Spending");
        require(SignatureLibrary.verify(message, _signature, idToRouter[_tokenId]) == true, "Router Signature Invalid");

        doubleSpendingProtection[message] = true;
        nonceDoubleSpendingProtection[_nonce] = true;

        bool _handlerType = tokenToHandlerType[_token];

        if (_handlerType) {
            // mint
            IBridgedToken(_token).mint(_destAddress, _amount);
        } else {
            // transfer
            IERC20(_token).safeTransfer(_destAddress, _amount);
        }

        emit TokensClaimed(_tokenId, _amount, _srcChain, _srcTimestamp, _nonce, _destAddress);
    }
    // State Getters
    function getOwner() external view returns (address) {
        return owner;
    }

    function getChain() external view returns (bytes32) {
        return CHAIN;
    }

    function getFeeManager() external view returns (address) {
        return feeManager;
    }
    
    function implementation() public view returns (address radarBridge_) {
        assembly {
            // solium-disable-line
            radarBridge_ := sload(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc)
        }
        return radarBridge_;
    }

    function getIsSupportedToken(address _token) external view returns (bool) {
        return isSupportedToken[_token];
    }

    function getTokenHandlerType(address _token) external view returns (bool) {
        return tokenToHandlerType[_token];
    }

    function getTokenId(address _token) external view returns (bytes32) {
        return tokenToId[_token];
    }

    function getTokenById(bytes32 _id) external view returns (address) {
        return idToToken[_id];
    }

    function getSupportedTokensLength() external view returns (uint) {
        return supportedTokens.length;
    }

    function getSupportedTokenByIndex(uint _index) external view returns (address) {
        return supportedTokens[_index];
    }
}