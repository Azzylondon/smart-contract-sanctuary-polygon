/**
 *Submitted for verification at polygonscan.com on 2021-08-28
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;
contract DaughterContract {
    string public name = "Filha";
    uint public age = 17;
}

pragma solidity ^0.6.0;
contract MomContract {
    string public name = "Mãe";
    uint public age = 55;
    DaughterContract public daughter;
    constructor(
    )
    
    public {
        daughter = new DaughterContract();
        
    }
}