/**
 *Submitted for verification at polygonscan.com on 2022-01-21
*/

// Sources flattened with hardhat v2.8.3 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}


// File contracts/SSSWhitelist.sol

pragma solidity 0.8.9;

contract SSSWhitelist {
  using Counters for Counters.Counter;
  Counters.Counter private _whitelistCount;
  mapping(address => bool) whitelisted;
  address[] public whitelistedAdds;
  uint256 public totalSlots = 100;

  function whitelist() external {
    require(_whitelistCount.current() < 100, 'whitelisted count: fullfilled');
    require(whitelisted[msg.sender] == false, 'whitelisted: true');
    whitelisted[msg.sender] = true;
    whitelistedAdds.push(msg.sender);
  }

  function getWhitelistedAdds() external view returns (address[] memory) {
    return whitelistedAdds;
  }

  function getWhitelistRemaining() external view returns (uint256) {
    uint256 remainingSlots = totalSlots - _whitelistCount.current();
    return remainingSlots;
  }
}