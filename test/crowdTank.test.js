const { expect } = require("chai");
const { ethers } = require("hardhat");
// Example: Adding the ID (0) as the first argument

describe("CrowdTank", function () {
  it("Should refund extra money if goal is exceeded", async function () {
    const [owner, addr1] = await ethers.getSigners();
    const CrowdTank = await ethers.getContractFactory("CrowdTank");
    const contract = await CrowdTank.deploy();

    // Create project with 10 ETH goal
    await contract.createProject("Test", "Desc", ethers.utils.parseEther("10"), 3600, 0);

    // Fund with 11 ETH
    await contract.connect(addr1).fundProject(0, { value: ethers.utils.parseEther("11") });

    const project = await contract.projects(0);
    expect(project.amountRaised).to.equal(ethers.utils.parseEther("10"));
    expect(project.funded).to.equal(true);
  });
});

