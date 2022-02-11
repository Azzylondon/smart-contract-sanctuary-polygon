/**
 *Submitted for verification at polygonscan.com on 2021-08-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

// File: @openzeppelin/contracts/math/SafeMath.sol

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/utils/Address.sol

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

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

// File: contracts/interfaces/IRelayRecipient.sol

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address payable);

    function versionRecipient() external virtual view returns (string memory);
}

// File: contracts/common/BaseRelayRecipient.sol

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder we accept calls from
     */
    function _trustedForwarder() internal virtual view returns(address);

    /*
     * require a function to be called through GSN only
     */
    modifier trustedForwarderOnly() {
        require(msg.sender == _trustedForwarder(), "Function can only be called through the trusted Forwarder");
        _;
    }

    function isTrustedForwarder(address forwarder) public override view returns(bool) {
        return forwarder == _trustedForwarder();
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address payable ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            return msg.sender;
        }
    }
}

// File: contracts/interfaces/IMigratable.sol

interface IMigratable {
    function approveMigration(IMigratable migrateTo_) external;
    function onMigration(address who_, uint256 amount_, bytes memory data_) external;
}

// File: contracts/common/Migratable.sol

abstract contract Migratable is IMigratable {

    IMigratable public migrateTo;

    function _migrationCaller() internal virtual view returns(address);

    function approveMigration(IMigratable migrateTo_) external override {
        require(msg.sender == _migrationCaller(), "Only _migrationCaller() can call");
        require(address(migrateTo_) != address(0) &&
                address(migrateTo_) != address(this), "Invalid migrateTo_");
        migrateTo = migrateTo_;
    }

    function onMigration(address who_, uint256 amount_, bytes memory data_) external virtual override {
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/common/NonReentrancy.sol

contract NonReentrancy {

    uint256 private unlocked = 1;

    modifier lock() {
        require(unlocked == 1, 'Tidal: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }
}

// File: contracts/common/WeekManaged.sol

abstract contract WeekManaged {

    uint256 public offset = 4 days;

    function getCurrentWeek() public view returns(uint256) {
        return (now + offset) / (7 days);
    }

    function getNow() public view returns(uint256) {
        return now;
    }

    function getUnlockWeek() public view returns(uint256) {
        return getCurrentWeek() + 2;
    }

    function getUnlockTime(uint256 time_) public view returns(uint256) {
        require(time_ + offset > (7 days), "Time not large enough");
        return ((time_ + offset) / (7 days) + 2) * (7 days) - offset;
    }
}

// File: contracts/interfaces/IAssetManager.sol

interface IAssetManager {
    function getCategoryLength() external view returns(uint8);
    function getAssetLength() external view returns(uint256);
    function getAssetToken(uint16 index_) external view returns(address);
    function getAssetCategory(uint16 index_) external view returns(uint8);
    function getIndexesByCategory(uint8 category_, uint256 categoryIndex_) external view returns(uint16);
    function getIndexesByCategoryLength(uint8 category_) external view returns(uint256);
}

// File: contracts/interfaces/IBuyer.sol

interface IBuyer is IMigratable {
    function premiumForGuarantor(uint16 assetIndex_) external view returns(uint256);
    function premiumForSeller(uint16 assetIndex_) external view returns(uint256);
    function weekToUpdate() external view returns(uint256);
    function currentSubscription(uint16 assetIndex_) external view returns(uint256);
    function futureSubscription(uint16 assetIndex_) external view returns(uint256);
    function assetUtilization(uint16 assetIndex_) external view returns(uint256);
    function isUserCovered(address who_) external view returns(bool);
}

// File: contracts/interfaces/IGuarantor.sol

interface IGuarantor is IMigratable {
    function updateBonus(uint16 assetIndex_, uint256 amount_) external;
    function update(address who_) external;
    function startPayout(uint16 assetIndex_, uint256 payoutId_) external;
    function setPayout(uint16 assetIndex_, uint256 payoutId_, address toAddress_, uint256 total_) external;
}

// File: contracts/interfaces/IRegistry.sol

interface IRegistry {

    function PERCENTAGE_BASE() external pure returns(uint256);
    function UTILIZATION_BASE() external pure returns(uint256);
    function PREMIUM_BASE() external pure returns(uint256);
    function UNIT_PER_SHARE() external pure returns(uint256);

    function buyer() external view returns(address);
    function seller() external view returns(address);
    function guarantor() external view returns(address);
    function staking() external view returns(address);
    function bonus() external view returns(address);

    function tidalToken() external view returns(address);
    function baseToken() external view returns(address);
    function assetManager() external view returns(address);
    function premiumCalculator() external view returns(address);
    function platform() external view returns(address);

    function guarantorPercentage() external view returns(uint256);
    function platformPercentage() external view returns(uint256);

    function depositPaused() external view returns(bool);

    function stakingWithdrawWaitTime() external view returns(uint256);

    function governor() external view returns(address);
    function committee() external view returns(address);

    function trustedForwarder() external view returns(address);
}

// File: contracts/Guarantor.sol

// This contract is not Ownable.
contract Guarantor is IGuarantor, WeekManaged, Migratable, NonReentrancy, BaseRelayRecipient {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    string public override versionRecipient = "1.0.0";

    IRegistry public registry;

    struct WithdrawRequest {
        uint256 amount;
        uint256 time;
        bool executed;
    }

    // who => week => assetIndex => WithdrawRequest
    mapping(address => mapping(uint256 => mapping(uint16 => WithdrawRequest))) public withdrawRequestMap;

    struct PoolInfo {
        uint256 weekOfPremium;
        uint256 weekOfBonus;
        uint256 premiumPerShare;
        uint256 bonusPerShare;
    }

    mapping(uint16 => PoolInfo) public poolInfo;

    struct UserBalance {
        uint256 currentBalance;
        uint256 futureBalance;
    }

    mapping(address => mapping(uint16 => UserBalance)) public userBalance;

    struct UserInfo {
        uint256 week;
        uint256 premium;
        uint256 bonus;
    }

    mapping(address => UserInfo) public userInfo;

    // Balance here not withdrawn yet, and are good for staking bonus.
    // assetIndex => amount
    mapping(uint16 => uint256) public assetBalance;

    struct PayoutInfo {
        address toAddress;
        uint256 total;
        uint256 unitPerShare;
        uint256 paid;
        bool finished;
    }

    // assetIndex => payoutId => PayoutInfo
    mapping(uint16 => mapping(uint256 => PayoutInfo)) public payoutInfo;

    // assetIndex => payoutId
    mapping(uint16 => uint256) public payoutIdMap;

    // who => assetIndex => payoutId
    mapping(address => mapping(uint16 => uint256)) public userPayoutIdMap;

    event Update(address indexed who_);
    event Deposit(address indexed who_, uint16 indexed assetIndex_, uint256 amount_);
    event ReduceDeposit(address indexed who_, uint16 indexed assetIndex_, uint256 amount_);
    event Withdraw(address indexed who_, uint16 indexed assetIndex_, uint256 amount_);
    event WithdrawReady(address indexed who_, uint16 indexed assetIndex_, uint256 amount_);
    event ClaimPremium(address indexed who_, uint256 amount_);
    event ClaimBonus(address indexed who_, uint256 amount_);
    event StartPayout(uint16 indexed assetIndex_, uint256 indexed payoutId_);
    event SetPayout(uint16 indexed assetIndex_, uint256 indexed payoutId_, address toAddress_, uint256 total_);
    event DoPayout(address indexed who_, uint16 indexed assetIndex_, uint256 indexed payoutId_, uint256 amount_);
    event FinishPayout(uint16 indexed assetIndex_, uint256 indexed payoutId_);

    constructor (IRegistry registry_) public {
        registry = registry_;
    }

    function _trustedForwarder() internal override view returns(address) {
        return registry.trustedForwarder();
    }

    function _migrationCaller() internal override view returns(address) {
        return address(registry);
    }

    function migrate(uint16 assetIndex_) external lock {
        uint256 balance = userBalance[_msgSender()][assetIndex_].futureBalance;

        require(address(migrateTo) != address(0), "Destination not set");
        require(balance > 0, "No balance");

        userBalance[_msgSender()][assetIndex_].currentBalance = 0;
        userBalance[_msgSender()][assetIndex_].futureBalance = 0;

        address token = IAssetManager(registry.assetManager()).getAssetToken(assetIndex_);

        IERC20(token).safeTransfer(address(migrateTo), balance);
        migrateTo.onMigration(_msgSender(), balance, abi.encodePacked(assetIndex_));
    }

    // Update and pay last week's premium.
    function updatePremium(uint16 assetIndex_) external lock {
        uint256 week = getCurrentWeek();
        require(IBuyer(registry.buyer()).weekToUpdate() == week, "buyer not ready");
        require(poolInfo[assetIndex_].weekOfPremium < week, "already updated");

        uint256 amount = IBuyer(registry.buyer()).premiumForGuarantor(assetIndex_);

        if (assetBalance[assetIndex_] > 0 &&
                IAssetManager(registry.assetManager()).getAssetToken(assetIndex_) != address(0)) {
            IERC20(registry.baseToken()).safeTransferFrom(registry.buyer(), address(this), amount);
            poolInfo[assetIndex_].premiumPerShare =
                amount.mul(registry.UNIT_PER_SHARE()).div(assetBalance[assetIndex_]);
        } else {
            poolInfo[assetIndex_].premiumPerShare = 0;
        }

        poolInfo[assetIndex_].weekOfPremium = week;
    }

    // Update and pay last week's bonus.
    function updateBonus(uint16 assetIndex_, uint256 amount_) external lock override {
        require(msg.sender == registry.bonus(), "Only Bonus can call");

        uint256 week = getCurrentWeek();

        require(poolInfo[assetIndex_].weekOfBonus < week, "already updated");

        if (assetBalance[assetIndex_] > 0 && 
                IAssetManager(registry.assetManager()).getAssetToken(assetIndex_) != address(0)) {
            IERC20(registry.tidalToken()).safeTransferFrom(msg.sender, address(this), amount_);
            poolInfo[assetIndex_].bonusPerShare =
                amount_.mul(registry.UNIT_PER_SHARE()).div(assetBalance[assetIndex_]);
        } else {
            poolInfo[assetIndex_].bonusPerShare = 0;
        }

        poolInfo[assetIndex_].weekOfBonus = week;
    }

    // Called for every user every week.
    function update(address who_) public override {
        uint256 week = getCurrentWeek();

        require(userInfo[who_].week < week, "Already updated");

        uint16 index;
        // Assert if premium or bonus not updated, or user already updated.
        for (index = 0; index < IAssetManager(registry.assetManager()).getAssetLength(); ++index) {
            require(poolInfo[index].weekOfPremium == week &&
                poolInfo[index].weekOfBonus == week, "Not ready");
        }

        // For every asset
        for (index = 0; index < IAssetManager(registry.assetManager()).getAssetLength(); ++index) {
            uint256 currentBalance = userBalance[who_][index].currentBalance;
            uint256 futureBalance = userBalance[who_][index].futureBalance;

            // Update premium.
            userInfo[who_].premium = userInfo[who_].premium.add(currentBalance.mul(
                poolInfo[index].premiumPerShare).div(registry.UNIT_PER_SHARE()));

            // Update bonus.
            userInfo[who_].bonus = userInfo[who_].bonus.add(currentBalance.mul(
                poolInfo[index].bonusPerShare).div(registry.UNIT_PER_SHARE()));

            // Update balances and baskets if no claims.
            if (!isAssetLocked(index)) {
                assetBalance[index] = assetBalance[index].add(futureBalance).sub(currentBalance);
                userBalance[who_][index].currentBalance = futureBalance;
            }
        }

        // Update week.
        userInfo[who_].week = week;

        emit Update(who_);
    }

    function isFirstTime(address who_) public view returns(bool) {
        return userInfo[who_].week == 0;
    }

    function isAssetLocked(uint16 assetIndex_) public view returns(bool) {
        uint256 payoutId = payoutIdMap[assetIndex_];
        return payoutId > 0 && !payoutInfo[assetIndex_][payoutId].finished;
    }

    function deposit(uint16 assetIndex_, uint256 amount_) external lock {
        require(!isAssetLocked(assetIndex_), "Is asset locked");

        if (isFirstTime(_msgSender())) {
            update(_msgSender());
        }

        require(userInfo[_msgSender()].week == getCurrentWeek(), "Not updated yet");

        address token = IAssetManager(registry.assetManager()).getAssetToken(assetIndex_);
        require(token != address(0), "No token address");

        IERC20(token).safeTransferFrom(_msgSender(), address(this), amount_);

        userBalance[_msgSender()][assetIndex_].futureBalance = userBalance[_msgSender()][assetIndex_].futureBalance.add(amount_);

        emit Deposit(_msgSender(), assetIndex_, amount_);
    }

    function reduceDeposit(uint16 assetIndex_, uint256 amount_) external lock {
        // Even asset locked, user can still reduce.

        require(userInfo[_msgSender()].week == getCurrentWeek(), "Not updated yet");
        require(amount_ <= userBalance[_msgSender()][assetIndex_].futureBalance.sub(
            userBalance[_msgSender()][assetIndex_].currentBalance), "Not enough future balance");

        address token = IAssetManager(registry.assetManager()).getAssetToken(assetIndex_);
        require(token != address(0), "No token address");

        IERC20(token).safeTransfer(_msgSender(), amount_);

        userBalance[_msgSender()][assetIndex_].futureBalance = userBalance[_msgSender()][assetIndex_].futureBalance.sub(amount_);

        emit ReduceDeposit(_msgSender(), assetIndex_, amount_);
    }

    function withdraw(uint16 assetIndex_, uint256 amount_) external {
        require(IAssetManager(registry.assetManager()).getAssetToken(assetIndex_) != address(0), "No token address");
        require(!isAssetLocked(assetIndex_), "Is asset locked");

        require(userInfo[_msgSender()].week == getCurrentWeek(), "Not updated yet");

        require(amount_ > 0, "Requires positive amount");
        require(amount_ <= userBalance[_msgSender()][assetIndex_].currentBalance, "Not enough user balance");

        WithdrawRequest memory request;
        request.amount = amount_;
        request.time = getNow();
        request.executed = false;
        withdrawRequestMap[_msgSender()][getUnlockWeek()][assetIndex_] = request;

        emit Withdraw(_msgSender(), assetIndex_, amount_);
    }

    function withdrawReady(address who_, uint16 assetIndex_) external lock {
        WithdrawRequest storage request = withdrawRequestMap[who_][getCurrentWeek()][assetIndex_];

        require(!isAssetLocked(assetIndex_), "Is asset locked");
        require(userInfo[who_].week == getCurrentWeek(), "Not updated yet");
        require(!request.executed, "already executed");
        require(request.time > 0, "No request");

        uint256 unlockTime = getUnlockTime(request.time);
        require(getNow() > unlockTime, "Not ready to withdraw yet");

        address token = IAssetManager(registry.assetManager()).getAssetToken(assetIndex_);
        IERC20(token).safeTransfer(who_, request.amount);

        assetBalance[assetIndex_] = assetBalance[assetIndex_].sub(request.amount);
        userBalance[who_][assetIndex_].currentBalance = userBalance[who_][assetIndex_].currentBalance.sub(request.amount);
        userBalance[who_][assetIndex_].futureBalance = userBalance[who_][assetIndex_].futureBalance.sub(request.amount);

        request.executed = true;

        emit WithdrawReady(_msgSender(), assetIndex_, request.amount);
    }

    function claimPremium() external lock {
        IERC20(registry.baseToken()).safeTransfer(_msgSender(), userInfo[_msgSender()].premium);
        emit ClaimPremium(_msgSender(), userInfo[_msgSender()].premium);

        userInfo[_msgSender()].premium = 0;
    }

    function claimBonus() external lock {
        IERC20(registry.tidalToken()).safeTransfer(_msgSender(), userInfo[_msgSender()].bonus);
        emit ClaimBonus(_msgSender(), userInfo[_msgSender()].bonus);

        userInfo[_msgSender()].bonus = 0;
    }

    function startPayout(uint16 assetIndex_, uint256 payoutId_) external override {
        require(msg.sender == registry.committee(), "Only commitee can call");

        require(payoutId_ == payoutIdMap[assetIndex_] + 1, "payoutId should be increasing");
        payoutIdMap[assetIndex_] = payoutId_;

        emit StartPayout(assetIndex_, payoutId_);
    }

    function setPayout(uint16 assetIndex_, uint256 payoutId_, address toAddress_, uint256 total_) external override {
        require(msg.sender == registry.committee(), "Only commitee can call");

        require(payoutId_ == payoutIdMap[assetIndex_], "payoutId should be started");
        require(payoutInfo[assetIndex_][payoutId_].toAddress == address(0), "already set");
        require(total_ <= assetBalance[assetIndex_], "More than asset");

        // total_ can be 0.

        payoutInfo[assetIndex_][payoutId_].toAddress = toAddress_;
        payoutInfo[assetIndex_][payoutId_].total = total_;
        payoutInfo[assetIndex_][payoutId_].unitPerShare = total_.mul(registry.UNIT_PER_SHARE()).div(assetBalance[assetIndex_]);
        payoutInfo[assetIndex_][payoutId_].paid = 0;
        payoutInfo[assetIndex_][payoutId_].finished = false;

        emit SetPayout(assetIndex_, payoutId_, toAddress_, total_);
    }

    // This function can be called by anyone.
    function doPayout(address who_, uint16 assetIndex_) external {
        uint256 payoutId = payoutIdMap[assetIndex_];
        
        require(payoutInfo[assetIndex_][payoutId].toAddress != address(0), "not set");
        require(userPayoutIdMap[who_][assetIndex_] < payoutId, "Already paid");

        userPayoutIdMap[who_][assetIndex_] = payoutId;

        if (payoutInfo[assetIndex_][payoutId].finished) {
            // In case someone paid for the difference.
            return;
        }

        uint256 amountToPay = userBalance[who_][assetIndex_].currentBalance.mul(
            payoutInfo[assetIndex_][payoutId].unitPerShare).div(registry.UNIT_PER_SHARE());

        userBalance[who_][assetIndex_].currentBalance = userBalance[who_][assetIndex_].currentBalance.sub(amountToPay);
        userBalance[who_][assetIndex_].futureBalance = userBalance[who_][assetIndex_].futureBalance.sub(amountToPay);
        assetBalance[assetIndex_] = assetBalance[assetIndex_].sub(amountToPay);
        payoutInfo[assetIndex_][payoutId].paid = payoutInfo[assetIndex_][payoutId].paid.add(amountToPay);

        emit DoPayout(who_, assetIndex_, payoutId, amountToPay);
    }

    // This function can be called by anyone as long as he will pay for the difference.
    function finishPayout(uint16 assetIndex_, uint256 payoutId_) external lock {
        require(payoutId_ <= payoutIdMap[assetIndex_], "payoutId should be valid");
        require(!payoutInfo[assetIndex_][payoutId_].finished, "already finished");

        address token = IAssetManager(registry.assetManager()).getAssetToken(assetIndex_);

        if (payoutInfo[assetIndex_][payoutId_].paid < payoutInfo[assetIndex_][payoutId_].total) {
            // In case there is still small error.
            IERC20(token).safeTransferFrom(
                msg.sender,
                address(this),
                payoutInfo[assetIndex_][payoutId_].total.sub(payoutInfo[assetIndex_][payoutId_].paid));
            payoutInfo[assetIndex_][payoutId_].paid = payoutInfo[assetIndex_][payoutId_].total;
        }

        if (token != address(0)) {
            IERC20(token).safeTransfer(payoutInfo[assetIndex_][payoutId_].toAddress,
                                       payoutInfo[assetIndex_][payoutId_].total);
        }

        payoutInfo[assetIndex_][payoutId_].finished = true;

        emit FinishPayout(assetIndex_, payoutId_);
    }
}