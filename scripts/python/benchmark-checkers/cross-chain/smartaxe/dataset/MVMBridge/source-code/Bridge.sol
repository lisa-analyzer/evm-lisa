// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

interface Factory {
    function contracts(uint256 id) external view returns (address);
}

interface IERC20 {
    function transferWithExtra(
        address to,
        uint256 value,
        bytes memory extra
    ) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

contract Bridge {
    uint256 public constant BASE = 10000000000;

    address public immutable FACTORY;
    address public immutable XIN;
    address public immutable OWNER;
    mapping(address => address) public bridges;

    event Vault(address indexed from, uint256 amount);
    event Bound(address indexed from, address indexed to);
    event Through(
        address indexed asset,
        address indexed from,
        address indexed to,
        uint256 amount
    );

    constructor(address factory, address xin) {
        FACTORY = factory;
        XIN = xin;
        OWNER = msg.sender;
    }

    receive() external payable {
        if (msg.sender == OWNER) {
            emit Vault(msg.sender, msg.value / BASE);
            return;
        }

        address receiver = bridges[msg.sender];
        require(receiver != address(0), "no address bound");

        release(receiver, new bytes(0));
    }

    function release(address receiver, bytes memory input) public payable {
        uint256 amount = msg.value / BASE;
        require(amount > 0, "value too small");

        address bound = bridges[msg.sender];
        require(bound == address(0) || receiver == bound, "bound not match");

        IERC20(XIN).transferWithExtra(receiver, amount, input);
        emit Through(XIN, msg.sender, receiver, amount);
    }

    function vault(address asset, uint256 amount) public {
        asset = canonical(asset);
        require(asset == XIN, "only XIN accepted");
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        emit Vault(msg.sender, amount);
    }

    function bind(address receiver) public {
        require(receiver != address(0), "invalid address");
        bridges[msg.sender] = receiver;
        emit Bound(msg.sender, receiver);
    }

    function pass(address asset, uint256 amount) public {
        address receiver = bridges[msg.sender];
        require(receiver != address(0), "no address bound");
        require(amount > 0, "too small");

        asset = canonical(asset);
        if (asset == XIN) {
            passXIN(receiver, amount);
        } else {
            IERC20(asset).transferFrom(msg.sender, receiver, amount);
        }

        emit Through(asset, msg.sender, receiver, amount);
    }

    function passXIN(address receiver, uint256 amount) internal {
        IERC20(XIN).transferFrom(msg.sender, address(this), amount);
        payable(receiver).transfer(amount * BASE);
    }

    function canonical(address asset) internal view returns (address) {
        uint256 id = uint256(uint160(asset));
        address another = Factory(FACTORY).contracts(id);
        if (another != address(0)) {
            return another;
        }
        return asset;
    }
}