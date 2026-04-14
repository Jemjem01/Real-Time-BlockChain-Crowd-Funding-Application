// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Greeter {

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event GreetingUpdated(address indexed updater, string newGreeting);

    /*//////////////////////////////////////////////////////////////
                                STATE
    //////////////////////////////////////////////////////////////*/

    address public admin;
    string private greeting;

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _greeting) {
        require(bytes(_greeting).length > 0, "Empty greeting");
        admin = msg.sender;
        greeting = _greeting;
    }

    /*//////////////////////////////////////////////////////////////
                              FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function greet() external view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting)
        external
        onlyAdmin
    {
        require(bytes(_greeting).length > 0, "Empty greeting");

        greeting = _greeting;

        emit GreetingUpdated(msg.sender, _greeting);
    }
}
