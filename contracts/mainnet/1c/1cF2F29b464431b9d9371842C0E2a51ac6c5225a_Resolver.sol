/**
 *Submitted for verification at polygonscan.com on 2021-10-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Resolver {

    struct spell {
        string connector;
        bytes data;
    }

    struct TokenInfo {
        address token;
        uint256 amount;
    }
    
    struct Position {
        TokenInfo[] supply;
        TokenInfo[] withdraw;
    }

    struct PositionData {
        uint256 ratio;
        uint256 liquidationRatio;
        uint256 totalSupply;
        uint256 totalBorrow;
        uint256 price;
    }

    function checkAavePosition(Position memory position) public view returns(bool, PositionData memory p) {
        return (true, p);
    }

    function checkLiquidity(address[] memory tokens, uint256 borrowAmount) public view returns(bool, PositionData memory p) {
        return (true, p);
    }
}