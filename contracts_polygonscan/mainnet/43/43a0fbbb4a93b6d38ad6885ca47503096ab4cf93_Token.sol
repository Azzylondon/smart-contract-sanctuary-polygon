/**
 *Submitted for verification at polygonscan.com on 2021-11-04
*/

pragma solidity ^0.8.4;

contract Token {

    mapping(address => uint) public balances;

    uint public totalSupply = 13500000 * 10 ** 18;
    string public name = "Big Panda";
    string public symbol = "BPANDA";
    uint public decimals = 18;

    event Transfer(address indexed from, address indexed to, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'Insufficient balance');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
}

//SPDX-License-Identifier: UNLICENSED