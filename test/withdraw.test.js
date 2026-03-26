const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("User Withdrawal Tests", function () {
  let CrowdTank;
  let contract;
  let owner, user1;

  beforeEach(async function () {
    [owner, user1] = await ethers.getSigners();
    CrowdTank = await ethers.getContractFactory("CrowdTank");
    contract = await CrowdTank.deploy();
    await contract.connect(owner).addCreator(owner.address);
  });

  it("User can withdraw before deadline", async function () {
    // CORRECT parameter order matching the contract
    await contract.createProject(
      "Test",                          // _name (string)
      "Desc",                          // _description (string)
      ethers.utils.parseEther("10"),   // _fundingGoal (uint)
      3600,                            // _durationSeconds (uint)
      1,                               // _id (uint)
      0                                // _deadline (uint256)
    );

    await contract.connect(user1).fundProject(1, {
      value: ethers.utils.parseEther("2")
    });

    await contract.connect(user1).userWithdrawFunds(1);

    const contribution = await contract.contributions(1, user1.address);
    expect(contribution).to.equal(0);
  });
});
