pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenConfig is ERC20 {
    // admin to be set to the bridge smart contract:
    address public admin;

    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "not admin");
        _;
    }

    function updateAdmin(address _newAdmin) external onlyAdmin {
        admin = _newAdmin;
    }

    function mintToken(address _to, uint256 _amount) external onlyAdmin {
        _mint(_to, _amount);
    }

    function burnToken(address _owner, uint256 _amount) external onlyAdmin {
        _burn(_owner, _amount);
    }
}
