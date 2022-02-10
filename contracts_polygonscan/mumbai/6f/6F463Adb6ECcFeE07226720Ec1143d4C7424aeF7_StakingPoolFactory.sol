// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./StakingPool.sol";
import "../Interface/IReferralManager.sol";
import "../Interface/IFeeManager.sol";
import "../Interface/IMinimalProxy.sol";
import "../library/CloneBase.sol";

contract StakingPoolFactory is Ownable, CloneBase {
    using SafeMath for uint256;

    /// @notice information of deployed pool
    struct StakingPoolInfo {
        address poolAddress;
        IERC20 rewardToken;
        IERC20 inputToken;
        uint256 blockReward;
    }

    StakingPoolInfo[] public pools;

    uint256 public poolsIndex;

    bool public ownerFunctionalityEnabled;

    uint256 public poolOwnerFeePercentage;

    mapping(address => address) public poolOwner;

    //Trigger for FeeManager mode
    bool public isFeeManagerEnabled;

    IFeeManager public feeManager;

    //Trigger for ReferralManager mode
    bool public isReferralManagerEnabled;

    IReferralManager public referralManager;

    mapping(uint256 => address) public implementationIdVsImplementation;
    uint256 public nextId;

    struct LocalVars {
        address feeTokenAddress;
        uint256 fetchedFees;
        uint256 feeAmount;
        address feeToken;
        uint256 _blockReward;
    }

    LocalVars private _localVars;

    modifier onlyPoolOwner(address _pool) {
        require(poolOwner[_pool] == msg.sender, "Not pool owner");
        require(ownerFunctionalityEnabled, "Owner function Restricted");
        _;
    }

    event PoolsLaunched(
        uint256 id,
        uint256 indexed poolsIndex,
        address indexed poolsAddress,
        address indexed feeTokenAddress,
        uint256 feeAmountFetched
    );

    event ImplementationLaunched(uint256 _id, address _implementation);
    event ImplementationUpdated(uint256 _id, address _implementation);

    /**
     * Constructor
     * @param _poolOwnerFeePercentage Fee percentage to be borne by pool owner
     *                                for operations like update block rate, reward token,etc.
     */
    constructor(uint256 _poolOwnerFeePercentage) {
        poolOwnerFeePercentage = _poolOwnerFeePercentage;
    }

    function updatePoolOwnerFeePercentage(uint256 _poolOwnerFeePercentage)
        external
    {
        poolOwnerFeePercentage = _poolOwnerFeePercentage;
    }

    function addImplementation(address _newImplementation) external onlyOwner {
        require(_newImplementation != address(0), "Invalid implementation");
        implementationIdVsImplementation[nextId] = _newImplementation;

        emit ImplementationLaunched(nextId, _newImplementation);

        nextId = nextId.add(1);
    }

    function updateImplementation(uint256 _id, address _newImplementation)
        external
        onlyOwner
    {
        address currentImplementation = implementationIdVsImplementation[_id];
        require(currentImplementation != address(0), "Incorrect Id");

        implementationIdVsImplementation[_id] = _newImplementation;
        emit ImplementationUpdated(_id, _newImplementation);
    }

    function _handleFeeManager()
        private
        returns (uint256 feeAmount_, address feeToken_)
    {
        if (isFeeManagerEnabled) {
            // take a percentage of feeAmount for config change.
            (feeAmount_, feeToken_) = getFeeInfo();
            if (feeToken_ != address(0)) {
                TransferHelper.safeTransferFrom(
                    feeToken_,
                    msg.sender,
                    address(this),
                    feeAmount_
                );

                TransferHelper.safeApprove(
                    feeToken_,
                    address(feeManager),
                    feeAmount_
                );

                feeManager.fetchFees();
            } else {
                require(msg.value == feeAmount_, "Invalid value sent for fee");
                feeManager.fetchFees{value: msg.value}();
            }
        }

        return (feeAmount_, feeToken_);
    }

    function _calculateFeeApplicable(uint256 _feeAmount)
        private
        returns (uint256)
    {
        uint256 feeApplicable = (_feeAmount * poolOwnerFeePercentage) / 10000;

        return feeApplicable;
    }

    function _handleFeeForOwnerOperations() private {
        if (isFeeManagerEnabled) {
            (uint256 feeAmount, address feeToken) = getFeeInfo();

            // No fees
            if (feeAmount == uint256(0)) {
                return;
            }

            uint256 applicableFee = _calculateFeeApplicable(feeAmount);
            if (applicableFee == uint256(0)) {
                if (feeToken != address(0)) {
                    TransferHelper.safeTransferFrom(
                        feeToken,
                        msg.sender,
                        address(this),
                        applicableFee
                    );

                    TransferHelper.safeApprove(
                        feeToken,
                        address(feeManager),
                        applicableFee
                    );

                    feeManager.fetchExactFees(applicableFee);
                } else {
                    require(
                        msg.value == applicableFee,
                        "Invalid value sent for fee"
                    );
                    feeManager.fetchFees{value: msg.value}();
                }
            }
        }
    }

    function getFeeInfo() public view returns (uint256, address) {
        if (isFeeManagerEnabled) {
            return feeManager.getFactoryFeeInfo(address(this));
        }
    }

    function _handleReferral(address referrer, uint256 feeAmount) private {
        if (isReferralManagerEnabled && referrer != address(0)) {
            referralManager.handleReferralForUser(
                referrer,
                msg.sender,
                feeAmount
            );
        }
    }

    function _launchStakingPool(uint256 _id, bytes memory _encodedData)
        internal
        returns (address)
    {
        IERC20 _rewardToken;
        IERC20 _inputToken;
        uint256 _startBlock;
        uint256 _endBlock;
        uint256 _amount;

        (
            _rewardToken,
            _inputToken,
            _startBlock,
            _endBlock,
            _amount,
            _localVars._blockReward
        ) = abi.decode(
            _encodedData,
            (IERC20, IERC20, uint256, uint256, uint256, uint256)
        );

        require(
            address(_rewardToken) != address(0) &&
                address(_inputToken) != address(0),
            "Cant be Zero address"
        );
        require(
            _startBlock >= block.number,
            "Start block should be greater than current"
        ); // ideally at least 24 hours more to give investors time
        require(
            _endBlock > _startBlock,
            "End Block should be greater than StartBlock"
        ); //_crowdsaleEndTime = 0 means crowdsale would be concluded manually by owner
        require(_amount > 0, "Allocate some amount for Pool");
        require(_localVars._blockReward > 0, "Block Rewards cant be zero");

        address stakingPoolLibrary = implementationIdVsImplementation[_id];
        require(stakingPoolLibrary != address(0), "Invalid implementation id");

        address stakingPool = createClone(stakingPoolLibrary);
        _localVars.fetchedFees = 0;
        _localVars.feeTokenAddress = address(0);

        TransferHelper.safeTransferFrom(
            address(_rewardToken),
            msg.sender,
            address(this),
            _amount
        );

        TransferHelper.safeApprove(
            address(_rewardToken),
            address(stakingPool),
            _amount
        );

        IMinimalProxy(stakingPool).init(_encodedData);

        //stacking up necessary pool info ever made to pools variable
        pools.push(
            StakingPoolInfo({
                poolAddress: address(stakingPool),
                rewardToken: _rewardToken,
                inputToken: _inputToken,
                blockReward: _localVars._blockReward
            })
        );
        poolOwner[address(stakingPool)] = msg.sender;
        emit PoolsLaunched(
            _id,
            poolsIndex,
            address(stakingPool),
            _localVars.feeTokenAddress,
            _localVars.fetchedFees
        );
        poolsIndex++;

        return address(stakingPool);
    }

    /**
     * @notice Creates a new Staking Pool contract and registers it in the Factory
     */
    function launchStakingPool(uint256 _id, bytes memory _encodedData)
        external
        payable
        returns (address)
    {
        address stakingPool = _launchStakingPool(_id, _encodedData);
        _handleFeeManager();

        return address(stakingPool);
    }

    /**
     * @notice Creates a new Staking Pool contract and registers it in the Factory
     */
    function launchStakingPoolWithReferral(
        uint256 _id,
        address _referrer,
        bytes memory _encodedData
    ) external payable returns (address) {
        address stakingPool = _launchStakingPool(_id, _encodedData);
        (uint256 feeAmount, ) = _handleFeeManager();
        _handleReferral(_referrer, feeAmount);
        return address(stakingPool);
    }

    function updateOwnerFunctionality(bool _flag) external onlyOwner {
        ownerFunctionalityEnabled = _flag;
    }

    function addRewardToken(
        address _pool,
        uint256 _startBlock,
        uint256 _endBlock,
        IERC20 _rewardToken,
        uint256 _lastRewardBlock,
        uint256 _blockReward,
        uint256 _amount,
        string memory _tokenUrl
    ) external payable onlyPoolOwner(_pool) {
        _handleFeeForOwnerOperations();

        StakingPool newPool = StakingPool(_pool);
        TransferHelper.safeTransfer(address(_rewardToken), msg.sender, _amount);
        TransferHelper.safeApprove(address(_rewardToken), _pool, _amount);
        newPool.addRewardToken(
            _startBlock,
            _endBlock,
            _rewardToken,
            _lastRewardBlock,
            _blockReward,
            _amount,
            _tokenUrl
        );
    }

    function updateRewardTokenURL(
        string memory _url,
        address _pool,
        uint256 _rewardInfoIndex
    ) external payable onlyPoolOwner(_pool) {
        _handleFeeForOwnerOperations();
        StakingPool stakingPool = StakingPool(_pool);
        stakingPool.updateRewardTokenURL(_rewardInfoIndex, _url);
    }

    function setFeeAddress(address _feeAddress, address _pool)
        external
        onlyPoolOwner(_pool)
    {
        StakingPool newPool = StakingPool(_pool);
        newPool.setFeeAddress(_feeAddress);
    }

    function updateEndBlock(
        uint256 _endBlock,
        uint256 _rewardInfoIndex,
        address _pool
    ) external payable onlyPoolOwner(_pool) {
        _handleFeeForOwnerOperations();
        StakingPool newPool = StakingPool(_pool);
        newPool.updateEndBlock(_endBlock, _rewardInfoIndex);
    }

    function updateBlockReward(
        uint256 _blockReward,
        uint256 _rewardTokenIndex,
        address _pool
    ) external payable onlyPoolOwner(_pool) {
        _handleFeeForOwnerOperations();
        StakingPool newPool = StakingPool(_pool);
        newPool.updateBlockReward(_blockReward, _rewardTokenIndex);
    }

    function transferRewardToken(
        uint256 _rewardTokenIndex,
        uint256 _amount,
        address _pool,
        address _poolOwner
    ) external onlyPoolOwner(_pool) {
        StakingPool newPool = StakingPool(_pool);
        newPool.transferRewardToken(_rewardTokenIndex, _amount, _poolOwner);
    }

    function updateFeeManagerMode(
        bool _isFeeManagerEnabled,
        address _feeManager
    ) external onlyOwner {
        require(_feeManager != address(0), "Fee Manager address cant be zero");
        isFeeManagerEnabled = _isFeeManagerEnabled;
        feeManager = IFeeManager(_feeManager);
    }

    function updateReferralManagerMode(
        bool _isReferralManagerEnabled,
        address _referralManager
    ) external onlyOwner {
        require(
            _referralManager != address(0),
            "Referral Manager address cant be zero"
        );
        isReferralManagerEnabled = _isReferralManagerEnabled;
        referralManager = IReferralManager(_referralManager);
    }
}

// File contracts/StakingPool.sol
pragma solidity ^0.7.6;

import "../library/IPolydexPair.sol";
import "../library/TransferHelper.sol";
import "../library/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract StakingPool is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @notice information stuct on each user than stakes LP tokens.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 nextHarvestUntil; // When can the user harvest again.
        mapping(IERC20 => uint256) rewardDebt; // Reward debt.
        mapping(IERC20 => uint256) rewardLockedUp; // Reward locked up.
        mapping(address => bool) whiteListedHandlers;
    }

    // Info of each pool.
    struct RewardInfo {
        uint256 startBlock;
        uint256 endBlock;
        uint256 accRewardPerShare;
        uint256 lastRewardBlock; // Last block number that rewards distribution occurs.
        uint256 blockReward;
        IERC20 rewardToken; // Address of reward token contract.
        string rewardTokenUrl;
    }

    /// @notice all the settings for this farm in one struct
    struct FarmInfo {
        uint256 numFarmers;
        uint256 harvestInterval; // Harvest interval in seconds
        IERC20 inputToken;
        uint16 withdrawalFeeBP; // Deposit fee in basis points
        string inputTokenUrl;
    }

    // Deposit Fee address
    address public feeAddress;
    // Max harvest interval: 14 days.
    uint256 public constant MAXIMUM_HARVEST_INTERVAL = 14 days;

    // Max deposit fee: 10%. This number is later divided by 10000 for calculations.
    uint16 public constant MAXIMUM_WITHDRAWAL_FEE_BP = 1000;

    uint256 public totalInputTokensStaked = 0;

    // Total locked up rewards
    mapping(IERC20 => uint256) public totalLockedUpRewards;

    FarmInfo public farmInfo;

    mapping(address => bool) public activeRewardTokens;

    /// @notice information on each user than stakes LP tokens
    mapping(address => UserInfo) public userInfo;

    RewardInfo[] public rewardPool;

    bool public initialized;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event RewardLockedUp(address indexed user, uint256 amountLockedUp);
    event RewardTokenAdded(IERC20 _rewardToken);
    event FeeAddressChanged(address _feeAddress);
    event RewardPoolUpdated(uint256 _rewardInfoIndex);
    event EndBlockUpdated(uint256 _endBlock, uint256 _rewardPoolIndex);
    event UserWhitelisted(address _primaryUser, address _whitelistedUser);
    event UserBlacklisted(address _primaryUser, address _blacklistedUser);
    event BlockRewardUpdated(uint256 _blockReward, uint256 _rewardPoolIndex);
    event RewardTokenURLUpdated(string _url, uint256 _rewardPoolIndex);

    /**
     * @notice Construct a new staking pool
     */
    constructor() {
        initialized = true;
    }

    struct LocalVars {
        uint256 _amount;
        uint256 _startBlock;
        uint256 _endBlock;
        uint256 _blockReward;
        IERC20 _rewardToken;
    }

    LocalVars private _localVars;

    /**
     * @notice initialize the staking pool contract.
     * This is called only once and state is initialized.
     */
    function init(bytes memory extraData) external {
        require(initialized == false, "Contract already initialized");

        // Decoding is done in two parts due to stack too deep issue.
        (
            _localVars._rewardToken,
            farmInfo.inputToken,
            _localVars._startBlock,
            _localVars._endBlock,
            _localVars._amount
        ) = abi.decode(extraData, (IERC20, IERC20, uint256, uint256, uint256));

        string memory _rewardTokenUrl;
        (
            ,
            ,
            ,
            ,
            ,
            _localVars._blockReward,
            farmInfo.harvestInterval,
            feeAddress,
            farmInfo.withdrawalFeeBP,
            owner // StakingPool factory address
        ) = abi.decode(
            extraData,
            (
                IERC20,
                IERC20,
                uint256,
                uint256,
                uint256,
                uint256,
                uint256,
                address,
                uint16,
                address
            )
        );

        (, , , , , , , , , , _rewardTokenUrl, farmInfo.inputTokenUrl) = abi
            .decode(
                extraData,
                (
                    IERC20,
                    IERC20,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    address,
                    uint16,
                    address,
                    string,
                    string
                )
            );

        require(
            farmInfo.withdrawalFeeBP <= MAXIMUM_WITHDRAWAL_FEE_BP,
            "add: invalid deposit fee basis points"
        );
        require(
            farmInfo.harvestInterval <= MAXIMUM_HARVEST_INTERVAL,
            "add: invalid harvest interval"
        );

        TransferHelper.safeTransferFrom(
            address(_localVars._rewardToken),
            msg.sender,
            address(this),
            _localVars._amount
        );

        rewardPool.push(
            RewardInfo({
                startBlock: _localVars._startBlock,
                endBlock: _localVars._endBlock,
                rewardToken: _localVars._rewardToken,
                lastRewardBlock: block.number > _localVars._startBlock
                    ? block.number
                    : _localVars._startBlock,
                blockReward: _localVars._blockReward,
                accRewardPerShare: 0,
                rewardTokenUrl: _rewardTokenUrl
            })
        );

        activeRewardTokens[address(_localVars._rewardToken)] = true;
        initialized = true;
    }

    /**
     * @notice Gets the reward multiplier over the given _from_block until _to block
     * @param _fromBlock the start of the period to measure rewards for
     * @param _rewardInfoIndex RewardPool Id number
     * @param _to the end of the period to measure rewards for
     * @return The weighted multiplier for the given period
     */
    function getMultiplier(
        uint256 _fromBlock,
        uint256 _rewardInfoIndex,
        uint256 _to
    ) public view returns (uint256) {
        RewardInfo memory rewardInfo = rewardPool[_rewardInfoIndex];
        uint256 _from = _fromBlock >= rewardInfo.startBlock
            ? _fromBlock
            : rewardInfo.startBlock;
        uint256 to = rewardInfo.endBlock > _to ? _to : rewardInfo.endBlock;
        if (_from > to) {
            return 0;
        }

        return to.sub(_from, "from getMultiplier");
    }

    function updateRewardTokenURL(uint256 _rewardTokenIndex, string memory _url)
        external
        onlyOwner
    {
        RewardInfo storage rewardInfo = rewardPool[_rewardTokenIndex];
        rewardInfo.rewardTokenUrl = _url;
        emit RewardTokenURLUpdated(_url, _rewardTokenIndex);
    }

    function addRewardToken(
        uint256 _startBlock,
        uint256 _endBlock,
        IERC20 _rewardToken, // Address of reward token contract.
        uint256 _lastRewardBlock,
        uint256 _blockReward,
        uint256 _amount,
        string memory _tokenUrl
    ) external onlyOwner nonReentrant {
        require(address(_rewardToken) != address(0), "Invalid reward token");
        require(
            activeRewardTokens[address(_rewardToken)] == false,
            "Reward Token already added"
        );

        require(
            _lastRewardBlock >= block.number,
            "Last RewardBlock must be greater than currentBlock"
        );

        rewardPool.push(
            RewardInfo({
                startBlock: _startBlock,
                endBlock: _endBlock,
                rewardToken: _rewardToken,
                lastRewardBlock: _lastRewardBlock,
                blockReward: _blockReward,
                accRewardPerShare: 0,
                rewardTokenUrl: _tokenUrl
            })
        );

        activeRewardTokens[address(_rewardToken)] = true;

        TransferHelper.safeTransferFrom(
            address(_rewardToken),
            msg.sender,
            address(this),
            _amount
        );

        emit RewardTokenAdded(_rewardToken);
    }

    /**
     * @notice function to see accumulated balance of reward token for specified user
     * @param _user the user for whom unclaimed tokens will be shown
     * @return total amount of withdrawable reward tokens
     */
    function pendingReward(address _user, uint256 _rewardInfoIndex)
        external
        view
        returns (uint256)
    {
        UserInfo storage user = userInfo[_user];
        RewardInfo memory rewardInfo = rewardPool[_rewardInfoIndex];
        uint256 accRewardPerShare = rewardInfo.accRewardPerShare;
        uint256 lpSupply = totalInputTokensStaked;

        if (block.number > rewardInfo.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                rewardInfo.lastRewardBlock,
                _rewardInfoIndex,
                block.number
            );
            uint256 tokenReward = multiplier.mul(rewardInfo.blockReward);
            accRewardPerShare = accRewardPerShare.add(
                tokenReward.mul(1e12).div(lpSupply)
            );
        }

        uint256 pending = user.amount.mul(accRewardPerShare).div(1e12).sub(
            user.rewardDebt[rewardInfo.rewardToken]
        );
        return pending.add(user.rewardLockedUp[rewardInfo.rewardToken]);
    }

    // View function to see if user can harvest cnt's.
    function canHarvest(address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_user];
        return block.timestamp >= user.nextHarvestUntil;
    }

    // View function to see if user harvest until time.
    function getHarvestUntil(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        return user.nextHarvestUntil;
    }

    /**
     * @notice updates pool information to be up to date to the current block
     */
    function updatePool(uint256 _rewardInfoIndex) public {
        RewardInfo storage rewardInfo = rewardPool[_rewardInfoIndex];
        if (block.number <= rewardInfo.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = totalInputTokensStaked;

        if (lpSupply == 0) {
            rewardInfo.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(
            rewardInfo.lastRewardBlock,
            _rewardInfoIndex,
            block.number
        );
        uint256 tokenReward = multiplier.mul(rewardInfo.blockReward);
        rewardInfo.accRewardPerShare = rewardInfo.accRewardPerShare.add(
            tokenReward.mul(1e12).div(lpSupply)
        );
        rewardInfo.lastRewardBlock = block.number < rewardInfo.endBlock
            ? block.number
            : rewardInfo.endBlock;

        emit RewardPoolUpdated(_rewardInfoIndex);
    }

    function deposit(uint256 _amount) external nonReentrant {
        _deposit(_amount, msg.sender);
    }

    function depositFor(uint256 _amount, address _user) external nonReentrant {
        _deposit(_amount, _user);
    }

    function _deposit(uint256 _amount, address _user) internal {
        UserInfo storage user = userInfo[_user];
        user.whiteListedHandlers[_user] = true;
        payOrLockupPendingReward(_user, _user);
        if (user.amount == 0 && _amount > 0) {
            farmInfo.numFarmers++;
        }
        if (_amount > 0) {
            farmInfo.inputToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            user.amount = user.amount.add(_amount);
        }
        totalInputTokensStaked = totalInputTokensStaked.add(_amount);
        updateRewardDebt(_user);
        emit Deposit(_user, _amount);
    }

    /**
     * @notice withdraw LP token function for msg.sender
     * @param _amount the total withdrawable amount
     */
    function withdraw(uint256 _amount) external nonReentrant {
        _withdraw(_amount, msg.sender, msg.sender);
    }

    function withdrawFor(uint256 _amount, address _user) external nonReentrant {
        UserInfo storage user = userInfo[_user];
        require(
            user.whiteListedHandlers[msg.sender],
            "Handler not whitelisted to withdraw"
        );
        _withdraw(_amount, _user, msg.sender);
    }

    function _withdraw(
        uint256 _amount,
        address _user,
        address _withdrawer
    ) internal {
        UserInfo storage user = userInfo[_user];
        require(user.amount >= _amount, "INSUFFICIENT");
        payOrLockupPendingReward(_user, _withdrawer);
        if (user.amount == _amount && _amount > 0) {
            farmInfo.numFarmers--;
        }

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            if (farmInfo.withdrawalFeeBP > 0) {
                uint256 withdrawalFee = _amount
                    .mul(farmInfo.withdrawalFeeBP)
                    .div(10000);
                farmInfo.inputToken.safeTransfer(feeAddress, withdrawalFee);
                farmInfo.inputToken.safeTransfer(
                    address(_withdrawer),
                    _amount.sub(withdrawalFee)
                );
            } else {
                farmInfo.inputToken.safeTransfer(address(_withdrawer), _amount);
            }
        }
        totalInputTokensStaked = totalInputTokensStaked.sub(_amount);
        updateRewardDebt(_user);
        emit Withdraw(_user, _amount);
    }

    /**
     * @notice emergency function to withdraw LP tokens and forego harvest rewards. Important to protect users LP tokens
     */
    function emergencyWithdraw() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        farmInfo.inputToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, user.amount);
        if (user.amount > 0) {
            farmInfo.numFarmers--;
        }
        totalInputTokensStaked = totalInputTokensStaked.sub(user.amount);
        user.amount = 0;

        for (uint256 i = 0; i < rewardPool.length; i++) {
            user.rewardDebt[rewardPool[i].rewardToken] = 0;
        }
    }

    function whitelistHandler(address _handler) external {
        UserInfo storage user = userInfo[msg.sender];
        user.whiteListedHandlers[_handler] = true;
        emit UserWhitelisted(msg.sender, _handler);
    }

    function removeWhitelistedHandler(address _handler) external {
        UserInfo storage user = userInfo[msg.sender];
        user.whiteListedHandlers[_handler] = false;
        emit UserBlacklisted(msg.sender, _handler);
    }

    function isUserWhiteListed(address _owner, address _user)
        external
        view
        returns (bool)
    {
        UserInfo storage user = userInfo[_owner];
        return user.whiteListedHandlers[_user];
    }

    function payOrLockupPendingReward(address _user, address _withdrawer)
        internal
    {
        UserInfo storage user = userInfo[_user];
        if (user.nextHarvestUntil == 0) {
            user.nextHarvestUntil = block.timestamp.add(
                farmInfo.harvestInterval
            );
        }

        bool canUserHarvest = canHarvest(_user);

        for (uint256 i = 0; i < rewardPool.length; i++) {
            RewardInfo storage rewardInfo = rewardPool[i];

            updatePool(i);

            uint256 userRewardDebt = user.rewardDebt[rewardInfo.rewardToken];
            uint256 userRewardLockedUp = user.rewardLockedUp[
                rewardInfo.rewardToken
            ];
            uint256 pending = user
                .amount
                .mul(rewardInfo.accRewardPerShare)
                .div(1e12)
                .sub(userRewardDebt);
            if (canUserHarvest) {
                if (pending > 0 || userRewardLockedUp > 0) {
                    uint256 totalRewards = pending.add(userRewardLockedUp);
                    // reset lockup
                    totalLockedUpRewards[
                        rewardInfo.rewardToken
                    ] = totalLockedUpRewards[rewardInfo.rewardToken].sub(
                        userRewardLockedUp
                    );
                    user.rewardLockedUp[rewardInfo.rewardToken] = 0;
                    user.nextHarvestUntil = block.timestamp.add(
                        farmInfo.harvestInterval
                    );
                    // send rewards
                    _safeRewardTransfer(
                        _withdrawer,
                        totalRewards,
                        rewardInfo.rewardToken
                    );
                }
            } else if (pending > 0) {
                user.rewardLockedUp[rewardInfo.rewardToken] = user
                    .rewardLockedUp[rewardInfo.rewardToken]
                    .add(pending);
                totalLockedUpRewards[
                    rewardInfo.rewardToken
                ] = totalLockedUpRewards[rewardInfo.rewardToken].add(pending);
                emit RewardLockedUp(_user, pending);
            }
        }
    }

    function updateRewardDebt(address _user) internal {
        UserInfo storage user = userInfo[_user];
        for (uint256 i = 0; i < rewardPool.length; i++) {
            RewardInfo storage rewardInfo = rewardPool[i];

            user.rewardDebt[rewardInfo.rewardToken] = user
                .amount
                .mul(rewardInfo.accRewardPerShare)
                .div(1e12);
        }
    }

    // Update fee address by the previous fee address.
    function setFeeAddress(address _feeAddress) external onlyOwner {
        require(_feeAddress != address(0), "setFeeAddress: invalid address");
        feeAddress = _feeAddress;
        emit FeeAddressChanged(feeAddress);
    }

    // Function to update the end block for owner. To control the distribution duration.
    function updateEndBlock(uint256 _endBlock, uint256 _rewardInfoIndex)
        external
        onlyOwner
    {
        RewardInfo storage rewardInfo = rewardPool[_rewardInfoIndex];
        rewardInfo.endBlock = _endBlock;
        emit EndBlockUpdated(_endBlock, _rewardInfoIndex);
    }

    function updateBlockReward(uint256 _blockReward, uint256 _rewardTokenIndex)
        external
        onlyOwner
    {
        updatePool(_rewardTokenIndex);
        rewardPool[_rewardTokenIndex].blockReward = _blockReward;
        emit BlockRewardUpdated(_blockReward, _rewardTokenIndex);
    }

    function transferRewardToken(
        uint256 _rewardTokenIndex,
        uint256 _amount,
        address poolOwner
    ) external onlyOwner {
        RewardInfo storage rewardInfo = rewardPool[_rewardTokenIndex];

        rewardInfo.rewardToken.transfer(poolOwner, _amount);
    }

    /**
     * @notice Safe reward transfer function, just in case a rounding error causes pool to not have enough reward tokens
     * @param _amount the total amount of tokens to transfer
     * @param _rewardToken token address for transferring tokens
     */
    function _safeRewardTransfer(
        address _to,
        uint256 _amount,
        IERC20 _rewardToken
    ) private {
        uint256 rewardBal = _rewardToken.balanceOf(address(this));
        if (_amount > rewardBal) {
            _rewardToken.transfer(_to, rewardBal);
        } else {
            _rewardToken.transfer(_to, _amount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IReferralManager {
    function handleReferralForUser(
        address referrer,
        address user,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IFeeManager {
    function fetchFees() external payable returns (uint256);
    function fetchExactFees(uint256 _feeAmount) external payable returns (uint256);

    function getFactoryFeeInfo(address _factoryAddress)
        external
        view
        returns (uint256, address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IMinimalProxy {
    function init(
        bytes memory extraData
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

contract CloneBase {

    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, clone, 0x37)
        }
    }

    function isClone(address target, address query)
        internal
        view
        returns (bool result)
    {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000
            )
            mstore(add(clone, 0xa), targetBytes)
            mstore(
                add(clone, 0x1e),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )

            let other := add(clone, 0x40)
            extcodecopy(query, other, 0, 0x2d)
            result := and(
                eq(mload(clone), mload(other)),
                eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
            )
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IPolydexPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.0 <0.8.0;

// helper methods for interacting with ERC20 tokens that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
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
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}