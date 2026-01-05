import pkg from "hardhat";
const { ethers } = pkg;

async function main() {
    // 1. Charger le contrat (Utilisez l'adresse générée lors de votre deploy)
    const CONTRACT_ADDRESS = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
    const club = await ethers.getContractAt("SafeClub", CONTRACT_ADDRESS);

    console.log("Connexion au contrat réussie...");

    // 2. Tester une fonction (Bouton bleu - Lecture)
    const quorum = await club.quorum();
    console.log("Valeur du Quorum :", quorum.toString());

    // 3. Envoyer une transaction (Bouton orange - Écriture)
    console.log("Ajout d'un membre en cours...");
    const tx = await club.addMember("0x70997970C51812dc3A010C7d01b50e0d17dc79C8");

    // Attendre que la transaction soit minée sur la blockchain
    await tx.wait();
    console.log("Membre ajouté avec succès !");
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});