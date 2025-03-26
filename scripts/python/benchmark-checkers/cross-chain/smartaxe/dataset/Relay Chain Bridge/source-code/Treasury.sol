pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Treasury is Ownable {
    uint256 public cliff;

    constructor(uint256 _cliff) {
        cliff = _cliff;
    }

    modifier whenCliff {
        require(block.timestamp >= cliff, "Withdrawing not yet available");
        _;
    }

    function withdrawETH() external onlyOwner whenCliff {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawERC20(IERC20 token) external onlyOwner whenCliff {
        uint256 amount = token.balanceOf(address(this));
        SafeERC20.safeTransfer(token, msg.sender, amount);
    }

    receive() external payable {}
}