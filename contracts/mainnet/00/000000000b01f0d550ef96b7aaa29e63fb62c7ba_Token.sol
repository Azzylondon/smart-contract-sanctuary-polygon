/**
 *Submitted for verification at polygonscan.com on 2021-09-15
*/

pragma solidity ^0.8.2;

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 1000000000 * 10 ** 18;
    string public name = "Draconeum";
    string public symbol = "Draco";
    
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        uint256 burn_token = (value / 100);
        require(balanceOf(msg.sender) >= value, 'Wallet balance is too low');
        balances[to] += value - burn_token;
        balances[msg.sender] -= value;
        return true;
    }
    
    
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        uint256 burn_token = (value / 100);
        require(balanceOf(msg.sender) >= value, 'Wallet balance is too low');
        balances[to] += value - burn_token;
        balances[msg.sender] -= value;
        return true;  
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}