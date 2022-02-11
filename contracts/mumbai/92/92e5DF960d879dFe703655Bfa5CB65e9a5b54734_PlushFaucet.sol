// SPDX-License-Identifier: UNLISCENSED

pragma solidity ^0.8.2;

interface IERC20
{
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract PlushFaucet {
    IERC20 token;
    address owner;
    mapping(address=>uint256) nextRequestAt;
    uint256 faucetDripAmount;
    uint256 faucetTime;

    constructor (address _smtAddress)
    {
        faucetTime = 24 hours;
        faucetDripAmount = 1;
        token = IERC20(_smtAddress);
        owner = msg.sender;
    }

    modifier onlyOwner
    {
        require(msg.sender == owner, "FaucetError: Caller not owner");
        _;
    }

    function send(address _sender) external
    {
        require(token.balanceOf(address(this)) >= 1, "FaucetError: Empty");
        require(nextRequestAt[_sender] < block.timestamp, "FaucetError: Try again later");

        // Next request from the address can be made only after faucetTime
        nextRequestAt[_sender] = block.timestamp + faucetTime;

        token.transfer(_sender, faucetDripAmount * 10 ** token.decimals());
    }

    function setTokenAddress(address _tokenAddr) external onlyOwner
    {
        token = IERC20(_tokenAddr);
    }

    function setFaucetDripAmount(uint256 _amount) external onlyOwner
    {
        faucetDripAmount = _amount;
    }

    function setFaucetTime(uint256 _time) external onlyOwner
    {
        faucetTime = _time;
    }

    function withdrawTokens(address _receiver, uint256 _amount) external onlyOwner
    {
        require(token.balanceOf(address(this)) >= _amount * 10 ** token.decimals(), "FaucetError: Insufficient funds");
        token.transfer(_receiver, _amount * 10 ** token.decimals());
    }
}