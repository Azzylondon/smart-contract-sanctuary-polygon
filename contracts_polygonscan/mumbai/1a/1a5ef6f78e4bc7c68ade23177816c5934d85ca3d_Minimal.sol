/**
 *Submitted for verification at polygonscan.com on 2021-11-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Minimal {
  uint storedData;

  function set(uint x) public {
    storedData = x;
  }

  function get() public view returns (uint) {
    return storedData;
  }
}