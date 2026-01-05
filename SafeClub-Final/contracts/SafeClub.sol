// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title SafeClub
 * @dev Trésorerie sécurisée avec gouvernance pour club étudiant
 */
contract SafeClub is Ownable, ReentrancyGuard {

    uint256 public quorum;

    struct Proposal {
        address recipient;
        uint256 amount;
        string description;
        uint256 deadline;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        mapping(address => bool) voted;
    }

    mapping(uint256 => Proposal) private propositions;
    uint256 public nextProposalId;

    address[] public members;
    mapping(address => bool) public isMember;

    event MemberAdded(address member);
    event MemberRemoved(address member);
    event ProposalCreated(uint256 proposalId, address recipient, uint256 amount, uint256 deadline);
    event Voted(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId, address recipient, uint256 amount);

    modifier onlyMember() {
        require(isMember[msg.sender], "Seul un membre");
        _;
    }

    constructor(uint256 _quorum) Ownable(msg.sender) {
        quorum = _quorum;

        isMember[msg.sender] = true;
        members.push(msg.sender);
        emit MemberAdded(msg.sender);
    }

    receive() external payable {}

    // ------------------ Membres ------------------

    function addMember(address _member) external onlyOwner {
        require(_member != address(0), "Adresse invalide");
        require(!isMember[_member], "Deja membre");

        isMember[_member] = true;
        members.push(_member);

        emit MemberAdded(_member);
    }

    function removeMember(address _member) external onlyOwner {
        require(isMember[_member], "Pas membre");

        isMember[_member] = false;

        for (uint256 i = 0; i < members.length; i++) {
            if (members[i] == _member) {
                members[i] = members[members.length - 1];
                members.pop();
                break;
            }
        }

        emit MemberRemoved(_member);
    }

    // ------------------ Propositions ------------------

    function createProposal(
        address _recipient,
        uint256 _amount,
        string calldata _description,
        uint256 _durationSeconds
    ) external onlyMember {

        require(_recipient != address(0), "Destinataire invalide");
        require(_amount > 0, "Montant invalide");
        require(_amount <= address(this).balance, "Solde insuffisant");

        uint256 proposalId = nextProposalId++;
        Proposal storage p = propositions[proposalId];

        p.recipient = _recipient;
        p.amount = _amount;
        p.description = _description;
        p.deadline = block.timestamp + _durationSeconds;

        emit ProposalCreated(proposalId, _recipient, _amount, p.deadline);
    }

    function getProposal(uint256 _proposalId)
        external
        view
        returns (
            address recipient,
            uint256 amount,
            string memory description,
            uint256 deadline,
            uint256 yesVotes,
            uint256 noVotes,
            bool executed
        )
    {
        require(_proposalId < nextProposalId, "Proposition inexistante");

        Proposal storage p = propositions[_proposalId];

        return (
            p.recipient,
            p.amount,
            p.description,
            p.deadline,
            p.yesVotes,
            p.noVotes,
            p.executed
        );
    }

    // ------------------ Vote ------------------

    function vote(uint256 _proposalId, bool _support)
        external
        onlyMember
    {
        require(_proposalId < nextProposalId, "Proposition inexistante");

        Proposal storage p = propositions[_proposalId];

        require(block.timestamp <= p.deadline, "Vote termine");
        require(!p.voted[msg.sender], "Deja vote");

        p.voted[msg.sender] = true;

        if (_support) {
            p.yesVotes += 1;
        } else {
            p.noVotes += 1;
        }

        emit Voted(_proposalId, msg.sender, _support);
    }

    // ------------------ Exécution ------------------

    function executeProposal(uint256 _proposalId)
        external
        nonReentrant
    {
        require(_proposalId < nextProposalId, "Proposition inexistante");

        Proposal storage p = propositions[_proposalId];

        require(block.timestamp > p.deadline, "Vote encore en cours");
        require(!p.executed, "Deja executee");
        require(p.yesVotes >= quorum, "Quorum non atteint");
        require(p.yesVotes > p.noVotes, "Majorite non atteinte");
        require(address(this).balance >= p.amount, "Solde insuffisant");

        p.executed = true;

        (bool sent, ) = p.recipient.call{value: p.amount}("");
        require(sent, "Transfert echoue");

        emit ProposalExecuted(_proposalId, p.recipient, p.amount);
    }

    // ------------------ Utils ------------------

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
