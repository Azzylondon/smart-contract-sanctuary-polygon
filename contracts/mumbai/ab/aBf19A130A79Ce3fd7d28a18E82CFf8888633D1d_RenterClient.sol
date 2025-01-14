/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

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


/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


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


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex;
                // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}


library Array256Lib {
    function removeAll(uint256[] memory array, uint256[] memory valuesToRemove) internal pure returns (uint256[] memory) {
        uint256[] memory newArray = new uint256[](array.length - valuesToRemove.length);
        uint idx = 0;
        for (uint i = 0; i < array.length; i++) {
            if (!contains(valuesToRemove, array[i])) {
                newArray[idx++] = array[i];
            }
        }
        require(newArray.length == array.length - valuesToRemove.length, "Failed to remove");
        return newArray;
    }

    function contains(uint256[] memory array, uint256 value) internal pure returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return true;
            }
        }
        return false;
    }


    function remove(uint256[] memory array, uint256 value) internal pure returns (uint256[] memory){
        uint256[] memory newArray = new uint256[](array.length - 1);
        uint idx = 0;
        for (uint i = 0; i < array.length; i++) {
            if (array[i] != value) {
                newArray[idx++] = array[i];
            }
        }
        require(newArray.length == array.length - 1, "Failed to remove");
        return newArray;
    }

    function add(uint256[] memory array, uint256 value) internal pure returns (uint256[] memory){
        uint256[] memory newArray = new uint256[](array.length + 1);
        for (uint i = 0; i < array.length; i++) {
            newArray[i] = array[i];
        }
        newArray[array.length] = value;
        return newArray;
    }

    function addAll(uint256[] memory array, uint256[] memory valuesToAdd) internal pure returns (uint256[] memory){
        uint256[] memory newArray = new uint256[](array.length + valuesToAdd.length);
        for (uint i = 0; i < array.length; i++) {
            newArray[i] = array[i];
        }
        for (uint i = array.length; i < array.length + valuesToAdd.length; i++) {
            newArray[i] = valuesToAdd[i - array.length];
        }
        return newArray;
    }
}


interface IRentingContract {

    enum Coin {
        XOIL,
        RBLS,
        WETH,
        USDC,
        BUSD,
        USDT,
        DAI
    }

    enum RentingType {
        FIXED_PRICE,
        REVENUE_SHARE
    }

    enum TokenRentingStatus {
        AVAILABLE,
        LISTED_BATTLE_SET,
        LISTED_COLLECTION,
        RENTED
    }

    struct BattleSet {
        uint256 landId;
        uint256[] botsIds;
    }

    struct RentingInfo {
        BattleSet battleSet;
        RentingType rentingType; // probaby change to uint
        Coin chargeCoin;// probaby change to uint
        uint256 price;
        address owner;
        address renter;
        uint256 rentingTs;
        uint256 renewTs;
        uint256 rentingEndTs;
        uint256 cancelTs;
        uint256 collectionId;
        bool perpetual;
        address[] whitelist;
        uint revenueShare;
    }

    struct Collection {
        uint256 id;
        address owner;
        uint256[] landIds;
        uint256[] botsIds;
        uint256[] rentedLandIds;
        uint256[] rentedBotsIds;
        uint256[] landsToRemove;
        uint256[] botsToRemove;
        address[] whitelist;
        RentingType rentingType;
        Coin chargeCoin;// probaby change to uint
        uint256 price;
        bool perpetual;
        uint256 disbandTs;
        uint revenueShare;
    }

    struct ListingInfo {
        BattleSet battleSet;
        RentingType rentingType;
        Coin chargeCoin;
        uint256 listingTs;
        address owner;
        uint256 price;
        bool perpetual;
        address[] whitelist;
        uint revenueShare;
    }
}


interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


interface IRentingContractStorage is IRentingContract {

    function renewRenting(uint256 id, uint256 renewTs, uint256 rentingEndTs) external;

    function getRentingInfo(uint256 landId) external view returns (RentingInfo memory);

    function getCollection(uint256 id) external view returns (Collection memory);

    function createRenting(BattleSet memory bs, RentingType rt, Coin coin, uint256 price, address owner, address renter,
        uint256 rentingEnd, uint256 collectionId, bool perpetual, address[] memory whitelist, uint revenueShare) external;

    function deleteListingInfo(uint256 landId) external;

    function getListingInfo(uint256 landId) external view returns (ListingInfo memory);

    function updateCollectionRentedAssets(uint256 id, uint256[] memory availableLands, uint256[] memory availableBotsIds,
        uint256[] memory rentedLandIds, uint256[] memory rentedBotsIds) external;

    function deleteRenting(uint256 landId) external;

    function disbandCollection(uint256 id) external returns (bool);

    function processCollectionRentalEnd(RentingInfo memory ri) external returns (Collection memory);

    function createListingInfo(BattleSet memory bs, RentingType rt, address owner, Coin coin, uint256 price,
        bool perpetual, address[] memory whitelist, uint revenueShare) external;
}


interface IERC721RentingContract {
    function safeTransferFromForRent(address from, address to, uint256 tokenId, bytes memory _data) external;

    function transferFrom(address from, address to, uint256 tokenId) external;
}


contract RenterClient is Context, IRentingContract, Ownable, Pausable, ReentrancyGuard {

    using EnumerableSet for EnumerableSet.UintSet;

    IERC721RentingContract private landsContract;
    IERC721RentingContract private botsContract;

    //    uint private constant defaultRentingDuration = 7 days;
    //    uint private constant rentingRenewalPeriodGap = 2 days;
    
    uint private defaultRentingDuration = 5 hours;
    uint private rentingRenewalPeriodGap = 4 hours;


//        uint private constant defaultRentingDuration = 1 minutes;
//        uint private constant rentingRenewalPeriodGap = 1 minutes;

    uint256[] private rentedLands;
    mapping(uint256 => uint256) private rentedLandsIndex;

    mapping(address => EnumerableSet.UintSet) private _rentedBattleSetsOwnersMapping;

    mapping(Coin => address) paymentContracts;
    IRentingContractStorage private storageContract;

    uint256 private feePercent = 5;
    address private feeCollectorAddress;

    event RentBattleSetStart(uint256 indexed landId, uint256[] botIds, address renter, address owner);
    event RentCollectionStart(uint256 indexed landId, uint256[] botIds, uint256 collectionId, address renter, address owner);
    event RentRenewed(uint256 indexed landId);
    event RentEnd(uint256 indexed landId, uint256 collectionId, address renter, address owner);
    event CollectionDisband(uint256 id);

    constructor(address storageContractAddress, address landsContractAddress, address botsContractAddress,
        address xoilAddress, address rblsAddress, address wethAddress) {
        paymentContracts[Coin.XOIL] = xoilAddress;
        paymentContracts[Coin.RBLS] = rblsAddress;
        paymentContracts[Coin.WETH] = wethAddress;
        storageContract = IRentingContractStorage(storageContractAddress);
        landsContract = IERC721RentingContract(landsContractAddress);
        botsContract = IERC721RentingContract(botsContractAddress);
        feeCollectorAddress = _msgSender();
    }
    
    function setRentingDuration(uint _defaultRentingDuration, uint _rentingRenewalPeriodGap) external onlyOwner {
        defaultRentingDuration = _defaultRentingDuration;
        rentingRenewalPeriodGap = _rentingRenewalPeriodGap;
    }

    function updateFees(uint256 newFeePercent, address newFeeCollectorAddress) external onlyOwner {
        require(newFeePercent >= 0 && newFeePercent < 100, "Incorrect fee");
        require(newFeeCollectorAddress != address(0), "Incorrect fee");
        feePercent = newFeePercent;
        feeCollectorAddress = newFeeCollectorAddress;
    }

    function rentBattleSet(uint256 landId) nonReentrant whenNotPaused external {
        ListingInfo memory li = storageContract.getListingInfo(landId);
        require(li.listingTs != 0, "Listing not found");
        if (li.whitelist.length > 0) {
            require(addressWhitelisted(li.whitelist, _msgSender()), "Address not whitelisted");
        }

        if (li.rentingType == RentingType.FIXED_PRICE && !transferPayment(li.chargeCoin, li.price, _msgSender(), li.owner)) {
            revert("Failed to transfer payment");
        }

        storageContract.deleteListingInfo(landId);

        safeTransferFromForRent(address(storageContract), _msgSender(), li.battleSet.landId, li.battleSet.botsIds);

        storageContract.createRenting(li.battleSet, li.rentingType, li.chargeCoin, li.price, li.owner, _msgSender(), block.timestamp + defaultRentingDuration,
            0, li.perpetual, li.whitelist, li.revenueShare);

        addTokenToRentedTokensList(li.battleSet.landId);
        _rentedBattleSetsOwnersMapping[li.owner].add(landId);

        emit RentBattleSetStart(landId, li.battleSet.botsIds, _msgSender(), li.owner);
    }

    function rentedLandsByOwner(address owner) external view returns (uint256) {
        return _rentedBattleSetsOwnersMapping[owner].length();
    }

    function rentedOwnersLandsByIndex(address owner, uint256 idx) external view returns (uint256) {
        return _rentedBattleSetsOwnersMapping[owner].at(idx);
    }

    function rentFromCollection(uint256 id, uint256 landId, uint256[] memory botsIds) nonReentrant whenNotPaused external returns (bool) {
        Collection memory collection = storageContract.getCollection(id);
        require(collection.owner != address(0x0), "Collection not found");
        require(landId != 0 && botsIds.length == 3, "Incorrect token ids");
        require(collection.disbandTs == 0, "Collection disbanded");
        if (collection.whitelist.length > 0) {
            require(addressWhitelisted(collection.whitelist, _msgSender()), "Address not whitelisted");
        }

        if (collection.rentingType == RentingType.FIXED_PRICE && !transferPayment(collection.chargeCoin, collection.price, _msgSender(), collection.owner)) {
            return false;
        }

        safeTransferFromForRent(address(storageContract), _msgSender(), landId, botsIds);

        storageContract.updateCollectionRentedAssets(id, Array256Lib.remove(collection.landIds, landId),
            Array256Lib.removeAll(collection.botsIds, botsIds), Array256Lib.add(collection.rentedLandIds, landId),
            Array256Lib.addAll(collection.rentedBotsIds, botsIds));

        BattleSet memory bs = BattleSet({landId : landId, botsIds : botsIds});
        storageContract.createRenting(bs, collection.rentingType, collection.chargeCoin, collection.price, collection.owner, _msgSender(),
            block.timestamp + defaultRentingDuration, collection.id, collection.perpetual, new address[](0), collection.revenueShare);

        addTokenToRentedTokensList(bs.landId);
        _rentedBattleSetsOwnersMapping[collection.owner].add(landId);

        emit RentCollectionStart(landId, botsIds, id, _msgSender(), collection.owner);
        return true;
    }

    function renewRental(uint256 landId) nonReentrant whenNotPaused external {
        RentingInfo memory ri = storageContract.getRentingInfo(landId);
        require(ri.perpetual || ri.cancelTs == 0, "The listing is not perpetual or cancelled");
        require(ri.renewTs < ri.rentingEndTs - rentingRenewalPeriodGap, "Already renewed for next period");
        require(ri.renter == _msgSender(), "Caller is not renter");
        require(block.timestamp < ri.rentingEndTs && block.timestamp > ri.rentingEndTs - rentingRenewalPeriodGap, "Renew is not available yet");
        if (ri.collectionId != 0) {
            Collection memory collection = storageContract.getCollection(ri.collectionId);
            require(collection.disbandTs == 0, "Collection disbanded");
            require(addressWhitelistedInCollection(collection, _msgSender()), "Player not whitelisted to renew listing");
            require(!ifCollectionAssetNeedsToBeRemoved(ri.collectionId, ri.battleSet.landId, ri.battleSet.botsIds), "Some asset removed from collection");
        }

        if (ri.rentingType == RentingType.FIXED_PRICE && !transferPayment(ri.chargeCoin, ri.price, _msgSender(), ri.owner)) {
            revert("Cannot charge payment");
        }

        storageContract.renewRenting(landId, block.timestamp, ri.rentingEndTs + defaultRentingDuration);

        emit RentRenewed(landId);
    }

    function getTotalRentings() external view returns (uint256) {
        return rentedLands.length;
    }

    function rentedLandByIdx(uint idx) public view returns (uint256) {
        return rentedLands[idx];
    }

    function getFinishedRentingLands(uint256 searchIdxFrom, uint256 searchIdxTo) external view returns (uint256[] memory) {
        uint256[] memory ids = new uint[](searchIdxTo - searchIdxFrom);
        uint finishedCounter = 0;
        for (uint i = searchIdxFrom; i < searchIdxTo; i++) {
            uint256 landId = rentedLandByIdx(i);
            if (storageContract.getRentingInfo(landId).rentingEndTs <= block.timestamp) {
                ids[finishedCounter++] = landId;
            }
        }
        uint[] memory trimmedResult = new uint[](finishedCounter);
        for (uint j = 0; j < finishedCounter; j++) {
            trimmedResult[j] = ids[j];
        }
        return trimmedResult;
    }


    function transferPayment(Coin coin, uint256 price, address from, address to) private returns (bool) {
        IERC20 paymentContract = IERC20(paymentContracts[coin]);
        uint256 fee = getPlatformFee(price);
        uint256 targetAmount = price - fee;
        if (!paymentContract.transferFrom(from, feeCollectorAddress, fee) || !paymentContract.transferFrom(from, to, targetAmount)) {
            return false;
        }
        return true;
    }

    function getPlatformFee(uint256 price) private view returns (uint256){
        return (price * feePercent) / 100;
    }

    function completeRentings(uint256[] memory landIds) external {
        for (uint i = 0; i < landIds.length; i++) {
            completeRenting(landIds[i]);
        }
    }

    function completeRenting(uint256 landId) private {
        RentingInfo memory ri = storageContract.getRentingInfo(landId);
        if (ri.rentingTs == 0 || ri.rentingEndTs > block.timestamp) {
            return;
        }

        storageContract.deleteRenting(landId);

        if (ri.collectionId != 0) {
            completeCollectionRental(ri);
        } else {
            completeBattleSetRental(ri);
        }

        _removeTokenFromRentedTokensList(landId);
        _rentedBattleSetsOwnersMapping[ri.owner].remove(ri.battleSet.landId);

        emit RentEnd(landId, ri.collectionId, ri.renter, ri.owner);
    }

    function completeCollectionRental(RentingInfo memory ri) private {
        Collection memory collection = storageContract.getCollection(ri.collectionId);

        address landReturnAddress = Array256Lib.contains(collection.landsToRemove, ri.battleSet.landId) ? ri.owner : address(storageContract);
        landsContract.transferFrom(ri.renter, landReturnAddress, ri.battleSet.landId);
        for (uint i = 0; i < 3; i++) {
            address botReturnAddress = Array256Lib.contains(collection.botsToRemove, ri.battleSet.botsIds[i]) ? ri.owner : address(storageContract);
            botsContract.transferFrom(ri.renter, botReturnAddress, ri.battleSet.botsIds[i]);
        }

        collection = storageContract.processCollectionRentalEnd(ri);
        if (collection.disbandTs != 0 && collection.rentedLandIds.length == 0 && storageContract.disbandCollection(ri.collectionId)) {
            transferTokens(collection.landIds, collection.botsIds, address(storageContract), collection.owner);
            emit CollectionDisband(ri.collectionId);
        }
    }

    function completeBattleSetRental(RentingInfo memory ri) private {
        address returnTo = ri.owner;
        if (ri.cancelTs == 0 && ri.perpetual) {
            storageContract.createListingInfo(ri.battleSet, ri.rentingType, ri.owner, ri.chargeCoin, ri.price, ri.perpetual,
                ri.whitelist, ri.revenueShare);
            returnTo = address(storageContract);
        }

        landsContract.transferFrom(ri.renter, returnTo, ri.battleSet.landId);
        for (uint i = 0; i < 3; i++) {
            botsContract.transferFrom(ri.renter, returnTo, ri.battleSet.botsIds[i]);
        }
    }

    function transferTokens(uint256[] memory landIds, uint256[] memory botIds, address from, address to) private {
        for (uint i = 0; i < landIds.length; i++) {
            landsContract.transferFrom(from, to, landIds[i]);
        }
        for (uint i = 0; i < botIds.length; i++) {
            botsContract.transferFrom(from, to, botIds[i]);
        }
    }


    function addTokenToRentedTokensList(uint256 tokenId) private {
        rentedLandsIndex[tokenId] = rentedLands.length;
        rentedLands.push(tokenId);
    }


    function _removeTokenFromRentedTokensList(uint256 tokenId) private {
        uint256 lastTokenIndex = rentedLands.length - 1;
        uint256 tokenIndex = rentedLandsIndex[tokenId];

        uint256 lastTokenId = rentedLands[lastTokenIndex];

        rentedLands[tokenIndex] = lastTokenId;
        rentedLandsIndex[lastTokenId] = tokenIndex;

        delete rentedLandsIndex[tokenId];
        rentedLands.pop();
    }

    function safeTransferFromForRent(address from, address to, uint256 landId, uint256[] memory botIds) private {
        landsContract.safeTransferFromForRent(from, to, landId, "");
        for (uint i = 0; i < botIds.length; i++) {
            botsContract.safeTransferFromForRent(from, to, botIds[i], "");
        }
    }

    function addressWhitelisted(address[] memory array, address value) private pure returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return true;
            }
        }
        return false;
    }

    function ifCollectionAssetNeedsToBeRemoved(uint256 collectionId, uint256 landId, uint256[] memory botIds) private view returns (bool) {
        Collection memory collection = storageContract.getCollection(collectionId);
        if (Array256Lib.contains(collection.landsToRemove, landId)) {
            return true;
        }
        for (uint i = 0; i < botIds.length; i++) {
            if (Array256Lib.contains(collection.botsToRemove, botIds[i])) {
                return true;
            }
        }
        return false;
    }

    function addressWhitelistedInCollection(Collection memory collection, address player) private pure returns (bool){
        for (uint i = 0; i < collection.whitelist.length; i++) {
            if (collection.whitelist[i] == player) {
                return true;
            }
        }
        return false;
    }

    /**
    * @dev Pauses operations.
    */
    function setPaused(bool pause) public onlyOwner {
        if (pause) {
            _pause();
        } else {
            _unpause();
        }
    }

}