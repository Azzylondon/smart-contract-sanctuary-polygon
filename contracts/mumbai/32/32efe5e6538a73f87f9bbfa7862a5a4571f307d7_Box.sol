/**
 *Submitted for verification at polygonscan.com on 2022-06-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

contract Box {
    uint public val;

    // constructor(uint _val) {
    //     val = _val;
    // }

    function initialize(uint _val) external {
        val = _val;
    }
}