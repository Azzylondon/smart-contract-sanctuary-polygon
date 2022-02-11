/**
 *Submitted for verification at polygonscan.com on 2021-07-16
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/access/Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/GSN/Context.sol

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/utils/Address.sol

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/math/SafeMath.sol

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/token/ERC20/IERC20.sol

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

contract Trodl is Context, IERC20, Ownable {
    
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _refOwned;
    mapping (address => uint256) private _tokOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    // _isExempted from transaction rewards
    mapping (address => bool) private _isExempted;
    address[] private _exempted;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tokTotalSupply = 600 * 10**6 * 10**18;
    uint256 private _refTotalSupply = (MAX - (MAX % _tokTotalSupply));
    uint256 private _tokFeeTotal;
    uint256 private _tokBurned;

    string private _name = 'Trodl';
    string private _symbol = 'TRO';
    uint8 private _decimals = 18;

    constructor () public {
        _refOwned[_msgSender()] = _refTotalSupply;
        emit Transfer(address(0), _msgSender(), _tokTotalSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tokTotalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExempted[account]) return _tokOwned[account];
        return tokenFromSplit(_refOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExempted(address account) public view returns (bool) {
        return _isExempted[account];
    }

    function totalFees() public view returns (uint256) {
        return _tokFeeTotal;
    }

    function totalBurned() public view returns (uint256) {
        return _tokBurned;
    }

    function distribute(uint256 tokAmount, bool burn) public {
        address sender = _msgSender();
        require(!_isExempted[sender], "Trodl: Exempted addresses not allowed");
        if (!burn) {
            (uint256 refAmount,,,,) = _getValues(tokAmount);
            _refOwned[sender] = _refOwned[sender].sub(refAmount);
            _refTotalSupply = _refTotalSupply.sub(refAmount);
            _tokFeeTotal = _tokFeeTotal.add(tokAmount);
        } else {
            (uint256 refAmount,,,,) = _getValues(tokAmount);
            _refOwned[sender] = _refOwned[sender].sub(refAmount);    
            uint256 tokAmountHalf = tokAmount.div(2); 
            _refTotalSupply = _refTotalSupply.sub(refAmount);
            _tokFeeTotal = _tokFeeTotal.add(tokAmountHalf);
            _tokBurned = _tokBurned.add(tokAmountHalf);
        }
    }

    function burn(uint256 tokAmount) public {
        address sender = _msgSender();
        require(!_isExempted[sender], "Trodl: Exempted addresses cannot burn");
        (uint256 refAmount,,,,) = _getValues(tokAmount);
        _refOwned[sender] = _refOwned[sender].sub(refAmount);
        _refTotalSupply = _refTotalSupply.sub(refAmount);
        _tokBurned = _tokBurned.add(tokAmount);
    }

    function SplitFromToken(uint256 tokAmount, bool deductTransferFeeAndBurn) public view returns(uint256) {
        require(tokAmount <= (_tokTotalSupply + _tokFeeTotal), "Trodl: Amount must be less than supply");
        if (!deductTransferFeeAndBurn) {
            (uint256 refAmount,,,,) = _getValues(tokAmount);
            return refAmount;
        } else {
            (,uint256 refTransferAmount,,,) = _getValues(tokAmount);
            return refTransferAmount;
        }
    }

    function tokenFromSplit(uint256 refAmount) public view returns(uint256) {
        require(refAmount <= _refTotalSupply, "Trodl: Amount must be less than total split");
        if(refAmount == 0) return 0;
        uint256 currentRate =  _getRate();
        return refAmount.div(currentRate);
    }

    function exemptAccount(address account) external onlyOwner() {
        require(!_isExempted[account], "Trodl: Account is already exempted");
        if(_refOwned[account] > 0) {
            _tokOwned[account] = tokenFromSplit(_refOwned[account]);
        }
        _isExempted[account] = true;
        _exempted.push(account);
    }
    
    function obligateAccount(address account) external onlyOwner() {
        require(_isExempted[account], "Trodl: Account is not Exempted");
        
        for (uint256 i = 0; i < _exempted.length; i++) {
            if (_exempted[i] == account) {
                uint256 _rBalance = SplitFromToken(_tokOwned[account], false);
                _refTotalSupply = _refTotalSupply.sub(_refOwned[account].sub(_rBalance));
                _refOwned[account] = _rBalance;
                _tokOwned[account] = 0;
                _isExempted[account] = false;
                _exempted[i] = _exempted[_exempted.length - 1];               
                _exempted.pop();
                break;
            }
        }
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Trodl: Transfer amount must be greater than zero");
        if (_isExempted[sender] && !_isExempted[recipient]) {
            _transferFromExempted(sender, recipient, amount);
        } else if (!_isExempted[sender] && _isExempted[recipient]) {
            _transferToExempted(sender, recipient, amount);
        } else if (_isExempted[sender] && _isExempted[recipient]) {
            _transferBothExempted(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tokAmount) private {
        (uint256 refAmount, uint256 refTransferAmount, uint256 refFeeHalf, uint256 tokTransferAmount, uint256 tokFeeHalf) = _getValues(tokAmount);
        _refOwned[sender] = _refOwned[sender].sub(refAmount);
        _refOwned[recipient] = _refOwned[recipient].add(refTransferAmount);
        _distributeFee(refFeeHalf, tokFeeHalf);
        emit Transfer(sender, recipient, tokTransferAmount);
    }

    function _transferToExempted(address sender, address recipient, uint256 tokAmount) private {
        (uint256 refAmount, uint256 refTransferAmount, uint256 refFeeHalf, uint256 tokTransferAmount, uint256 tokFeeHalf) = _getValues(tokAmount);
        _refOwned[sender] = _refOwned[sender].sub(refAmount);
        _tokOwned[recipient] = _tokOwned[recipient].add(tokTransferAmount);
        _refOwned[recipient] = _refOwned[recipient].add(refTransferAmount);           
        _distributeFee(refFeeHalf, tokFeeHalf);
        emit Transfer(sender, recipient, tokTransferAmount);
    }

    function _transferFromExempted(address sender, address recipient, uint256 tokAmount) private {
        (uint256 refAmount, uint256 refTransferAmount, uint256 refFeeHalf, uint256 tokTransferAmount,uint256 tokFeeHalf) = _getValues(tokAmount);
        _tokOwned[sender] = _tokOwned[sender].sub(tokAmount);
        _refOwned[sender] = _refOwned[sender].sub(refAmount);
        _refOwned[recipient] = _refOwned[recipient].add(refTransferAmount);   
        _distributeFee(refFeeHalf, tokFeeHalf);
        emit Transfer(sender, recipient, tokTransferAmount);
    }

    function _transferBothExempted(address sender, address recipient, uint256 tokAmount) private {
        (uint256 refAmount, uint256 refTransferAmount, uint256 refFeeHalf, uint256 tokTransferAmount, uint256 tokFeeHalf) = _getValues(tokAmount);
        _tokOwned[sender] = _tokOwned[sender].sub(tokAmount);
        _refOwned[sender] = _refOwned[sender].sub(refAmount);
        _tokOwned[recipient] = _tokOwned[recipient].add(tokTransferAmount);
        _refOwned[recipient] = _refOwned[recipient].add(refTransferAmount);        
        _distributeFee(refFeeHalf, tokFeeHalf);
        emit Transfer(sender, recipient, tokTransferAmount);
    }

    function _distributeFee(uint256 refFeeHalf, uint256 tokFeeHalf) private {
        _refTotalSupply = _refTotalSupply.sub(refFeeHalf);
        _tokFeeTotal = _tokFeeTotal.add(tokFeeHalf);
        _tokBurned = _tokBurned.add(tokFeeHalf);
        _tokTotalSupply = _tokTotalSupply.sub(tokFeeHalf);
        
    }

    function _getValues(uint256 tokAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tokTransferAmount, uint256 tFee, uint256 tokFeeHalf) = _getTValues(tokAmount);
        uint256 currentRate =  _getRate();
        (uint256 refAmount, uint256 refTransferAmount, uint256 refFeeHalf) = _getRValues(tokAmount, tFee, tokFeeHalf, currentRate);
        return (refAmount, refTransferAmount, refFeeHalf, tokTransferAmount, tokFeeHalf);
    }

    function _getTValues(uint256 tokAmount) private pure returns (uint256, uint256, uint256) {
        uint256 tokFeeHalf = tokAmount.div(200);
        uint256 tFee = tokFeeHalf.mul(2);
        uint256 tokTransferAmount = tokAmount.sub(tFee);       
        return (tokTransferAmount, tFee, tokFeeHalf);
    }

    function _getRValues(uint256 tokAmount, uint256 tFee, uint256 tokFeeHalf, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 refAmount = tokAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 refFeeHalf = tokFeeHalf.mul(currentRate);
        uint256 refTransferAmount = refAmount.sub(rFee);
        return (refAmount, refTransferAmount, refFeeHalf);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _refTotalSupply;
        uint256 tTotal = _tokTotalSupply.add( _tokFeeTotal);    
        uint256 tSupply = tTotal;  
        for (uint256 i = 0; i < _exempted.length; i++) {
            if (_refOwned[_exempted[i]] > rSupply || _tokOwned[_exempted[i]] > tSupply) return (_refTotalSupply, tTotal);
            rSupply = rSupply.sub(_refOwned[_exempted[i]]);
            tSupply = tSupply.sub(_tokOwned[_exempted[i]]);
        }
        if (rSupply < _refTotalSupply.div(tTotal)) return (_refTotalSupply, tTotal);
        return (rSupply, tSupply);
    }
}