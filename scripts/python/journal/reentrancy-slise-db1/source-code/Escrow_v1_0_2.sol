pragma solidity 0.4.24;



/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


interface ITokenContract {
    function balanceOf(address _owner) external view returns (uint256 balance);
  
    function transfer(
        address _to, 
        uint256 _amount
    )
        external 
        returns (bool success);

    function transferFrom(
        address _from, 
        address _to, 
        uint256 _amount
    ) 
        external 
        returns (bool success);
}


/**
* @dev Supports ERC20 tokens
* The escrow smart contract for the open bazaar trades in Ethereum
* The smart contract is desgined keeping in mind the current wallet interface of the OB-core
* https://github.com/OpenBazaar/wallet-interface/blob/master/wallet.go
* Current wallet interface strictly adheres to UTXO(bitcoin) model
*/
contract Escrow_v1_0 {

    using SafeMath for uint256;

    enum Status {FUNDED, RELEASED}

    enum TransactionType {ETHER, TOKEN}

    event Executed(
        bytes32 scriptHash,
        address[] destinations,
        uint256[] amounts
    );

    event FundAdded(
        bytes32 scriptHash,
        address indexed from,
        uint256 valueAdded
    );

    event Funded(bytes32 scriptHash, address indexed from, uint256 value);

    struct Transaction {
        //SWC-Presence of unused variables: L39
        bytes32 scriptHash;//This is unique indentifier for a transaction
        uint256 value;
        uint256 lastModified;//Time at which transaction was last modified
        Status status;
        TransactionType transactionType;
        uint8 threshold;
        uint32 timeoutHours;
        address buyer;
        address seller;
        address tokenAddress;// Token address in case of token transfer
        address moderator;
        mapping(address=>bool) isOwner;//to keep track of owners/signers.
        mapping(address=>bool) voted;//to keep track of who all voted
        mapping(address=>bool) beneficiaries;//Benefeciaries of execution
    }

    mapping(bytes32 => Transaction) public transactions;

    uint256 public transactionCount = 0;

    //Contains mapping between each party and all of his transactions
    mapping(address => bytes32[])public partyVsTransaction;

    modifier transactionExists(bytes32 scriptHash) {
        require(
            transactions[scriptHash].value != 0, "Transaction does not exists"
        );
        _;
    }

    modifier transactionDoesNotExists (bytes32 scriptHash) {
        require(transactions[scriptHash].value == 0, "Transaction exists");
        _;
    }

    modifier inFundedState(bytes32 scriptHash) {
        require(
            transactions[scriptHash].status == Status.FUNDED, "Transaction is either in dispute or released state"
        );
        _;
    }

    modifier nonZeroAddress(address addressToCheck) {
        require(addressToCheck != address(0), "Zero address passed");
        _;
    }

    modifier checkTransactionType(
        bytes32 scriptHash,
        TransactionType transactionType
    )
    {
        require(
            transactions[scriptHash].transactionType == transactionType, "Transaction type does not match"
        );
        _;
    }

    modifier onlyBuyer(bytes32 scriptHash) {
        require(
            msg.sender == transactions[scriptHash].buyer, "The initiator of the transaction is not buyer"
        );
        _;
    }

    /**
    *@dev Add new transaction in the contract
    *@param buyer The buyer of the transaction
    *@param seller The seller of the listing associated with the transaction
    *@param moderator Moderator for this transaction
    *@param scriptHash keccak256 hash of the redeem script
    *@param threshold Minimum number of singatures required to released funds
    *@param timeoutHours Hours after which seller can release funds into his favour by signing transaction
    *@param uniqueId bytes20 unique id for the transaction, generated by ETH wallet
    *Redeem Script format will be following
    <uniqueId: 20><threshold:1><timeoutHours:4><buyer:20><seller:20><moderator:20><multisigAddress:20>
    * scripthash-> keccak256(uniqueId, threshold, timeoutHours, buyer, seller, moderator)
    *Pass amount of the ethers to be put in escrow
    *Please keep in mind you will have to add moderator fees also in the value
    */
    function addTransaction(
        address buyer,
        address seller,
        address moderator,
        uint8 threshold,
        uint32 timeoutHours,
        bytes32 scriptHash,
        bytes20 uniqueId
    )
        external
        payable
        transactionDoesNotExists(scriptHash)
        nonZeroAddress(buyer)
        nonZeroAddress(seller)
    {
        _addTransaction(
            buyer,
            seller,
            moderator,
            threshold,
            timeoutHours,
            scriptHash,
            msg.value,
            uniqueId,
            TransactionType.ETHER,
            address(0)
        );
        
        emit Funded(scriptHash, msg.sender, msg.value);

    }

    /**
    *@dev Add new transaction in the contract
    *@param buyer The buyer of the transaction
    *@param seller The seller of the listing associated with the transaction
    *@param moderator Moderator for this transaction
    *@param scriptHash keccak256 hash of the redeem script
    *@param threshold Minimum number of singatures required to released funds
    *@param timeoutHours Hours after which seller can release funds into his favour by signing transaction
    *@param value Amount of tokens to be put in escrow
    *@param uniqueId bytes20 unique id for the transaction, generated by ETH wallet
    *@param tokenAddress Address of the token to be used
    *Redeem Script format will be following
    <uniqueId: 20><threshold:1><timeoutHours:4><buyer:20><seller:20><moderator:20><multisigAddress:20><tokenAddress:20>
    * scripthash-> keccak256(uniqueId, threshold, timeoutHours, buyer, seller, moderator, tokenAddress)
    *approve escrow contract to spend amount of token on your behalf
    *Please keep in mind you will have to add moderator fees also in the value
    */
    function addTokenTransaction(
        address buyer,
        address seller,
        address moderator,
        uint8 threshold,
        uint32 timeoutHours,
        bytes32 scriptHash,
        uint256 value,
        bytes20 uniqueId,
        address tokenAddress
    )
        external
        transactionDoesNotExists(scriptHash)
        nonZeroAddress(buyer)
        nonZeroAddress(seller)
        nonZeroAddress(tokenAddress)
    {

        _addTransaction(
            buyer,
            seller,
            moderator,
            threshold,
            timeoutHours,
            scriptHash,
            value,
            uniqueId,
            TransactionType.TOKEN,
            tokenAddress
        );

        ITokenContract token = ITokenContract(tokenAddress);

        require(
            token.transferFrom(msg.sender, this, value),
            "Token transfer failed, maybe you did not approve escrow contract to spend on behalf of buyer"
        );
        emit Funded(scriptHash, msg.sender, value);
    }

    /**
    * @dev Check whether given address was a beneficiary of transaction execution or not
    * @param scriptHash script hash of the transaction
    * @param beneficiary Beneficiary address to be checked
    */
    function checkBeneficiary(
        bytes32 scriptHash,
        address beneficiary
    )
        external
        view
        returns (bool check)
    {
        check = transactions[scriptHash].beneficiaries[beneficiary];
    }

    /**
    * @dev Check whether given party has voted or not
    * @param scriptHash script hash of the transaction
    * @param party Address of the party whose vote has to be checked
    * @return bool vote
    */
    function checkVote(
        bytes32 scriptHash,
        address party
    )
        external
        view
        returns (bool vote)
    {
        vote = transactions[scriptHash].voted[party];
    }

    /**
    *@dev Allows buyer of the transaction to add more funds(ether) in the transaction. This will help to cater scenarios wherein initially buyer missed to fund transaction as required
    *@param scriptHash script hash of the transaction
    * Only buyer of the transaction can invoke this method
    */
    function addFundsToTransaction(
        bytes32 scriptHash
    )
        external
        transactionExists(scriptHash)
        inFundedState(scriptHash)
        checkTransactionType(scriptHash, TransactionType.ETHER)
        onlyBuyer(scriptHash)
        payable
    {
        uint256 _value = msg.value;

        require(_value > 0, "Value must be greater than zero.");

        transactions[scriptHash].value = transactions[scriptHash].value
            .add(_value);
        transactions[scriptHash].lastModified = block.timestamp;

        emit FundAdded(scriptHash, msg.sender, _value);
    }

    /**
    *@dev Allows buyer of the transaction to add more funds(Tokens) in the transaction. This will help to cater scenarios wherein initially buyer missed to fund transaction as required
    *@param scriptHash script hash of the transaction
    */
    function addTokensToTransaction(
        bytes32 scriptHash,
        uint256 value
    )
        external
        transactionExists(scriptHash)
        inFundedState(scriptHash)
        checkTransactionType(scriptHash, TransactionType.TOKEN)
        onlyBuyer(scriptHash)
    {
        uint256 _value = value;

        require(_value > 0, "Value must be greater than zero.");

        ITokenContract token = ITokenContract(
            transactions[scriptHash].tokenAddress
        );

        require(
            token.transferFrom(transactions[scriptHash].buyer, this, value),
            "Token transfer failed, maybe you did not approve escrow contract to spend on behalf of buyer"
        );

        transactions[scriptHash].value = transactions[scriptHash].value
            .add(_value);
        transactions[scriptHash].lastModified = block.timestamp;

        emit FundAdded(scriptHash, msg.sender, _value);
    }

    /**
    *@dev Returns all transaction ids for a party
    *@param partyAddress Address of the party
    */
    function getAllTransactionsForParty(
        address partyAddress
    ) 
        external 
        view 
        returns (bytes32[] scriptHashes) 
    {
        return partyVsTransaction[partyAddress];
    }

    /**
    *@dev Allows one of the moderator to collect all the signature to solve dispute and submit it to this method.
    * If all the required signatures are collected and consensus has been reached than funds will be released to the voted party
    *@param sigV Array containing V component of all the signatures
    *@param sigR Array containing R component of all the signatures
    *@param signS Array containing S component of all the signatures
    *@param scriptHash script hash of the transaction
    *@param destinations address of the destination in whose favour dispute resolution is taking place. In case of split payments it will be address of the split payments contract
    *@param amounts value to send to each destination
    */
    function execute(
        uint8[] sigV,
        bytes32[] sigR,
        bytes32[] sigS,
        bytes32 scriptHash,
        address[] destinations,
        uint256[] amounts
    )
        external
        transactionExists(scriptHash)
        inFundedState(scriptHash)
    {
        require(
            destinations.length>0 && destinations.length == amounts.length, "Length of destinations is incorrect."
        );

        verifyTransaction(
            sigV,
            sigR,
            sigS,
            scriptHash,
            destinations,
            amounts
        );

        transactions[scriptHash].status = Status.RELEASED;
        //Last modified timestamp modified, which will be used by rewards
        transactions[scriptHash].lastModified = block.timestamp;
        require(
            transferFunds(scriptHash, destinations, amounts) == transactions[scriptHash].value,
            "Total value to be released must be equal to the transaction escrow value"
        );
        
        emit Executed(scriptHash, destinations, amounts);
    }


    /**
    *@dev Method for calculating script hash. Calculation will depend upon the type of transaction
    * ETHER Type transaction-:
    * Script Hash- keccak256(uniqueId, threshold, timeoutHours, buyer, seller, moderator)
    * TOKEN Type transaction
    * Script Hash- keccak256(uniqueId, threshold, timeoutHours, buyer, seller, moderator, tokenAddress)
    * Client can use this method to verify whether it has calculated correct script hash or not
    */
    function calculateRedeemScriptHash(
        bytes20 uniqueId,
        uint8 threshold,
        uint32 timeoutHours,
        address buyer,
        address seller,
        address moderator,
        address tokenAddress
    )
        public
        view
        returns (bytes32 hash)
    {
        if (tokenAddress == address(0)) {
            hash = keccak256(
                abi.encodePacked(
                    uniqueId,
                    threshold,
                    timeoutHours,
                    buyer,
                    seller,
                    moderator,
                    this
                )
            );
        } else {
            hash = keccak256(
                abi.encodePacked(
                    uniqueId,
                    threshold,
                    timeoutHours,
                    buyer,
                    seller,
                    moderator,
                    this,
                    tokenAddress
                )
            );
        }
    }

    /**
    * @dev This methods checks validity of transaction
    * 1. Verify Signatures
    * 2. Check if minimum number of signatures has been acquired
    * 3. If above condition is false, check if time lock is expired and the execution is signed by seller
    */
    function verifyTransaction(
        uint8[] sigV,
        bytes32[] sigR,
        bytes32[] sigS,
        bytes32 scriptHash,
        address[] destinations,
        uint256[] amounts
    )
        private
    {
        address lastRecovered = verifySignatures(
            sigV,
            sigR,
            sigS,
            scriptHash,
            destinations,
            amounts
        );

        bool timeLockExpired = isTimeLockExpired(
            transactions[scriptHash].timeoutHours,
            transactions[scriptHash].lastModified
        );

        //if Minimum number of signatures are not gathered and timelock has not expired or transaction was not signed by seller then revert
        if (
                sigV.length < transactions[scriptHash].threshold && (!timeLockExpired || lastRecovered != transactions[scriptHash].seller)
            )
        {
            revert("sigV.length is under the threshold.");
        }

    }

    /**
    *@dev Private method to transfer funds to the destination addresses on the basis of transaction type
    */
    function transferFunds(
        bytes32 scriptHash,
        address[]destinations,
        uint256[]amounts
    )
        private
        returns (uint256 valueTransferred)
    {
        Transaction storage t = transactions[scriptHash];

        if (t.transactionType == TransactionType.ETHER) {
            for (uint256 i = 0; i < destinations.length; i++) {

                require(destinations[i] != address(0) && t.isOwner[destinations[i]], "Not a valid destination");
                require(amounts[i] > 0, "Amount to be sent should be greater than 0");

                valueTransferred = valueTransferred.add(amounts[i]);

                t.beneficiaries[destinations[i]] = true;//add receiver as beneficiary
                destinations[i].transfer(amounts[i]);//shall we use send instead of transfer to stop malicious actors from blocking funds?
            }

        } else if (t.transactionType == TransactionType.TOKEN) {

            ITokenContract token = ITokenContract(t.tokenAddress);

            for (uint256 j = 0; j<destinations.length; j++) {

                require(destinations[j] != address(0) && t.isOwner[destinations[j]], "Not a valid destination");
                require(amounts[j] > 0, "Amount to be sent should be greater than 0");

                valueTransferred = valueTransferred.add(amounts[j]);
                t.beneficiaries[destinations[j]] = true;//add receiver as beneficiary

                require(token.transfer(destinations[j], amounts[j]), "Token transfer failed.");
            }
        // SWC-Code With No Effects: L491
        } else {
            //transaction type is not supported. Ideally this state should never be reached
            revert("Transation type is not supported.");
        }
    }

    //to check whether the signature are valid or not and if consensus was reached
    //returns the last address recovered, in case of timeout this must be the sender's address
    function verifySignatures(
        uint8[] sigV,
        bytes32[] sigR,
        bytes32[] sigS,
        bytes32 scriptHash,
        address[] destinations,
        uint256[]amounts
    )
        private
        returns (address lastAddress)
    {
        require(
            sigR.length == sigS.length && sigR.length == sigV.length, 
            "R,S,V length mismatch."
        );

        // Follows ERC191 signature scheme: https://github.com/ethereum/EIPs/issues/191
        bytes32 txHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encodePacked(
                        byte(0x19),
                        byte(0),
                        this,
                        destinations,
                        amounts,
                        scriptHash
                    )
                )
            )
        );

        for (uint i = 0; i < sigR.length; i++) {

            address recovered = ecrecover(
                txHash,
                sigV[i],
                sigR[i],
                sigS[i]
            );

            require(
                transactions[scriptHash].isOwner[recovered], 
                "Invalid signature"
            );
            require(
                !transactions[scriptHash].voted[recovered], 
                "Same signature sent twice"
            );
            transactions[scriptHash].voted[recovered] = true;
            lastAddress = recovered;
        }
    }

    function isTimeLockExpired(
        uint32 timeoutHours,
        uint256 lastModified
    )
        private
        view
        returns (bool expired)
    {
        uint256 timeSince = now.sub(lastModified);
        expired = (
            timeoutHours == 0 ? false:timeSince > uint256(timeoutHours).mul(3600)
        );
    }

    /**
    * Private method to add transaction to reduce code redundancy
    */
    function _addTransaction(
        address buyer,
        address seller,
        address moderator,
        uint8 threshold,
        uint32 timeoutHours,
        bytes32 scriptHash,
        uint256 value,
        bytes20 uniqueId,
        TransactionType transactionType,
        address tokenAddress
    )
        private
    {        
        require(buyer != seller, "Buyer and seller are same");

        //value passed should be greater than 0
        require(value > 0, "Value passed is 0");

        // For now allowing 0 moderator to support 1-2 multisig wallet
        require(
            threshold > 0 && threshold <= 3, 
            "Threshold cannot be greater than 3 and must be greater than 0"
        );
        require(
            threshold == 1 || moderator != address(0),
            "Either threshold should be 1 otherwise valid moderator address should be passed"
        );

        require(
            scriptHash == calculateRedeemScriptHash(
                uniqueId,
                threshold,
                timeoutHours,
                buyer,
                seller,
                moderator,
                tokenAddress
            ), 
            "Calculated script hash does not match passed script hash."
        );

        transactions[scriptHash] = Transaction({
            buyer: buyer,
            seller: seller,
            moderator: moderator,
            value: value,
            status: Status.FUNDED,
            lastModified: block.timestamp,
            scriptHash: scriptHash,
            threshold: threshold,
            timeoutHours: timeoutHours,
            transactionType:transactionType,
            tokenAddress:tokenAddress
        });

        transactions[scriptHash].isOwner[seller] = true;
        transactions[scriptHash].isOwner[buyer] = true;            

        //Check if buyer or seller are not passed as moderator
        require(
            !transactions[scriptHash].isOwner[moderator], 
            "Either buyer or seller is passed as moderator"
        );

        transactions[scriptHash].isOwner[moderator] = true;
       

        transactionCount++;

        partyVsTransaction[buyer].push(scriptHash);
        partyVsTransaction[seller].push(scriptHash);
    }
}
