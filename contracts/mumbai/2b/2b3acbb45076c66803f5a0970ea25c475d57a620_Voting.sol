/**
 *Submitted for verification at polygonscan.com on 2022-11-13
*/

// File: base_contract.sol

pragma solidity ^0.6.4;
// We have to specify what version of compiler this code will compile with

contract Voting {
  event VoteStarted(uint256 voteFinishTime, bytes32[] candidateList);
  event Voted(bytes32 candidate);

  /* mapping field below is equivalent to an associative array or hash.
  The key of the mapping is candidate name stored as type bytes32 and value is
  an unsigned integer to store the vote count
  */

  mapping (bytes32 => uint256) public votesReceived;
  
  /* Solidity doesn't let you pass in an array of strings in the constructor (yet).
  We will use an array of bytes32 instead to store the list of candidates
  */
  
  bytes32[] public candidateList;
  uint256 public voteFinishTime;

  /* This is the constructor which will be called once when you
  deploy the contract to the blockchain. When we deploy the contract,
  we will pass an array of candidates who will be contesting in the election
  */
  constructor(bytes32[] memory candidateNames, uint256 finishTime) public {
    candidateList = candidateNames;
    voteFinishTime = finishTime;

    emit VoteStarted(finishTime, candidateList);
  }

  // This function returns the total votes a candidate has received so far
  function totalVotesFor(bytes32 candidate) view public returns (uint256) {
    require(validCandidate(candidate));
    return votesReceived[candidate];
  }

  // This function increments the vote count for the specified candidate. This
  // is equivalent to casting a vote
  function voteForCandidate(bytes32 candidate) public {
    require(validCandidate(candidate));
    require(block.timestamp < voteFinishTime, "Error: Vote is over.");
    votesReceived[candidate] += 1;

    emit Voted(candidate);
  }

  function validCandidate(bytes32 candidate) view public returns (bool) {
    for(uint i = 0; i < candidateList.length; i++) {
      if (candidateList[i] == candidate) {
        return true;
      }
    }
    return false;
  }
}