pragma solidity ^0.8.1;

import "./AnyCallApp.sol";

abstract contract AnyCallAppFallback is AnyCallApp {
    function _anyFallback(bytes calldata data) internal virtual;

    function anyFallback(address to, bytes calldata data) external onlyExecutor {
        (address callFrom, ,) = IExecutor(IAnycallV6Proxy(anyCallProxy).executor()).context();
        require(address(this) == callFrom, "call not allowed");
        _anyFallback(data);
    }
}