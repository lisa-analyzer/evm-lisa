// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@zeppelin-solidity/contracts/proxy/utils/Initializable.sol";
import "./AccessController.sol";

contract Backing is AccessController, Initializable {
    address public messageEndpoint;
    address public remoteMappingTokenFactory;
    
    uint256 internal locked;
    modifier nonReentrant {
        require(locked == 0, "backing: locked");
        locked = 1;
        _;
        locked = 0;
    }

    modifier onlyMessageEndpoint() {
        require(messageEndpoint == msg.sender, "Backing:Bad message handle");
        _;
    }

    function initialize(address _messageEndpoint) public initializer {
        messageEndpoint = _messageEndpoint;
        _initialize(msg.sender);
    }

    function _setMessageEndpoint(address _messageEndpoint) internal {
        messageEndpoint = _messageEndpoint;
    }

    function setRemoteMappingTokenFactory(address _remoteMappingTokenFactory) external onlyAdmin {
          remoteMappingTokenFactory = _remoteMappingTokenFactory;
    }
}
 
