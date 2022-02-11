/**
 *Submitted for verification at polygonscan.com on 2021-11-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.0 <0.8.9;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 private number;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}