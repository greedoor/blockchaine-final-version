const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();

    console.log("----------------------------------------------------");
    console.log("Préparation du déploiement du contrat SafeClub...");
    console.log("Déploiement effectué avec le compte :", deployer.address);
    console.log("Solde du compte :", (await hre.ethers.provider.getBalance(deployer.address)).toString());
    console.log("----------------------------------------------------");

    // 1. Récupérer l'usine de contrat
    const SafeClub = await hre.ethers.getContractFactory("SafeClub");

    // 2. Définir le Quorum (ex:5 membres doivent voter pour valider une dépense)
    const QUORUM_INITIAL = 5;

    console.log(`Déploiement en cours avec un quorum de : ${QUORUM_INITIAL}...`);

    // 3. Lancer le déploiement avec le paramètre du constructeur
    const safeClub = await SafeClub.deploy(QUORUM_INITIAL);

    // 4. Attendre que le contrat soit miné sur la blockchain
    await safeClub.waitForDeployment();

    const contractAddress = await safeClub.getAddress();

    console.log("----------------------------------------------------");
    console.log("SUCCÈS !");
    console.log(`Le contrat SafeClub a été déployé à : ${contractAddress}`);
    console.log("----------------------------------------------------");
}

// Gestion propre des erreurs pour le terminal
main().catch((error) => {
    console.error("Erreur lors du déploiement :");
    console.error(error);
    process.exitCode = 1;
});
