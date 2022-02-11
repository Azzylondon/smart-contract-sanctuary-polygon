/**
 *Submitted for verification at polygonscan.com on 2021-11-24
*/

// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code
pragma solidity ^0.6.8;


contract OpenBiSeaTest   {

     event ValueReceived(address user, uint amount);
    receive() external payable {
            emit ValueReceived(msg.sender, msg.value);
        }
    
    function _withdrawSuperAdmin(address payable sender,address token, uint256 amount) external  returns (bool) {
       require(amount>0);
       if (token == address(0)) {           
                sender.transfer(amount);
                return true;           
        }
        return false;
    }
}