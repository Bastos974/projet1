// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.20;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Voting is Ownable {
    uint winningProposalId;

    mapping(address => bool) whitelist;
    mapping(address => Voter) votant;

    modifier iswhitelist() {
        require(whitelist[msg.sender] == true, "vous n ete pas authorise");
        _;
    }

    modifier isEnregistre() {
        require(
            votant[msg.sender].isRegistered == true,
            "vous n ete pas authorise"
        );
        _;
    }

    WorkflowStatus public currentStatus = WorkflowStatus.RegisteringVoters;

    enum WorkflowStatus {
        RegisteringVoters, // 0
        ProposalsRegistrationStarted, // 1
        ProposalsRegistrationEnded, // 2
        VotingSessionStarted, // 3
        VotingSessionEnded, // 4
        VotesTallied // 5
    }

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    Proposal[] public arrayProposals;

    // LES event

    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );
    event ProposalRegistered(uint proposalId);
    event Voted(address voter, uint proposalId);

    ////

    /* Fonction de l'administrateur*/

    function ChangerdeStatus(WorkflowStatus _newStatus) external onlyOwner {
        require(
            uint(_newStatus) > uint(currentStatus),
            " Vous avez deja realise cette etape"
        );

        emit WorkflowStatusChange(currentStatus, _newStatus);

        currentStatus = _newStatus;
    }

    function whitelistAddress(address _address) external onlyOwner {
        require(!whitelist[_address], " Vous avez deja realise cette etape");
        whitelist[_address] = true;
    }

    /* Fonction pour s'enregistrer test ok  */
    function RegisteringVoter() external iswhitelist {
        require(
            currentStatus == WorkflowStatus.RegisteringVoters,
            "Fonctionalite impossible a cette etape du vote "
        );
        require(
            votant[msg.sender].isRegistered == false,
            "vous vous etes deja inscrit pour le vote "
        );

        votant[msg.sender].isRegistered = true;

        emit VoterRegistered(msg.sender);
    }

    function getRegisteringVoter(address _address) public view returns (bool) {
        return votant[_address].isRegistered;
    }

    /* fin de fonction pour s'enregistrer*/

    /* 
    L'administrateur passe en statu  ProposalsRegistrationStarted 1
    */

    //Fonction pour les propistions

    function setProposal(string memory _proposal) external isEnregistre {
        require(
            currentStatus == WorkflowStatus.ProposalsRegistrationStarted,
            "Fonctionalite impossible a cette etape du vote "
        );
        arrayProposals.push(Proposal(_proposal, 0));

        emit ProposalRegistered(arrayProposals.length - 1);
    }

    function getPropoasl(uint _index) external view returns (string memory) {
        require(
            _index < arrayProposals.length,
            "Aucune Propositon pour cette id"
        );
        return arrayProposals[_index].description;
    }

    // L'administrateur passe en statu  ProposalsRegistrationEnded 2

    // a few moment later...  L'administrateur passe en statu  VotingSessionStarted 3

    //Fonction de vote apres avoir pris connaissance des propsitions OK

    function voted(uint _index) external isEnregistre {
        require(
            _index < arrayProposals.length,
            "Aucune Propositon pour cette id"
        );
        require(
            currentStatus == WorkflowStatus.VotingSessionStarted,
            "Fonctionalite impossible a cette etape du vote "
        );
        require(
            votant[msg.sender].hasVoted == false,
            "Vous avez deja vot petit mailin"
        );

        arrayProposals[_index].voteCount += 1;

        votant[msg.sender].hasVoted = true;

        votant[msg.sender].votedProposalId = _index;

        emit Voted(msg.sender, _index);
    }

    //L'administrateur passe en statu VotingSessionEnded,   4

    function countTheVote() external onlyOwner returns (uint) {
        require(
            currentStatus == WorkflowStatus.VotingSessionEnded,
            "Fonctionalite impossible a cette etape du vote "
        );

        uint maxVote;

        for (uint i = 0; i < arrayProposals.length; i++) {
            if (arrayProposals[i].voteCount > maxVote) {
                maxVote = arrayProposals[i].voteCount;
                winningProposalId = i;
            }
        }

        return winningProposalId;
    }

    //L'administrateur passe en statu VotesTallied,   5

    function getWinner() external view returns (string memory) {
        require(
            currentStatus == WorkflowStatus.VotesTallied,
            "Fonctionalite impossible a cette etape du vote "
        );
        return arrayProposals[winningProposalId].description;
    }

    // la propostion retenue est celle qui a le plus de votes

    // En cas d'égalité, pour départager les propositions qui ont eu le plus de votes on va dire que c'est la proposition
    // qui a été déclarée en premier qui est retenue (conformément au règlement).
}
