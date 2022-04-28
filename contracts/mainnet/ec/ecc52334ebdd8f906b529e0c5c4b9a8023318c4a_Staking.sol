// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./interfaces/IRewarder.sol";

import "./EnumerableItems.sol";

/// @title Metaswap Bonded Staking Contract
/// @author Daniel Lee
/// @notice You can use this contract for staking tokens
/// @dev All function calls are currently implemented without side effects
contract Staking is Initializable, OwnableUpgradeable, EnumerableItems {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCastUpgradeable for int256;
    using SafeCastUpgradeable for uint256;

    /// @notice Info of each user.
    /// `amount` LP token amount the user has provided.
    /// `rewardDebt` The amount of reward entitled to the user.
    struct ItemInfo {
        uint256 amount;
        int256 rewardDebt;
        uint256 unbondedAt;
    }

    uint256 private constant ACC_REWARD_PRECISION = 1e12;

    /// @notice Address of reward token contract.
    IERC20Upgradeable public rewardToken;

    /// @notice Address of the LP token.
    IERC20Upgradeable public lpToken;

    /// @notice Rewarder contract of custom token.
    IRewarder public rewarder;

    /********************** Staking params ***********************/

    /// @notice Reward treasury
    address public rewardTreasury;

    /// @notice Unbonding period
    uint256 public unbondPeriod;

    /// @notice Amount of reward token allocated per second.
    uint256 public rewardPerSecond;

    /********************** Staking status ***********************/

    /// @notice reward amount allocated per LP token.
    uint256 public accRewardPerShare;

    /// @notice Last time that the reward is calculated.
    uint256 public lastRewardTime;

    // The next new item's id.
    uint256 private newItemId;

    /// @notice Item of the user that's not in unbonding.
    mapping(address => uint256) public defaultItem;

    /// @notice Info of each user that stakes LP tokens.
    mapping(uint256 => ItemInfo) public itemInfo;

    /// @notice total unbonding LP token amount of all users.
    uint256 public totalUnbondingAmount;

    event Deposit(address indexed user, uint256 itemId, uint256 amount, address indexed to);
    event Withdraw(address indexed user, uint256 itemId, uint256 amount, address indexed to);
    event Harvest(address indexed user, uint256 itemId, uint256 amount);
    event Unbond(address indexed user, uint256 itemId);
    event EmergencyUnbond(address indexed user, uint256 itemId);

    event LogUpdatePool(
        uint256 lastRewardTime,
        uint256 lpSupply,
        uint256 accRewardPerShare
    );
    event LogRewardPerSecond(uint256 rewardPerSecond);
    event LogUnbondingPeriod(uint256 unbondPeriod);
    event LogRewardTreasury(address indexed wallet);
    event LogRewarder(address indexed rewarder);

    modifier onlyOwnerOfItem(uint256 itemId) {
        require(ownerOf(itemId) == msg.sender, "Must be the owner of this item");
        _;
    }

    /**
     * @param _rewardToken The reward token contract address.
     * @param _lpToken The LP token contract address.
     */
    function initialize(
        IERC20Upgradeable _rewardToken,
        IERC20Upgradeable _lpToken,
        uint256 _unbondPeriod
    ) external initializer {
        require(
            address(_rewardToken) != address(0),
            "initialize: reward token address cannot be zero"
        );
        require(
            address(_lpToken) != address(0),
            "initialize: LP token address cannot be zero"
        );

        __Ownable_init();
        __EnumerableItems_init();

        rewardToken = _rewardToken;
        lpToken = _lpToken;
        lastRewardTime = block.timestamp;
        unbondPeriod = _unbondPeriod;
        accRewardPerShare = 0;
        newItemId = 1;
    }

    /**
     * @notice Set the unbondPeriod
     * @param _unbondPeriod The new unbondPeriod
     */
    function setUnbondPeriod(uint256 _unbondPeriod) external onlyOwner {
        unbondPeriod = _unbondPeriod;
        emit LogUnbondingPeriod(unbondPeriod);
    }

    /**
     * @notice Sets the reward per second to be distributed. Can only be called by the owner.
     * @dev Its decimals count is ACC_REWARD_PRECISION
     * @param _rewardPerSecond The amount of reward to be distributed per second.
     */
    function setRewardPerSecond(uint256 _rewardPerSecond) public onlyOwner {
        updatePool();
        rewardPerSecond = _rewardPerSecond;
        emit LogRewardPerSecond(_rewardPerSecond);
    }

    /**
     * @notice set reward wallet
     * @param _wallet address that contains the rewards
     */
    function setRewardTreasury(address _wallet) external onlyOwner {
        rewardTreasury = _wallet;
        emit LogRewardTreasury(_wallet);
    }

    /**
     * @notice set rewarder contract
     * @param _rewarder address that contains the rewarder
     */
    function setRewarder(IRewarder _rewarder) external onlyOwner {
        rewarder = _rewarder;
        emit LogRewarder(address(rewarder));
    }

    /**
     * @notice return available reward amount
     * @return rewardInTreasury reward amount in treasury
     * @return rewardAllowedForThisPool allowed reward amount to be spent by this pool
     */
    function availableReward()
        public
        view
        returns (uint256 rewardInTreasury, uint256 rewardAllowedForThisPool)
    {
        rewardInTreasury = rewardToken.balanceOf(rewardTreasury);
        rewardAllowedForThisPool = rewardToken.allowance(
            rewardTreasury,
            address(this)
        );
    }

    /**
     * @notice View function to see pending reward on frontend.
     * @dev It doens't update accRewardPerShare, it's just a view function.
     *
     *  pending reward = (item.amount * pool.accRewardPerShare) - item.rewardDebt
     *
     * @param _itemId ID of item.
     * @return pending reward for a given item.
     */
    function pendingReward(uint256 _itemId)
        external
        view
        returns (uint256 pending)
    {
        ItemInfo memory item = itemInfo[_itemId];
        if (item.unbondedAt > 0) {
            return 0;
        }

        uint256 lpSupply = lpToken.balanceOf(address(this)) - totalUnbondingAmount;
        uint256 accRewardPerShare_ = accRewardPerShare;

        if (block.timestamp > lastRewardTime && lpSupply != 0) {
            uint256 newReward = (block.timestamp - lastRewardTime) *
                rewardPerSecond;
            accRewardPerShare_ =
                accRewardPerShare_ +
                ((newReward * ACC_REWARD_PRECISION) / lpSupply);
        }
        pending = (((item.amount * accRewardPerShare_) / ACC_REWARD_PRECISION)
            .toInt256() - item.rewardDebt).toUint256();
    }

    /**
     * @notice Update reward variables.
     * @dev Updates accRewardPerShare and lastRewardTime.
     */
    function updatePool() public {
        if (block.timestamp > lastRewardTime) {
            uint256 lpSupply = lpToken.balanceOf(address(this)) - totalUnbondingAmount;
            if (lpSupply > 0) {
                uint256 newReward = (block.timestamp - lastRewardTime) *
                    rewardPerSecond;
                accRewardPerShare =
                    accRewardPerShare +
                    ((newReward * ACC_REWARD_PRECISION) / lpSupply);
            }
            lastRewardTime = block.timestamp;
            emit LogUpdatePool(lastRewardTime, lpSupply, accRewardPerShare);
        }
    }

    /**
     * @notice Deposit LP tokens for staking.
     * @param amount LP token amount to deposit.
     * @param to The receiver of `amount` deposit benefit.
     */
    function deposit(uint256 amount, address to) public {
        require(amount > 0, "Deposit: amount should be above zero");

        uint256 itemId = defaultItem[to];
        if (!_exists(itemId) || ownerOf(itemId) != to) {
            itemId = 0;
            defaultItem[to] = 0;
        }
        if (itemId == 0 || itemInfo[itemId].unbondedAt > 0) {
            _create(to, newItemId);
            itemId = newItemId;
            newItemId = newItemId + 1;
        }
        defaultItem[to] = itemId;

        ItemInfo storage item = itemInfo[itemId];
        require(
            item.unbondedAt + unbondPeriod < block.timestamp,
            "Deposit: Can't deposit in unbonding period"
        );

        updatePool();

        // Effects
        item.amount = item.amount + amount;
        item.rewardDebt = item.rewardDebt + ((amount * accRewardPerShare) / ACC_REWARD_PRECISION).toInt256();

        emit Deposit(to, itemId, amount, to);

        lpToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @notice Starts unbonding period of the user.
     */
    function unbond(uint256 itemId, address to) external onlyOwnerOfItem(itemId) {
        ItemInfo storage item = itemInfo[itemId];
        require(item.unbondedAt == 0, "Unbond: Already unbonding");
        require(item.amount > 0, "Unbond: Nothing to unbond");

        updatePool();
        int256 accumulatedReward = ((item.amount * accRewardPerShare) /
            ACC_REWARD_PRECISION).toInt256();
        uint256 _pendingReward = (accumulatedReward - item.rewardDebt)
            .toUint256();

        // Effects
        item.rewardDebt = 0;
        item.unbondedAt = block.timestamp;
        totalUnbondingAmount = totalUnbondingAmount + item.amount;

        emit Harvest(msg.sender, itemId, _pendingReward);
        emit Unbond(msg.sender, itemId);

        // Interactions
        rewardToken.safeTransferFrom(rewardTreasury, to, _pendingReward);

        if (address(rewarder) != address(0)) {
            rewarder.onMTReward(itemId, to, _pendingReward, item.amount);
        }
    }

    /**
     * @notice Unbond without caring about rewards. EMERGENCY ONLY.
     */
    function emergencyUnbond(uint256 itemId) external onlyOwnerOfItem(itemId) {
        ItemInfo storage item = itemInfo[itemId];
        require(item.unbondedAt == 0, "Unbond: Already unbonding");
        require(item.amount > 0, "Unbond: Nothing to unbond");

        item.rewardDebt = 0;
        item.unbondedAt = block.timestamp;
        totalUnbondingAmount = totalUnbondingAmount + item.amount;

        emit EmergencyUnbond(msg.sender, itemId);
    }

    /**
     * @notice Withdraw LP tokens and harvest rewards to `to`.
     * @param to Receiver of the LP tokens and rewards.
     */
    function withdraw(uint256 itemId, address to) external onlyOwnerOfItem(itemId)  {
        ItemInfo storage item = itemInfo[itemId];
        require(
            item.unbondedAt > 0,
            "Withdraw: Unbond first"
        );
        require(
            item.unbondedAt + unbondPeriod < block.timestamp,
            "Withdraw: Can't withdraw in unbonding period"
        );

        uint256 amount = item.amount;
        item.unbondedAt = 0;
        item.amount = 0;
        totalUnbondingAmount = totalUnbondingAmount - amount;

        if (defaultItem[msg.sender] == itemId) {
            defaultItem[msg.sender] = 0;
        }
        _remove(itemId);

        emit Withdraw(msg.sender, itemId, amount, to);

        lpToken.safeTransfer(to, amount);
    }

    /**
     * @notice Harvest all rewards and send to `to`.
     * @dev Here comes the formula to calculate reward token amount
     * @param to Receiver of rewards.
     */
    function harvestAll(address to) external {
        updatePool();

        for (uint256 index = 0; index < itemCountOf(_msgSender()); index += 1) {
            uint256 itemId = itemOfOwnerByIndex(_msgSender(), index);

            ItemInfo storage item = itemInfo[itemId];
            if (item.unbondedAt + unbondPeriod >= block.timestamp) {
                continue;
            }

            int256 accumulatedReward = ((item.amount * accRewardPerShare) /
                ACC_REWARD_PRECISION).toInt256();
            uint256 _pendingReward = (accumulatedReward - item.rewardDebt)
                .toUint256();

            // Effects
            item.rewardDebt = accumulatedReward;

            emit Harvest(msg.sender, itemId, _pendingReward);

            // Interactions
            if (_pendingReward != 0) {
                rewardToken.safeTransferFrom(rewardTreasury, to, _pendingReward);
            }

            if (address(rewarder) != address(0)) {
                rewarder.onMTReward(itemId, to, _pendingReward, item.amount);
            }
        }
    }

    /**
     * @notice Harvest rewards and send to `to`.
     * @dev Here comes the formula to calculate reward token amount
     * @param to Receiver of rewards.
     */
    function harvest(uint256 itemId, address to) external onlyOwnerOfItem(itemId) {
        ItemInfo storage item = itemInfo[itemId];
        if (item.unbondedAt + unbondPeriod >= block.timestamp) {
            return;
        }

        updatePool();
        int256 accumulatedReward = ((item.amount * accRewardPerShare) /
            ACC_REWARD_PRECISION).toInt256();
        uint256 _pendingReward = (accumulatedReward - item.rewardDebt)
            .toUint256();

        // Effects
        item.rewardDebt = accumulatedReward;

        emit Harvest(msg.sender, itemId, _pendingReward);

        // Interactions
        if (_pendingReward != 0) {
            rewardToken.safeTransferFrom(rewardTreasury, to, _pendingReward);
        }

        if (address(rewarder) != address(0)) {
            rewarder.onMTReward(itemId, to, _pendingReward, item.amount);
        }
    }

    function renounceOwnership() public override onlyOwner {
        revert();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRewarder {
    function onMTReward(uint256 itemId, address recipient, uint256 mtAmount, uint256 newLpAmount) external;
    function pendingTokens(uint256 itemId, uint256 mtAmount) external view returns (IERC20[] memory, uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract EnumerableItems is Initializable {
    // Mapping from owner to list of owned item IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedItems;

    // Mapping from item ID to index of the owner items list
    mapping(uint256 => uint256) private _ownedItemsIndex;

    // Array with all item ids, used for enumeration
    uint256[] private _allItems;

    // Mapping from item id to position in the allItems array
    mapping(uint256 => uint256) private _allItemsIndex;

    // Mapping from item ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to item count
    mapping(address => uint256) private _balances;

    /**
     * @dev Initializes the contract.
     */
    function __EnumerableItems_init() internal initializer {}

    /**
     * @dev Items balance of the owner.
     */
    function itemCountOf(address owner) public view returns (uint256) {
        require(owner != address(0), "EnumerableItems: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev Return owner of item.
     */
    function ownerOf(uint256 itemId) public view returns (address) {
        address owner = _owners[itemId];
        require(owner != address(0), "EnumerableItems: owner query for nonexistent item");
        return owner;
    }

    /**
     * @dev Query item of an owner by index.
     */
    function itemOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < itemCountOf(owner), "EnumerableItems: owner index out of bounds");
        return _ownedItems[owner][index];
    }

    /**
     * @dev Total count of items.
     */
    function totalCount() public view returns (uint256) {
        return _allItems.length;
    }

    /**
     * @dev Query each item by index.
     */
    function itemByIndex(uint256 index) public view returns (uint256) {
        require(index < totalCount(), "EnumerableItems: global index out of bounds");
        return _allItems[index];
    }


    /**
     * @dev Create `itemId` to `to`.
     *
     * Requirements:
     *
     * - `itemId` must not exist.
     * - `to` cannot be the zero address.
     *
     */
    function _create(address to, uint256 itemId) internal {
        require(to != address(0), "EnumerableItems: mint to the zero address");
        require(!_exists(itemId), "EnumerableItems: item already minted");

        _addItemToAllItemsEnumeration(itemId);
        _addItemToOwnerEnumeration(to, itemId);

        _balances[to] += 1;
        _owners[itemId] = to;
    }

    /**
     * @dev Destroys `itemId`.
     * The approval is cleared when the item is burned.
     *
     * Requirements:
     *
     * - `itemId` must exist.
     *
     */
    function _remove(uint256 itemId) internal {
        address owner = ownerOf(itemId);

        _removeItemFromOwnerEnumeration(owner, itemId);
        _removeItemFromAllItemsEnumeration(itemId);

        _balances[owner] -= 1;
        delete _owners[itemId];
    }

    /**
     * @dev Returns whether `itemId` exists.
     *
     * Tokens start existing when they are minted (`_create`),
     * and stop existing when they are burned (`_remove`).
     */
    function _exists(uint256 itemId) internal view returns (bool) {
        return _owners[itemId] != address(0);
    }

    /**
     * @dev Private function to add a item to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given item ID
     * @param itemId uint256 ID of the item to be added to the items list of the given address
     */
    function _addItemToOwnerEnumeration(address to, uint256 itemId) private {
        uint256 length = itemCountOf(to);
        _ownedItems[to][length] = itemId;
        _ownedItemsIndex[itemId] = length;
    }

    /**
     * @dev Private function to add a item to this extension's item tracking data structures.
     * @param itemId uint256 ID of the item to be added to the items list
     */
    function _addItemToAllItemsEnumeration(uint256 itemId) private {
        _allItemsIndex[itemId] = _allItems.length;
        _allItems.push(itemId);
    }

    /**
     * @dev Private function to remove a item from this extension's ownership-tracking data structures. Note that
     * while the item is not assigned a new owner, the `_ownedItemsIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedItems array.
     * @param from address representing the previous owner of the given item ID
     * @param itemId uint256 ID of the item to be removed from the items list of the given address
     */
    function _removeItemFromOwnerEnumeration(address from, uint256 itemId) private {
        // To prevent a gap in from's items array, we store the last item in the index of the item to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastItemIndex = itemCountOf(from) - 1;
        uint256 itemIndex = _ownedItemsIndex[itemId];

        // When the item to delete is the last item, the swap operation is unnecessary
        if (itemIndex != lastItemIndex) {
            uint256 lastItemId = _ownedItems[from][lastItemIndex];

            _ownedItems[from][itemIndex] = lastItemId; // Move the last item to the slot of the to-delete item
            _ownedItemsIndex[lastItemId] = itemIndex; // Update the moved item's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedItemsIndex[itemId];
        delete _ownedItems[from][lastItemIndex];
    }

    /**
     * @dev Private function to remove a item from this extension's item tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allItems array.
     * @param itemId uint256 ID of the item to be removed from the items list
     */
    function _removeItemFromAllItemsEnumeration(uint256 itemId) private {
        // To prevent a gap in the items array, we store the last item in the index of the item to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastItemIndex = _allItems.length - 1;
        uint256 itemIndex = _allItemsIndex[itemId];

        // When the item to delete is the last item, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted item is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeItemFromOwnerEnumeration)
        uint256 lastItemId = _allItems[lastItemIndex];

        _allItems[itemIndex] = lastItemId; // Move the last item to the slot of the to-delete item
        _allItemsIndex[lastItemId] = itemIndex; // Update the moved item's index

        // This also deletes the contents at the last position of the array
        delete _allItemsIndex[itemId];
        _allItems.pop();
    }
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}