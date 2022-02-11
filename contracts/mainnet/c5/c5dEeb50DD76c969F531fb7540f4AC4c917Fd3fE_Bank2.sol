/**
 *Submitted for verification at polygonscan.com on 2021-10-19
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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

// File: contracts\libs\IERC20.sol



pragma solidity 0.6.12;

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

// File: contracts\libs\Address.sol



pragma solidity 0.6.12;


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

// File: contracts\libs\SafeERC20.sol



pragma solidity 0.6.12;



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

// File: contracts\interfaces\IUniswapV2Router02.sol


pragma solidity 0.6.12;


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


interface IUniswapV2Pair {
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

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: contracts\libs\Context.sol



pragma solidity 0.6.12;

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

// File: contracts\libs\Ownable.sol



pragma solidity 0.6.12;

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

// File: contracts\libs\ReentrancyGuard.sol



pragma solidity 0.6.12;

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

// File: contracts\bank.sol









contract Bank2 is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    struct UserInfo {
        uint amount;
        uint rewardDebt;//usdc debt
        uint lastwithdraw;
        uint[] pids;
    }
    struct PoolInfo{
        uint initamt;
        uint amount;
        uint startTime;
        uint endTime;
        uint tokenPerSec;//X10^18
        uint accPerShare;
        IERC20 token;
        uint lastRewardTime;
        address router;
        bool disableCompound;//in case of error
    }
    struct UserPInfo{
        uint rewardDebt;
    }
    struct UsdcPool{
        //usdcPerSec everyweek
        uint idx;
        uint[] wkUnit; //weekly usdcPerSec. 4week cycle
        uint usdcPerTime;//*1e18
        uint startTime;
        uint accUsdcPerShare;
        uint lastRewardTime;
    }

    /**Variables */

    mapping(address=>UserInfo) public userInfo;
    PoolInfo[] public poolInfo;
    mapping(uint=>bool) public skipPool;//in case of stuck in one token.
    mapping(uint =>mapping(address=>UserPInfo)) public userPInfo;
    address[] public lotlist;
    uint public lotstart=1;
    UsdcPool public usdcPool;
    IERC20 public TOKEN;

    address public usdcAddress = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    IERC20 public USDC=IERC20(usdcAddress);
    IERC20 public wmatic=IERC20(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    address public tokenRouter=0xC0788A3aD43d79aa53B09c2EaCc313A787d1d607;
    address public dfynrouter=0xA102072A4C07F06EC3B4900FDC4C7B80b6c57429;
    address public ironAddress = address(0xD86b5923F3AD7b585eD81B448170ae026c65ae9a);
    IERC20 public IRON=IERC20(ironAddress);
    address public devaddr;
    address public winner;
    address public lotwinner;
    uint public winnum;
    uint public totalAmount;
    uint public newRepo;
    uint public currentRepo;
    uint public period;
    uint public endtime;
    uint public totalpayout;
    uint public entryMin=5 ether; //min TOKEN to enroll lotterypot
    uint public lotsize;
    uint public lotrate=200;//bp of total prize.
    address public burnAddress=0x000000000000000000000000000000000000dEaD;
    uint public totalBurnt;
    bool public paused;
    mapping(address => bool) public approvedContracts;
    modifier onlyApprovedContractOrEOA() {
        require(
            tx.origin == msg.sender || approvedContracts[msg.sender],
            "onlyApprovedContractOrEOA"
        );
        _;
    }
    constructor() public {
        TOKEN=IERC20(0x87cf37B07a5f879c1af35532862e6229E90C72AF);
        paused=false;
        usdcPool.wkUnit=[0,0,0,0];
        devaddr=address(msg.sender);
        wmatic.approve(tokenRouter,uint(-1));

        USDC.approve(tokenRouter,uint(-1));
        IRON.approve(tokenRouter,uint(-1));

        USDC.approve(dfynrouter,uint(-1));
        IRON.approve(dfynrouter,uint(-1));

        lotlist.push(burnAddress);
    }

    function adminSetRouter(address _address) public onlyOwner{
        tokenRouter = _address;
        USDC.approve(_address,uint(-1));
        IRON.approve(_address,uint(-1));
    }
    function adminSetDFYNRouter(address _address) public onlyOwner{
        dfynrouter = _address;
        USDC.approve(dfynrouter,uint(-1));
        IRON.approve(dfynrouter,uint(-1));
    }
    function adminSetToken(address _address) public onlyOwner{
        TOKEN=IERC20(_address);
        TOKEN.balanceOf(address(this));
    }
    function adminSetUSDC(address _address) public onlyOwner{
        usdcAddress=_address;
        USDC=IERC20(usdcAddress);
        USDC.balanceOf(address(this));
        USDC.approve(dfynrouter,uint(-1));
        USDC.approve(tokenRouter,uint(-1));
    }
    function adminSetIRON(address _address) public onlyOwner{
        ironAddress=_address;
        IRON=IERC20(usdcAddress);
        IRON.balanceOf(address(this));
        IRON.approve(dfynrouter,uint(-1));
        IRON.approve(tokenRouter,uint(-1));
    }

    modifier ispaused(){
        require(paused==false,"paused");
        _;
    }

    /**View functions  */
    function userinfo(address _user) public view returns(UserInfo memory){
        return userInfo[_user];
    }
    function usdcinfo() public view returns(UsdcPool memory){
        return usdcPool;
    }
    function poolLength() public view returns(uint){
        return poolInfo.length;
    }
    function livepoolIndex() public view returns(uint[] memory,uint){
        uint[] memory index=new uint[](poolInfo.length);
        uint cnt;
        for(uint i=0;i<poolInfo.length;i++){
            if(poolInfo[i].endTime > block.timestamp){
                index[cnt++]=i;
            }
        }
        return (index,cnt);
    }
    function pendingReward(uint _pid,address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        PoolInfo storage pool = poolInfo[_pid];
        UserPInfo storage userP=userPInfo[_pid][_user];
        uint256 _accUsdcPerShare = pool.accPerShare;
        if(block.timestamp<=pool.startTime){
            return 0;
        }
        if (block.timestamp > pool.lastRewardTime && pool.amount != 0 ) {
            uint multiplier;
            if(block.timestamp>pool.endTime){
                multiplier=pool.endTime.sub(pool.lastRewardTime);
            }else{
                multiplier = block.timestamp.sub(pool.lastRewardTime);
            }
            uint256 Reward = multiplier.mul(pool.tokenPerSec);
            _accUsdcPerShare = _accUsdcPerShare.add(Reward.mul(1e12).div(pool.amount));
        }
        return user.amount.mul(_accUsdcPerShare).div(1e12).sub(userP.rewardDebt).div(1e18);
    }
    function pendingrewards(address _user) public view returns(uint[] memory){
        uint[] memory pids=userInfo[_user].pids;
        uint[] memory rewards=new uint[](pids.length);
        for(uint i=0;i<pids.length;i++){
            rewards[i]=pendingReward(pids[i],_user);
        }
        return rewards;
    }
    function mytickets(address _user) public view returns(uint[] memory){
        uint[] memory my=new uint[](lotlist.length-lotstart);
        uint count;
        for(uint i=lotstart;i<lotlist.length;i++){
            if(lotlist[i]==_user){
                my[count++]=i;
            }
        }
        return my;
    }
    function totalticket() public view returns(uint){
        return lotlist.length-lotstart;
    }
    function pendingUsdc(address _user) public view returns(uint256){
        UserInfo storage user = userInfo[_user];
        uint256 _accUsdcPerShare = usdcPool.accUsdcPerShare;
        if (block.timestamp > usdcPool.lastRewardTime && totalAmount != 0) {
            uint256 multiplier = block.timestamp.sub(usdcPool.lastRewardTime);
            uint256 UsdcReward = multiplier.mul(usdcPool.usdcPerTime);
            _accUsdcPerShare = _accUsdcPerShare.add(UsdcReward.mul(1e12).div(totalAmount));
        }
        return user.amount.mul(_accUsdcPerShare).div(1e12).sub(user.rewardDebt).div(1e18);
    }

    /**Public functions */

    function updateUsdcPool() internal {
        if (block.timestamp <= usdcPool.lastRewardTime) {
            return;
        }
        if (totalAmount == 0) {
            usdcPool.lastRewardTime = block.timestamp;
            return;
        }
        uint256 multiplier = block.timestamp.sub(usdcPool.lastRewardTime);
        uint256 usdcReward = multiplier.mul(usdcPool.usdcPerTime);
        usdcPool.accUsdcPerShare = usdcPool.accUsdcPerShare.add(usdcReward.mul(1e12).div(totalAmount));
        usdcPool.lastRewardTime = block.timestamp;
    }

    function updatePool(uint _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        if(pool.lastRewardTime>=pool.endTime || block.timestamp <= pool.lastRewardTime){
            return;
        }
        if (totalAmount == 0 || pool.amount==0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        uint multiplier;
        if(block.timestamp>pool.endTime){
            multiplier=pool.endTime.sub(pool.lastRewardTime);
        }else{
            multiplier = block.timestamp.sub(pool.lastRewardTime);
        }
        uint256 Reward = multiplier.mul(pool.tokenPerSec);
        pool.accPerShare = pool.accPerShare.add(Reward.mul(1e12).div(pool.amount));

        pool.lastRewardTime = block.timestamp;
        if(block.timestamp>pool.endTime){
            pool.lastRewardTime=pool.endTime;
        }
    }

    function deposit(uint256 _amount) public onlyApprovedContractOrEOA ispaused {
        UserInfo storage user = userInfo[msg.sender];
        updateUsdcPool();
        for(uint i=0;i<user.pids.length;i++){
            uint _pid=user.pids[i];
            if(skipPool[_pid]){continue;}
            updatePool(_pid);
            uint pendingR=user.amount.mul(poolInfo[_pid].accPerShare).div(1e12).sub(userPInfo[_pid][msg.sender].rewardDebt);
            pendingR=pendingR.div(1e18);
            if(pendingR>0){
                poolInfo[_pid].token.safeTransfer(msg.sender,pendingR);
            }
        }
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(usdcPool.accUsdcPerShare).div(1e12).sub(user.rewardDebt);
            pending=pending.div(1e18);
            if(pending > 0) {
                safeUsdcTransfer(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            uint before=TOKEN.balanceOf(address(this));
            TOKEN.safeTransferFrom(address(msg.sender), address(this), _amount);
            TOKEN.safeTransfer(burnAddress , TOKEN.balanceOf(address(this)).sub(before));
            user.amount = user.amount.add(_amount);
            totalBurnt+=_amount;
            totalAmount=totalAmount.add(_amount);
        }

        for(uint i=0;i<user.pids.length;i++){
            uint _pid=user.pids[i];
            if(skipPool[_pid]){continue;}
            poolInfo[_pid].amount+=_amount;
            userPInfo[_pid][msg.sender].rewardDebt=user.amount.mul(poolInfo[_pid].accPerShare).div(1e12);
        }
        user.rewardDebt = user.amount.mul(usdcPool.accUsdcPerShare).div(1e12);
        checkend();
    }
    function enroll(uint _pid) public onlyApprovedContractOrEOA {
        require(_pid<poolInfo.length && poolInfo[_pid].endTime > block.timestamp ,"wrong pid");
        require(skipPool[_pid]==false);
        UserInfo storage user = userInfo[msg.sender];
        for(uint i=0;i<user.pids.length;i++){
            require(user.pids[i]!=_pid,"duplicated pid");
        }
        updatePool(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        pool.amount+=user.amount;
        user.pids.push(_pid);
        userPInfo[_pid][msg.sender].rewardDebt=user.amount.mul(poolInfo[_pid].accPerShare).div(1e12);
    }

    function compound() public onlyApprovedContractOrEOA returns (uint){
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount>0);
        updateUsdcPool();
        uint before=wmatic.balanceOf(address(this));
        for(uint i=0;i<user.pids.length;i++){
            uint _pid=user.pids[i];
            if(skipPool[_pid]){continue;}
            updatePool(_pid);
            PoolInfo memory pool=poolInfo[_pid];
            uint pendingR=user.amount.mul(pool.accPerShare).div(1e12).sub(userPInfo[_pid][msg.sender].rewardDebt);
            pendingR=pendingR.div(1e18);
            if(pool.disableCompound){
                if(pendingR>0){
                    pool.token.safeTransfer(msg.sender,pendingR);
                }
            }else{
                _safeSwap(pool.router, pendingR, address(pool.token), address(wmatic));
            }
        }

        uint beforeSing=TOKEN.balanceOf(address(this));
        //wmatic=>TOKEN
        _safeSwap(tokenRouter, wmatic.balanceOf(address(this)).sub(before), address(wmatic), address(TOKEN));

        //USDC=>TOKEN
        uint256 pending = user.amount.mul(usdcPool.accUsdcPerShare).div(1e12).sub(user.rewardDebt);
        pending=pending.div(1e18);
        _safeSwap(tokenRouter, pending, address(USDC), address(TOKEN));
        uint burningSing=TOKEN.balanceOf(address(this)).sub(beforeSing);
        user.amount+=burningSing.mul(105).div(100);
        user.rewardDebt = user.amount.mul(usdcPool.accUsdcPerShare).div(1e12);
        for(uint i=0;i<user.pids.length;i++){
            uint _pid=user.pids[i];
            if(skipPool[_pid]){continue;}
            poolInfo[_pid].amount+=burningSing.mul(105).div(100);
            userPInfo[_pid][msg.sender].rewardDebt=user.amount.mul(poolInfo[_pid].accPerShare).div(1e12);
        }
        TOKEN.transfer(burnAddress, burningSing);
        totalBurnt+=burningSing;
        totalAmount+=burningSing.mul(105).div(100);

        if(burningSing>entryMin){//enroll for lottery
            lotlist.push(msg.sender);
        }
        checkend();
        return burningSing;
    }


    function addRepo(uint _amount) public {
        require(msg.sender==address(TOKEN) || msg.sender==owner());
        uint _lotadd=_amount.mul(lotrate).div(10000);
        lotsize=lotsize.add(_lotadd);
        newRepo=newRepo.add(_amount.sub(_lotadd));
    }

    /**Internal functions */

    function checkend() internal {//already updated pool above.
        deletepids();
        if(endtime<=block.timestamp){
            endtime=block.timestamp.add(period);
            if(newRepo>10**7){//USDC decimal 6 in polygon. should change on other chains.
                safeUsdcTransfer(msg.sender, 10**7);//reward for the first resetter
                newRepo=newRepo.sub(10**7);
            }
            winner=address(msg.sender);
            currentRepo=newRepo.mul(999).div(1000);//in case of error by over-paying
            newRepo=0;
            if(usdcPool.idx==3){
                usdcPool.usdcPerTime-=usdcPool.wkUnit[0];
                usdcPool.idx=0;
                usdcPool.wkUnit[0]=currentRepo.mul(1e18).div(period*4);
                usdcPool.usdcPerTime+=usdcPool.wkUnit[0];
            }else{
                uint idx=usdcPool.idx;
                usdcPool.usdcPerTime=usdcPool.usdcPerTime.sub(usdcPool.wkUnit[idx+1]);
                usdcPool.idx++;
                usdcPool.wkUnit[usdcPool.idx]=currentRepo.mul(1e18).div(period*4);
                usdcPool.usdcPerTime+=usdcPool.wkUnit[usdcPool.idx];
            }
            pickwin();
        }
    }

    function deletepids() internal {
        UserInfo storage user=userInfo[msg.sender];
        for(uint i=0;i<user.pids.length;i++){
            if(poolInfo[user.pids[i]].endTime <= block.timestamp){
                user.pids[i]=user.pids[user.pids.length-1];
                user.pids.pop();
                deletepids();
                break;
            }
        }
    }

    function pickwin() internal {
        uint _mod=lotlist.length-lotstart;
        bytes32 _structHash;
        uint256 _randomNumber;
        _structHash = keccak256(
            abi.encode(
                msg.sender,
                block.difficulty,
                gasleft()
            )
        );
        _randomNumber  = uint256(_structHash);
        assembly {_randomNumber := mod(_randomNumber,_mod )}
        winnum=lotstart+_randomNumber;
        lotwinner=lotlist[winnum];
        safeUsdcTransfer(lotwinner, lotsize);
        lotsize=0;
        lotstart+=_mod;
    }
    function _safeSwap(
        address _router,
        uint256 _amountIn,
        address token0,address token1
    ) internal {
        if(_amountIn>0){
            address[] memory _path = new address[](2);
            uint bal=IERC20(token0).balanceOf(address(this));
            if(_amountIn<bal){
                bal=_amountIn;
            }
            _path[0] = token0;
            _path[1] = token1;
            IUniswapV2Router02(_router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                bal,
                0,
                _path,
                address(this),
                now.add(600)
            );
        }
    }

    event IronTransfer(address _to, uint256 _amountUSDC, uint256 _amountIRON);
    function safeUsdcTransfer(address _to, uint256 _amount) internal {
        uint256 balance = USDC.balanceOf(address(this));
        if (_amount > balance) {
            _amount = balance;
        }

        totalpayout=totalpayout.add(balance);

        uint256 ironBefore = IRON.balanceOf(address(this));
        address[] memory _path = new address[](2);
        _path[0] = usdcAddress;
        _path[1] = ironAddress;
        IUniswapV2Router02(dfynrouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount,
            0,
            _path,
            address(this),
            now.add(600)
        );
        uint256 ironAfter = IRON.balanceOf(address(this));
        uint256 ironAmount = ironAfter.sub(ironBefore);
        IRON.safeTransfer(_to, ironAmount);
        emit IronTransfer(_to, _amount, ironAmount);
    }

    /*governance functions*/

    function addpool(uint _amount,uint _startTime,uint _endTime,IERC20 _token,address _router) public onlyOwner{
        require(_startTime>block.timestamp && _endTime>_startTime, "wrong time");
        poolInfo.push(PoolInfo({
        initamt:_amount,
        amount :0,
        startTime:_startTime,
        endTime:_endTime,
        tokenPerSec:_amount.mul(1e18).div(_endTime-_startTime),//X10^18
        accPerShare:0,
        token:_token,
        lastRewardTime: _startTime,
        router:_router,
        disableCompound:false//in case of error
        }));
        _token.approve(_router,uint(-1));
    }
    function start(uint _period) public onlyOwner{
        paused=false;
        period=_period;
        endtime=block.timestamp.add(period);
        currentRepo=newRepo;
        usdcPool.usdcPerTime=currentRepo.mul(1e18).div(period*4);
        usdcPool.wkUnit[0]=usdcPool.usdcPerTime;
        newRepo=0;
    }
    function stopPool(uint _pid) public onlyOwner{
        skipPool[_pid]=!skipPool[_pid];//toggle
    }
    function pause(bool _paused) public onlyOwner{
        paused=_paused;
    }
    function setPeriod(uint _period) public onlyOwner{
        period=_period;
    }
    function setMin(uint _entryMin) public onlyOwner{
        entryMin=_entryMin;
    }
    function disableCompound(uint _pid,bool _disable) public onlyOwner{
        poolInfo[_pid].disableCompound=_disable;
    }
    function setApprovedContract(address _contract, bool _status)
    external
    onlyOwner
    {
        approvedContracts[_contract] = _status;
    }

}