/**
 *Submitted for verification at polygonscan.com on 2022-07-26
*/

/**
 *Submitted for verification at polygonscan.com on 2022-01-16
*/

pragma solidity 0.8.7;


// SPDX-License-Identifier: Unlicense
/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// Taken from Solmate: https://github.com/Rari-Capital/solmate
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    function name() external view virtual returns (string memory);
    function symbol() external view virtual returns (string memory);
    function decimals() external view virtual returns (uint8);

    // string public constant name     = "TREAT";
    // string public constant symbol   = "TREAT";
    // uint8  public constant decimals = 18;

    /*///////////////////////////////////////////////////////////////
                             ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => bool) public isMinter;

    address public ruler;

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    constructor() { ruler = msg.sender;}

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        balanceOf[msg.sender] -= value;

        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to] += value;
        }

        emit Transfer(msg.sender, to, value);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= value;
        }

        balanceOf[from] -= value;

        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to] += value;
        }

        emit Transfer(from, to, value);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                             PRIVILEGE
    //////////////////////////////////////////////////////////////*/

    function mint(address to, uint256 value) external {
        require(isMinter[msg.sender], "FORBIDDEN TO MINT");
        _mint(to, value);
    }

    function burn(address from, uint256 value) external {
        require(isMinter[msg.sender], "FORBIDDEN TO BURN");
        _burn(from, value);
    }

    /*///////////////////////////////////////////////////////////////
                         Ruler Function
    //////////////////////////////////////////////////////////////*/

    function setMinter(address minter, bool status) external {
        require(msg.sender == ruler, "NOT ALLOWED TO RULE");

        isMinter[minter] = status;
    }

    function setRuler(address ruler_) external {
        require(msg.sender == ruler ||ruler == address(0), "NOT ALLOWED TO RULE");

        ruler = ruler_;
    }


    /*///////////////////////////////////////////////////////////////
                          INTERNAL UTILS
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 value) internal {
        totalSupply += value;

        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to] += value;
        }

        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] -= value;

        // This is safe because a user won't ever
        // have a balance larger than totalSupply!
        unchecked {
            totalSupply -= value;
        }

        emit Transfer(from, address(0), value);
    }
}

contract TreatPoly is ERC20 {
    string public constant override name     = "pTREAT";
    string public constant override symbol   = "pTREAT";
    uint8  public constant override decimals = 18;
    bool public isBuying;
    uint256 public tokensPerEth = 100;
    event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);

    constructor(){
       _mint(msg.sender, 10000);
       isBuying = true;
    }

    function buyTokens() public payable returns (uint256 tokenAmount) {
        require(isBuying , "Buying token deactivated!");
        require(msg.sender != ruler, "Ruler cannot buy");
        require(msg.value > 0, "Send ETH to buy some tokens");
        uint256 amountToBuy = msg.value * tokensPerEth;
        // check if the Vendor Contract has enough amount of tokens for the transaction
        uint256 vendorBalance = balanceOf[ruler];
        require(vendorBalance >= amountToBuy, "Vendor has not enough tokens in its balance");
        // Transfer token to the msg.sender
        //(bool sent) = ruler.transfer(msg.sender, amountToBuy);
        uint remainingBalance = vendorBalance - amountToBuy;
        balanceOf[ruler] = remainingBalance;
        balanceOf[msg.sender] += amountToBuy;

        emit BuyTokens(msg.sender, msg.value, amountToBuy);
        return amountToBuy;
  }

  function activateBuying(bool isActive) public returns (bool) {
        require(msg.sender == ruler, "Only owner can activate or deactivate buying");
        isBuying = isActive;
        return true;
  }

}