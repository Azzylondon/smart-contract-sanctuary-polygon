// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract EverNowStaking is Ownable, Pausable {
    struct StakeParameters {
        uint256 tgePercentage;
        uint256 lockDuration;
        uint256 vestingDuration;
    }

    struct Stake {
        uint256 depositAmount; // tokens
        uint256 withdrawAmount; //tokens
    }

    struct ReferralInfo {
        address referrer;
        uint256 referralStakeAmount;
        uint256 timestamp;
        uint256 referralPercentage;
    }

    uint256 public everNowTokensPerUSD = 100;
    uint256 public totalSupply = 0;
    uint256 public minUSDStaking = 1_000; // usd
    uint256 public maxUSDStaking = 25_000; // usd

    uint256 public tgeDate = 0; // timestamp

    address public everNowToken;

    mapping(address => StakeParameters) private _stakeParameters;

    mapping(address => Stake) private _stake;

    mapping(address => uint256) private _exchangeRates;

    mapping(address => uint256) private _maxLimitsPerUser;

    mapping(address => ReferralInfo[]) private _referralInfo;

    address[] private _payableTokens;

    event NewStake(uint256 amount, address from);
    event NewReferral(
        uint256 amount,
        address invitedBy,
        address from,
        uint256 percentage
    );
    event WithdrawReward(uint256 amount, address from);

    constructor(
        address _everNowToken,
        address[] memory _payTokens,
        uint256[] memory _payTokenRates
    ) {
        require(
            _payTokens.length == _payTokenRates.length,
            "_payTokens.length !== _payTokenRates.length"
        );

        everNowToken = _everNowToken;
        for (uint256 i = 0; i < _payTokens.length; i++) {
            _exchangeRates[_payTokens[i]] = _payTokenRates[i];
        }
        _payableTokens = _payTokens;
    }

    function getExchangeRate(address tokenAddress)
        external
        view
        returns (uint256)
    {
        return _exchangeRates[tokenAddress];
    }

    function setExchangeRate(address tokenAddress, uint256 _exchangeRate)
        public
        onlyOwner
    {
        _exchangeRates[tokenAddress] = _exchangeRate;
    }

    function setEverNowTokensPerUSD(uint256 _everNowTokensPerUSD)
        public
        onlyOwner
    {
        everNowTokensPerUSD = _everNowTokensPerUSD;
    }

    function evernowTokensToUSD(uint256 tokens) public view returns (uint256) {
        uint256 decimals = IERC20Metadata(everNowToken).decimals();
        uint256 usdStake = tokens / everNowTokensPerUSD / 10**decimals;
        return usdStake;
    }

    function USDToEvernowTokens(uint256 usd) public view returns (uint256) {
        uint256 decimals = IERC20Metadata(everNowToken).decimals();
        uint256 tokens = usd * everNowTokensPerUSD * 10**decimals;
        return tokens;
    }

    function usdToToken(uint256 _usd, address _token)
        public
        view
        returns (uint256)
    {
        require(_exchangeRates[_token] > 0, "Token not supported");
        uint256 tokensAmount = _exchangeRates[_token] * _usd;
        return tokensAmount;
    }

    function getStackingLevel(address _address) public view returns (uint256) {
        if (_stakeParameters[_address].lockDuration > 0) {
            //individual stake parameters
            return 3;
        }
        uint256 tokensStake = stakingBalanceOf(_address);
        uint256 usdStake = evernowTokensToUSD(tokensStake);

        if (usdStake > 9000) {
            return 2;
        }
        return 1;
    }

    function getStakeParameters(address _address)
        public
        view
        returns (StakeParameters memory)
    {
        uint256 level = getStackingLevel(_address);

        if (level == 1) {
            return (StakeParameters(10, 90 days, 548 days));
        } else if (level == 2) {
            return (StakeParameters(10, 180 days, 548 days));
        } else {
            return (_stakeParameters[_address]);
        }
    }

    function setStakeParameters(
        address _address,
        uint256 tge,
        uint256 lockDuration,
        uint256 vestingDuration
    ) public onlyOwner {
        _stakeParameters[_address] = StakeParameters(
            tge,
            lockDuration,
            vestingDuration
        );
    }

    function setMinUSDStaking(uint256 _usd) public onlyOwner {
        minUSDStaking = _usd;
    }

    function setMaxUSDStaking(uint256 _usd) public onlyOwner {
        maxUSDStaking = _usd;
    }

    function setMaxUSDStakingForUser(uint256 _usd, address _user)
        public
        onlyOwner
    {
        _maxLimitsPerUser[_user] = _usd;
    }

    function getMaxUSDStakingForUser(address _user)
        public
        view
        returns (uint256)
    {
        if (_maxLimitsPerUser[_user] == 0) {
            return maxUSDStaking;
        }
        return _maxLimitsPerUser[_user];
    }

    function setTgeDate(uint256 _tgeDate) public onlyOwner {
        tgeDate = _tgeDate;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function stakingBalanceOf(address account) public view returns (uint256) {
        return _stake[account].depositAmount;
    }

    function getStakingInfo(address account)
        external
        view
        returns (Stake memory)
    {
        return _stake[account];
    }

    function adminStake(uint256 evernowTokenCount, address to)
        external
        onlyOwner
    {
        _stake[to].depositAmount += evernowTokenCount;
        totalSupply += evernowTokenCount;
        emit NewStake(evernowTokenCount, to);
    }

    function payableTokens() public view returns (address[] memory) {
        return _payableTokens;
    }

    function getReferralPercentage(uint256 usdAmount)
        public
        pure
        returns (uint256)
    {
        if (usdAmount < 25_000) {
            return 5;
        }
        return 3;
    }

    function getReferralInfo(address account)
        public
        view
        returns (ReferralInfo[] memory)
    {
        return _referralInfo[account];
    }

    function purchaseAndStake(
        uint256 evernowTokenAmount,
        address payToken,
        address _invitedBy
    ) external whenNotPaused {
        require(evernowTokenAmount > 0, "Cannot stake 0 tokens");

        require(
            ((tgeDate > 0 && block.timestamp <= tgeDate) || tgeDate == 0),
            "TGE already happens"
        );

        uint256 usdAmountToStake = evernowTokensToUSD(evernowTokenAmount);
        uint256 usdAmountAfterStaking = evernowTokensToUSD(
            stakingBalanceOf(msg.sender)
        ) + usdAmountToStake;

        require(
            usdAmountAfterStaking >= minUSDStaking,
            "minTokenStaking not matched"
        );
        require(
            usdAmountAfterStaking <= getMaxUSDStakingForUser(msg.sender),
            "maxTokenStaking not matched"
        );

        uint256 payTokenAmount = usdToToken(usdAmountToStake, payToken);

        IERC20(payToken).transferFrom(msg.sender, this.owner(), payTokenAmount);
        _stake[msg.sender].depositAmount += evernowTokenAmount;
        totalSupply += evernowTokenAmount;
        emit NewStake(evernowTokenAmount, msg.sender);
        uint256 referralPercentage = getReferralPercentage(usdAmountToStake);

        if (_invitedBy != address(0)) {
            // if invited by someone
            require(
                _invitedBy != msg.sender,
                "Referral is the same as the sender"
            );
            _referralInfo[_invitedBy].push(
                ReferralInfo(
                    msg.sender,
                    evernowTokenAmount,
                    block.timestamp,
                    referralPercentage
                )
            );
            _stake[_invitedBy].depositAmount +=
                (evernowTokenAmount * referralPercentage) /
                100;

            emit NewReferral(
                evernowTokenAmount,
                _invitedBy,
                msg.sender,
                referralPercentage
            );
        }
    }

    function getAvailableReward(address account) public view returns (uint256) {
        if (_stake[account].depositAmount == 0) {
            return 0;
        }

        if (tgeDate == 0) {
            return 0; // TGE not happens
        }

        if (block.timestamp < tgeDate) {
            return 0; // not yet available
        }

        StakeParameters memory stakeParams = getStakeParameters(account);
        uint256 percentageOfUnlock = 0;
        if (block.timestamp < (tgeDate + stakeParams.lockDuration)) {
            percentageOfUnlock = stakeParams.tgePercentage;
        } else if (
            block.timestamp >
            (tgeDate + stakeParams.lockDuration + stakeParams.vestingDuration)
        ) {
            percentageOfUnlock = 100;
        } else {
            uint256 percentageOfVesting = ((block.timestamp -
                tgeDate -
                stakeParams.lockDuration) * 100) /
                (stakeParams.vestingDuration - stakeParams.lockDuration);

            percentageOfUnlock =
                stakeParams.tgePercentage +
                ((100 - stakeParams.tgePercentage) * percentageOfVesting) /
                100;
        }

        uint256 unlockedAmount = ((_stake[account].depositAmount) *
            percentageOfUnlock) / 100;

        return unlockedAmount - _stake[account].withdrawAmount;
    }

    function withdrawReward() external returns (uint256) {
        uint256 reward = this.getAvailableReward(msg.sender);
        require(reward > 0, "No reward available");
        _stake[msg.sender].withdrawAmount += reward;
        emit WithdrawReward(reward, msg.sender);
        IERC20(everNowToken).transfer(msg.sender, reward);
        return reward;
    }

    function withdrawEvernowForOwner() external onlyOwner {
        uint256 ballance = IERC20(everNowToken).balanceOf(address(this));
        IERC20(everNowToken).transfer(msg.sender, ballance);
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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