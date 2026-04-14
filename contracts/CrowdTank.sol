// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CrowdTank {

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event ProjectCreated(
        uint indexed projectId,
        address indexed creator,
        string name,
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
        address indexed user,
        uint amount
    );

    /*//////////////////////////////////////////////////////////////
                                STATE
    //////////////////////////////////////////////////////////////*/

    address public admin;
    uint public nextProjectId;

    mapping(address => bool) public creators;

    struct Project {
        address creator;
        string name;
        string description;
        uint fundingGoal;
        uint deadline;
        uint amountRaised;
        bool funded;
        bool withdrawn;
    }

    mapping(uint => Project) public projects;
    mapping(uint => mapping(address => uint)) public contributions;

    uint public totalProjects;
    uint public totalFunded;
    uint public totalFailed;

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    modifier onlyCreator() {
        require(creators[msg.sender], "Not creator");
        _;
    }

    modifier projectExists(uint id) {
        require(projects[id].creator != address(0), "Invalid project");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        admin = msg.sender;
        creators[msg.sender] = true;
    }

    /*//////////////////////////////////////////////////////////////
                        CREATOR MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    function addCreator(address _creator) external onlyAdmin {
        creators[_creator] = true;
    }

    function removeCreator(address _creator) external onlyAdmin {
        creators[_creator] = false;
    }

    /*//////////////////////////////////////////////////////////////
                          PROJECT CREATION
    //////////////////////////////////////////////////////////////*/

    function createProject(
        string memory _name,
        string memory _description,
        uint _fundingGoal,
        uint _duration
    ) external onlyCreator {

        require(_fundingGoal > 0, "Invalid goal");
        require(_duration > 0, "Invalid duration");

        uint id = ++nextProjectId;

        projects[id] = Project({
            creator: msg.sender,
            name: _name,
            description: _description,
            fundingGoal: _fundingGoal,
            deadline: block.timestamp + _duration,
            amountRaised: 0,
            funded: false,
            withdrawn: false
        });

        totalProjects++;

        emit ProjectCreated(
            id,
            msg.sender,
            _name,
            _fundingGoal,
            block.timestamp + _duration
        );
    }

    /*//////////////////////////////////////////////////////////////
                            FUNDING
    //////////////////////////////////////////////////////////////*/

    function fundProject(uint id)
        external
        payable
        projectExists(id)
    {
        Project storage p = projects[id];

        require(block.timestamp < p.deadline, "Expired");
        require(!p.funded, "Already funded");
        require(msg.value > 0, "Zero value");

        uint remaining = p.fundingGoal - p.amountRaised;
        uint contribution = msg.value;

        if (contribution > remaining) {
            contribution = remaining;
            payable(msg.sender).transfer(msg.value - remaining);
        }

        p.amountRaised += contribution;
        contributions[id][msg.sender] += contribution;

        emit ProjectFunded(id, msg.sender, contribution);

        if (p.amountRaised == p.fundingGoal) {
            p.funded = true;
            totalFunded++;
        }
    }

    /*//////////////////////////////////////////////////////////////
                        USER REFUND (BEFORE DEADLINE)
    //////////////////////////////////////////////////////////////*/

    function withdrawContribution(uint id)
        external
        projectExists(id)
    {
        Project storage p = projects[id];

        require(block.timestamp < p.deadline, "Deadline passed");
        require(!p.funded, "Already funded");

        uint amount = contributions[id][msg.sender];
        require(amount > 0, "Nothing to withdraw");

        contributions[id][msg.sender] = 0;
        p.amountRaised -= amount;

        payable(msg.sender).transfer(amount);

        emit FundsWithdrawn(id, msg.sender, amount);
    }

    /*//////////////////////////////////////////////////////////////
                        CREATOR WITHDRAW (SUCCESS)
    //////////////////////////////////////////////////////////////*/

    function withdrawFunds(uint id)
        external
        projectExists(id)
    {
        Project storage p = projects[id];

        require(msg.sender == p.creator, "Not creator");
        require(p.funded, "Not funded");
        require(block.timestamp >= p.deadline, "Too early");
        require(!p.withdrawn, "Already withdrawn");

        p.withdrawn = true;

        uint amount = p.amountRaised;
        p.amountRaised = 0;

        payable(msg.sender).transfer(amount);

        emit FundsWithdrawn(id, msg.sender, amount);
    }

    /*//////////////////////////////////////////////////////////////
                        MARK FAILED PROJECT
    //////////////////////////////////////////////////////////////*/

    function markFailed(uint id)
        external
        projectExists(id)
    {
        Project storage p = projects[id];

        require(block.timestamp >= p.deadline, "Not ended");
        require(!p.funded, "Funded");

        totalFailed++;
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW HELPERS
    //////////////////////////////////////////////////////////////*/

    function getFundingPercentage(uint id)
        external
        view
        returns (uint)
    {
        Project storage p = projects[id];
        return (p.amountRaised * 100) / p.fundingGoal;
    }
}
