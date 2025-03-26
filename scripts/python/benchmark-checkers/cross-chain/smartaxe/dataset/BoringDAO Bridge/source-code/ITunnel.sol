// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ITunnel {
    function pledge(address account, uint amount) external;
    function redeem(address account, uint amount) external;
    function issue(address account, uint amount) external;
    function burn(address account, uint amount, string memory assetAddress) external;
    function totalValuePledge() external view  returns(uint);
    function canIssueAmount() external view returns(uint);
    function oTokenKey() external view returns(bytes32);
}

interface ITunnelV2 {
    function pledge(address account, uint amount) external;
    function redeem(address account, uint amount) external;
    function issue(address account, uint amount) external;
    function burn(address account, uint amount, string memory assetAddress) external;
    function totalValuePledge() external view  returns(uint);
    function canIssueAmount() external view returns(uint);
}

interface ITunnelTVL {
    function totalTVL() external view returns(uint);
}