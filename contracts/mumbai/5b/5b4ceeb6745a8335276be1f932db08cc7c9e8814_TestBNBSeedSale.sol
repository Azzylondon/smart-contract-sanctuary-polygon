/**
 *Submitted for verification at polygonscan.com on 2022-03-09
*/

// Dependency file: @openzeppelin/contracts/security/ReentrancyGuard.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Context.sol";

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


// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/utils/Address.sol

// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/utils/Address.sol";

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


// Dependency file: contracts/BNBSeedSale.sol


// pragma solidity ^0.8.9;

// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Seed Sale
contract BNBSeedSale is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    mapping(address => uint256) public participants;

    IERC20 private saleToken;

    uint256 internal constant PRECISION = 1 ether;

    uint256 public  BUY_PRICE; //buy price in format 1 base token = amount of sell token, 1 BNB = 0.01 Token
    uint256 public  SOFTCAP; //soft cap
    uint256 public  HARDCAP; //hard cap
    uint256 public  MIN_BNB_PER_WALLET; //min base token per wallet
    uint256 public  MAX_BNB_PER_WALLET; //max base token per wallet
    uint256 public  SALE_LENGTH; //sale length in seconds

    enum STATUS {
        QUED,
        ACTIVE,
        SUCCESS,
        FAILED
    }

    uint256 public totalCollected; //total bnb collected
    uint256 public totalSold; //total sold tokens

    uint256 public startTime; //start time for presale
    uint256 public endTime; //end time for presale

    uint256 public timeForClaim; //time for claim tokens

    bool forceFailed; //force failed, emergency
    bool isClaimActivated;
    

    event SellToken(address recipient, uint256 tokensSold, uint256 value);
    event Refund(address recipient, uint256 bnbToRefund);
    event ForceFailed();
    event Withdraw(address recipient, uint256 amount);
    event WithdrawToken(address token, address recipient, uint256 amount);
    event SetIsClaimActivated(bool isClaimActivated);
    event SetTimeForClaim(uint256 _timeForClaim);

    constructor(
        IERC20 _saleToken,
        uint256 _buyPrice,
        uint256 _softCap,
        uint256 _hardCap,
        uint256 _minBNBPerWallet,
        uint256 _maxBNBPerWallet,
        uint256 _startTime,
        uint256 _sellLengh,
        uint256 _timeForClaim
    ) {
        BUY_PRICE = _buyPrice;
        SOFTCAP = _softCap;
        HARDCAP = _hardCap;
        MIN_BNB_PER_WALLET = _minBNBPerWallet;
        MAX_BNB_PER_WALLET = _maxBNBPerWallet;
        SALE_LENGTH = _sellLengh; //2 days, 48 hours

        saleToken = _saleToken;

        startTime = _startTime;
        endTime = _startTime + SALE_LENGTH;

        require(_timeForClaim > endTime, "SeedSale: time for claim cannot be less than end sale time");

        timeForClaim = _timeForClaim;
    }

    /// @notice sell
    /// @dev before this, need approve
    function sell() external payable nonReentrant {
        uint256 _amount = msg.value;

        require(status() == STATUS.ACTIVE, "SeedSale: sale is not started yet or ended");
        require(_amount >= MIN_BNB_PER_WALLET, "SeedSale: insufficient purchase amount");
        require(_amount <= MAX_BNB_PER_WALLET, "SeedSale: reached purchase amount");
        require(participants[_msgSender()] < MAX_BNB_PER_WALLET, "SeedSale: the maximum amount of purchases has been reached");

        uint256 newTotalCollected = totalCollected + _amount;

        if (HARDCAP < newTotalCollected) {
            // Refund anything above the hard cap
            uint256 diff = newTotalCollected - HARDCAP;
            _amount = _amount - diff;
        }

        if (_amount >= MAX_BNB_PER_WALLET - participants[_msgSender()]) {
            _amount = MAX_BNB_PER_WALLET - participants[_msgSender()];
        }

        // Token amount per price
        uint256 tokensSold = (_amount * BUY_PRICE) / PRECISION;

        if (_amount < msg.value) {
            //refund
            _deliverFunds(_msgSender(), msg.value - _amount, "Cant send BNB");
        }

        // Save participants
        participants[_msgSender()] = participants[_msgSender()] + _amount;

        // Update total BNB
        totalCollected = totalCollected + _amount;

        // Update tokens sold
        totalSold = totalSold + tokensSold;

        emit SellToken(_msgSender(), tokensSold, _amount);
    }

    /// @notice refund base tokens
    /// @dev only if sale status is failed
    function refund() external nonReentrant {
        require(status() == STATUS.FAILED, "SeedSale: sale is failed");

        require(participants[_msgSender()] > 0, "SeedSale: no tokens for refund");

        uint256 bnbToRefund = participants[_msgSender()];

        _withdraw(_msgSender(), bnbToRefund);

        participants[_msgSender()] = 0;

        emit Refund(_msgSender(), bnbToRefund);
    }

    /// @notice total tokens for sale, send this amount to contract
    function totalTokensNeeded() external view returns (uint256) {
        return (totalCollected * BUY_PRICE) / PRECISION;
    }

    /// @notice withdraw unsold sale tokens to address
    /// @param _recipient recipient address
    function withdrawUnsoldSaleToken(address _recipient) external onlyOwner {
        require(_recipient != address(0x0), "SeedSale: address is zero");
        require(status() == STATUS.SUCCESS || status() == STATUS.FAILED, "SeedSale: active sale");
        _deliverTokens(saleToken, _recipient, saleToken.balanceOf(address(this)));
    }

    ///@notice withdraw all BNB
    ///@param _recipient address
    ///@dev from owner
    function withdraw(address _recipient) external virtual onlyOwner {
        require(status() == STATUS.SUCCESS, "SeedSale: failed or active");
        _withdraw(_recipient, address(this).balance);
    }

    /// @notice force fail contract
    /// @dev in other world, emergency exit
    function forceFail() external onlyOwner {
        forceFailed = true;
        emit ForceFailed();
    }

    /// @notice claim tokens
    /// @dev after claim is activated

    function claim() external nonReentrant {
        require(status() == STATUS.SUCCESS, "SeedSale: failed or active");
        require(block.timestamp >= timeForClaim, "SeedSale: the time has not yet come");
        require(isClaimActivated, "SeedSale: claim is not activated");
        require(participants[_msgSender()] > 0, "SeedSale: no tokens for claim");

        uint256 amountToClaim = getTokenAmount(_msgSender());

        _deliverTokens(saleToken, _msgSender(), amountToClaim);

        participants[_msgSender()] = 0;
    }

    /// @notice set claim activated or deactivated
    /// @param _isClaimActivated bool
    /// @dev from owner
    function setIsClaimActivated(bool _isClaimActivated) external onlyOwner {
        isClaimActivated = _isClaimActivated;

        emit SetIsClaimActivated(_isClaimActivated);
    }

    function setTimeForClaim(uint256 _timeForClaim) external onlyOwner {
        timeForClaim = _timeForClaim;

        emit SetTimeForClaim(_timeForClaim);
    }

    /// sale status
    function status() public view returns (STATUS) {
        if (forceFailed) {
            return STATUS.FAILED;
        }
        if ((block.timestamp > endTime) && (totalCollected < SOFTCAP)) {
            return STATUS.FAILED; // FAILED - SOFTCAP not met by end time
        }

        if (totalCollected >= HARDCAP) {
            return STATUS.SUCCESS; // SUCCESS - HARDCAP met
        }

        if ((block.timestamp > endTime) && (totalCollected >= SOFTCAP)) {
            return STATUS.SUCCESS; // SUCCESS - endblock and soft cap reached
        }
        if ((block.timestamp >= startTime) && (block.timestamp <= endTime)) {
            return STATUS.ACTIVE; // ACTIVE - deposits enabled
        }

        return STATUS.QUED; // QUED - awaiting start time
    }

    ///@notice get sale token
    function getSaleToken() external view returns (address) {
        return address(saleToken);
    }

    ///@notice get token amount
    ///@param _account account
    function getTokenAmount(address _account) public view returns (uint256 tokenAmount) {
        tokenAmount = participants[_account] * BUY_PRICE / PRECISION;
    }

    function getClaimStatus() external view returns(bool claimStatus) {
        if (status() == STATUS.SUCCESS && isClaimActivated && block.timestamp >= timeForClaim) {
            claimStatus = true;
        } else {
            claimStatus = false;
        }
    }

    function _withdraw(address _recipient, uint256 _amount) internal virtual {
        require(_recipient != address(0x0), "SeedSale: address is zero");
        require(_amount <= address(this).balance, "SeedSale: not enought BNB balance");

        _deliverFunds(_recipient, _amount, "SeedSale: Cant send BNB");
    }

    function _deliverFunds(
        address _recipient,
        uint256 _value,
        string memory _message
    ) internal {
        if (_value > address(this).balance) {
            _value = address(this).balance;
        }

        (bool sent, ) = payable(_recipient).call{value: _value}("");

        require(sent, _message);

        emit Withdraw(_recipient, _value);
    }

    function _deliverTokens(
        IERC20 _token,
        address _recipient,
        uint256 _value
    ) internal {
        require(_token.balanceOf(address(this)) > 0, "SeedSale: not enough tokens on balance");
        if (_value > _token.balanceOf(address(this))) {
            _value = _token.balanceOf(address(this));
        }

        _token.safeTransfer(_recipient, _value);

        emit WithdrawToken(address(_token), _recipient, _value);
    }
}


// Root file: contracts/TestBNBSeedSale.sol


pragma solidity ^0.8.9;

// import "contracts/BNBSeedSale.sol";

contract TestBNBSeedSale is BNBSeedSale {

    constructor(
        IERC20 _saleToken,
        uint256 _buyPrice,
        uint256 _softCap,
        uint256 _hardCap,
        uint256 _minBNBPerWallet,
        uint256 _maxBNBPerWallet,
        uint256 _startTime,
        uint256 _sellLengh,
        uint256 _timeForClaim
    ) 
    BNBSeedSale(
        _saleToken,
        _buyPrice,
        _softCap,
        _hardCap,
        _minBNBPerWallet,
        _maxBNBPerWallet,
        _startTime,
        _sellLengh,
        _timeForClaim
    )
    {}

    function test_setSOFTCAP(uint256 _softcap) external {
        SOFTCAP = _softcap;
    }

    function test_setHARDCAP(uint256 _hardcap) external {
        SOFTCAP = _hardcap;
    }

    function test_setMIN_BNB_PER_WALLET(uint256 _minTokens) external {
        MIN_BNB_PER_WALLET = _minTokens;
    }

    function test_setMAX_BNB_PER_WALLET(uint256 _maxokens) external {
        MAX_BNB_PER_WALLET = _maxokens;
    }

    function test_setSALE_LENGTH(uint256 _saleLength) external {
        SALE_LENGTH = _saleLength;
    }

    function test_setStartTime(uint256 _startTime) external {
        startTime = _startTime;
    }

    function test_setEndTime(uint256 _endTime) external {
        endTime = _endTime;
    }

    function test_forceFail(bool _failed) external {
        forceFailed = _failed;
    }
}