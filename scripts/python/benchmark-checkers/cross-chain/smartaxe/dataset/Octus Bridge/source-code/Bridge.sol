// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;

import "./../interfaces/IBridge.sol";
import "./../libraries/ECDSA.sol";

import "./../utils/Cache.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";


/// @title Ethereum Bridge contract
/// @author https://github.com/broxus
/// @dev Stores relays for each round, implements slashing, helps in validating TON-ETH events
contract Bridge is OwnableUpgradeable, PausableUpgradeable, Cache, IBridge {
    using ECDSA for bytes32;

    // NOTE: round number -> address -> is relay?
    mapping (uint32 => mapping(address => bool)) public relays;

    // NOTE: is relay banned or not
    mapping (address => bool) public blacklist;

    // NOTE: round meta data
    mapping (uint32 => Round) public rounds;

    // NOTE: signature verifications always fails is emergency is on
    bool public emergencyShutdown;

    // NOTE: The required signatures per round can't be less than this
    uint32 public minimumRequiredSignatures;

    // NOTE: how long round signatures are considered valid after the end of the round
    uint32 public roundTTL;

    // NOTE: initial round number
    uint32 public initialRound;

    // NOTE: last round with known relays
    uint32 public lastRound;

    // NOTE: special address, can set up rounds without relays's signatures
    address public roundSubmitter;

    // NOTE: Broxus Bridge TON-ETH configuration address, that emits event with round relays
    TONAddress public roundRelaysConfiguration;

    /**
        @notice
            Bridge initializer
        @dev
            `roundRelaysConfiguration` should be specified later.
        @param _owner Bridge owner
        @param _roundSubmitter Round submitter
        @param _minimumRequiredSignatures Minimum required signatures per round.
        @param _roundTTL Round TTL after round ends.
        @param _initialRound Initial round number. Useful in case new EVM network is connected to the bridge.
        @param _initialRoundEnd Initial round end timestamp.
        @param _relays Initial set of relays. Encode addresses as uint160
    */
    function initialize(
        address _owner,
        address _roundSubmitter,
        uint32 _minimumRequiredSignatures,
        uint32 _roundTTL,
        uint32 _initialRound,
        uint32 _initialRoundEnd,
        uint160[] calldata _relays
    ) external initializer {
        __Pausable_init();
        __Ownable_init();
        transferOwnership(_owner);

        roundSubmitter = _roundSubmitter;
        emit UpdateRoundSubmitter(_roundSubmitter);

        minimumRequiredSignatures = _minimumRequiredSignatures;
        emit UpdateMinimumRequiredSignatures(minimumRequiredSignatures);

        roundTTL = _roundTTL;
        emit UpdateRoundTTL(roundTTL);

        require(
            _initialRoundEnd >= block.timestamp,
            "Bridge: initial round end should be in the future"
        );

        initialRound = _initialRound;
        _setRound(initialRound, _relays, _initialRoundEnd);

        lastRound = initialRound;
    }

    /**
        @notice
            Update address of configuration, that emits event with next round relays.
        @param _roundRelaysConfiguration TON address of configuration
    */
    function updateRoundRelaysConfiguration(
        TONAddress calldata _roundRelaysConfiguration
    ) external override onlyOwner {
        emit UpdateRoundRelaysConfiguration(_roundRelaysConfiguration);

        roundRelaysConfiguration = _roundRelaysConfiguration;
    }

    /**
        @notice
            Pause Bridge contract.
        @dev
            When Bridge paused, signature verification fails.
    */
    function pause() external override onlyOwner {
        _pause();
    }

    /**
        @notice
            Unpause Bridge contract.
    */
    function unpause() external override onlyOwner {
        _unpause();
    }

    /**
        @notice
            Update minimum amount of required signatures per round
        @param _minimumRequiredSignatures New value
    */
    function updateMinimumRequiredSignatures(
        uint32 _minimumRequiredSignatures
    ) external override onlyOwner {
        minimumRequiredSignatures = _minimumRequiredSignatures;

        emit UpdateMinimumRequiredSignatures(_minimumRequiredSignatures);
    }

    /**
        @notice
            Update round TTL
        @dev
            This affects only future rounds. Rounds, that were already set,
            keep their current TTL.
        @param _roundTTL New TTL value
    */
    function updateRoundTTL(
        uint32 _roundTTL
    ) external override onlyOwner {
        roundTTL = _roundTTL;

        emit UpdateRoundTTL(_roundTTL);
    }

    /// @dev Check if relay is banned.
    /// Ban is global. If the relay is banned it means it lost
    /// relay power in all rounds, past and future.
    /// @param candidate Address to check
    function isBanned(
        address candidate
    ) override public view returns(bool) {
        return blacklist[candidate];
    }

    /// @dev Check if some address is relay at specific round
    /// @param round Round id
    /// @param candidate Address to check
    function isRelay(
        uint32 round,
        address candidate
    ) override public view returns (bool) {
        return relays[round][candidate];
    }

    /// @dev Check if round is rotten
    /// @param round Round id
    function isRoundRotten(
        uint32 round
    ) override public view returns (bool) {
        return block.timestamp > rounds[round].ttl;
    }

    /**
        @notice
            Verify payload signatures.
        @dev
            Signatures should be sorted by the ascending signers.
            Error codes:
                0. Verification passed (no error)
                1. Specified round is less than `initialRound`
                2. Specified round is more than `lastRound`
                3. Not enough correct signatures. Possible reasons:
                    - Some of the signers are not relays at the specified round
                    - Some of the signers are banned
                4. Round is rotten.
                5. Everything is correct, but bridge is in "paused" state

        @param payload Bytes encoded TONEvent structure
        @param signatures Payload signatures
        @return errorCode Error code
    */
    function verifySignedTonEvent(
        bytes memory payload,
        bytes[] memory signatures
    )
        override
        public
        view
    returns (
        uint32 errorCode
    ) {
        (TONEvent memory tonEvent) = abi.decode(payload, (TONEvent));

        uint32 round = tonEvent.round;

        // Check round is not less than initial round
        if (round < initialRound) return 1;

        // Check round is not more than last initialized round
        if (round > lastRound) return 2;

        // Check there are enough correct signatures
        uint32 count = _countRelaySignatures(payload, signatures, round);
        if (count < rounds[round].requiredSignatures) return 3;

        // Check round rotten
        if (isRoundRotten(round)) return 4;

        // Check bridge has been paused
        if (paused()) return 5;

        return 0;
    }

    /**
        @notice
            Recover signer from the payload and signature
        @param payload Payload
        @param signature Signature
    */
    function recoverSignature(
        bytes memory payload,
        bytes memory signature
    ) public pure returns (address signer) {
        signer = keccak256(payload)
            .toBytesPrefixed()
            .recover(signature);
    }

    /**
        @notice Forced set of next round relays
        @dev Can be called only by `roundSubmitter`
        @param _relays Next round relays
        @param roundEnd Round end
    */
    function forceRoundRelays(
        uint160[] calldata _relays,
        uint32 roundEnd
    ) override external {
        require(msg.sender == roundSubmitter, "Bridge: sender not round submitter");

        _setRound(lastRound + 1, _relays, roundEnd);

        lastRound++;
    }

    /**
        @notice Set round submitter
        @dev Can be called only by owner
        @param _roundSubmitter New round submitter address
    */
    function setRoundSubmitter(
        address _roundSubmitter
    ) override external onlyOwner {
        roundSubmitter = _roundSubmitter;

        emit UpdateRoundSubmitter(roundSubmitter);
    }

    /**
        @dev Grant relay permission for set of addresses at specific round
        @param payload Bytes encoded TONEvent structure
        @param signatures Payload signatures
    */
    function setRoundRelays(
        bytes calldata payload,
        bytes[] calldata signatures
    ) override external notCached(payload) {
        require(
            verifySignedTonEvent(
                payload,
                signatures
            ) == 0,
            "Bridge: signatures verification failed"
        );

        (TONEvent memory tonEvent) = abi.decode(payload, (TONEvent));

        require(
            tonEvent.configurationWid == roundRelaysConfiguration.wid &&
            tonEvent.configurationAddress == roundRelaysConfiguration.addr,
            "Bridge: wrong event configuration"
        );

        (uint32 round, uint160[] memory _relays, uint32 roundEnd) = decodeRoundRelaysEventData(payload);

        require(round == lastRound + 1, "Bridge: wrong round");

        _setRound(round, _relays, roundEnd);

        lastRound++;
    }

    function decodeRoundRelaysEventData(
        bytes memory payload
    ) public pure returns(
        uint32 round,
        uint160[] memory _relays,
        uint32 roundEnd
    ) {
        (TONEvent memory tonEvent) = abi.decode(payload, (TONEvent));

        (round, _relays, roundEnd) = abi.decode(
            tonEvent.eventData,
            (uint32, uint160[], uint32)
        );
    }

    function decodeTonEvent(
        bytes memory payload
    ) external pure returns (TONEvent memory tonEvent) {
        (tonEvent) = abi.decode(payload, (TONEvent));
    }

    /**
        @notice
            Ban relays
        @param _relays List of relay addresses to ban
    */
    function banRelays(
        address[] calldata _relays
    ) override external onlyOwner {
        for (uint i=0; i<_relays.length; i++) {
            blacklist[_relays[i]] = true;

            emit BanRelay(_relays[i], true);
        }
    }

    /**
        @notice
            Unban relays
        @param _relays List of relay addresses to unban
    */
    function unbanRelays(
        address[] calldata _relays
    ) override external onlyOwner {
        for (uint i=0; i<_relays.length; i++) {
            blacklist[_relays[i]] = false;

            emit BanRelay(_relays[i], false);
        }
    }

    function _setRound(
        uint32 round,
        uint160[] memory _relays,
        uint32 roundEnd
    ) internal {
        uint32 requiredSignatures = uint32(_relays.length * 2 / 3) + 1;

        rounds[round] = Round(
            roundEnd,
            roundEnd + roundTTL,
            uint32(_relays.length),
            requiredSignatures < minimumRequiredSignatures ? minimumRequiredSignatures : requiredSignatures
        );

        emit NewRound(round, rounds[round]);

        for (uint i=0; i<_relays.length; i++) {
            address relay = address(_relays[i]);

            relays[round][relay] = true;

            emit RoundRelay(round, relay);
        }
    }

    function _countRelaySignatures(
        bytes memory payload,
        bytes[] memory signatures,
        uint32 round
    ) internal view returns (uint32) {
        address lastSigner = address(0);
        uint32 count = 0;

        for (uint i=0; i<signatures.length; i++) {
            address signer = recoverSignature(payload, signatures[i]);

            require(signer > lastSigner, "Bridge: signatures sequence wrong");
            lastSigner = signer;

            if (isRelay(round, signer) && !isBanned(signer)) {
                count++;
            }
        }

        return count;
    }
}