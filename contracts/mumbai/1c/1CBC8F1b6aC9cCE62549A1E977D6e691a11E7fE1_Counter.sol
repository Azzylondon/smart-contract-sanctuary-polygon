/**
 *Submitted for verification at polygonscan.com on 2022-04-13
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Counter{
    uint public count = 0;

    function increment() public returns(uint){
        count++;
        return count;
    }
}