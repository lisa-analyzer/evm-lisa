pragma solidity ^0.8.6;

interface ITokenConfig {
    function mintToken(address _to, uint256 _amount) external;

    function burnToken(address _owner, uint256 _amount) external;
}
