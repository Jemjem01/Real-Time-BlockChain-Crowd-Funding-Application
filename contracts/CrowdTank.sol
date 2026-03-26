// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "hardhat/console.sol";

contract CrowdTank {
    event ProjectCreated(
        uint indexed projectId,
        address indexed creator,
        string name,
        string description,
        uint fundingGoal,
        uint deadline
    );
    event ProjectFunded(
        uint indexed projectId,
        address indexed contributor,
        uint amount
    );
    event FundsWithdrawn(
        uint indexed projectId,
        address indexed withdrawer,
        uint amount,
        string withdrawerType
    );


    address public admin;
    mapping(address => bool) public creators;
    constructor() {
        console.log("Deploying CrowdTank with admin:", msg.sender);
        admin = msg.sender;  // Set deployer as admin
        creators[msg.sender] = true;  // Admin is also a creator
    }
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;

    }
    modifier onlyCreator() {
        require(creators[msg.sender] == true, "Only authorized creators can call this function");
        _;

    }
    // struct to store project details
    struct Project {
        address creator;
        string name;
        string description;
        uint fundingGoal;
        uint deadline;
        uint amountRaised;
        bool funded;
    }
    // projectId => project details
    mapping(uint => Project) public projects;
    mapping(uint256 => bool) public isProjectSuccessful;

    uint public totalProjectsCreated;
    uint public totalSuccessfullyFunded;
    uint public totalFailedToFund;

    // projectId => user => contribution amount/funding amount 
    mapping(uint => mapping(address => uint)) public contributions;

    // projectId => whether the id is used or not
    mapping(uint => bool) public isIdUsed;

    function addCreator(address _creator) external onlyAdmin {
        console.log("Admin adding creator:", _creator);
        creators[_creator] = true;
    }

    function removeCreator(address _creator) external onlyAdmin {
        console.log("Admin removing creator:", _creator);
        creators[_creator] = false;
    }


    // create project by a creator
    // external public internal private
    function createProject(
        string memory _name,
        string memory _description,
        uint _fundingGoal,
        uint _durationSeconds,
        uint _id,
        uint256 _deadline
    ) public {
        require(!isIdUsed[_id], "Project Id is already used");
        isIdUsed[_id] = true;

        projects[_id] = Project({
            creator: msg.sender,
            name: _name,
            description: _description,
            fundingGoal: _fundingGoal,
            deadline: block.timestamp + _durationSeconds,
            amountRaised: 0,
            funded: false
        });

        totalProjectsCreated++;
        emit ProjectCreated(_id, msg.sender, _name, _description, _fundingGoal, _deadline);

    }

    function fundProject(uint _projectId) external payable {
        Project storage project = projects[_projectId];
        require(block.timestamp <= project.deadline, "Project deadline is already passed");
        require(!project.funded, "Project is already funded");
        require(msg.value > 0, "Must send some value of ether");

        uint256 neededAmount = project.fundingGoal - project.amountRaised;
        uint256 actualContribution = msg.value;

        if (msg.value > neededAmount) {
            actualContribution = neededAmount;
            uint256 refundAmount = msg.value - neededAmount;

            // 3. Refund the extra funds to the user immediately
            payable(msg.sender).transfer(refundAmount);
        }

        project.amountRaised += actualContribution;
        contributions[_projectId][msg.sender] += actualContribution;
        emit ProjectFunded(_projectId, msg.sender, actualContribution);


        if (project.amountRaised >= project.fundingGoal) {
            project.funded = true;
            totalSuccessfullyFunded++;           // Increment successful count
            isProjectSuccessful[_projectId] = true; // Mark as successful
        }

    }

    function getFundingPercentage(uint _projectId) public view returns (uint) {
        Project storage project = projects[_projectId];
        require(project.fundingGoal > 0, "Project has no funding goal");
        uint percentage = (project.amountRaised * 100) / project.fundingGoal;
        return percentage;

    }

    function userWithdrawFunds(uint _projectId) external {
        Project storage project = projects[_projectId];

        // Check user contributed
        uint fundContributed = contributions[_projectId][msg.sender];
        require(fundContributed > 0, "You have not contributed");

        // Check BEFORE deadline
        require(block.timestamp < project.deadline, "Deadline passed");

        // Check project not fully funded
        require(project.amountRaised < project.fundingGoal, "Project fully funded");

        // Security: Reset first
        contributions[_projectId][msg.sender] = 0;

        // Update project total
        project.amountRaised -= fundContributed;

        // Transfer
        payable(msg.sender).transfer(fundContributed);
    }

    function checkFailedProject(uint _projectId) public {
        Project storage project = projects[_projectId];

        // Check if project exists and deadline has passed
        require(block.timestamp > project.deadline, "Deadline not passed yet");
        require(!project.funded, "Project was funded successfully ");

        // Mark as failed if not already counted
        if (!isProjectSuccessful[_projectId]) {
            totalFailedToFund++;
            isProjectSuccessful[_projectId] = true; // Mark as proceed
        }
    }

    function checkAllFailedProjects() external {
        for (uint i = 1; i <= totalProjectsCreated; i++) {
            if (projects[i].creator != address(0)) { // Project exists
                Project storage project = projects[i];
                if (!project.funded && block.timestamp > project.deadline && !isProjectSuccessful[i]) {
                    totalFailedToFund++;
                    isProjectSuccessful[i] = true;
                }
            }
        }
    }



    function adminWithdrawFunds(uint _projectId) external {
        Project storage project = projects[_projectId];
        require(project.funded, "Funding is not sufficient");
        require(project.creator == msg.sender, "Only project admin can withdraw");
        require(block.timestamp >= project.deadline, "Deadline for project is not reached");

        uint totalFunding = project.amountRaised;

        // Reset before transfer (security best practice)
        project.amountRaised = 0;
        payable(msg.sender).transfer(totalFunding);
    }


    function isIdUsedCall(uint _id)external view returns(bool){
        return isIdUsed[_id];
    }


    function getSuccessfullyFundedCount() external view returns (uint) {
        return totalSuccessfullyFunded;
    }


    function getFailedProjectsCount() external view returns (uint) {
        return totalFailedToFund;
    }


    function getFundingStats() external view returns (
        uint256 totalProjects,
        uint256 successfulProjects,
        uint256 failedProjects,
        uint256 totalFundsRaised
    ) {
        uint256 validCount = 0;
        uint256 successCount = 0;
        uint256 failCount = 0;
        uint256 totalRaised = 0;

        // Loop through a reasonable range (adjust if needed)
        for (uint256 i = 1; i <= 1000; i++) {
            // Check if project exists by verifying creator is not zero address
            if (projects[i].creator != address(0)) {
                validCount++;
                totalRaised += projects[i].amountRaised;

                if (projects[i].funded) {
                    successCount++;
                } else if (block.timestamp > projects[i].deadline) {
                    failCount++;
                }
            }
        }

        return (
            validCount,
            successCount,
            failCount,
            totalRaised
        );
    }

    function debugGetAllProjects() external view returns (
        uint256[] memory projectIds,
        address[] memory creators,
        uint256[] memory amountsRaised,
        bool[] memory funded
    ) {
        uint256 count = 0;
        // First count how many valid projects
        for (uint i = 1; i <= totalProjectsCreated; i++) {
            if (projects[i].creator != address(0)) {
                count++;
            }
        }

        // Create arrays
        projectIds = new uint256[](count);
        creators = new address[](count);
        amountsRaised = new uint256[](count);
        funded = new bool[](count);

        // Fill arrays
        uint256 index = 0;
        for (uint i = 1; i <= totalProjectsCreated; i++) {
            if (projects[i].creator != address(0)) {
                projectIds[index] = i;
                creators[index] = projects[i].creator;
                amountsRaised[index] = projects[i].amountRaised;
                funded[index] = projects[i].funded;
                index++;
            }
        }
    }

}