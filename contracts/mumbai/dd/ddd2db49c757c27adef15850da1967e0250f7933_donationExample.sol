/**
 *Submitted for verification at polygonscan.com on 2022-11-19
*/

/**
 *Submitted for verification at polygonscan.com on 2022-01-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract donationExample {

    address payable owner;

    constructor() {
         owner = payable(msg.sender);
     }

     event Donate (
        address from,
        uint256 amount,
        string messge
     );

    function newDonation(string memory note) public payable{
        (bool success,) = owner.call{value: msg.value}("");
        require(success, "Failed to send money");
        emit Donate(
            msg.sender,
            msg.value,
            note

        );
    } 

}