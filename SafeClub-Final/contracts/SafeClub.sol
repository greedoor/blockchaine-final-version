// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Importations mises à jour pour OpenZeppelin v5
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title SafeClub
 * @dev Trésorerie sécurisée avec système de gouvernance pour club étudiant.
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

    // Gestion des propositions
    mapping(uint256 => Proposal) public propositions;
    uint256 public nextProposalId;
    
    // Gestion des membres
    address[] public members;
    mapping(address => bool) public isMember;

    // Événements
    event MemberAdded(address member);
    event MemberRemoved(address member);
    event ProposalCreated(uint256 proposalId, address recipient, uint256 amount, uint256 deadline);
    event Voted(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId, address recipient, uint256 amount);

    /**
     * @dev Constructeur corrigé pour OpenZeppelin v5
     * @param _quorum Nombre minimum de votes "Pour" requis pour l'exécution
     */
    constructor(uint256 _quorum) Ownable(msg.sender) {
        quorum = _quorum;
        
        // L'owner est automatiquement le premier membre
        isMember[msg.sender] = true;
        members.push(msg.sender);
        emit MemberAdded(msg.sender);
    }

    // Permet au contrat de recevoir de l'ETH (Le Vault)
    receive() external payable {}

    // --- Gestion des membres ---
    function addMember(address _member) external onlyOwner {
        require(!isMember[_member], "Deja membre");
        isMember[_member] = true;
        members.push(_member);
        emit MemberAdded(_member);
    }

    function removeMember(address _member) external onlyOwner {
        require(isMember[_member], "Pas membre");
        isMember[_member] = false;
        
        for (uint i = 0; i < members.length; i++) {
            if (members[i] == _member) {
                members[i] = members[members.length - 1];
                members.pop();
                break;
            }
        }
        emit MemberRemoved(_member);
    }

    // --- Gestion des propositions ---
    function createProposal(
        address _recipient,
        uint256 _amount,
        string calldata _description,
        uint256 _durationSeconds
    ) external {
        require(isMember[msg.sender], "Seul un membre peut creer");
        require(_amount <= address(this).balance, "Solde insuffisant dans le club");

        uint256 proposalId = nextProposalId++;
        Proposal storage p = propositions[proposalId];
        p.recipient = _recipient;
        p.amount = _amount;
        p.description = _description;
        p.deadline = block.timestamp + _durationSeconds;

        emit ProposalCreated(proposalId, _recipient, _amount, p.deadline);
    }

    // --- Système de vote ---
    function vote(uint256 _proposalId, bool _support) external {
        Proposal storage p = propositions[_proposalId];
        require(isMember[msg.sender], "Seul un membre peut voter");
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

    // --- Exécution sécurisée ---
    function executeProposal(uint256 _proposalId) external nonReentrant {
        Proposal storage p = propositions[_proposalId];
        require(block.timestamp > p.deadline, "Vote encore en cours");
        require(!p.executed, "Deja executee");
        require(p.yesVotes >= quorum, "Quorum non atteint");
        require(p.yesVotes > p.noVotes, "Majorite non atteinte");

        p.executed = true;
        
        // Transfert sécurisé via .call
        (bool sent, ) = p.recipient.call{value: p.amount}("");
        require(sent, "Transfert echoue");

        emit ProposalExecuted(_proposalId, p.recipient, p.amount);
    }

    function getBalance() external view returns(uint256) {
        return address(this).balance;
    }
}