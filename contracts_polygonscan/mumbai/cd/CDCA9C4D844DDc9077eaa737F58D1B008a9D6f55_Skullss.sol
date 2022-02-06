/**
 *Submitted for verification at polygonscan.com on 2022-02-05
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.0;
// creator 0x34F84BF1b6D9a0B6ABcc0a91e4cb837B6Eb66D36 (balance)
// dante (user) test 0x77Fa62e63681f03c17E1F1211714Be2C27639A84
// Loss  0x8ec887b8dcec48357b4059b63e1490fc6baef581
// DEX 0xaff69be4eef3aa212d1d9d07c2cacd945bb58f2c

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract NeverLoss is IERC20 {

    string public constant name = "NeverLoss";
    string public constant symbol = "LOSS";
    uint8 public constant decimals = 0;

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    uint256 totalSupply_ = 1000000;
    using SafeMath for uint256;

    constructor(address owner) public {
        balances[owner] = totalSupply_;
    }

    function totalSupply() public override view returns (uint256) {
        return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

    function airDrop(address receiver, uint256 numTokens) public returns (bool) {
        require(numTokens <= balances[address(this)]);
        balances[address(this)] = balances[address(this)].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(address(this), receiver, numTokens);
        return true;
    }
}

contract Skullss {

    event Staked(uint256 amount);
    event Unstaked(uint256 amount);
    uint256 public dexBalance;
    address public owner;

    NeverLoss public token;

    constructor() public {
        owner = address(this);
        token = new NeverLoss(owner);
        dexBalance = token.balanceOf(owner);
    }

    receive() external payable {}

    function stake() payable public {

        uint256 maticQty = msg.value;
        uint256 lossQty = maticQty * 100;
        
        require(maticQty > 0, "You need to send some MATIC");
        //require(lossQty <= dexBalance, "Not enough tokens in the reserve");

        token.airDrop(msg.sender, lossQty);
        dexBalance = dexBalance - lossQty;
        //emit Staked(maticQty);
    }

    function unstake(uint256 lossQty) public {

        require(lossQty > 0, "You need to sell at least some tokens");
        uint256 allowance = token.allowance(msg.sender, owner);

        require(allowance >= lossQty, "Check the token allowance");
        token.transferFrom(msg.sender, owner, lossQty);
        msg.sender.transfer(lossQty);
        emit Unstaked(lossQty);
    }

    function balance() public view returns (uint256) {
        return dexBalance;
    }

    function staking() public view returns (uint256) {
        return owner.balance;
    }
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}