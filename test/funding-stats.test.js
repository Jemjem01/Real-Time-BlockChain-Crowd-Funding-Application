const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Funding Statistics", function () {
    let contract;
    let owner, creator, funder1, funder2;

    beforeEach(async function () {
        [owner, creator, funder1, funder2] = await ethers.getSigners();
        const CrowdTank = await ethers.getContractFactory("CrowdTank");
        contract = await CrowdTank.deploy();

        await contract.connect(owner).addCreator(creator.address);
    });

    describe("Successfully Funded Projects", function () {
        it("should increment totalSuccessfullyFunded when project is fully funded", async function () {
            // Create a project with 10 ETH goal
            await contract.connect(creator).createProject(
                "Success Test",
                "This project will succeed",
                ethers.utils.parseEther("10"),
                3600, // 1 hour deadline
                1, // project ID
                0 // deadline parameter
            );

            // Check initial count
            expect(await contract.totalSuccessfullyFunded()).to.equal(0);

            // Fund the project fully
            await contract.connect(funder1).fundProject(1, {
                value: ethers.utils.parseEther("10")
            });

            // Check count increased
            expect(await contract.totalSuccessfullyFunded()).to.equal(1);

            // Check getter function
            expect(await contract.getSuccessfullyFundedCount()).to.equal(1);
        });

        it("should handle multiple successful projects", async function () {
            // Create 3 projects
            for (let i = 1; i <= 3; i++) {
                await contract.connect(creator).createProject(
                    'Project ${i}',
                    "Description",
                    ethers.utils.parseEther("5"),
                    3600,
                    i,
                    0
                );
            }

            // Fund first two projects
            await contract.connect(funder1).fundProject(1, {
                value: ethers.utils.parseEther("5")
            });
            await contract.connect(funder1).fundProject(2, {
                value: ethers.utils.parseEther("5")
            });

            // Check count (should be 2)
            expect(await contract.totalSuccessfullyFunded()).to.equal(2);
            expect(await contract.getSuccessfullyFundedCount()).to.equal(2);

            // Fund third project
            await contract.connect(funder2).fundProject(3, {
                value: ethers.utils.parseEther("5")
            });

            // Check count (should be 3)
            expect(await contract.totalSuccessfullyFunded()).to.equal(3);
        });

        it("should not count project as successful if not fully funded", async function () {
            await contract.connect(creator).createProject(
                "Partial Fund",
                "Only partially funded",
                ethers.utils.parseEther("10"),
                3600,
                1,
                0
            );

            // Fund partially (5 ETH only)
            await contract.connect(funder1).fundProject(1, {
                value: ethers.utils.parseEther("5")
            });

            // Check count (should still be 0)
            expect(await contract.totalSuccessfullyFunded()).to.equal(0);
        });
    });

    describe("Failed Projects", function () {
        it("should increment totalFailedToFund when project deadline passes without full funding", async function () {
            // Create project with short deadline (1 second)
            await contract.connect(creator).createProject(
                "Fail Test",
                "This project will fail",
                ethers.utils.parseEther("10"),
                1,
                1,// 1 second deadline
                0
            );

            // Fund partially (2 ETH only)
            await contract.connect(funder1).fundProject(1, {
                value: ethers.utils.parseEther("2")
            });

            // Check initial failed count
            expect(await contract.totalFailedToFund()).to.equal(0);

            // Increase time beyond deadline
            await ethers.provider.send("evm_increaseTime", [2]);
            await ethers.provider.send("evm_mine");

            // Check project status
            await contract.checkFailedProject(1);

            // Verify failed count increased
            expect(await contract.totalFailedToFund()).to.equal(1);
            expect(await contract.getFailedProjectsCount()).to.equal(1);
        });

        it("should not count successful projects as failed", async function () {
            // Create successful project
            await contract.connect(creator).createProject(
                "Success",
                "Will succeed",
                ethers.utils.parseEther("10"),
                3600,
                1,
                0
            );

            // Fund fully
            await contract.connect(funder1).fundProject(1, {
                value: ethers.utils.parseEther("10")
            });

            // Try to mark as failed (should revert)
            await ethers.provider.send("evm_increaseTime", [3601]);
            await ethers.provider.send("evm_mine");

            await expect(
                contract.checkFailedProject(1)
            ).to.be.revertedWith("Project was funded successfully");

            // Failed count should still be 0
            expect(await contract.totalFailedToFund()).to.equal(0);
        });

        it("should handle multiple failed projects", async function () {
            // Create 3 failing projects
            for (let i = 1; i <= 3; i++) {
                await contract.connect(creator).createProject(
                    'Fail ${i}',
                    "Will fail",
                    ethers.utils.parseEther("10"),
                    1, // 1 second deadline
                    i,
                    0
                );

                // Fund a little bit
                await contract.connect(funder1).fundProject(i, {
                    value: ethers.utils.parseEther("1")
                });
            }

            // Advance time
            await ethers.provider.send("evm_increaseTime", [2]);
            await ethers.provider.send("evm_mine");

            // Mark all as failed
            for (let i = 1; i <= 3; i++) {
                await contract.checkFailedProject(i);
            }

            // Check count
            expect(await contract.totalFailedToFund()).to.equal(3);
        });

        it("should prevent double-counting the same failed project", async function () {
            await contract.connect(creator).createProject(
                "Double Count Test",
                "Should not double count",
                ethers.utils.parseEther("10"),
                1,
                1,
                0
            );

            // Fund partially
            await contract.connect(funder1).fundProject(1, {
                value: ethers.utils.parseEther("1")
            });

            // Advance time
            await ethers.provider.send("evm_increaseTime", [2]);
            await ethers.provider.send("evm_mine");

            // Check failed project first time
            await contract.checkFailedProject(1);
            expect(await contract.totalFailedToFund()).to.equal(1);

            // Try to check again (should not increase count)
            await contract.checkFailedProject(1);
            expect(await contract.totalFailedToFund()).to.equal(1);
        });
    });

    describe("Combined Statistics", function () {
        it("should return correct combined stats from getFundingStats", async function () {
            // Create 2 successful projects
            for (let i = 1; i <= 2; i++) {
                await contract.connect(creator).createProject(
                    'Success ${i}',
                    "Will succeed",
                    ethers.utils.parseEther("10"),
                    3600,
                    i,
                    0
                );
                await contract.connect(funder1).fundProject(i, {
                    value: ethers.utils.parseEther("10")
                });
            }

            // Create 3 failed projects
            for (let i = 3; i <= 5; i++) {
                await contract.connect(creator).createProject(
                    'Fail $fi',
                    "Will fail",
                    ethers.utils.parseEther("10"),
                    1, // short deadline
                    i,
                    0
                );
                await contract.connect(funder1).fundProject(i, {
                    value: ethers.utils.parseEther("1")
                });
            }

            // Advance time for failed projects
            await ethers.provider.send("evm_increaseTime", [2]);
            await ethers.provider.send("evm_mine");

            // Mark failed projects
            for (let i = 3; i <= 5; i++) {
                await contract.checkFailedProject(i);
            }

            // Check combined stats
            const [totalProjects, successful, failed, totalRaised] = await contract.getFundingStats();
            expect(successful).to.equal(2);
            expect(failed).to.equal(3);
        });

        it("should maintain correct totals with mixed outcomes", async function () {
            // Project 1: Success (10 ETH)
            await contract.connect(creator).createProject("P1", "", ethers.utils.parseEther("10"), 3600, 1, 0);
            await contract.connect(funder1).fundProject(1, { value: ethers.utils.parseEther("10") });

            // Project 2: Fail (short deadline)
            await contract.connect(creator).createProject("P2", "", ethers.utils.parseEther("10"), 1, 2, 0);
            await contract.connect(funder1).fundProject(2, { value: ethers.utils.parseEther("5") });

            // Project 3: Success (20 ETH)
            await contract.connect(creator).createProject("P3", "", ethers.utils.parseEther("20"), 3600, 3, 0);
            await contract.connect(funder1).fundProject(3, { value: ethers.utils.parseEther("20") });

            // Project 4: Partial but not failed yet (deadline not passed)
            await contract.connect(creator).createProject("P4", "", ethers.utils.parseEther("15"), 3600, 4, 0);
            await contract.connect(funder1).fundProject(4, { value: ethers.utils.parseEther("5") });

            // Advance time for failed project only
            await ethers.provider.send("evm_increaseTime", [2]);
            await ethers.provider.send("evm_mine");
            await contract.checkFailedProject(2);

            // Check final stats
            expect(await contract.getSuccessfullyFundedCount()).to.equal(2); // P1 and P3
            expect(await contract.getFailedProjectsCount()).to.equal(1); // P2 only

            const [totalProjects, successful, failed, totalRaised] = await contract.getFundingStats();
            expect(successful).to.equal(2);
            expect(failed).to.equal(1);
        });
    });
});