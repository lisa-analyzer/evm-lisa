pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IToken.sol";

contract BridgeBase {
    IToken public token;
    mapping(address => mapping(uint256 => bool)) public processedNonces;

    // Handling multisig
    mapping(bytes32 => Transaction) public transactions;
    struct Transaction {
        address[] potentialSigners;
        address[] signers;
        address sender;
        address receiver;
        uint amount;
    }

    enum Step {
        Burn,
        Mint
    }
    event Proposed(
        address sender,
        address receiver,
        uint amount,
        address proposer,
        bytes signature
    );
    event Confirmed(
        address sender,
        address receiver,
        uint amount,
        address signer,
        bytes signature
    );
    event Transfer(address from, address to, uint256 amount, Step indexed step);

    constructor(address _token) {
        token = IToken(_token);
    }

    // Function to propose a transaction
    function proposeTransaction(
        address sender,
        address receiver,
        uint amount,
        address[] memory potentialSigners,
        address proposer,
        bytes calldata signature
    ) public {
        // check if the message is signed by the user
        bytes32 message = prefixed(
            keccak256(abi.encodePacked(sender, receiver, amount))
        );
        require(
            recoverSigner(message, signature) == proposer,
            "Signature Error: Not Signed by the Proposer"
        );
        // Check if there are three potential signers
        require(
            potentialSigners.length == 3,
            "Three potential signers are required"
        );

        // Store the transaction details in the mapping

        transactions[message] = Transaction(
            potentialSigners,
            new address[](0),
            sender,
            receiver,
            amount
        );
        // adding proposer as the signer
        transactions[message].signers.push(msg.sender);

        // emit the event that the transaction has been proposed

        emit Proposed(sender, receiver, amount, proposer, signature);
    }

    // Internal function to check if an address exists in an array
    function addressExists(
        address[] memory _arr,
        address _address
    ) internal view returns (bool) {
        for (uint256 i = 0; i < _arr.length; i++) {
            if (_arr[i] == _address) {
                return true;
            }
        }
        return false;
    }

    // Function to confirm a transaction
    function confirmTransaction(
        address sender,
        address receiver,
        uint amount,
        address signer,
        bytes memory signature
    ) public {
        // Checking validity of signature
        // check if the message is signed by the user
        bytes32 message = prefixed(
            keccak256(abi.encodePacked(sender, receiver, amount))
        );

        require(
            recoverSigner(message, signature) == signer,
            "Signature Error: Not Signed by the Sender"
        );

        // If the caller is valid potential Signer
        // Someone can confirm the transaction only if they are one of the potential signers
        require(
            addressExists(transactions[message].potentialSigners, signer),
            "Provided Address is not a potential signer for this transaction"
        );
        // The transaction should not be repeatedly signed by same person
        require(
            !addressExists(transactions[message].signers, signer),
            "Sender has already signed this transaction"
        );

        // adding proposer as the signer
        transactions[message].signers.push(signer);
        // if 2 of 3 people have signed the transaction, execute it
        emit Confirmed(sender, receiver, amount, signer, signature);
        if (transactions[message].signers.length >= 2) {
            Transaction memory trx = transactions[message];
            burn(trx.sender, trx.receiver, trx.amount);
        }
    }

    function burn(address from, address to, uint256 amount) internal {
        token.burn(from, amount);
        emit Transfer(from, to, amount, Step.Burn);
    }

    function mint(address from, address to, uint256 amount) external {
        token.mint(to, amount);
        //address from, address to, uint256 amount, Step indexed step
        emit Transfer(from, to, amount, Step.Mint);
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    function recoverSigner(
        bytes32 message,
        bytes memory sig
    ) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    function splitSignature(
        bytes memory sig
    ) internal pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }
}
