// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "lib/forge-std/src/Test.sol";
import {Voting} from "src/Voting.sol";
import {DeployVoting} from "script/DeployVoting.s.sol";

contract VotingTest is Test {

    Voting voting;
    address public PLAYER = makeAddr("player");
    uint256 public REGISTERATION_WINDOW_TIME = 10 minutes;

    function setUp() external {
        DeployVoting deploy = new DeployVoting();
        voting = deploy.run();
    }

   function testRoomCreationWithValidArgs() public {
        uint256 candidateRegisterationWindow = REGISTERATION_WINDOW_TIME; 
        uint256 votingStartTime = block.timestamp + candidateRegisterationWindow + 1;
        uint256 votingEndTime = votingStartTime + 1 hours; 
    
        voting.createRoom(candidateRegisterationWindow, votingStartTime, votingEndTime);
    }

    function testRoomCreationFailsIfVotingStartsBeforeRegistrationEnds() public {
        uint256 candidateRegisterationWindow = REGISTERATION_WINDOW_TIME; 
        uint256 votingStartTime = block.timestamp + candidateRegisterationWindow; 
        uint256 votingEndTime = votingStartTime + 1 hours; 
    
        vm.expectRevert(Voting.Voting__CantStartVotingBeforeRegistationWindowEnd.selector);
        voting.createRoom(candidateRegisterationWindow, votingStartTime, votingEndTime);
    }

    function testRevertOnVotingStartTimeIsLessThanVotingEndTime() public{
        uint256 candidateRegisterationWindow = REGISTERATION_WINDOW_TIME; 
        uint256 votingStartTime = block.timestamp + candidateRegisterationWindow + 1; 
        uint256 votingEndTime = votingStartTime; 
    
        vm.expectRevert(Voting.Voting__VotingEndTimeCanNotBeLessThanStartTime.selector);
        voting.createRoom(candidateRegisterationWindow, votingStartTime, votingEndTime);
    }

    modifier createRoom(){
        uint256 candidateRegisterationWindow = REGISTERATION_WINDOW_TIME; 
        uint256 votingStartTime = block.timestamp + candidateRegisterationWindow + 1;
        uint256 votingEndTime = votingStartTime + 1 hours; 
        voting.createRoom(candidateRegisterationWindow, votingStartTime, votingEndTime);
        _;
    }

    function testRegisterCandidateWithValidArgs() public createRoom {
        voting.registerCandidate(1);
    }

    function testRegisterCandidateButInvalidRoomId() public createRoom{
        vm.expectRevert(Voting.Voting__roomIdDoesNotExist.selector);
        voting.registerCandidate(2);
    }

    function testRegisterCandidateButDoubleRegisteration() public createRoom{
        vm.prank(PLAYER);
        voting.registerCandidate(1);

        vm.prank(PLAYER);
        vm.expectRevert(Voting.Voting__CandidateAlreadyRegistered.selector);
        voting.registerCandidate(1);
    }

    function testRevertingIfCandidateRegisterAfterEndingTime() public createRoom{
        vm.warp(block.timestamp + REGISTERATION_WINDOW_TIME + 1);
        vm.roll(block.number + 1);

        vm.prank(PLAYER);
        vm.expectRevert(Voting.Voting__candidateRegisterationTimeOut.selector);
        voting.registerCandidate(1);
    }

    function testVoteForCandidateWithValidArgs() public createRoom{
        vm.prank(PLAYER);
        voting.registerCandidate(1);
        vm.warp(block.timestamp + REGISTERATION_WINDOW_TIME + 1);
        vm.roll(block.number + 1);
        voting.voteForCandidate(1, PLAYER);
    }

    function testVoteForCandidateRevertsAsVotingNotStarted() public createRoom{
        vm.prank(PLAYER);
        voting.registerCandidate(1);

        vm.expectRevert(Voting.Voting__votingHasNotStarted.selector);
        voting.voteForCandidate(1, PLAYER);
    }

    function testVotingHasEnded() public createRoom{
        vm.prank(PLAYER);
        voting.registerCandidate(1);

        vm.warp(block.timestamp + REGISTERATION_WINDOW_TIME + 1 hours + 2);
        vm.roll(block.number + 1);

        vm.expectRevert(Voting.Voting__votingHasEnded.selector);
        voting.voteForCandidate(1, PLAYER);
    }

    function testVoterCanOnlyVoteOnce() public createRoom{
        vm.prank(PLAYER);
        voting.registerCandidate(1);

        vm.warp(block.timestamp + REGISTERATION_WINDOW_TIME + 1);
        vm.roll(block.number + 1);

        voting.voteForCandidate(1, PLAYER);
        vm.expectRevert(Voting.Voting__CanOnlyVoteOnce.selector);
        voting.voteForCandidate(1, PLAYER);
    }

    function testMax() public{
        assert(voting.max(2,3)==3);
    }

    function testdeclareResultWithValidArgs() public createRoom{
        vm.prank(PLAYER);
        voting.registerCandidate(1);

        vm.warp(block.timestamp + REGISTERATION_WINDOW_TIME + 1);
        vm.roll(block.number + 1);

        voting.voteForCandidate(1, PLAYER);

        vm.warp(block.timestamp + 1 hours + 1);
        vm.roll(block.number + 1);

        voting.declareResult(1);
    }

    function testCantDeclareResultBeforeEndTime() public createRoom{
        vm.prank(PLAYER);
        voting.registerCandidate(1);

        vm.warp(block.timestamp + REGISTERATION_WINDOW_TIME + 1);
        vm.roll(block.number + 1);

        voting.voteForCandidate(1, PLAYER);
        vm.expectRevert(Voting.Voting__votingHasNotEnded.selector);
        voting.declareResult(1);
    }

    function testResultDeclarationButNoneRegistered() public createRoom{
        vm.warp(block.timestamp + REGISTERATION_WINDOW_TIME + 1 hours + 2);
        vm.roll(block.number + 1);

        vm.expectRevert(Voting.Voting__NooneRegisteredAsCandidate.selector);
        voting.declareResult(1);
    }

}
