// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract SideBridge {
  IERC20 private bnbToken;
        struct getDetailsByHashDetail{
        bytes32 getDetailsByHash;
        address user;
        uint amount;
        uint bridgetime;
    }
    event BridgeInitialized(uint256 indexed timestamp);
    event TokensBridged(
        address indexed requester,
    
        uint256 amount,
        uint256 timestamp
    );
    event TokensReturned(
        address indexed requester,
    
        uint256 amount,
        uint256 timestamp
    );

    bool bridgeInitState;
    address owner;
    address gateway;

    function initializeToken(address _childTokenAddress) external  {
        bnbToken = IERC20(_childTokenAddress);
        bridgeInitState = true;
    }

    function bridgeTokens(
        address _requester,
        uint aaamount
      
    ) external  onlyGateway verifyInitialization {
    
        IERC20(bnbToken).mint(_requester, aaamount);
        emit TokensBridged(
            _requester,
            aaamount,
            block.timestamp
        );
    }
  function setGateway() public {
        gateway = msg.sender;
    }

    function getGateway() public view returns (address) {
        return gateway;
    }

   
 function lockTokens(
        address _requester,
        uint256 _bridgedAmount
    ) external onlyGateway verifyInitialization {
        require (_bridgedAmount >= 100 ||_bridgedAmount <= 1000 , " min 100 and max 1000");
        IERC20(bnbToken).burn(_requester, _bridgedAmount);
        emit TokensLocked(
            _requester,
            _bridgedAmount,
            block.timestamp
         
        );
    }
    
 modifier verifyInitialization() {
        require(bridgeInitState, "Bridge has not been initialized");
        _;
    }
    modifier onlyGateway() {
        require(
            msg.sender == gateway,
            "Only gateway can execute this function"
        );
        _;
    }

    event TokensLocked(
        address indexed requester,
        uint256 amount,
        uint256 timestamp
    );
   
}
