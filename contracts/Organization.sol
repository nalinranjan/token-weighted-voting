pragma solidity ^0.4.11;

import "./PersistentStorage.sol";
import "./PToken.sol";

// 0xd99a7e8a6c2fc89d341b98c923b91db69e44c453

/*    
    Poll
    
    "PollCount"                                 uint
    "Poll", pollId, "description"               string
    "Poll", pollId, "option", idx               string
    "Poll", pollId, "startTime"                 uint
    "Poll", pollId, "closeTime"                 uint
    "Poll", pollId, "status"                    uint
    "Poll", pollId, "optionCount"               uint
    "Poll", pollId, optionIdx, "votes"          uint
    "Poll", pollId, "leadingOption"             uint
    ----------------------------------------------------

    Vote

    "Vote", address, voteCloseTime, "prevTimestamp"         uint
    "Vote", address, voteCloseTime, "nextTimestamp"         uint
    "Vote", address, voteCloseTime, pollId, "secret"        bytes32
    "Vote", address, voteCloseTime, pollId, "prevPollId"    uint
    "Vote", address, voteCloseTime, pollId, "nextPollId"    uint

*/

contract Organization {

    address public storageAddress;
    address public ptokenAddress;

    function Organization(address _ptoken, address _storage) {
        ptokenAddress = _ptoken;
        storageAddress = _storage;
    }

    function updateStorageAddress(address _storage) {
        storageAddress = _storage;
    }

    modifier checkPollStatus(uint pollId, uint status) {
        /*
            Status      Description
                 0      Not yet created
                 1      Unopened
                 2      Opened but not resolved
                 3      Resolved
        */
        if (status != PersistentStorage(storageAddress).getUintValue(sha3("Poll", pollId, "status"))) {
            throw;
        }
        _;
    }

    function createPoll(string _description) returns (bool success) {
        var store = PersistentStorage(storageAddress);
        var pollId = store.getUintValue(sha3("PollCount")) + 1;
        store.setUintValue(sha3("PollCount"), pollId);
        store.setStringValue(sha3("Poll", pollId, "description"), _description);
        store.setUintValue(sha3("Poll", pollId, "status"), 1);
        return true;
    }

    function addOption(uint pollId, string option) checkPollStatus(pollId, 1) returns (bool success) {
        var store = PersistentStorage(storageAddress);
        var numOptions = store.getUintValue(sha3("Poll", pollId, "optionCount")) + 1;
        store.setUintValue(sha3("Poll", pollId, "optionCount"), numOptions);
        store.setStringValue(sha3("Poll", pollId, "option", numOptions), option);
        return true;
    }

    function openPoll(uint pollId, uint voteDurationInMinutes) checkPollStatus(pollId, 1) returns (bool success) {
        var store = PersistentStorage(storageAddress);

        // Verify that poll has at least 2 options
        if (store.getUintValue(sha3("Poll", pollId, "optionCount")) < 2) {
            return false;
        }

        store.setUintValue(sha3("Poll", pollId, "status"), 2);
        store.setUintValue(sha3("Poll", pollId, "startTime"), now);
        store.setUintValue(sha3("Poll", pollId, "closeTime"), now + (voteDurationInMinutes * 1 minutes));
        return true;
    }

    function resolvePoll(uint pollId) checkPollStatus(pollId, 2) returns (bool success) {
        var store = PersistentStorage(storageAddress);

        // Verify that poll is closed
        if (store.getUintValue(sha3("Poll", pollId, "closeTime")) > now) {
            return false;
        }
        
        store.setUintValue(sha3("Poll", pollId, "status"), 3);
        return true;
    }

    function submitVote(uint pollId, bytes32 voteHash, uint prevTimestamp, uint prevPollId) 
    checkPollStatus(pollId, 2)
    returns (bool success) {
        var store = PersistentStorage(storageAddress);

        // Verify that poll is open
        if (store.getUintValue(sha3("Poll", pollId, "closeTime")) < now) {
            return false;
        }

        var closeTime = store.getUintValue(sha3("Poll", pollId, "closeTime"));

        var nextTimestamp = store.getUintValue(sha3("Vote", msg.sender, prevTimestamp, "nextTimestamp"));
        if (prevTimestamp >= closeTime || (nextTimestamp != uint(0) && nextTimestamp <= closeTime)) { return false; }

        var nextPollId = store.getUintValue(sha3("Vote", msg.sender, closeTime, prevPollId, "nextPollId"));
        if (prevPollId > pollId || (nextPollId != uint(0) && nextPollId < pollId)) { return false; }

        store.setUintValue(sha3("Vote", msg.sender, closeTime, "nextTimestamp"), nextTimestamp);
        store.setUintValue(sha3("Vote", msg.sender, closeTime, "prevTimestamp"), prevTimestamp);
        store.setUintValue(sha3("Vote", msg.sender, prevTimestamp, "nextTimestamp"), closeTime);
        store.setUintValue(sha3("Vote", msg.sender, nextTimestamp, "prevTimestamp"), closeTime);

        store.setBytes32Value(sha3("Vote", msg.sender, closeTime, pollId, "secret"), voteHash);
        store.setUintValue(sha3("Vote", msg.sender, closeTime, pollId, "nextPollId"), nextPollId);
        store.setUintValue(sha3("Vote", msg.sender, closeTime, pollId, "prevPollId"), prevPollId);
        store.setUintValue(sha3("Vote", msg.sender, closeTime, prevPollId, "nextPollId"), pollId);
        store.setUintValue(sha3("Vote", msg.sender, closeTime, nextPollId, "prevPollId"), pollId);

        return true;
    }

    function revealVote(uint pollId, uint optionIdx, bytes32 salt) 
    checkPollStatus(pollId, 2) 
    returns (bool success) {
        var store = PersistentStorage(storageAddress);

        // Verify that poll is closed
        if (store.getUintValue(sha3("Poll", pollId, "closeTime")) > now) {
            return false;
        }

        var closeTime = store.getUintValue(sha3("Poll", pollId, "closeTime"));

        if (sha3(pollId, optionIdx, salt) != store.getBytes32Value(sha3("Vote", msg.sender, closeTime, pollId, "secret"))) {
            throw;
        }

        // TODO: Get Balance
        var votes = store.getUintValue(sha3("Poll", pollId, optionIdx, "votes")) + 1;
        var leadingOption = store.getUintValue(sha3("Poll", pollId, "leadingOption"));
        if (votes > store.getUintValue(sha3("Poll", pollId, leadingOption, "votes"))) {
            store.setUintValue(sha3("Poll", pollId, "leadingOption"), votes);
        }
        store.setUintValue(sha3("Poll", pollId, optionIdx, "votes"), votes);

        // TODO: Release Funds
        return true;
    }

    function getResult(uint pollId) constant checkPollStatus(pollId, 3) returns (uint optionIdx, uint votes) {
        var store = PersistentStorage(storageAddress);
        optionIdx = store.getUintValue(sha3("Poll", pollId, "leadingOption"));
        votes = store.getUintValue(sha3("Poll", pollId, optionIdx, "votes"));
    }
}