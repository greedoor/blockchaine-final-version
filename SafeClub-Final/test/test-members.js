async function main() {
    const [owner, member1, member2] = await ethers.getSigners();

    const safeClubAddress = "PUT_YOUR_CONTRACT_ADDRESS_HERE";
    const SafeClub = await ethers.getContractFactory("SafeClub");
    const safeClub = await SafeClub.attach(safeClubAddress);

    console.log("Owner is adding a member...");
    await safeClub.addMember(member1.address);
    console.log("Members:", await safeClub.members());

    console.log("Owner removing a member...");
    await safeClub.removeMember(member1.address);
    console.log("Members:", await safeClub.members());
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
