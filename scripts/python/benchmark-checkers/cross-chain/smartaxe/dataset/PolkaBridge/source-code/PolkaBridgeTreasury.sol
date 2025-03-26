pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "@openzeppelin/contracts/ownership/Ownable.sol";

contract PolkaBridgeTreasury is Ownable {
    string public name = "PolkaBridge: Treasury";

    using SafeERC20 for IERC20;
    address payable private fundOwner;

    constructor(address payable _fundOwner) public {
        fundOwner = _fundOwner;
    }

    function withdrawToken(address asset) public onlyOwner {
        IERC20 token = IERC20(asset);
        token.safeTransfer(owner(), token.balanceOf(address(this)));
    }

    function withdrawFund() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        fundOwner.transfer(balance);
    }

    receive() external payable {}
}