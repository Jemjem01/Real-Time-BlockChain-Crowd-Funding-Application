const { expect } = require("cha");
const { ethers } = require("hardhat");

describe("CrowdTank Withdrawal", function () {
  let CrowdTank;
  let contract;
  let owner, user1, user2;

  beforeEach(async function () {
      // Get test accounts
      [owner, user1, user2] = await ethers.getSigners();

      CrowdTank = await ethers.getContractFactory("CrowdTank");
      contract = await CrowdTank.deploy();

      await contract.deployed();
  });

  it("User can withdraw funds before deadline", async function () {
      // Create a project
      await contract.createProject(
        1,                    // project ID
        "Test Project",       // name
        "Test Description",   // description
        ethers.utils.parseEther("10"),  // funding goal: 10 ETH
        3600                  // duration: 1 hour
      );

       await contract.connect(user1).fundProject(1, {
            value: ethers.utils.parseEther("2")
       });

       await contract.connect(user1).userWithdrawFunds(1);

       const userContribution = await contract.contributions(1, user1.address);
       expect(userContribution).to.equal(0);

       const project = await contract.projects(1);
       expect(project.amountRaised).to.equal(0);
  });

  it("User cannot withdraw after deadline", async function () {
      // Create project with short deadline (2 seconds)
      await contract.createProject(
        2,
        "Short Project",
        "Test",
        ethers.utils.parseEther("10"),
        2
      );

      await contract.connect(user1).fundProject(2, {
            value: ethers.utils.parseEther("1")
      });

      await ethers.provider.send("evm_increaseTime", [5]);
      await ethers.provider.send("evm_mine"); // Mine new block

       await expect(
            contract.connect(user1).userWithdrawFunds(2)
       ).to.be.revertedWith("Deadline passed");

  });

  it("User cannot withdraw if project is fully funded", async function () {
      // Create project
      await contract.createProject(
        3,
        "Test Project",
        "Test",
        ethers.utils.parseEther("6"),
        deadline
        3600
      );

      await contract.connect(user1).fundProject(3, {
              value: ethers.utils.parseEther("6")
      });

      await expect(
            contract.connect(user1).userWithdrawFunds(3)
      ).to.be.revertedWith("Project fully funded");

  });

  it("User cannot withdraw if never contributed", async function () {
      // Create project
      await contract.createProject(
        4,
        "Test Project",
        "Test",
        ethers.utils.parseEther("10"),
        3600
      );

      await expect(
            contract.connect(user2).userWithdrawFunds(4)
      ).to.be.revertedWith("You have not contributed");
  });

  it("Project amount updates when user withdraws", async function () {
      // Create project
      await contract.createProject(
        5,
        "Test Project",
        "Test",
        ethers.utils.parseEther("10"),
        3600
      );

      await contract.connect(user1).fundProject(5, {
            value: ethers.utils.parseEther("3")
      });

      let project = await contract.projects(5);
      expect(project.amountRaised).to.equal(ethers.utils.parseEther("3"));

      await contract.connect(user1).userWithdrawFunds(5);
      project = await contract.projects(5);
      expect(project.amountRaised).to.equal(0);
  });

   it("Multiple users can withdraw from same project", async function () {
      // Create project
      await contract.createProject(
        6,
        "Multi User Project",
        "Test",
        ethers.utils.parseEther("20"),
        3600
      );

      await contract.connect(user1).fundProject(6, {
            value: ethers.utils.parseEther("5")
      });

      await contract.connect(user2).fundProject(6, {
            value: ethers.utils.parseEther("5")
      });

      let project = await contract.projects(6);
      expect(project.amountRaised).to.equal(ethers.utils.parseEther("10"));

      await contract.connect(user2).userWithdrawFunds(6);
      project = await contract.projects(6);
      expect(project.amountRaised).to.equal(0);
   });
});















