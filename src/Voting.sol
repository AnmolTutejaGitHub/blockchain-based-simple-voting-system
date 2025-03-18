// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
import {AutomationCompatibleInterface} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

/**
 * @title Simple Voting System Smart Contract
 * @author Anmol Tuteja
 * @notice This contract allows the creation of a basic voting system.
 * @dev --ignore
 */

contract Voting is AutomationCompatibleInterface {

    error Voting__roomIdDoesNotExist();
    error Voting__candidateRegisterationTimeOut();
    error Voting__votingHasNotStarted();
    error Voting__votingHasEnded();
    error Voting__CanOnlyVoteOnce();
    error Voting__votingHasNotEnded();
    error Voting__CandidateAlreadyRegistered();
    error Voting__CantStartVotingBeforeRegistationWindowEnd();
    error Voting__VotingEndTimeCanNotBeLessThanStartTime();
    error Voting__NooneRegisteredAsCandidate();


     event WinnerPicked(uint256 indexed roomId, address[] indexed winner);

    uint256 s_roomCount = 0;
    mapping(uint256 => Room) public s_rooms;

    struct Room {
        uint256 id;
        address creator;
        address[] voters;
        address[] candidates;
        address[] winners;
        uint256 candidateRegisterationEndTime;
        uint256 votingStartTime;
        uint256 votingEndTime;

        mapping(address => bool) hasVoted;
        mapping(address => uint256) voteCount;
    }

    struct Voter {
        address voter;
    }

    struct Candidate {
        address candidate;
        uint256[] roomsParticipated;
    }

    function createRoom(uint256 candidateRegisterationWindow,uint256 votingStartTime,uint256 votingEndTime) public returns (uint256) {
    
        if(votingStartTime < block.timestamp + candidateRegisterationWindow + 1){
            revert Voting__CantStartVotingBeforeRegistationWindowEnd();
        }

        if(votingEndTime <= votingStartTime){
            revert Voting__VotingEndTimeCanNotBeLessThanStartTime();
        }


        s_roomCount++;
        uint256 newRoomId = s_roomCount;

        Room storage newRoom = s_rooms[newRoomId];
        newRoom.id = newRoomId;
        newRoom.creator = msg.sender;
        newRoom.candidateRegisterationEndTime = block.timestamp + candidateRegisterationWindow;
        newRoom.votingStartTime = votingStartTime;
        newRoom.votingEndTime = votingEndTime;

        return s_roomCount;
    }

    function registerCandidate(uint256 roomId) public {
        if(s_roomCount<roomId){
            revert Voting__roomIdDoesNotExist();
        }
    
        if(block.timestamp > s_rooms[roomId].candidateRegisterationEndTime){
            revert  Voting__candidateRegisterationTimeOut();
        }

        for (uint256 i = 0; i < s_rooms[roomId].candidates.length; i++) {
            if (s_rooms[roomId].candidates[i] == msg.sender){
                revert Voting__CandidateAlreadyRegistered();
            }
        }

        Room storage room = s_rooms[roomId];
        room.candidates.push(msg.sender);
        room.voteCount[msg.sender] = 0;
    }

    function voteForCandidate(uint256 roomId,address candidate) public {
       if(s_roomCount<roomId){
            revert Voting__roomIdDoesNotExist();
        }
        if(block.timestamp < s_rooms[roomId].votingStartTime){
            revert Voting__votingHasNotStarted();
        }
        if(block.timestamp > s_rooms[roomId].votingEndTime){
            revert Voting__votingHasEnded();
        }
        if(s_rooms[roomId].hasVoted[msg.sender]){
            revert Voting__CanOnlyVoteOnce();
        }

        Room storage room = s_rooms[roomId];
        room.voteCount[candidate]+=1;
        room.hasVoted[msg.sender] = true;
    }


    function max(uint256 a, uint256 b) public pure returns (uint256) {
        return a > b ? a : b;
    }

    function declareResult(uint256 roomId) public {
        if(s_roomCount<roomId){
            revert Voting__roomIdDoesNotExist();
        }

        if(block.timestamp <= s_rooms[roomId].votingEndTime){
            revert Voting__votingHasNotEnded();
        }

        if(s_rooms[roomId].candidates.length == 0){
            revert Voting__NooneRegisteredAsCandidate();
        }

        uint256 length = s_rooms[roomId].candidates.length;
        uint256 maxVotes;
        Room storage room = s_rooms[roomId];

        for(uint256 i=0;i<length;i++){
            maxVotes = max(maxVotes,s_rooms[roomId].voteCount[room.candidates[i]]);
        }

        for(uint256 i=0;i<length;i++){
            if(s_rooms[roomId].voteCount[room.candidates[i]] == maxVotes) room.winners.push(room.candidates[i]);
        }
        emit WinnerPicked(roomId,room.winners);
    }


    function checkUpkeep( bytes calldata /* checkData */) public view override returns (bool upkeepNeeded, bytes memory performData) {
    upkeepNeeded = false;
    uint256 roomIdToDeclare;

    for (uint256 i = 1 ;i< = s_roomCount; i++) {
        if (block.timestamp > s_rooms[i].votingEndTime && s_rooms[i].winners.length == 0) {
            upkeepNeeded = true;
            roomIdToDeclare = i;
            break;
        }
    }
    performData = abi.encode(roomIdToDeclare);
}

    function performUpkeep(bytes calldata performData) external override {
        uint256 roomId = abi.decode(performData, (uint256));

        if (s_roomCount >= roomId && s_rooms[roomId].winners.length == 0) {
        declareResult(roomId);
        }
    }
}
