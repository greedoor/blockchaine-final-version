import { expect } from "chai";
import pkg from "hardhat";
const { ethers } = pkg;

describe("SafeClub", function () {
    async function deploySafeClubFixture() {
        const quorum = 5;
        const [owner, otherAccount] = await ethers.getSigners();
        const SafeClub = await ethers.getContractFactory("SafeClub");
        const safeClub = await SafeClub.deploy(quorum);
        return { safeClub, quorum, owner, otherAccount };
    }

    it("Devrait initialiser le bon quorum", async function () {
        const { safeClub, quorum } = await deploySafeClubFixture();
        expect(await safeClub.quorum()).to.equal(quorum);
    });

    it("Devrait ajouter l'owner comme premier membre", async function () {
        const { safeClub, owner } = await deploySafeClubFixture();
        expect(await safeClub.isMember(owner.address)).to.equal(true);
    });
});