pragma solidity 0.4.24;

import "@1hive/apps-dandelion-voting/contracts/DandelionVoting.sol";


// NOTE: used because truffle does not support function overloading
contract VotingMock is DandelionVoting {
    function newVoteExt(
        bytes _executionScript,
        string _metadata,
        bool _castVote
    ) external returns (uint256) {
        return _newVote(_executionScript, _metadata, _castVote);
    }
}