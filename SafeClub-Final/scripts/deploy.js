// On importe explicitement ethers depuis hardhat
import pkg from 'hardhat';
const { ethers } = pkg;

async function main() {
    // Maintenant ethers est bien défini
    const [deployer] = await ethers.getSigners();

    console.log("----------------------------------------------------");
    console.log("Préparation du déploiement...");
    console.log("Compte :", deployer.address);

    // Récupérer le solde
    const balance = await ethers.provider.getBalance(deployer.address);
    console.log("Solde :", ethers.formatEther(balance), "ETH");
    console.log("----------------------------------------------------");

    const SafeClub = await ethers.getContractFactory("SafeClub");

    const QUORUM_INITIAL = 5;
    console.log(`Déploiement avec un quorum de : ${QUORUM_INITIAL}...`);

    const safeClub = await SafeClub.deploy(QUORUM_INITIAL);
    await safeClub.waitForDeployment();

    const contractAddress = await safeClub.getAddress();

    console.log("----------------------------------------------------");
    console.log("SUCCÈS !");
    console.log(`Contrat SafeClub déployé à : ${contractAddress}`);
    console.log("----------------------------------------------------");
}

main().catch((error) => {
    console.error("Erreur lors du déploiement :");
    console.error(error);
    process.exitCode = 1;
});