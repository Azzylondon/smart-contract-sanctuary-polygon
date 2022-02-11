/**
 *Submitted for verification at polygonscan.com on 2022-01-10
*/

// SPDX-License-Identifier: MIT
// File contracts/Chainlink/IPriceFeeds.sol

pragma solidity ^0.8.11;

/// @title IPriceFeeds
/// @author Polytrade
interface IPriceFeeds {
    /**
     * @notice Link Stable Address to ChainLink Aggregator
     * @dev Add a mapping stableAddress to aggregator
     * @param stable, address of the ERC-20 stable smart contract
     * @param aggregator, address of the aggregator to map with the stableAddress
     */
    function setStableAggregator(address stable, address aggregator) external;

    /**
     * @notice Get the price of the stableAddress against USD dollar
     * @dev Query Chainlink aggregator to get Stable/USD price
     * @param stableAddress, address of the stable to be queried
     * @return price of the stable against USD dollar
     */
    function getPrice(address stableAddress) external view returns (uint);

    /**
     * @notice Returns the decimal used for the stable
     * @dev Query Chainlink aggregator to get decimal
     * @param stableAddress, address of the stable to be queried
     * @return decimals of the USD
     */
    function getDecimals(address stableAddress) external view returns (uint);
}


// File contracts/Chainlink/AggregatorV3Interface.sol

pragma solidity ^0.8.11;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int answer,
            uint startedAt,
            uint updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int answer,
            uint startedAt,
            uint updatedAt,
            uint80 answeredInRound
        );
}


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]


pragma solidity ^0.8.0;

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
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/Chainlink/PriceFeeds.sol

pragma solidity ^0.8.11;



/// @title PriceFeeds
/// @author Polytrade
contract PriceFeeds is IPriceFeeds, Ownable {
    /// Mapping stableAddress to its USD Aggregator
    mapping(address => AggregatorV3Interface) public stableAggregators;

    /**
     * @notice Link Stable Address to ChainLink Aggregator
     * @dev Add a mapping stableAddress to aggregator
     * @param stable, address of the ERC-20 stable smart contract
     * @param aggregator, address of the aggregator to map with the stableAddress
     */
    function setStableAggregator(address stable, address aggregator)
        external
        onlyOwner
    {
        stableAggregators[stable] = AggregatorV3Interface(aggregator);
    }

    /**
     * @notice Get the price of the stableAddress against USD dollar
     * @dev Query Chainlink aggregator to get Stable/USD price
     * @param stableAddress, address of the stable to be queried
     * @return price of the stable against USD dollar
     */
    function getPrice(address stableAddress) public view returns (uint) {
        (, int price, , uint timestamp, ) = stableAggregators[stableAddress]
            .latestRoundData();
        require(
            block.timestamp - timestamp >= 24 hours,
            "Outdated pricing feed"
        );

        return uint(price);
    }

    /**
     * @notice Returns the decimal used for the stable
     * @dev Query Chainlink aggregator to get decimal
     * @param stableAddress, address of the stable to be queried
     * @return decimals of the USD
     */
    function getDecimals(address stableAddress) public view returns (uint) {
        return stableAggregators[stableAddress].decimals();
    }
}