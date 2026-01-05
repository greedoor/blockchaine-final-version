async function main() {
    const [owner, member1, member2] = await ethers.getSigners();

    const safeClubAddress = "PUT_YOUR_CONTRACT_ADDRESS_HERE";
    const SafeClub = await ethers.getContractFactory("SafeClub");
    const safeClub = await SafeClub.attach(safeClubAddress);

    // Fund the contract
    await owner.sendTransaction({
        to: safeClub.address,
        value: ethers.utils.parseEther("10")
    });
    console.log("Contract funded, balance:", (await safeClub.getBalance()).toString());

    // Add members
    await safeClub.addMember(member1.address);
    await safeClub.addMember(member2.address);

    // Create a proposal
    const tx = await safeClub.createProposal(member1.address, ethers.utils.parseEther("5"), "Payer membre 1", 60);
    await tx.wait();
    console.log("Proposal created");

    const proposal = await safeClub.getProposal(0);
    console.log("Proposal details:", proposal);

    // Vote
    await safeClub.connect(member1).vote(0, true);
    await safeClub.connect(member2).vote(0, true);
    console.log("Votes cast");

    // Wait for 61 seconds for deadline
    console.log("Waiting for deadline...");
    await new Promise(r => setTimeout(r, 61000));

    // Execute proposal
    await safeClub.executeProposal(0);
    console.log("Proposal executed, new balance:", (await safeClub.getBalance()).toString());
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
