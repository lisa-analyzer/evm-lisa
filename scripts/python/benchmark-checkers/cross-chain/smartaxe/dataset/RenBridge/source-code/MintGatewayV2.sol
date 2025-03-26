pragma solidity ^0.5.17;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/cryptography/ECDSA.sol";
import "@openzeppelin/upgrades/contracts/upgradeability/InitializableAdminUpgradeabilityProxy.sol";

import "../Governance/Claimable.sol";
import "../libraries/String.sol";
import "./RenERC20.sol";
import "./interfaces/IGateway.sol";
import "../libraries/CanReclaimTokens.sol";
import "./MintGatewayV1.sol";

contract MintGatewayStateV2 {
    struct Burn {
        uint256 _blocknumber;
        bytes _to;
        uint256 _amount;
        // Optional
        string _chain;
        bytes _payload;
    }

    mapping(uint256 => Burn) internal burns;

    bytes32 public selectorHash;
}

/// @notice Gateway handles verifying mint and burn requests. A mintAuthority
/// approves new assets to be minted by providing a digital signature. An owner
/// of an asset can request for it to be burnt.
contract MintGatewayLogicV2 is
    Initializable,
    Claimable,
    CanReclaimTokens,
    IGateway,
    MintGatewayStateV1,
    MintGatewayStateV2
{
    using SafeMath for uint256;

    event LogMintAuthorityUpdated(address indexed _newMintAuthority);
    event LogMint(
        address indexed _to,
        uint256 _amount,
        uint256 indexed _n,
        // Log the nHash instead of sHash so that it can be queried without
        // knowing the sHash.
        bytes32 indexed _nHash
    );
    event LogBurn(
        bytes _to,
        uint256 _amount,
        uint256 indexed _n,
        bytes indexed _indexedTo
    );

    /// @notice Only allow the Darknode Payment contract.
    modifier onlyOwnerOrMintAuthority() {
        require(
            msg.sender == mintAuthority || msg.sender == owner(),
            "MintGateway: caller is not the owner or mint authority"
        );
        _;
    }

    /// @param _token The RenERC20 this Gateway is responsible for.
    /// @param _feeRecipient The recipient of burning and minting fees.
    /// @param _mintAuthority The address of the key that can sign mint
    ///        requests.
    /// @param _mintFee The amount subtracted each mint request and
    ///        forwarded to the feeRecipient. In BIPS.
    /// @param _burnFee The amount subtracted each burn request and
    ///        forwarded to the feeRecipient. In BIPS.
    function initialize(
        RenERC20LogicV1 _token,
        address _feeRecipient,
        address _mintAuthority,
        uint16 _mintFee,
        uint16 _burnFee,
        uint256 _minimumBurnAmount
    ) public initializer {
        Claimable.initialize(msg.sender);
        CanReclaimTokens.initialize(msg.sender);
        minimumBurnAmount = _minimumBurnAmount;
        token = _token;
        mintFee = _mintFee;
        burnFee = _burnFee;
        updateMintAuthority(_mintAuthority);
        updateFeeRecipient(_feeRecipient);
    }

    /// @param _selectorHash Hash of the token and chain selector.
    ///        The hash should calculated from
    ///        `SHA256(4 bytes of selector length, selector)`
    function updateSelectorHash(bytes32 _selectorHash) public onlyOwner {
        selectorHash = _selectorHash;
    }

    /// @notice Allow the owner to update the token symbol.
    function updateSymbol(string memory symbol) public onlyOwner {
        token.updateSymbol(symbol);
    }

    // Public functions ////////////////////////////////////////////////////////

    /// @notice Claims ownership of the token passed in to the constructor.
    /// `transferStoreOwnership` must have previously been called.
    /// Anyone can call this function.
    function claimTokenOwnership() public {
        token.claimOwnership();
    }

    /// @notice Allow the owner to update the owner of the RenERC20 token.
    function transferTokenOwnership(MintGatewayLogicV2 _nextTokenOwner)
        public
        onlyOwner
    {
        token.transferOwnership(address(_nextTokenOwner));
        _nextTokenOwner.claimTokenOwnership();
    }

    /// @notice Allow the owner to update the mint authority.
    ///
    /// @param _nextMintAuthority The new mint authority address.
    function updateMintAuthority(address _nextMintAuthority)
        public
        onlyOwnerOrMintAuthority
    {
        // The mint authority should not be set to 0, which is the result
        // returned by ecrecover for an invalid signature.
        require(
            _nextMintAuthority != address(0),
            "MintGateway: mintAuthority cannot be set to address zero"
        );
        mintAuthority = _nextMintAuthority;
        emit LogMintAuthorityUpdated(mintAuthority);
    }

    /// @notice Allow the owner to update the minimum burn amount.
    ///
    /// @param _minimumBurnAmount The new min burn amount.
    function updateMinimumBurnAmount(uint256 _minimumBurnAmount)
        public
        onlyOwner
    {
        minimumBurnAmount = _minimumBurnAmount;
    }

    /// @notice Allow the owner to update the fee recipient.
    ///
    /// @param _nextFeeRecipient The address to start paying fees to.
    function updateFeeRecipient(address _nextFeeRecipient) public onlyOwner {
        // 'mint' and 'burn' will fail if the feeRecipient is 0x0
        require(
            _nextFeeRecipient != address(0x0),
            "MintGateway: fee recipient cannot be 0x0"
        );

        feeRecipient = _nextFeeRecipient;
    }

    /// @notice Allow the owner to update the 'mint' fee.
    ///
    /// @param _nextMintFee The new fee for minting and burning.
    function updateMintFee(uint16 _nextMintFee) public onlyOwner {
        mintFee = _nextMintFee;
    }

    /// @notice Allow the owner to update the burn fee.
    ///
    /// @param _nextBurnFee The new fee for minting and burning.
    function updateBurnFee(uint16 _nextBurnFee) public onlyOwner {
        burnFee = _nextBurnFee;
    }

    /// @notice Allow the owner to update the mint and burn fees.
    ///
    /// @param _nextMintFee The new fee for minting and burning.
    /// @param _nextBurnFee The new fee for minting and burning.
    function updateFees(uint16 _nextMintFee, uint16 _nextBurnFee)
        public
        onlyOwner
    {
        mintFee = _nextMintFee;
        burnFee = _nextBurnFee;
    }

    /// @notice mint verifies a mint approval signature from RenVM and creates
    ///         tokens after taking a fee for the `_feeRecipient`.
    ///
    /// @param _pHash (payload hash) The hash of the payload associated with the
    ///        mint.
    /// @param _amountUnderlying The amount of the token being minted, in its smallest
    ///        value. (e.g. satoshis for BTC).
    /// @param _nHash (nonce hash) The hash of the nonce, amount and pHash.
    /// @param _sig The signature of the hash of the following values:
    ///        (pHash, amount, msg.sender, nHash), signed by the mintAuthority.
    function mint(
        bytes32 _pHash,
        uint256 _amountUnderlying,
        bytes32 _nHash,
        bytes memory _sig
    ) public returns (uint256) {
        // Calculate the hash signed by RenVM.
        bytes32 sigHash =
            hashForSignature(_pHash, _amountUnderlying, msg.sender, _nHash);

        // Calculate the v0.2 signature hash for backwards-compatibility.
        bytes32 legacySigHash =
            _legacy_hashForSignature(
                _pHash,
                _amountUnderlying,
                msg.sender,
                _nHash
            );

        // Check that neither signature has been redeemed.
        require(
            status[sigHash] == false && status[legacySigHash] == false,
            "MintGateway: nonce hash already spent"
        );

        // If both signatures fail verification, throw an error. If any one of
        // them passed the verification, continue.
        if (
            !verifySignature(sigHash, _sig) &&
            !verifySignature(legacySigHash, _sig)
        ) {
            // Return a detailed string containing the hash and recovered
            // signer. This is somewhat costly but is only run in the revert
            // branch.
            revert(
                String.add8(
                    "MintGateway: invalid signature. pHash: ",
                    String.fromBytes32(_pHash),
                    ", amount: ",
                    String.fromUint(_amountUnderlying),
                    ", msg.sender: ",
                    String.fromAddress(msg.sender),
                    ", _nHash: ",
                    String.fromBytes32(_nHash)
                )
            );
        }

        // Update the status for both signature hashes. This is to ensure that
        // legacy signatures can't be re-redeemed if `updateSelectorHash` is
        // ever called - thus changing the result of `sigHash` but not
        // `legacySigHash`.
        status[sigHash] = true;
        status[legacySigHash] = true;

        uint256 amountScaled = token.fromUnderlying(_amountUnderlying);

        // Mint `amount - fee` for the recipient and mint `fee` for the minter
        uint256 absoluteFeeScaled =
            amountScaled.mul(mintFee).div(BIPS_DENOMINATOR);
        uint256 receivedAmountScaled =
            amountScaled.sub(
                absoluteFeeScaled,
                "MintGateway: fee exceeds amount"
            );

        // Mint amount minus the fee
        token.mint(msg.sender, receivedAmountScaled);
        // Mint the fee
        if (absoluteFeeScaled > 0) {
            token.mint(feeRecipient, absoluteFeeScaled);
        }

        // Emit a log with a unique identifier 'n'.
        uint256 receivedAmountUnderlying =
            token.toUnderlying(receivedAmountScaled);
        emit LogMint(msg.sender, receivedAmountUnderlying, nextN, _nHash);
        nextN += 1;

        return receivedAmountScaled;
    }

    /// @notice burn destroys tokens after taking a fee for the `_feeRecipient`,
    ///         allowing the associated assets to be released on their native
    ///         chain.
    ///
    /// @param _to The address to receive the un-bridged asset. The format of
    ///        this address should be of the destination chain.
    ///        For example, when burning to Bitcoin, _to should be a
    ///        Bitcoin address.
    /// @param _amount The amount of the token being burnt, in its
    ///        smallest value. (e.g. satoshis for BTC)
    function burn(bytes memory _to, uint256 _amount) public returns (uint256) {
        // The recipient must not be empty. Better validation is possible,
        // but would need to be customized for each destination ledger.
        require(_to.length != 0, "MintGateway: to address is empty");

        // Calculate fee, subtract it from amount being burnt.
        uint256 fee = _amount.mul(burnFee).div(BIPS_DENOMINATOR);
        uint256 amountAfterFee =
            _amount.sub(fee, "MintGateway: fee exceeds amount");

        // If the scaled token can represent more precision than the underlying
        // token, the difference is lost. This won't exceed 1 sat, so is
        // negligible compared to burning and transaction fees.
        uint256 amountAfterFeeUnderlying = token.toUnderlying(amountAfterFee);

        // Burn the whole amount, and then re-mint the fee.
        token.burn(msg.sender, _amount);
        if (fee > 0) {
            token.mint(feeRecipient, fee);
        }

        require(
            // Must be strictly greater, to that the release transaction is of
            // at least one unit.
            amountAfterFeeUnderlying > minimumBurnAmount,
            "MintGateway: amount is less than the minimum burn amount"
        );

        emit LogBurn(_to, amountAfterFeeUnderlying, nextN, _to);

        // Store burn so that it can be looked up instead of relying on event
        // logs.
        bytes memory payload;
        MintGatewayStateV2.burns[nextN] = Burn({
            _blocknumber: block.number,
            _to: _to,
            _amount: amountAfterFeeUnderlying,
            _chain: "",
            _payload: payload
        });

        nextN += 1;

        return amountAfterFeeUnderlying;
    }

    function getBurn(uint256 _n)
        public
        view
        returns (
            uint256 _blocknumber,
            bytes memory _to,
            uint256 _amount,
            // Optional
            string memory _chain,
            bytes memory _payload
        )
    {
        Burn memory burnStruct = MintGatewayStateV2.burns[_n];
        require(burnStruct._to.length > 0, "MintGateway: burn not found");
        return (
            burnStruct._blocknumber,
            burnStruct._to,
            burnStruct._amount,
            burnStruct._chain,
            burnStruct._payload
        );
    }

    /// @notice verifySignature checks the the provided signature matches the
    /// provided parameters.
    function verifySignature(bytes32 _sigHash, bytes memory _sig)
        public
        view
        returns (bool)
    {
        return mintAuthority == ECDSA.recover(_sigHash, _sig);
    }

    /// @notice hashForSignature hashes the parameters so that they can be
    /// signed.
    function hashForSignature(
        bytes32 _pHash,
        uint256 _amount,
        address _to,
        bytes32 _nHash
    ) public view returns (bytes32) {
        return
            keccak256(abi.encode(_pHash, _amount, selectorHash, _to, _nHash));
    }

    /// @notice _legacy_hashForSignature calculates the signature hash used by
    /// the 0.2 version of RenVM. It's kept here for backwards-compatibility.
    function _legacy_hashForSignature(
        bytes32 _pHash,
        uint256 _amount,
        address _to,
        bytes32 _nHash
    ) public view returns (bytes32) {
        return
            keccak256(abi.encode(_pHash, _amount, address(token), _to, _nHash));
    }
}

/* solium-disable-next-line no-empty-blocks */
contract MintGatewayProxy is InitializableAdminUpgradeabilityProxy {

}