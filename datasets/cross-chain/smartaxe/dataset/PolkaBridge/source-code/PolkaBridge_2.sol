pragma solidity >=0.6.0;
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Detailed.sol";
import "./IERC20.sol";

contract PolkaBridge is ERC20, ERC20Detailed, ERC20Burnable {
    constructor(uint256 initialSupply)
        public
        ERC20Detailed("PolkaBridge", "PBR", 18)
    {
        _deploy(msg.sender, initialSupply, 1615766400); //15 Mar 2021 1615766400
    }

    //withdraw contract token
    //use for someone send token to contract
    //recuse wrong user

    function withdrawErc20(IERC20 token) public {
        token.transfer(tokenOwner, token.balanceOf(address(this)));
    }
}