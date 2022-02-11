/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

// import "hardhat/console.sol";

contract Greeter {
    string greeting;

    constructor(string memory _greeting) {
        // console.log("Deploying a Greeter with greeting:", _greeting);
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        // console.log("Changing greeting from '%s' to '%s'", greeting, _greeting);
        greeting = _greeting;
    }
}