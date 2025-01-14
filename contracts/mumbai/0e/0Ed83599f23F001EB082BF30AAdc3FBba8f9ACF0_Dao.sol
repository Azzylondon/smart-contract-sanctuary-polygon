// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IdaoContract{
    function balanceOf(address, uint) external view returns (uint);
}



contract Dao {

    //DAO's owner public address
    address public owner;
    //Proposals Id
    uint256 nextProposal;
    //Array of which tokens are allowed to vote 
    uint256[] public validTokens;
    //Pointer to NFT Dao Contract
    IdaoContract daoContract;


    constructor(){
        owner = msg.sender;
        nextProposal = 1;
        daoContract = IdaoContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        validTokens = [28245160071610983618485065481627837093612348058502790405691860022471958724708];
    }    


    struct proposal {
        uint256 id;
        bool exists;
        string description;
        uint deadline;
        uint256 votesUp;
        uint256 votesDown;
        address[] canVote;
        uint256 maxVotes;
        mapping(address => bool) voteStatus;
        bool countConduced;
        bool passed;
    }

    // Store all proposals created
    mapping(uint256 => proposal) public Proposals;

    // Event to emit new Proposal creation
    event proposalCreated (
        uint256 id,
        string description,
        uint256 maxVotes,
        address proposer
    );

    // Event to emit new vote
    event newVote (
        uint256 votesUp,
        uint256 votesDown,
        address voter,
        uint256 proposal,
        bool votedFor
    );

    event proposalCount(
        uint256 id,
        bool passed
    );

    
    //Private Functions

    function checkProposalEligibility(address _proposalList) private view returns(bool){
        for(uint i = 0; i < validTokens.length; i++){
            if(daoContract.balanceOf(_proposalList, validTokens[i]) >= 1){
                return true;
            }
        }

        return false;
    }

    function checkVoteEligibility(uint256 _id, address _voter)private view returns(bool){
        for(uint i = 0; i < Proposals[_id].canVote.length; i++){
            if(Proposals[_id].canVote[i] == _voter){
                return true;
            }
        }
        return false;
    }

    function createProposal(string memory _description, address[] memory _canVote) public {
        require(checkProposalEligibility(msg.sender), "Only NFT Holders can submit proposal");

        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + 100;
        newProposal.canVote = _canVote;
        newProposal.maxVotes = _canVote.length;

        emit proposalCreated(nextProposal, _description, _canVote.length, msg.sender);
        nextProposal++;
    }

    function voteOnProposal(uint _id, bool _vote) public {
        require(Proposals[_id].exists, "This proposal does not exist");
        require(checkVoteEligibility(_id, msg.sender), "You can not vote on this proposal");
        require(!Proposals[_id].voteStatus[msg.sender], "You have already voted on this proposal");
        require(block.number <= Proposals[_id].deadline, "The deadline has passed for this proposal");

        proposal storage p = Proposals[_id];

        if(_vote){
            p.votesUp++;
        }else{
            p.votesDown++;
        }

        p.voteStatus[msg.sender] = true;

         emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);
        
    }

    function countVotes(uint256 _id) public{
        require(msg.sender == owner, "Only Owner can count votes");
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(block.number > Proposals[_id].deadline, "Voting has not concluded");
        require(!Proposals[_id].countConduced, "Count already conduced");

        proposal storage p = Proposals[_id];

        if (Proposals[_id].votesDown < Proposals[_id].votesUp){
            p.passed = true;
        }else{
            p.passed = false;
        }

        p.countConduced = true;

        emit proposalCount(_id, p.passed);
    }


    function addTokenId(uint256 _tokenId)public {
        require(msg.sender == owner, "Only Owner can add Tokens");
        validTokens.push(_tokenId);
    }



}