// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Blacklist is Ownable {

    enum BlacklistType {WARNING, PROBATION, PERMANENT, FREE}

    struct BlacklistInfo {
        BlacklistType blacklist_type;
        uint256 blacklistStart;
        uint256 blacklistEnd;
        uint256 _blacklistCount;
        uint _isBlacklisted;
    }

    struct BlacklistAdmins {
        address _blacklistAdmins;
        address _blacklistContracts;
    }

    //Map the user address to the contract address to the blacklist info
    mapping(address => mapping(address => BlacklistInfo)) public _blacklistInfo;

    BlacklistInfo public blacklist_info;
    BlacklistAdmins public blacklist_admins;

    //The amount of times that an address has been blacklisted
    mapping(address => uint256) public _blacklistCount;

    //The contracts that are available to use the blacklist contract

    modifier isBlacklisted(address _address, address _contract) {
        require((blacklist_info.blacklist_type == BlacklistType.WARNING)||(blacklist_info.blacklist_type == BlacklistType.PROBATION)||(blacklist_info.blacklist_type == BlacklistType.PERMANENT), "Not Blacklisted");
        _;
    }

    modifier blacklistTimeIsOVer(address _address, address _contract) {
        require(block.timestamp <= _blacklistInfo[_address][_contract].blacklistEnd, "Time is up");
        _;
    }

    function setBlacklist(uint256 _blacklistTime, address _address, address _contract, uint256 _type) public {
        require((msg.sender == blacklist_admins._blacklistAdmins)&&(_contract == blacklist_admins._blacklistContracts), "You cannot blacklist!");
        BlacklistInfo memory blacklist = _blacklistInfo[_address][_contract];
        uint256 blacklistStart = block.timestamp;

        blacklist.blacklistStart=blacklistStart;
        blacklist.blacklistEnd=(_blacklistTime * 1 minutes) + blacklistStart; 

        if(_type == 0) {
            blacklist.blacklist_type = BlacklistType.WARNING;
            _blacklistCount[_address]++;
            blacklist._isBlacklisted = 1;
        } else if(_type == 1) {
            blacklist.blacklist_type = BlacklistType.PROBATION;
            _blacklistCount[_address]++;
            blacklist._isBlacklisted = 1;
        } else if(_type == 2) {
            blacklist.blacklist_type = BlacklistType.PERMANENT;
            _blacklistCount[_address]++;
            blacklist._isBlacklisted = 1;
        } else if(_type == 3) {
            blacklist.blacklist_type = BlacklistType.FREE;
            blacklist.blacklistStart=0;
            blacklist.blacklistEnd=0;
            blacklist._isBlacklisted = 0; 
        }
    }

    function blacklistTimeLeft(address _address, address _contract) public returns(uint256) {
        uint256 remainTime = _blacklistInfo[_address][_contract].blacklistEnd > block.timestamp ? _blacklistInfo[_address][_contract].blacklistEnd-block.timestamp : 0;
        if (remainTime == 0) {
            setBlacklist(0, _address, _contract, 3);
        }

        return remainTime;
    }

    function _deleteBlacklist(address _address, address _contract) public {
        require((msg.sender == blacklist_admins._blacklistAdmins)&&(_contract == blacklist_admins._blacklistContracts), "You cannot do this!");
        setBlacklist(0, _address, _contract, 3);
    }

    function _addBlacklister(address _blacklist_admins, address _blacklist_contracts) public onlyOwner {
        blacklist_admins._blacklistAdmins = _blacklist_admins;
        blacklist_admins._blacklistContracts = _blacklist_contracts;
    }

    function _permaBan() public view {
        if (blacklist_info._blacklistCount > 3) {
            blacklist_info.blacklist_type == BlacklistType.PERMANENT;
        }
    }

    function getBlacklist(address _address, address _contract) public view returns (uint256 is_blacklisted) {
        BlacklistInfo memory blacklist = _blacklistInfo[_address][_contract];

        return (blacklist._isBlacklisted);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}