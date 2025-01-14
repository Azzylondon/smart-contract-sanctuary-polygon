// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IPoolFactory.sol";
import "./CorePool.sol";

/**
 * @title Elixir Pool Factory
 *
 * @notice ELI Pool Factory manages Elixir Yield farming pools, provides a single
 *      public interface to access the pools, provides an interface for the pools
 *      to mint yield rewards, access pool-related info, update weights, etc.
 *
 * @notice The factory is authorized (via its owner) to register new pools, change weights
 *      of the existing pools, removing the pools (by changing their weights to zero)
 *
 * @dev The factory requires ROLE_TOKEN_CREATOR permission on the ELI token to mint yield
 *      (see `transferYieldTo` function)
 *
 * @author Pedro Bergamini, reviewed by Basil Gorin
 */
contract PoolFactory is Ownable {
  /**
   * @dev Smart contract unique identifier, a random number
   * @dev Should be regenerated each time smart contact source code is changed
   *      and changes smart contract itself is to be redeployed
   * @dev Generated using https://www.random.org/bytes/
   */
  address public eli;
  address public start;

  /**
   * @dev ELI/block determines yield farming reward base
   *      used by the yield pools controlled by the factory
   */
  uint192 public eliPerBlock;

  /**
   * @dev Percent of Reward Reduce Per Block
   */
  uint192 public rewardReducePercent = 97;

  /**
   * @dev The yield is distributed proportionally to pool weights;
   *      total weight is here to help in determining the proportion
   */
  uint32 public totalWeight;

  /**
   * @dev ELI/block decreases by 3% every blocks/update (set to 91252 blocks during deployment);
   *      an update is triggered by executing `updateELIPerBlock` public function
   */
  uint32 public blocksPerUpdate;

  /**
   * @dev End block is the last block when ELI/block can be decreased;
   *      it is implied that yield farming stops after that block
   */
  uint32 public endBlock;

  /** @dev Burn Address */
  address public constant burnAddress =
    0x000000000000000000000000000000000000dEaD;

  /** @dev Burn Percentage */
  uint256 public burnFee = 250; // 2.5% of Liquid Reward will be burned

  /** @dev Maximum Reward Lock Period */
  uint256 public maximumRewardLock = 365 days;
  uint256 public minimumRewardLock = 30 days;

  /**
   * @dev Each time the ELI/block ratio gets updated, the block number
   *      when the operation has occurred gets recorded into `lastRatioUpdate`
   * @dev This block number is then used to check if blocks/update `blocksPerUpdate`
   *      has passed when decreasing yield reward by 3%
   */
  uint32 public lastRatioUpdate;

  /// @dev Maps pool token address (like ELI) -> pool address (like core pool instance)
  mapping(address => address) public pools;

  /// @dev Keeps track of registered pool addresses, maps pool address -> exists flag
  mapping(address => bool) public poolExists;

  /**
   * @dev Fired in createPool() and registerPool()
   *
   * @param _by an address which executed an action
   * @param poolToken pool token address (like ELI)
   * @param poolAddress deployed pool instance address
   * @param weight pool weight
   */
  event PoolRegistered(
    address indexed _by,
    address indexed poolToken,
    address indexed poolAddress,
    uint64 weight
  );

  /**
   * @dev Fired in changePoolWeight()
   *
   * @param _by an address which executed an action
   * @param poolAddress deployed pool instance address
   * @param weight new pool weight
   */
  event WeightUpdated(
    address indexed _by,
    address indexed poolAddress,
    uint32 weight
  );

  /**
   * @dev Fired in updateELIPerBlock()
   *
   * @param _by an address which executed an action
   * @param newEliPerBlock new ELI/block value
   */
  event EliRatioUpdated(address indexed _by, uint256 newEliPerBlock);

  /**
   * @dev Creates/deploys a factory instance
   *
   * @param _eli ELI ERC20 token address
   * @param _eliPerBlock initial ELI/block value for rewards
   * @param _blocksPerUpdate how frequently the rewards gets updated (decreased by 3%), blocks
   * @param _initBlock block number to measure _blocksPerUpdate from
   * @param _endBlock block number when farming stops and rewards cannot be updated anymore
   */
  constructor(
    address _eli,
    uint192 _eliPerBlock,
    uint32 _blocksPerUpdate,
    uint32 _initBlock,
    uint32 _endBlock
  ) {
    // verify the inputs are set
    require(_eliPerBlock > 0, "-1");
    require(_blocksPerUpdate > 0, "-2");
    require(_initBlock > 0, "-3");
    require(_endBlock > _initBlock, "-4");

    // save the inputs into internal state variables
    eli = _eli;
    eliPerBlock = _eliPerBlock;
    blocksPerUpdate = _blocksPerUpdate;
    lastRatioUpdate = _initBlock;
    endBlock = _endBlock;
  }

  /**
   * @notice Given a pool token retrieves corresponding pool address
   *
   * @dev A shortcut for `pools` mapping
   *
   * @param poolToken pool token address (like ELI) to query pool address for
   * @return pool address for the token specified
   */
  function getPoolAddress(address poolToken) external view returns (address) {
    // read the mapping and return
    return pools[poolToken];
  }

  /**
   * @notice Reads pool information for the pool defined by its pool token address,
   *      designed to simplify integration with the front ends
   *
   * @param _poolToken pool token address to query pool information for
   * @return  poolToken pool token addres
   * @return poolAddress pool address
   * @return weight weight of pool
   */
  function getPoolData(address _poolToken)
    public
    view
    returns (
      address poolToken,
      address poolAddress,
      uint32 weight
    )
  {
    // get the pool address from the mapping
    poolAddress = pools[_poolToken];

    // throw if there is no pool registered for the token specified
    require(poolAddress != address(0), "-5");

    // read pool information from the pool smart contract
    // via the pool interface (IPool)
    poolToken = IPool(poolAddress).poolToken();
    weight = IPool(poolAddress).weight();
  }

  /**
   * @dev Verifies if `blocksPerUpdate` has passed since last ELI/block
   *      ratio update and if ELI/block reward can be decreased by 3%
   *
   * @return true if enough time has passed and `updateELIPerBlock` can be executed
   */
  function shouldUpdateRatio() public view returns (bool) {
    // if yield farming period has ended
    if (block.number > endBlock) {
      // ELI/block reward cannot be updated anymore
      return false;
    }

    // check if blocks/update (91252 blocks) have passed since last update
    return block.number >= lastRatioUpdate + blocksPerUpdate;
  }

  /**
   * @dev Creates a core pool (CorePool) and registers it within the factory
   *
   * @dev Can be executed by the pool factory owner only
   *
   * @param poolToken pool token address (like ELI, or ELI/ETH pair)
   * @param initBlock init block to be used for the pool created
   * @param weight weight of the pool to be created
   * @param starterInfo address of starter info contract
   */
  function createPool(
    address poolToken,
    uint64 initBlock,
    uint32 weight,
    address starterInfo
  ) external virtual onlyOwner {
    // create/deploy new core pool instance
    IPool pool = new CorePool(
      eli,
      IPoolFactory(address(this)),
      poolToken,
      initBlock,
      weight,
      starterInfo
    );

    // register it within a factory
    registerPool(address(pool));
  }

  /**
   * @dev Registers an already deployed pool instance within the factory
   *
   * @dev Can be executed by the pool factory owner only
   *
   * @param poolAddr address of the already deployed pool instance
   */
  function registerPool(address poolAddr) public onlyOwner {
    // read pool information from the pool smart contract
    // via the pool interface (IPool)
    address poolToken = IPool(poolAddr).poolToken();
    uint32 weight = IPool(poolAddr).weight();

    // ensure that the pool is not already registered within the factory
    require(pools[poolToken] == address(0), "-6");

    // create pool structure, register it within the factory
    pools[poolToken] = poolAddr;
    poolExists[poolAddr] = true;
    // update total pool weight of the factory
    totalWeight += weight;

    // emit an event
    emit PoolRegistered(msg.sender, poolToken, poolAddr, weight);
  }

  /**
   * @dev Registers an already deployed pool instance within the factory
   *
   * @dev Can be executed by the pool factory owner only
   *
   * @param poolAddr address of the already deployed pool instance
   */
  function removePool(address poolAddr) public onlyOwner {
    // read pool information from the pool smart contract
    // via the pool interface (IPool)
    address poolToken = IPool(poolAddr).poolToken();
    uint32 weight = IPool(poolAddr).weight();

    delete pools[poolToken];
    delete poolExists[poolAddr];
    // update total pool weight of the factory
    totalWeight -= weight;
  }

  /**
   * @notice Decreases ELI/block reward by 3%, can be executed
   *      no more than once per `blocksPerUpdate` blocks
   */
  function updateELIPerBlock() external {
    // checks if ratio can be updated i.e. if blocks/update (91252 blocks) have passed
    require(shouldUpdateRatio(), "-7");

    // decreases ELI/block reward by RewardReducePercent
    eliPerBlock = (eliPerBlock * rewardReducePercent) / 100;

    // set current block as the last ratio update block
    lastRatioUpdate = uint32(block.number);

    // emit an event
    emit EliRatioUpdated(msg.sender, eliPerBlock);
  }

  /**
   * @dev Transfer ELI tokens; executed by ELI Pool only
   *
   * @dev Requires factory to have ROLE_TOKEN_CREATOR permission
   *      on the ELI ERC20 token instance
   *
   * @param _to an address to mint tokens to
   * @param _amount amount of ELI tokens to mint
   */
  function transferYieldTo(
    address _to,
    uint256 _amount,
    uint256 _liquidRewardAmount
  ) external {
    // verify that sender is a pool registered withing the factory
    require(poolExists[msg.sender], "-8");

    uint256 burnAmount = (_liquidRewardAmount * burnFee) / 10000;

    require(_amount > burnAmount, "-9");

    uint256 rewardAmount = _amount - burnAmount;

    IERC20(eli).transfer(burnAddress, burnAmount);
    // send ELI tokens as required
    IERC20(eli).transfer(_to, rewardAmount);
  }

  /**
   * @dev Changes the weight of the pool;
   *      executed by the pool itself or by the factory owner
   *
   * @param poolAddr address of the pool to change weight for
   * @param weight new weight value to set to
   */
  function changePoolWeight(address poolAddr, uint32 weight)
    external
    onlyOwner
  {
    // recalculate total weight
    totalWeight = totalWeight + weight - IPool(poolAddr).weight();

    // set the new pool weight
    IPool(poolAddr).setWeight(weight);

    // emit an event
    emit WeightUpdated(msg.sender, poolAddr, weight);
  }

  /** @dev set burn fee function */
  function setBurnFee(uint256 _burnFee) external onlyOwner {
    burnFee = _burnFee;
  }

  /** @dev set reward lock period */

  function setRewardLockLimit(uint256 _minLock, uint256 _maxLock)
    external
    onlyOwner
  {
    minimumRewardLock = _minLock;
    maximumRewardLock = _maxLock;
  }

  function setAddresses(address _eli, address _start) external onlyOwner {
    eli = _eli;
    start = _start;
  }

  function setGeneralInfo(
    address _eli,
    uint192 _eliPerBlock,
    uint192 _rewardReducePercent,
    uint32 _blocksPerUpdate,
    uint32 _initBlock,
    uint32 _endBlock
  ) external onlyOwner {
    // save the inputs into internal state variables
    eli = _eli;
    eliPerBlock = _eliPerBlock;
    rewardReducePercent = _rewardReducePercent;
    blocksPerUpdate = _blocksPerUpdate;
    lastRatioUpdate = _initBlock;
    endBlock = _endBlock;
  }

  function addPoolAddress(address _pool) external onlyOwner {
    poolExists[_pool] = true;
  }

  function removePoolAddress(address _pool) external onlyOwner {
    delete poolExists[_pool];
  }

  function emergencyWithdraw(address _to) external onlyOwner {
    IERC20(eli).transfer(_to, IERC20(eli).balanceOf(address(this)));
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

/**
 * @title Illuvium Pool
 *
 * @notice An abstraction representing a pool, see IlluviumPoolBase for details
 *
 * @author Pedro Bergamini, reviewed by Basil Gorin
 */
interface IPool {
  /**
   * @dev Deposit is a key data structure used in staking,
   *      it represents a unit of stake with its amount, weight and term (time interval)
   */
  struct Deposit {
    // @dev token amount staked
    uint256 tokenAmount;
    // @dev stake weight
    uint256 weight;
    // @dev liquid percentage;
    uint256 liquidPercentage;
    // @dev locking period - from
    uint64 lockedFrom;
    // @dev locking period - until
    uint64 lockedUntil;
    // @dev indicates if the stake was created as a yield reward
    bool isYield;
  }

  /// @dev Data structure representing token holder using a pool
  struct User {
    // @dev Total staked amount
    uint256 tokenAmount;
    //@dev Total Liquid Staked Amount
    uint256 liquidAmount;
    // @dev Total weight
    uint256 totalWeight;
    // @dev Liquid weight;
    uint256 liquidWeight;
    // @dev Auxiliary variable for yield calculation
    uint256 subYieldRewards;
    // @dev Auxiliary variable for vault rewards calculation
    uint256 subVaultRewards;
    // @dev timestamp of last stake
    uint256 lastStakedTimestamp;
    // @dev timestamp of last unstake
    uint256 lastUnstakedTimestamp;
    // @dev timestamp of first stake
    uint256 firstStakedTimestamp;
    // @dev timestamp of last invest
    uint256 lastInvestTimestamp;
    // @dev An array of holder's deposits
    Deposit[] deposits;
  }

  function eli() external view returns (address);

  function poolToken() external view returns (address);

  function weight() external view returns (uint32);

  function lastYieldDistribution() external view returns (uint64);

  function yieldRewardsPerWeight() external view returns (uint256);

  function usersLockingWeight() external view returns (uint256);

  function pendingYieldRewards(address _user) external view returns (uint256);

  function balanceOf(address _user) external view returns (uint256);

  function getDeposit(address _user, uint256 _depositId)
    external
    view
    returns (Deposit memory);

  function getDepositsLength(address _user) external view returns (uint256);

  function stake(uint256 _amount, uint64 _lockedUntil) external;

  function stakeFor(
    address _staker,
    uint256 _amount,
    uint64 _lockUntil
  ) external;

  function unstake(uint256 _depositId, uint256 _amount) external;

  function sync() external;

  function processRewards() external;

  function setWeight(uint32 _weight) external;

  function isLongStaker(address _sender) external view returns (bool);

  function updateLastInvestTimestamp(address _user, uint256 _timestamp) external;

  function addPresaleAddress(address _presale) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IPoolFactory {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function endBlock() external view returns (uint32);

  function eliPerBlock() external view returns (uint192);

  function totalWeight() external view returns (uint32);

  function transferYieldTo(
    address _to,
    uint256 _amount,
    uint256 _liquidRewardAmount
  ) external;

  function unstakeBurnFee(address _tokenAddress)
    external
    view
    returns (uint256);

  function burnAddress() external view returns (address);

  function shouldUpdateRatio() external view returns (bool);

  function updateELIPerBlock() external;

  function getPoolAddress(address poolToken) external view returns (address);

  function owner() external view returns (address);

  function maximumRewardLock() external view returns (uint256);

  function minimumRewardLock() external view returns (uint256);

  function poolExists(address) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./PoolBase.sol";

/**
 * @title Elixir Core Pool
 *
 * @notice Core pools represent permanent pools like ELIXIR or ELIXIR/ETH Pair pool,
 *      core pools allow staking for arbitrary periods of time up to 1 year
 *
 * @dev See PoolBase for more details
 *
 */
contract CorePool is PoolBase, Initializable {
  /// @dev Link to deployed ElixirVault instance
  address public vault;

  /// @dev Used to calculate vault rewards
  /// @dev This value is different from "reward per token" used in locked pool
  /// @dev Note: stakes are different in duration and "weight" reflects that
  uint256 public vaultRewardsPerWeight;

  /// @dev Pool tokens value available in the pool;
  ///      pool token examples are ELIXIR (ELIXIR core pool) or ELIXIR/ETH pair (LP core pool)
  /// @dev For LP core pool this value doesnt' count for ELIXIR tokens received as Vault rewards
  ///      while for ELIXIR core pool it does count for such tokens as well
  uint256 public poolTokenReserve;

  /**
   * @dev Fired in receiveVaultRewards()
   *
   * @param _by an address that sent the rewards, always a vault
   * @param amount amount of tokens received
   */
  event VaultRewardsReceived(address indexed _by, uint256 amount);

  /**
   * @dev Fired in _processVaultRewards() and dependent functions, like processRewards()
   *
   * @param _by an address which executed the function
   * @param _to an address which received a reward
   * @param amount amount of reward received
   */
  event VaultRewardsClaimed(
    address indexed _by,
    address indexed _to,
    uint256 amount
  );

  /**
   * @dev Fired in setVault()
   *
   * @param _by an address which executed the function, always a factory owner
   */
  event VaultUpdated(address indexed _by, address _fromVal, address _toVal);

  /**
   * @dev Creates/deploys an instance of the core pool
   *
   * @param _eli ELI ERC20 Token ElixirERC20 address
   * @param _factory factory PoolFactory instance/address
   * @param _poolToken token the pool operates on, for example ELIXIR or ELIXIR/ETH pair
   * @param _initBlock initial block used to calculate the rewards
   * @param _weight number representing a weight of the pool, actual weight fraction
   *      is calculated as that number divided by the total pools weight and doesn't exceed one
   * @param _starterInfo addres of starter info contract
   */
  constructor(
    address _eli,
    IPoolFactory _factory,
    address _poolToken,
    uint64 _initBlock,
    uint32 _weight,
    address _starterInfo
  ) PoolBase(_eli, _factory, _poolToken, _initBlock, _weight, _starterInfo) {}

  function initialize(
    address _eli,
    IPoolFactory _factory,
    address _poolToken,
    uint64 _initBlock,
    uint32 _weight
  ) public initializer {
    super.initConfig(_eli, _factory, _poolToken, _initBlock, _weight);
  }

  /**
   * @notice Calculates current vault rewards value available for address specified
   *
   * @dev Performs calculations based on current smart contract state only,
   *      not taking into account any additional time/blocks which might have passed
   *
   * @param _staker an address to calculate vault rewards value for
   * @return pending calculated vault reward value for the given address
   */
  function pendingVaultRewards(address _staker)
    public
    view
    returns (uint256 pending)
  {
    User memory user = users[_staker];

    pending =
      weightToReward(user.totalWeight, vaultRewardsPerWeight) -
      user.subVaultRewards;
  }

  /**
   * @dev Executed only by the factory owner to Set the vault
   *
   * @param _vault an address of deployed ElixirVault instance
   */
  function setVault(address _vault) external {
    // verify function is executed by the factory owner
    require(factory.owner() == msg.sender, "-1");

    // verify input is set
    require(_vault != address(0), "-2");

    // emit an event
    emit VaultUpdated(msg.sender, vault, _vault);

    // update vault address
    vault = _vault;
  }

  /**
   * @dev Executed by the vault to transfer vault rewards ELIXIR from the vault
   *      into the pool
   *
   * @dev This function is executed only for ELIXIR core pools
   *
   * @param _rewardsAmount amount of ELIXIR rewards to transfer into the pool
   */
  function receiveVaultRewards(uint256 _rewardsAmount) external {
    require(msg.sender == vault, "-3");
    // return silently if there is no reward to receive
    if (_rewardsAmount == 0) {
      return;
    }
    require(usersLockingWeight != 0, "-4");

    transferEliFrom(msg.sender, address(this), _rewardsAmount);

    vaultRewardsPerWeight += rewardToWeight(_rewardsAmount, usersLockingWeight);

    // update `poolTokenReserve` only if this is a ELIXIR Core Pool
    if (poolToken == eli) {
      poolTokenReserve += _rewardsAmount;
    }

    emit VaultRewardsReceived(msg.sender, _rewardsAmount);
  }

  /**
   * @notice Service function to calculate and pay pending vault and yield rewards to the sender
   *
   * @dev Internally executes similar function `_processRewards` from the parent smart contract
   *      to calculate and pay yield rewards; adds vault rewards processing
   *
   * @dev Can be executed by anyone at any time, but has an effect only when
   *      executed by deposit holder and when at least one block passes from the
   *      previous reward processing
   * @dev Executed internally when "staking as a pool" (`stakeAsPool`)
   * @dev When timing conditions are not met (executed too frequently, or after factory
   *      end block), function doesn't throw and exits silently
   *
   */
  function processRewards() external override {
    _processRewards(msg.sender, true);
  }

  /**
   * @dev Executed internally by the pool itself (from the parent `PoolBase` smart contract)
   *      as part of yield rewards processing logic (`PoolBase._processRewards` function)
   *
   * @param _staker an address which stakes (the yield reward)
   * @param _amount amount to be staked (yield reward amount)
   * @param _liquidPercent the liquid percentage of this stake
   * @param _rewardLockPeriod the amout of seconds that the deposit will be locked
   */
  function stakeAsPool(
    address _staker,
    uint256 _amount,
    uint256 _liquidPercent,
    uint256 _rewardLockPeriod
  ) external {
    require(factory.poolExists(msg.sender), "-5");
    _sync();
    User storage user = users[_staker];
    if (user.tokenAmount > 0) {
      _processRewards(_staker, false);
    }
    uint256 depositWeight = _amount * YEAR_STAKE_WEIGHT_MULTIPLIER;
    Deposit memory newDeposit = Deposit({
      tokenAmount: _amount,
      lockedFrom: uint64(block.timestamp),
      lockedUntil: uint64(block.timestamp + _rewardLockPeriod),
      weight: depositWeight,
      liquidPercentage: _liquidPercent,
      isYield: true
    });
    user.tokenAmount += _amount;
    user.totalWeight += depositWeight;
    user.deposits.push(newDeposit);

    usersLockingWeight += depositWeight;

    user.subYieldRewards = weightToReward(
      user.totalWeight,
      yieldRewardsPerWeight
    );
    user.subVaultRewards = weightToReward(
      user.totalWeight,
      vaultRewardsPerWeight
    );

    // update `poolTokenReserve` only if this is a LP Core Pool (stakeAsPool can be executed only for LP pool)
    poolTokenReserve += _amount;
  }

  /**
   * @inheritdoc PoolBase
   *
   * @dev Additionally to the parent smart contract, updates vault rewards of the holder,
   *      and updates (increases) pool token reserve (pool tokens value available in the pool)
   */
  function _stake(
    address _staker,
    uint256 _amount,
    uint64 _lockedUntil,
    bool _isYield,
    uint256 _liquidPercent
  ) internal override {
    super._stake(_staker, _amount, _lockedUntil, _isYield, _liquidPercent);
    User storage user = users[_staker];
    user.subVaultRewards = weightToReward(
      user.totalWeight,
      vaultRewardsPerWeight
    );

    poolTokenReserve += _amount;
  }

  /**
   * @inheritdoc PoolBase
   *
   * @dev Additionally to the parent smart contract, updates vault rewards of the holder,
   *      and updates (decreases) pool token reserve (pool tokens value available in the pool)
   */
  function _unstake(
    address _staker,
    uint256 _depositId,
    uint256 _amount
  ) internal override {
    User storage user = users[_staker];
    Deposit memory stakeDeposit = user.deposits[_depositId];
    require(
      stakeDeposit.lockedFrom == 0 ||
        block.timestamp > stakeDeposit.lockedUntil,
      "-6"
    );
    poolTokenReserve -= _amount;
    super._unstake(_staker, _depositId, _amount);
    user.subVaultRewards = weightToReward(
      user.totalWeight,
      vaultRewardsPerWeight
    );
  }

  /**
   * @inheritdoc PoolBase
   *
   * @dev Additionally to the parent smart contract, processes vault rewards of the holder,
   *      and for ELIXIR pool updates (increases) pool token reserve (pool tokens value available in the pool)
   */
  function _processRewards(address _staker, bool _withUpdate)
    internal
    override
    returns (uint256 pendingYield)
  {
    _processVaultRewards(_staker);
    pendingYield = super._processRewards(_staker, _withUpdate);

    // update `poolTokenReserve` only if this is a ELIXIR Core Pool
    if (poolToken == eli) {
      poolTokenReserve += pendingYield;
    }
  }

  /**
   * @dev Used internally to process vault rewards for the staker
   *
   * @param _staker address of the user (staker) to process rewards for
   */
  function _processVaultRewards(address _staker) private {
    User storage user = users[_staker];
    uint256 pendingVaultClaim = pendingVaultRewards(_staker);
    if (pendingVaultClaim == 0) return;
    // read ELIXIR token balance of the pool via standard ERC20 interface
    uint256 eliBalance = IERC20(eli).balanceOf(address(this));
    require(eliBalance >= pendingVaultClaim, "-7");

    // update `poolTokenReserve` only if this is a ELIXIR Core Pool
    if (poolToken == eli) {
      // protects against rounding errors
      poolTokenReserve -= pendingVaultClaim > poolTokenReserve
        ? poolTokenReserve
        : pendingVaultClaim;
    }

    user.subVaultRewards = weightToReward(
      user.totalWeight,
      vaultRewardsPerWeight
    );

    // transfer fails if pool ELIXIR balance is not enough - which is a desired behavior
    transferEli(_staker, pendingVaultClaim);

    emit VaultRewardsClaimed(msg.sender, _staker, pendingVaultClaim);
  }

  /**
   * @dev Executes SafeERC20.safeTransfer on a pool token
   *
   * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
   */
  function transferEli(address _to, uint256 _value) internal nonReentrant {
    // just delegate call to the target
    SafeERC20.safeTransfer(IERC20(eli), _to, _value);
  }

  /**
   * @dev Executes SafeERC20.safeTransferFrom on a pool token
   *
   * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
   */
  function transferEliFrom(
    address _from,
    address _to,
    uint256 _value
  ) internal nonReentrant {
    // just delegate call to the target
    SafeERC20.safeTransferFrom(IERC20(eli), _from, _to, _value);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IPool.sol";
import "./interfaces/ICorePool.sol";
import "./interfaces/IPoolFactory.sol";
import "./interfaces/IStarterInfo.sol";

/**
 * @title Pool Base
 *
 * @notice An abstract contract containing common logic for any pool,
 *      be it a flash pool (temporary pool like SNX) or a core pool (permanent pool like ELIXIR/ETH or ELIXIR pool)
 *
 * @dev Deployment and initialization.
 *      Any pool deployed must be bound to the deployed pool factory (IPoolFactory)
 *      Additionally, 3 token instance addresses must be defined on deployment:
 *          - ELIXIR token address
 *          - pool token address, it can be ELIXIR token address, ELIXIR/ETH pair address, and others
 *
 * @dev Pool weight defines the fraction of the yield current pool receives among the other pools,
 *      pool factory is responsible for the weight synchronization between the pools.
 * @dev The weight is logically 10% for ELIXIR pool and 90% for ELIXIR/ETH pool.
 *      Since Solidity doesn't support fractions the weight is defined by the division of
 *      pool weight by total pools weight (sum of all registered pools within the factory)
 * @dev For ELIXIR Pool we use 100 as weight and for ELIXIR/ETH pool - 900.
 *
 */
abstract contract PoolBase is IPool, ReentrancyGuard {
  address public override eli;

  address[] public history;
  /// @dev Token holder storage, maps token holder address to their data record
  mapping(address => User) public users;

  /// @dev Link to the pool factory IPoolFactory instance
  IPoolFactory public factory;

  /// @dev Link to the pool token instance, for example ELIXIR or ELIXIR/ETH pair
  address public override poolToken;

  /// @dev Pool weight, 100 for ELIXIR pool or 900 for ELIXIR/ETH
  uint32 public override weight;

  /// @dev Block number of the last yield distribution event
  uint64 public override lastYieldDistribution;

  /// @dev Used to calculate yield rewards
  /// @dev This value is different from "reward per token" used in locked pool
  /// @dev Note: stakes are different in duration and "weight" reflects that
  uint256 public override yieldRewardsPerWeight;

  /// @dev Used to calculate yield rewards, keeps track of the tokens weight locked in staking
  uint256 public override usersLockingWeight;

  /**
   * @dev Stake weight is proportional to deposit amount and time locked, precisely
   *      "deposit amount wei multiplied by (fraction of the year locked plus one)"
   * @dev To avoid significant precision loss due to multiplication by "fraction of the year" [0, 1],
   *      weight is stored multiplied by 1e6 constant, as an integer
   * @dev Corner case 1: if time locked is zero, weight is deposit amount multiplied by 1e6
   * @dev Corner case 2: if time locked is one year, fraction of the year locked is one, and
   *      weight is a deposit amount multiplied by 2 * 1e6
   */
  uint256 internal WEIGHT_MULTIPLIER = 1e6;

  /** @dev Stake weight for Liquid Guys (its 1/10 of Normal Weight Multiplier)
   */
  uint256 internal LIQUID_MULTIPLIER = 1e5;

  /**
   * @dev When we know beforehand that staking is done for a year, and fraction of the year locked is one,
   *      we use simplified calculation and use the following constant instead previos one
   */
  uint256 internal YEAR_STAKE_WEIGHT_MULTIPLIER = 2 * WEIGHT_MULTIPLIER;

  /**
   * @dev Rewards per weight are stored multiplied by 1e12, as integers.
   */
  uint256 internal REWARD_PER_WEIGHT_MULTIPLIER = 1e12;

  /**
   * @dev burn fee for each fee cycle: [5%, 3%, 1%, 0.5%, 0%]
   */
  uint256[] public burnFees = [500, 300, 100, 50, 0];
  /**
   * @dev days of each fee cycle
   */
  uint256[] public feeCycle = [2 days, 5 days, 10 days, 14 days];

  /**
   * @dev days of min stake to be Diamond
   */
  uint256 public minStakeTimeForDiamond = 7 days;

  mapping(address => bool) public presales;

  /**
   * @dev starter devs information
   */
  IStarterInfo public starterInfo;

  /**
   * @dev Fired in _stake() and stake()
   *
   * @param _by an address which performed an operation, usually token holder
   * @param _from token holder address, the tokens will be returned to that address
   * @param amount amount of tokens staked
   */
  event Staked(address indexed _by, address indexed _from, uint256 amount);

  /**
   * @dev Fired in _updateStakeLock() and updateStakeLock()
   *
   * @param _by an address which performed an operation
   * @param depositId updated deposit ID
   * @param lockedFrom deposit locked from value
   * @param lockedUntil updated deposit locked until value
   */
  event StakeLockUpdated(
    address indexed _by,
    uint256 depositId,
    uint64 lockedFrom,
    uint64 lockedUntil
  );

  /**
   * @dev Fired in _unstake() and unstake()
   *
   * @param _by an address which performed an operation, usually token holder
   * @param _to an address which received the unstaked tokens, usually token holder
   * @param amount amount of tokens unstaked
   */
  event Unstaked(address indexed _by, address indexed _to, uint256 amount);

  /**
   * @dev Fired in _sync(), sync() and dependent functions (stake, unstake, etc.)
   *
   * @param _by an address which performed an operation
   * @param yieldRewardsPerWeight updated yield rewards per weight value
   * @param lastYieldDistribution usually, current block number
   */
  event Synchronized(
    address indexed _by,
    uint256 yieldRewardsPerWeight,
    uint64 lastYieldDistribution
  );

  /**
   * @dev Fired in _processRewards(), processRewards() and dependent functions (stake, unstake, etc.)
   *
   * @param _by an address which performed an operation
   * @param _to an address which claimed the yield reward
   * @param amount amount of yield paid
   */
  event YieldClaimed(address indexed _by, address indexed _to, uint256 amount);

  /**
   * @dev Fired in setWeight()
   *
   * @param _by an address which performed an operation, always a factory
   * @param _fromVal old pool weight value
   * @param _toVal new pool weight value
   */
  event PoolWeightUpdated(address indexed _by, uint32 _fromVal, uint32 _toVal);

  /**
   * @dev Fired in setConfiguration()
   *
   * @param _by an address which performed an operation, always a factory
   * @param _fromRewardPerWeightMultiplier old value of REWARD_PER_WEIGHT_MULTIPLIER
   * @param _toRewardPerWeightMultiplier new value of REWARD_PER_WEIGHT_MULTIPLIER
   * @param _fromYearStakeWeightMultiplier old value of YEAR_STAKE_WEIGHT_MULTIPLIER
   * @param _toYearStakeWeightMultiplier new value of YEAR_STAKE_WEIGHT_MULTIPLIER
   * @param _fromWeightMultiplier old value of WEIGHT_MULTIPLIER
   * @param _toWeightMultiplier new value of WEIGHT_MULTIPLIER
   * @param _fromLiquidMultiplier old value of LIQUID_MULTIPLIER
   * @param _toLiquidMultiplier new value of LIQUID_MULTIPLIER
   */
  event PoolConfigurationUpdated(
    address indexed _by,
    uint256 _fromRewardPerWeightMultiplier,
    uint256 _toRewardPerWeightMultiplier,
    uint256 _fromYearStakeWeightMultiplier,
    uint256 _toYearStakeWeightMultiplier,
    uint256 _fromWeightMultiplier,
    uint256 _toWeightMultiplier,
    uint256 _fromLiquidMultiplier,
    uint256 _toLiquidMultiplier
  );

  modifier onlyStarterDevOrFactory() {
    require(
      starterInfo.getStarterDev(msg.sender) ||
        starterInfo.getPresaleFactory() == msg.sender,
      "-1"
    );
    _;
  }

  /**
   * @dev Overridden in sub-contracts to construct the pool
   *
   * @param _eli ELI ERC20 Token ElixirERC20 address
   * @param _factory Pool factory IPoolFactory instance/address
   * @param _poolToken token the pool operates on, for example ELIXIR or ELIXIR/ETH pair
   * @param _initBlock initial block used to calculate the rewards
   *      note: _initBlock can be set to the future effectively meaning _sync() calls will do nothing
   * @param _weight number representing a weight of the pool, actual weight fraction
   *      is calculated as that number divided by the total pools weight and doesn't exceed one
   */
  constructor(
    address _eli,
    IPoolFactory _factory,
    address _poolToken,
    uint64 _initBlock,
    uint32 _weight,
    address _starterInfo
  ) {
    require(address(_factory) != address(0), "-2");
    require(_poolToken != address(0), "-3");
    require(_initBlock != 0, "-4");
    require(_weight != 0, "-5");
    require(_starterInfo != address(0), "-6");

    // save the inputs into internal state variables
    eli = _eli;
    factory = _factory;
    poolToken = _poolToken;
    weight = _weight;
    starterInfo = IStarterInfo(_starterInfo);

    // init the dependent internal state variables
    lastYieldDistribution = _initBlock;
  }

  function initConfig(
    address _eli,
    IPoolFactory _factory,
    address _poolToken,
    uint64 _initBlock,
    uint32 _weight
  ) internal {
    eli = _eli;
    factory = _factory;
    poolToken = _poolToken;
    weight = _weight;
    lastYieldDistribution = _initBlock;
  }

  /**
   * @notice Calculates current yield rewards value available for address specified
   *
   * @param _staker an address to calculate yield rewards value for
   * @return calculated yield reward value for the given address
   */
  function pendingYieldRewards(address _staker)
    external
    view
    override
    returns (uint256)
  {
    // `newYieldRewardsPerWeight` will store stored or recalculated value for `yieldRewardsPerWeight`
    uint256 newYieldRewardsPerWeight;

    // if smart contract state was not updated recently, `yieldRewardsPerWeight` value
    // is outdated and we need to recalculate it in order to calculate pending rewards correctly
    if (block.number > lastYieldDistribution && usersLockingWeight != 0) {
      uint256 endBlock = factory.endBlock();
      uint256 multiplier = block.number > endBlock
        ? endBlock - lastYieldDistribution
        : block.number - lastYieldDistribution;
      uint256 eliRewards = (multiplier * weight * factory.eliPerBlock()) /
        factory.totalWeight();

      // recalculated value for `yieldRewardsPerWeight`
      newYieldRewardsPerWeight =
        rewardToWeight(eliRewards, usersLockingWeight) +
        yieldRewardsPerWeight;
    } else {
      // if smart contract state is up to date, we don't recalculate
      newYieldRewardsPerWeight = yieldRewardsPerWeight;
    }

    // based on the rewards per weight value, calculate pending rewards;
    User memory user = users[_staker];
    uint256 pending = weightToReward(
      user.totalWeight,
      newYieldRewardsPerWeight
    ) - user.subYieldRewards;

    return pending;
  }

  /**
   * @notice Returns total staked token balance for the given address
   *
   * @param _user an address to query balance for
   * @return total staked token balance
   */
  function balanceOf(address _user) external view override returns (uint256) {
    // read specified user token amount and return
    return users[_user].tokenAmount;
  }

  /**
   * @notice Returns information on the given deposit for the given address
   *
   * @dev See getDepositsLength
   *
   * @param _user an address to query deposit for
   * @param _depositId zero-indexed deposit ID for the address specified
   * @return deposit info as Deposit structure
   */
  function getDeposit(address _user, uint256 _depositId)
    external
    view
    override
    returns (Deposit memory)
  {
    // read deposit at specified index and return
    return users[_user].deposits[_depositId];
  }

  /**
   * @notice Returns number of deposits for the given address. Allows iteration over deposits.
   *
   * @dev See getDeposit
   *
   * @param _user an address to query deposit length for
   * @return number of deposits for the given address
   */
  function getDepositsLength(address _user)
    external
    view
    override
    returns (uint256)
  {
    // read deposits array length and return
    return users[_user].deposits.length;
  }

  /**
   * @notice Stakes specified amount of tokens for the specified amount of time,
   *      and pays pending yield rewards if any
   *
   * @dev Requires amount to stake to be greater than zero
   *
   * @param _amount amount of tokens to stake
   * @param _lockUntil stake period as unix timestamp; zero means no locking
   */
  function stake(uint256 _amount, uint64 _lockUntil) external override {
    // delegate call to an internal function
    _stake(msg.sender, _amount, _lockUntil, false, 0);
    history.push(msg.sender);
  }

  /**
   * @notice Stakes specified amount of tokens to an user for the specified amount of time,
   *      and pays pending yield rewards if any
   *
   * @dev Requires amount to stake to be greater than zero
   *
   * @param _staker address to stake
   * @param _amount amount of tokens to stake
   * @param _lockUntil stake period as unix timestamp; zero means no locking
   */
  function stakeFor(
    address _staker,
    uint256 _amount,
    uint64 _lockUntil
  ) external override {
    require(_staker != msg.sender, "-7");
    // delegate call to an internal function
    _stake(_staker, _amount, _lockUntil, false, 0);
    history.push(_staker);
  }

  /**
   * @notice Unstakes specified amount of tokens, and pays pending yield rewards if any
   *
   * @dev Requires amount to unstake to be greater than zero
   *
   * @param _depositId deposit ID to unstake from, zero-indexed
   * @param _amount amount of tokens to unstake
   */
  function unstake(uint256 _depositId, uint256 _amount) external override {
    // delegate call to an internal function
    _unstake(msg.sender, _depositId, _amount);
    history.push(msg.sender);
  }

  /**
   * @notice Extends locking period for a given deposit
   *
   * @dev Requires new lockedUntil value to be:
   *      higher than the current one, and
   *      in the future, but
   *      no more than 1 year in the future
   *
   * @param depositId updated deposit ID
   * @param lockedUntil updated deposit locked until value
   */
  function updateStakeLock(uint256 depositId, uint64 lockedUntil) external {
    // sync and call processRewards
    _sync();
    _processRewards(msg.sender, false);
    // delegate call to an internal function
    _updateStakeLock(msg.sender, depositId, lockedUntil);
  }

  /**
   * @notice Service function to synchronize pool state with current time
   *
   * @dev Can be executed by anyone at any time, but has an effect only when
   *      at least one block passes between synchronizations
   * @dev Executed internally when staking, unstaking, processing rewards in order
   *      for calculations to be correct and to reflect state progress of the contract
   * @dev When timing conditions are not met (executed too frequently, or after factory
   *      end block), function doesn't throw and exits silently
   */
  function sync() external override {
    // delegate call to an internal function
    _sync();
  }

  /**
   * @notice Service function to calculate and pay pending yield rewards to the sender
   *
   * @dev Can be executed by anyone at any time, but has an effect only when
   *      executed by deposit holder and when at least one block passes from the
   *      previous reward processing
   * @dev Executed internally when staking and unstaking, executes sync() under the hood
   *      before making further calculations and payouts
   * @dev When timing conditions are not met (executed too frequently, or after factory
   *      end block), function doesn't throw and exits silently
   *
   */
  function processRewards() external virtual override {
    // delegate call to an internal function
    _processRewards(msg.sender, true);
  }

  /**
   * @dev Executed by the factory to modify pool weight; the factory is expected
   *      to keep track of the total pools weight when updating
   *
   * @dev Set weight to zero to disable the pool
   *
   * @param _weight new weight to set for the pool
   */
  function setWeight(uint32 _weight) external override {
    // verify function is executed by the factory
    require(msg.sender == address(factory), "-8");

    // emit an event logging old and new weight values
    emit PoolWeightUpdated(msg.sender, weight, _weight);

    // set the new weight value
    weight = _weight;
  }

  /**
   * @dev Similar to public pendingYieldRewards, but performs calculations based on
   *      current smart contract state only, not taking into account any additional
   *      time/blocks which might have passed
   *
   * @param _staker an address to calculate yield rewards value for
   * @return pending calculated yield reward value for the given address
   */
  function _pendingYieldRewards(address _staker)
    internal
    view
    returns (uint256 pending)
  {
    // read user data structure into memory
    User memory user = users[_staker];

    // and perform the calculation using the values read
    return
      weightToReward(user.totalWeight, yieldRewardsPerWeight) -
      user.subYieldRewards;
  }

  /**
   * @dev Used internally, mostly by children implementations, see stake()
   *
   * @param _staker an address which stakes tokens and which will receive them back
   * @param _amount amount of tokens to stake
   * @param _lockUntil stake period as unix timestamp; zero means no locking
   * @param _isYield a flag indicating if that stake is created to store yield reward
   *      from the previously unstaked stake
   */
  function _stake(
    address _staker,
    uint256 _amount,
    uint64 _lockUntil,
    bool _isYield,
    uint256 _liquidPercent
  ) internal virtual {
    // validate the inputs
    require(_amount != 0, "-9");
    require(
      _lockUntil == 0 ||
        (_lockUntil > block.timestamp &&
          _lockUntil - block.timestamp <= 365 days),
      "-10"
    );

    // update smart contract state
    _sync();

    // get a link to user data struct, we will write to it later
    User storage user = users[_staker];
    // process current pending rewards if any
    if (user.tokenAmount > 0) {
      _processRewards(_staker, false);
    }

    // in most of the cases added amount `addedAmount` is simply `_amount`
    // however for deflationary tokens this can be different

    // read the current balance
    uint256 previousBalance = IERC20(poolToken).balanceOf(address(this));
    // transfer `_amount`; note: some tokens may get burnt here
    transferPoolTokenFrom(address(msg.sender), address(this), _amount);
    // read new balance, usually this is just the difference `previousBalance - _amount`
    uint256 newBalance = IERC20(poolToken).balanceOf(address(this));
    // calculate real amount taking into account deflation
    uint256 addedAmount = newBalance - previousBalance;

    if (user.firstStakedTimestamp == 0) {
      user.firstStakedTimestamp = block.timestamp;
    }
    if (user.lastUnstakedTimestamp == 0) {
      user.lastUnstakedTimestamp = block.timestamp;
    }
    user.lastStakedTimestamp = block.timestamp;
    user.lastInvestTimestamp = block.timestamp;

    // set the `lockFrom` and `lockUntil` taking into account that
    // zero value for `_lockUntil` means "no locking" and leads to zero values
    // for both `lockFrom` and `lockUntil`
    uint64 lockFrom = _lockUntil > 0 ? uint64(block.timestamp) : 0;
    uint64 lockUntil = _lockUntil;

    uint256 weightMultiplier = lockUntil > 0
      ? WEIGHT_MULTIPLIER
      : LIQUID_MULTIPLIER;

    // stake weight formula rewards for locking
    uint256 stakeWeight = (((lockUntil - lockFrom) * weightMultiplier) /
      365 days +
      weightMultiplier) * addedAmount;

    // makes sure stakeWeight is valid
    if (lockUntil != 0) {
      assert(stakeWeight > 0);
    }

    // create and save the deposit (append it to deposits array)
    Deposit memory deposit = Deposit({
      tokenAmount: addedAmount,
      weight: stakeWeight,
      liquidPercentage: _isYield ? _liquidPercent : 0,
      lockedFrom: lockFrom,
      lockedUntil: lockUntil,
      isYield: _isYield
    });
    // deposit ID is an index of the deposit in `deposits` array
    user.deposits.push(deposit);

    // update user record
    user.tokenAmount += addedAmount;
    user.totalWeight += stakeWeight;
    if (lockUntil == 0) {
      user.liquidAmount += addedAmount;
      user.liquidWeight += stakeWeight;
    }
    user.subYieldRewards = weightToReward(
      user.totalWeight,
      yieldRewardsPerWeight
    );

    // update global variable
    usersLockingWeight += stakeWeight;

    // emit an event
    emit Staked(msg.sender, _staker, _amount);
  }

  /**
   * @dev Used internally, mostly by children implementations, see unstake()
   *
   * @param _staker an address which unstakes tokens (which previously staked them)
   * @param _depositId deposit ID to unstake from, zero-indexed
   * @param _amount amount of tokens to unstake
   */
  function _unstake(
    address _staker,
    uint256 _depositId,
    uint256 _amount
  ) internal virtual {
    // verify an amount is set
    require(_amount != 0, "-11");

    // get a link to user data struct, we will write to it later
    User storage user = users[_staker];
    // get a link to the corresponding deposit, we may write to it later
    Deposit storage stakeDeposit = user.deposits[_depositId];

    // deposit structure may get deleted, so we save isYield and liquidPercetange to be able to use it
    bool isYield = stakeDeposit.isYield;
    uint256 liquidPercentage = stakeDeposit.liquidPercentage;

    // verify available balance
    // if staker address ot deposit doesn't exist this check will fail as well
    require(stakeDeposit.tokenAmount >= _amount, "-12");

    // update smart contract state
    _sync();
    // and process current pending rewards if any
    _processRewards(_staker, false);

    // recalculate deposit weight
    uint256 previousWeight = stakeDeposit.weight;
    uint256 stakeWeightMultiplier = stakeDeposit.lockedUntil == 0
      ? LIQUID_MULTIPLIER
      : WEIGHT_MULTIPLIER;
    uint256 newWeight = (((stakeDeposit.lockedUntil - stakeDeposit.lockedFrom) *
      stakeWeightMultiplier) /
      365 days +
      stakeWeightMultiplier) * (stakeDeposit.tokenAmount - _amount);

    if (stakeDeposit.lockedUntil == 0) {
      user.liquidAmount -= _amount;
      user.liquidWeight = user.liquidWeight - previousWeight + newWeight;
    }

    // update the deposit, or delete it if its depleted
    if (stakeDeposit.tokenAmount - _amount == 0) {
      delete user.deposits[_depositId];
    } else {
      stakeDeposit.tokenAmount -= _amount;
      stakeDeposit.weight = newWeight;
    }

    // update user record
    user.tokenAmount -= _amount;
    user.totalWeight = user.totalWeight - previousWeight + newWeight;
    user.subYieldRewards = weightToReward(
      user.totalWeight,
      yieldRewardsPerWeight
    );

    if (user.tokenAmount == 0) {
      user.firstStakedTimestamp = 0;
      user.lastStakedTimestamp = 0;
      user.lastUnstakedTimestamp = 0;
      user.lastInvestTimestamp = 0;
    } else {
      user.firstStakedTimestamp = block.timestamp;
      user.lastStakedTimestamp = block.timestamp;
      user.lastUnstakedTimestamp = block.timestamp;
    }

    // update global variable
    usersLockingWeight = usersLockingWeight - previousWeight + newWeight;

    // if the deposit was created by the pool itself as a yield reward
    if (isYield) {
      // transfer the yield via the factory
      uint256 liquidRewardAmount = (_amount * liquidPercentage) / 100;
      factory.transferYieldTo(msg.sender, _amount, liquidRewardAmount);
    } else {
      uint256 burnAmount = (_amount * getTokenBurnFee(msg.sender)) / 10000;
      // otherwise just return tokens back to holder
      if (burnAmount > 0) {
        transferPoolToken(
          address(0x000000000000000000000000000000000000dEaD),
          burnAmount
        );
      }
      if (burnAmount < _amount) {
        transferPoolToken(msg.sender, _amount - burnAmount);
      }
    }

    // emit an event
    emit Unstaked(msg.sender, _staker, _amount);
  }

  /**
   * @dev Used internally, mostly by children implementations, see sync()
   *
   * @dev Updates smart contract state (`yieldRewardsPerWeight`, `lastYieldDistribution`),
   *      updates factory state via `updateELIPerBlock`
   */
  function _sync() internal virtual {
    // update ELIXIR per block value in factory if required
    if (factory.shouldUpdateRatio()) {
      factory.updateELIPerBlock();
    }

    // check bound conditions and if these are not met -
    // exit silently, without emitting an event
    uint256 endBlock = factory.endBlock();
    if (lastYieldDistribution >= endBlock) {
      return;
    }
    if (block.number <= lastYieldDistribution) {
      return;
    }
    // if locking weight is zero - update only `lastYieldDistribution` and exit
    if (usersLockingWeight == 0) {
      lastYieldDistribution = uint64(block.number);
      return;
    }

    // to calculate the reward we need to know how many blocks passed, and reward per block
    uint256 currentBlock = block.number > endBlock ? endBlock : block.number;
    uint256 blocksPassed = currentBlock - lastYieldDistribution;
    uint256 eliPerBlock = factory.eliPerBlock();

    // calculate the reward
    uint256 eliReward = (blocksPassed * eliPerBlock * weight) /
      factory.totalWeight();

    // update rewards per weight and `lastYieldDistribution`
    yieldRewardsPerWeight += rewardToWeight(eliReward, usersLockingWeight);
    lastYieldDistribution = uint64(currentBlock);

    // emit an event
    emit Synchronized(msg.sender, yieldRewardsPerWeight, lastYieldDistribution);
  }

  /**
   * @dev Used internally, mostly by children implementations, see processRewards()
   *
   * @param _staker an address which receives the reward (which has staked some tokens earlier)
   * @param _withUpdate flag allowing to disable synchronization (see sync()) if set to false
   * @return pendingYield the rewards calculated and optionally re-staked
   */
  function _processRewards(address _staker, bool _withUpdate)
    internal
    virtual
    returns (uint256 pendingYield)
  {
    // update smart contract state if required
    if (_withUpdate) {
      _sync();
    }

    // calculate pending yield rewards, this value will be returned
    pendingYield = _pendingYieldRewards(_staker);

    // if pending yield is zero - just return silently
    if (pendingYield == 0) return 0;

    // get link to a user data structure, we will write into it later
    User storage user = users[_staker];

    if (poolToken == eli) {
      // calculate pending yield weight,
      // 2e6 is the bonus weight when staking for 1 year
      uint256 depositWeight = pendingYield * YEAR_STAKE_WEIGHT_MULTIPLIER;

      // if the pool is ELIXIR Pool - create new ELIXIR deposit
      // and save it - push it into deposits array
      Deposit memory newDeposit = Deposit({
        tokenAmount: pendingYield,
        lockedFrom: uint64(block.timestamp),
        lockedUntil: uint64(block.timestamp + getRewardLockPeriod(_staker)), // staking yield for Reward Lock Period
        weight: depositWeight,
        liquidPercentage: (user.liquidWeight * 100) / user.totalWeight,
        isYield: true
      });
      user.deposits.push(newDeposit);

      // update user record
      user.tokenAmount += pendingYield;
      user.totalWeight += depositWeight;

      // update global variable
      usersLockingWeight += depositWeight;
    } else {
      // for other pools - stake as pool
      address eliPool = factory.getPoolAddress(eli);
      ICorePool(eliPool).stakeAsPool(
        _staker,
        pendingYield,
        (user.liquidWeight * 100) / user.totalWeight,
        getRewardLockPeriod(_staker)
      );
    }

    // update users's record for `subYieldRewards` if requested
    if (_withUpdate) {
      user.subYieldRewards = weightToReward(
        user.totalWeight,
        yieldRewardsPerWeight
      );
    }

    // emit an event
    emit YieldClaimed(msg.sender, _staker, pendingYield);
  }

  /**
   * @dev See updateStakeLock()
   *
   * @param _staker an address to update stake lock
   * @param _depositId updated deposit ID
   * @param _lockedUntil updated deposit locked until value
   */
  function _updateStakeLock(
    address _staker,
    uint256 _depositId,
    uint64 _lockedUntil
  ) internal {
    // validate the input time
    require(_lockedUntil > block.timestamp, "-13");

    // get a link to user data struct, we will write to it later
    User storage user = users[_staker];
    // get a link to the corresponding deposit, we may write to it later
    Deposit storage stakeDeposit = user.deposits[_depositId];

    // validate the input against deposit structure
    require(_lockedUntil > stakeDeposit.lockedUntil, "-14");

    // verify locked from and locked until values
    if (stakeDeposit.lockedFrom == 0) {
      require(_lockedUntil - block.timestamp <= 365 days, "-15");
      stakeDeposit.lockedFrom = uint64(block.timestamp);
    } else {
      require(_lockedUntil - stakeDeposit.lockedFrom <= 365 days, "-16");
    }

    // update locked until value, calculate new weight
    stakeDeposit.lockedUntil = _lockedUntil;
    uint256 newWeight = (((stakeDeposit.lockedUntil - stakeDeposit.lockedFrom) *
      WEIGHT_MULTIPLIER) /
      365 days +
      WEIGHT_MULTIPLIER) * stakeDeposit.tokenAmount;

    // save previous weight
    uint256 previousWeight = stakeDeposit.weight;
    // update weight
    stakeDeposit.weight = newWeight;

    // update user total weight and global locking weight
    user.totalWeight = user.totalWeight - previousWeight + newWeight;
    usersLockingWeight = usersLockingWeight - previousWeight + newWeight;

    // emit an event
    emit StakeLockUpdated(
      _staker,
      _depositId,
      stakeDeposit.lockedFrom,
      _lockedUntil
    );
  }

  /**
   * @dev Converts stake weight (not to be mixed with the pool weight) to
   *      ELIXIR reward value, applying the 10^12 division on weight
   *
   * @param _weight stake weight
   * @param rewardPerWeight ELIXIR reward per weight
   * @return reward value normalized to 10^12
   */
  function weightToReward(uint256 _weight, uint256 rewardPerWeight)
    public
    view
    returns (uint256)
  {
    // apply the formula and return
    return (_weight * rewardPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER;
  }

  /**
   * @dev Converts reward ELIXIR value to stake weight (not to be mixed with the pool weight),
   *      applying the 10^12 multiplication on the reward
   *      - OR -
   * @dev Converts reward ELIXIR value to reward/weight if stake weight is supplied as second
   *      function parameter instead of reward/weight
   *
   * @param reward yield reward
   * @param rewardPerWeight reward/weight (or stake weight)
   * @return stake weight (or reward/weight)
   */
  function rewardToWeight(uint256 reward, uint256 rewardPerWeight)
    public
    view
    returns (uint256)
  {
    // apply the reverse formula and return
    return (reward * REWARD_PER_WEIGHT_MULTIPLIER) / rewardPerWeight;
  }

  /**
   * @dev Executes SafeERC20.safeTransfer on a pool token
   *
   * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
   */
  function transferPoolToken(address _to, uint256 _value)
    internal
    nonReentrant
  {
    // just delegate call to the target
    SafeERC20.safeTransfer(IERC20(poolToken), _to, _value);
  }

  /**
   * @dev Executes SafeERC20.safeTransferFrom on a pool token
   *
   * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
   */
  function transferPoolTokenFrom(
    address _from,
    address _to,
    uint256 _value
  ) internal nonReentrant {
    // just delegate call to the target
    SafeERC20.safeTransferFrom(IERC20(poolToken), _from, _to, _value);
  }

  /** @dev Get History Length */
  function getHistoryLength() external view returns (uint256) {
    return history.length;
  }

  /** @dev Get tokens to burn */
  function getTokenBurnFee(address _staker) public view returns (uint256) {
    User memory user = users[_staker];
    for (uint256 i = 0; i < feeCycle.length; i++) {
      if (
        (block.timestamp < user.lastUnstakedTimestamp + feeCycle[i]) ||
        block.timestamp < user.lastInvestTimestamp + feeCycle[i]
      ) {
        return burnFees[i];
      }
    }
    return burnFees[feeCycle.length];
  }

  function setStakingConfig(
    uint256 _index,
    uint256 _cycle,
    uint256 _fee,
    uint256 _minStakeTime,
    address _newStarterInfo
  ) external onlyStarterDevOrFactory {
    feeCycle[_index] = _cycle;
    burnFees[_index] = _fee;
    minStakeTimeForDiamond = _minStakeTime;
    starterInfo = IStarterInfo(_newStarterInfo);
  }

  function isLongStaker(address _sender) external view returns (bool) {
    User memory user = users[_sender];
    return
      user.tokenAmount > 0 &&
      user.firstStakedTimestamp > 0 &&
      user.firstStakedTimestamp + minStakeTimeForDiamond < block.timestamp;
  }

  function updateLastInvestTimestamp(address _user, uint256 _timestamp)
    external
  {
    require(
      starterInfo.getStarterDev(msg.sender) || presales[msg.sender],
      "-17"
    );
    users[_user].lastInvestTimestamp = _timestamp;
  }

  /** @dev Clearing History for more updates */
  function clearHistory() external {
    require(msg.sender == factory.owner(), "-18");
    delete history;
  }

  function setConfiguration(
    uint256 _rewardPerWeightMultiplier,
    uint256 _yearStakeWeightMultiplier,
    uint256 _weightMultiplier,
    uint256 _liquidMultiplier
  ) external {
    require(msg.sender == factory.owner(), "-19");

    emit PoolConfigurationUpdated(
      msg.sender,
      REWARD_PER_WEIGHT_MULTIPLIER,
      _rewardPerWeightMultiplier,
      YEAR_STAKE_WEIGHT_MULTIPLIER,
      _yearStakeWeightMultiplier,
      WEIGHT_MULTIPLIER,
      _weightMultiplier,
      LIQUID_MULTIPLIER,
      _liquidMultiplier
    );

    REWARD_PER_WEIGHT_MULTIPLIER = _rewardPerWeightMultiplier;
    YEAR_STAKE_WEIGHT_MULTIPLIER = _yearStakeWeightMultiplier;
    WEIGHT_MULTIPLIER = _weightMultiplier;
    LIQUID_MULTIPLIER = _liquidMultiplier;
  }

  function setInitialSettings(address _factory, address _poolToken) external {
    require(msg.sender == factory.owner(), "-20");
    factory = IPoolFactory(_factory);
    poolToken = _poolToken;
  }

  /** @dev Get Reward Lock Time */
  function getRewardLockPeriod(address _staker) public view returns (uint256) {
    User storage user = users[_staker];
    if (user.tokenAmount == 0) {
      return factory.maximumRewardLock();
    }

    uint256 i;
    uint256 totalSum = 0;
    for (i = 0; i < user.deposits.length; i++) {
      Deposit storage stakeDeposit = user.deposits[i];
      if (!stakeDeposit.isYield) {
        totalSum =
          totalSum +
          stakeDeposit.tokenAmount *
          (stakeDeposit.lockedUntil - stakeDeposit.lockedFrom);
      }
    }
    uint256 averageLocked = factory.maximumRewardLock() -
      totalSum /
      user.tokenAmount;
    if (averageLocked < factory.minimumRewardLock()) {
      return factory.minimumRewardLock();
    }
    if (averageLocked > factory.maximumRewardLock()) {
      return factory.maximumRewardLock();
    }
    return averageLocked;
  }

  function addPresaleAddress(address _presale)
    external
    onlyStarterDevOrFactory
  {
    presales[_presale] = true;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
     * by making the `nonReentrant` function external, and making it call a
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./IPool.sol";

interface ICorePool is IPool {
  function vaultRewardsPerToken() external view returns (uint256);

  function poolTokenReserve() external view returns (uint256);

  function stakeAsPool(
    address _staker,
    uint256 _amount,
    uint256 _liquidPercent,
    uint256 _lockTime
  ) external;

  function receiveVaultRewards(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
pragma experimental ABIEncoderV2;

interface IStarterInfo {
  function owner() external returns (address);

  function getCakeV2LPAddress(
    address tokenA,
    address tokenB,
    uint256 swapIndex
  ) external view returns (address pair);

  function getStarterSwapLPAddress(address tokenA, address tokenB)
    external
    view
    returns (address pair);

  function getStarterDev(address _dev) external view returns (bool);

  function setStarterDevAddress(address _newDev) external;

  function removeStarterDevAddress(address _oldDev) external;

  function getPresaleCreatorDev(address _dev) external view returns (bool);

  function setPresaleCreatorDevAddress(address _newDev) external;

  function removePresaleCreatorDevAddress(address _oldDev) external;

  function getPoolFactory() external view returns (address);

  function setPoolFactory(address _newFactory) external;

  function getPresaleFactory() external view returns (address);

  function setPresaleFactory(address _newFactory) external;

  function addPresaleAddress(address _presale) external returns (uint256);

  function getPresalesCount() external view returns (uint256);

  function getPresaleAddress(uint256 bscsId) external view returns (address);

  function setPresaleAddress(uint256 bscsId, address _newAddress) external;

  function getDevFeePercentage(uint256 presaleType)
    external
    view
    returns (uint256);

  function setDevFeePercentage(uint256 presaleType, uint256 _devFeePercentage)
    external;

  function getMinDevFeeInWei() external view returns (uint256);

  function setMinDevFeeInWei(uint256 _minDevFeeInWei) external;

  function getMinInvestorBalance(address tokenAddress)
    external
    view
    returns (uint256);

  function setMinInvestorBalance(
    address tokenAddress,
    uint256 _minInvestorBalance
  ) external;

  function getMinYesVotesThreshold(address tokenAddress)
    external
    view
    returns (uint256);

  function setMinYesVotesThreshold(
    address tokenAddress,
    uint256 _minYesVotesThreshold
  ) external;

  function getMinCreatorStakedBalance(address fundingTokenAddress)
    external
    view
    returns (uint256);

  function setMinCreatorStakedBalance(
    address fundingTokenAddress,
    uint256 _minCreatorStakedBalance
  ) external;

  function getMinInvestorGuaranteedBalance(address tokenAddress)
    external
    view
    returns (uint256);

  function setMinInvestorGuaranteedBalance(
    address tokenAddress,
    uint256 _minInvestorGuaranteedBalance
  ) external;

  function getMinStakeTime() external view returns (uint256);

  function setMinStakeTime(uint256 _minStakeTime) external;

  function getMinUnstakeTime() external view returns (uint256);

  function setMinUnstakeTime(uint256 _minUnstakeTime) external;

  function getCreatorUnsoldClaimTime() external view returns (uint256);

  function setCreatorUnsoldClaimTime(uint256 _creatorUnsoldClaimTime) external;

  function getSwapRouter(uint256 index) external view returns (address);

  function setSwapRouter(uint256 index, address _swapRouter) external;

  function addSwapRouter(address _swapRouter) external;

  function getSwapFactory(uint256 index) external view returns (address);

  function setSwapFactory(uint256 index, address _swapFactory) external;

  function addSwapFactory(address _swapFactory) external;

  function getInitCodeHash(address _swapFactory)
    external
    view
    returns (bytes32);

  function setInitCodeHash(address _swapFactory, bytes32 _initCodeHash)
    external;

  function getStarterSwapRouter() external view returns (address);

  function setStarterSwapRouter(address _starterSwapRouter) external;

  function getStarterSwapFactory() external view returns (address);

  function setStarterSwapFactory(address _starterSwapFactory) external;

  function getStarterSwapICH() external view returns (bytes32);

  function setStarterSwapICH(bytes32 _initCodeHash) external;

  function getStarterSwapLPPercent() external view returns (uint256);

  function setStarterSwapLPPercent(uint256 _starterSwapLPPercent) external;

  function getWBWB() external view returns (address);

  function setWBNB(address _wmatic) external;

  function getVestingAddress() external view returns (address);

  function setVestingAddress(address _newVesting) external;

  function getInvestmentLimit(address tokenAddress)
    external
    view
    returns (uint256);

  function setInvestmentLimit(address tokenAddress, uint256 _limit) external;

  function getLpAddress(address tokenAddress) external view returns (address);

  function setLpAddress(address tokenAddress, address lpAddress) external;

  function getStartLpStaked(address lpAddress, address payable sender)
    external
    view
    returns (uint256);

  function getTotalStartLpStaked(address lpAddress)
    external
    view
    returns (uint256);

  function getStaked(address fundingTokenAddress, address payable sender)
    external
    view
    returns (uint256);

  function getTotalStaked(address fundingTokenAddress)
    external
    view
    returns (uint256);

  function getDevPresaleTokenFee() external view returns (uint256);

  function setDevPresaleTokenFee(uint256 _devPresaleTokenFee) external;

  function getDevPresaleAllocationAddress() external view returns (address);

  function setDevPresaleAllocationAddress(address _devPresaleAllocationAddress)
    external;

  function isBlacklistedAddress(address _sender) external view returns (bool);

  function addBlacklistedAddresses(address[] calldata _blacklistedAddresses)
    external;

  function removeBlacklistedAddresses(address[] calldata _blacklistedAddresses)
    external;

  function isAuditorWhitelistedAddress(address _sender)
    external
    view
    returns (bool);

  function addAuditorWhitelistedAddresses(
    address[] calldata _whitelistedAddresses
  ) external;

  function removeAuditorWhitelistedAddresses(
    address[] calldata _whitelistedAddresses
  ) external;
}