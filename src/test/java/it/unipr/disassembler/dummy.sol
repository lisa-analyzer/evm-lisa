pragma solidity ^0.8.0;

contract EthereumPot {
    address[] public addresses;
    address payable public winnerAddress;
    address payable public owner;
    uint[] public slots;

    constructor() {
        // owner = msg.sender;
    }

    receive() external payable {
        // Receive funds
    }

    function callback(bytes32 queryId, string memory result, bytes memory _proof) public {
        require(msg.sender == msg.sender, "Only Oraclize callback address can call this function");
        uint random_number = uint(keccak256(abi.encodePacked(result)));
        winnerAddress = findWinner(random_number);
        uint amountWon = address(this).balance * 98 / 100;
        winnerAnnounced(winnerAddress, amountWon);

        if (winnerAddress.send(amountWon) && owner.send(address(this).balance)) {
            openPot();
        }
    }

    function findWinner(uint random) internal view returns (address payable winner) {
        for (uint i = 0; i < slots.length; i++) {
            if (random <= slots[i]) {
                return payable(addresses[i]);
            }
        }
    }

    function winnerAnnounced(address winner, uint random) internal pure {
        // Implement your winnerAnnounced logic here
    }

    function openPot() internal pure {
        // Implement your openPot logic here
    }
}
