/**
 *Submitted for verification at polygonscan.com on 2022-03-09
*/

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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

// File: openzeppelin-solidity/contracts/utils/Address.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;



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

// File: contracts/EthermonEnum.sol

pragma solidity 0.6.6;

contract EthermonEnum {
    enum ResultCode {
        SUCCESS,
        ERROR_CLASS_NOT_FOUND,
        ERROR_LOW_BALANCE,
        ERROR_SEND_FAIL,
        ERROR_NOT_TRAINER,
        ERROR_NOT_ENOUGH_MONEY,
        ERROR_INVALID_AMOUNT
    }

    enum ArrayType {
        CLASS_TYPE,
        STAT_STEP,
        STAT_START,
        STAT_BASE,
        OBJ_SKILL
    }

    enum BattleResult {
        CASTLE_WIN,
        CASTLE_LOSE,
        CASTLE_DESTROYED
    }

    enum PropertyType {
        ANCESTOR,
        XFACTOR
    }
}

// File: contracts/EthermonDataBase.sol

pragma solidity 0.6.6;

interface EtheremonDataBase {

    // write
    function withdrawEther(address _sendTo, uint _amount) external returns(EthermonEnum.ResultCode);
    function addElementToArrayType(EthermonEnum.ArrayType _type, uint64 _id, uint8 _value) external returns(uint);
    function updateIndexOfArrayType(EthermonEnum.ArrayType _type, uint64 _id, uint _index, uint8 _value) external returns(uint);
    function setMonsterClass(uint32 _classId, uint256 _price, uint256 _returnPrice, bool _catchable) external returns(uint32);
    function addMonsterObj(uint32 _classId, address _trainer, string calldata _name) external returns(uint64);
    function setMonsterObj(uint64 _objId, string calldata _name, uint32 _exp, uint32 _createIndex, uint32 _lastClaimIndex) external;
    function increaseMonsterExp(uint64 _objId, uint32 amount) external;
    function decreaseMonsterExp(uint64 _objId, uint32 amount) external;
    function removeMonsterIdMapping(address _trainer, uint64 _monsterId) external;
    function addMonsterIdMapping(address _trainer, uint64 _monsterId) external;
    function clearMonsterReturnBalance(uint64 _monsterId) external returns(uint256 amount);
    function collectAllReturnBalance(address _trainer) external returns(uint256 amount);
    function transferMonster(address _from, address _to, uint64 _monsterId) external returns(EthermonEnum.ResultCode);
    function addExtraBalance(address _trainer, uint256 _amount) external returns(uint256);
    function deductExtraBalance(address _trainer, uint256 _amount) external returns(uint256);
    function setExtraBalance(address _trainer, uint256 _amount) external;
    
    // read
    function totalMonster() external view returns(uint256);
    function totalClass() external view returns(uint32);
    function getSizeArrayType(EthermonEnum.ArrayType _type, uint64 _id) external view returns(uint);
    function getElementInArrayType(EthermonEnum.ArrayType _type, uint64 _id, uint _index) external view returns(uint8);
    function getMonsterClass(uint32 _classId) external view returns(uint32 classId, uint256 price, uint256 returnPrice, uint32 total, bool catchable);
    function getMonsterObj(uint64 _objId) external view returns(uint64 objId, uint32 classId, address trainer, uint32 exp, uint32 createIndex, uint32 lastClaimIndex, uint createTime);
    function getMonsterName(uint64 _objId) external view returns(string memory name);
    function getExtraBalance(address _trainer) external view returns(uint256);
    function getMonsterDexSize(address _trainer) external view returns(uint);
    function getMonsterObjId(address _trainer, uint index) external view returns(uint64);
    function getExpectedBalance(address _trainer) external view returns(uint256);
    function getMonsterReturn(uint64 _objId) external view returns(uint256 current, uint256 total);
}

// File: contracts/Context.sol

pragma solidity 0.6.6;


contract Context {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

// File: contracts/BasicAccessControl.sol

pragma solidity 0.6.6;

contract BasicAccessControl is Context {
    address payable public owner;
    // address[] public moderators;
    uint16 public totalModerators = 0;
    mapping (address => bool) public moderators;
    bool public isMaintaining = false;

    constructor() public {
        owner = msgSender();
    }

    modifier onlyOwner {
        require(msgSender() == owner);
        _;
    }

    modifier onlyModerators() {
        require(msgSender() == owner || moderators[msgSender()] == true);
        _;
    }

    modifier isActive {
        require(!isMaintaining);
        _;
    }

    function ChangeOwner(address payable _newOwner) public onlyOwner {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }


    function AddModerator(address _newModerator) public onlyOwner {
        if (moderators[_newModerator] == false) {
            moderators[_newModerator] = true;
            totalModerators += 1;
        }
    }

    function Kill() public onlyOwner {
        selfdestruct(owner);
    }
}

// File: contracts/EtheremonTradeData.sol

pragma solidity >=0.6.0 <0.8.0;






contract EtheremonTradeData is BasicAccessControl {
    using SafeMath for uint256;

    struct BorrowItem {
        uint256 index;
        address owner;
        address borrower;
        uint256 price;
        bool lent;
        uint256 releaseTime;
        uint256 createTime;
    }

    struct SellingItem {
        uint256 index;
        uint256 price;
        uint256 createTime;
    }

    mapping(uint64 => SellingItem) public sellingDict; // monster id => item
    uint64[] public sellingList; // monster id

    mapping(uint64 => BorrowItem) public borrowingDict;
    uint64[] public borrowingList;

    mapping(address => uint64[]) public lendingList;

    function removeSellingItem(uint64 _itemId) external onlyModerators {
        SellingItem storage item = sellingDict[_itemId];
        if (item.index == 0) return;

        if (item.index <= sellingList.length) {
            // Move an existing element into the vacated key slot.
            sellingDict[sellingList[sellingList.length - 1]].index = item.index;
            sellingList[item.index - 1] = sellingList[sellingList.length - 1];
            sellingList.pop();
            //sellingList.length -= 1;
            delete sellingDict[_itemId];
        }
    }

    function addSellingItem(
        uint64 _itemId,
        uint256 _price,
        uint256 _createTime
    ) external onlyModerators {
        SellingItem storage item = sellingDict[_itemId];
        item.price = _price;
        item.createTime = _createTime;

        if (item.index == 0) {
            sellingList.push(_itemId);
            item.index = sellingList.length;
            //item.index = ++sellingList.length;
            //sellingList[item.index - 1] = _itemId;
        }
    }

    function removeBorrowingItem(uint64 _itemId) external onlyModerators {
        BorrowItem storage item = borrowingDict[_itemId];
        if (item.index == 0) return;

        if (item.index <= borrowingList.length) {
            // Move an existing element into the vacated key slot.
            borrowingDict[borrowingList[borrowingList.length - 1]].index = item
                .index;
            borrowingList[item.index - 1] = borrowingList[
                borrowingList.length - 1
            ];
            borrowingList.pop();
            // borrowingList.length -= 1;
            delete borrowingDict[_itemId];
        }
    }

    function addBorrowingItem(
        address _owner,
        uint64 _itemId,
        uint256 _price,
        address _borrower,
        bool _lent,
        uint256 _releaseTime,
        uint256 _createTime
    ) external onlyModerators {
        BorrowItem storage item = borrowingDict[_itemId];
        item.owner = _owner;
        item.borrower = _borrower;
        item.price = _price;
        item.lent = _lent;
        item.releaseTime = _releaseTime;
        item.createTime = _createTime;

        if (item.index == 0) {
            borrowingList.push(_itemId);
            item.index = borrowingList.length;
            // item.index = ++borrowingList.length;
            // borrowingList[item.index - 1] = _itemId;
        }
    }

    function addItemLendingList(address _trainer, uint64 _objId)
        external
        onlyModerators
    {
        lendingList[_trainer].push(_objId);
    }

    function removeItemLendingList(address _trainer, uint64 _objId)
        external
        onlyModerators
    {
        uint256 foundIndex = 0;
        uint64[] storage objList = lendingList[_trainer];
        for (; foundIndex < objList.length; foundIndex++) {
            if (objList[foundIndex] == _objId) {
                break;
            }
        }
        if (foundIndex < objList.length) {
            objList[foundIndex] = objList[objList.length - 1];
            objList.pop();
            // delete objList[objList.length - 1];
            // objList.length--;
        }
    }

    // read access
    function isOnBorrow(uint64 _objId) external view returns (bool) {
        return (borrowingDict[_objId].index > 0);
    }

    function isOnSell(uint64 _objId) external view returns (bool) {
        return (sellingDict[_objId].index > 0);
    }

    function isOnLent(uint64 _objId) external view returns (bool) {
        return borrowingDict[_objId].lent;
    }

    function getSellPrice(uint64 _objId) external view returns (uint256) {
        return sellingDict[_objId].price;
    }

    function isOnTrade(uint64 _objId) external view returns (bool) {
        return ((borrowingDict[_objId].index > 0) ||
            (sellingDict[_objId].index > 0));
    }

    function getBorrowBasicInfo(uint64 _objId)
        external
        view
        returns (address owner, bool lent)
    {
        BorrowItem storage borrowItem = borrowingDict[_objId];
        return (borrowItem.owner, borrowItem.lent);
    }

    function getBorrowInfo(uint64 _objId)
        external
        view
        returns (
            uint256 index,
            address owner,
            address borrower,
            uint256 price,
            bool lent,
            uint256 createTime,
            uint256 releaseTime
        )
    {
        BorrowItem storage borrowItem = borrowingDict[_objId];
        return (
            borrowItem.index,
            borrowItem.owner,
            borrowItem.borrower,
            borrowItem.price,
            borrowItem.lent,
            borrowItem.createTime,
            borrowItem.releaseTime
        );
    }

    function getSellInfo(uint64 _objId)
        external
        view
        returns (
            uint256 index,
            uint256 price,
            uint256 createTime
        )
    {
        SellingItem storage item = sellingDict[_objId];
        return (item.index, item.price, item.createTime);
    }

    function getTotalSellingItem() external view returns (uint256) {
        return sellingList.length;
    }

    function getTotalBorrowingItem() external view returns (uint256) {
        return borrowingList.length;
    }

    function getTotalLendingItem(address _trainer)
        external
        view
        returns (uint256)
    {
        return lendingList[_trainer].length;
    }

    function getSellingInfoByIndex(uint256 _index)
        external
        view
        returns (
            uint64 objId,
            uint256 price,
            uint256 createTime
        )
    {
        objId = sellingList[_index];
        SellingItem storage item = sellingDict[objId];
        price = item.price;
        createTime = item.createTime;
    }

    function getBorrowInfoByIndex(uint256 _index)
        external
        view
        returns (
            uint64 objId,
            address owner,
            address borrower,
            uint256 price,
            bool lent,
            uint256 createTime,
            uint256 releaseTime
        )
    {
        objId = borrowingList[_index];
        BorrowItem storage borrowItem = borrowingDict[objId];
        return (
            objId,
            borrowItem.owner,
            borrowItem.borrower,
            borrowItem.price,
            borrowItem.lent,
            borrowItem.createTime,
            borrowItem.releaseTime
        );
    }

    function getLendingObjId(address _trainer, uint256 _index)
        external
        view
        returns (uint64)
    {
        return lendingList[_trainer][_index];
    }

    function getLendingInfo(address _trainer, uint256 _index)
        external
        view
        returns (
            uint64 objId,
            address owner,
            address borrower,
            uint256 price,
            bool lent,
            uint256 createTime,
            uint256 releaseTime
        )
    {
        objId = lendingList[_trainer][_index];
        BorrowItem storage borrowItem = borrowingDict[objId];
        return (
            objId,
            borrowItem.owner,
            borrowItem.borrower,
            borrowItem.price,
            borrowItem.lent,
            borrowItem.createTime,
            borrowItem.releaseTime
        );
    }

    function getTradingInfo(uint64 _objId)
        external
        view
        returns (
            uint256 sellingPrice,
            uint256 lendingPrice,
            bool lent,
            uint256 releaseTime,
            address owner,
            address borrower
        )
    {
        SellingItem storage item = sellingDict[_objId];
        sellingPrice = item.price;
        BorrowItem storage borrowItem = borrowingDict[_objId];
        lendingPrice = borrowItem.price;
        lent = borrowItem.lent;
        releaseTime = borrowItem.releaseTime;
        owner = borrowItem.owner;
        borrower = borrower;
    }
}

// File: contracts/EtheremonTrade.sol

/**
 *Submitted for verification at Etherscan.io on 2018-08-29
 */

pragma solidity >=0.6.0 <0.8.0;

// copyright [email protected]






contract SafeMathEthermon {
    /* function assert(bool assertion) internal { */
    /*   if (!assertion) { */
    /*     throw; */
    /*   } */
    /* }      // assert no longer needed once solidity is on 0.4.10 */

    function safeAdd(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMult(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x * y;
        assert((x == 0) || (z / x == y));
        return z;
    }
}

interface EtheremonBattleInterface {
    function isOnBattle(uint64 _objId) external view returns (bool);
}

interface EtheremonMonsterNFTInterface {
    function triggerTransferEvent(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function getMonsterCP(uint64 _monsterId) external view returns (uint256 cp);
}

contract EtheremonTrade is EthermonEnum, BasicAccessControl, SafeMathEthermon {
    uint8 public constant GEN0_NO = 24;
    using SafeERC20 for IERC20;
    IERC20 public emon;

    struct MonsterClassAcc {
        uint32 classId;
        uint256 price;
        uint256 returnPrice;
        uint32 total;
        bool catchable;
    }

    struct MonsterObjAcc {
        uint64 monsterId;
        uint32 classId;
        address trainer;
        string name;
        uint32 exp;
        uint32 createIndex;
        uint32 lastClaimIndex;
        uint256 createTime;
    }

    // Gen0 has return price & no longer can be caught when this contract is deployed
    struct Gen0Config {
        uint32 classId;
        uint256 originalPrice;
        uint256 returnPrice;
        uint32 total; // total caught (not count those from eggs)
    }

    struct BorrowItem {
        uint256 index;
        address owner;
        address borrower;
        uint256 price;
        bool lent;
        uint256 releaseTime;
        uint256 createTime;
    }

    // data contract
    address public dataContract;
    address public battleContract;
    address public tradingMonDataContract;
    address public monsterNFTContract;

    mapping(uint32 => Gen0Config) public gen0Config;

    // trading fee
    uint16 public tradingFeePercentage = 3;

    // event
    event EventPlaceSellOrder(
        address indexed seller,
        uint64 objId,
        uint256 price
    );
    event EventRemoveSellOrder(address indexed seller, uint64 objId);
    event EventCompleteSellOrder(
        address indexed seller,
        address indexed buyer,
        uint64 objId,
        uint256 price
    );
    event EventOfferBorrowingItem(
        address indexed lender,
        uint64 objId,
        uint256 price,
        uint256 releaseTime
    );
    event EventRemoveOfferBorrowingItem(address indexed lender, uint64 objId);
    event EventAcceptBorrowItem(
        address indexed lender,
        address indexed borrower,
        uint64 objId,
        uint256 price
    );
    event EventGetBackItem(
        address indexed lender,
        address indexed borrower,
        uint64 objId
    );

    // constructor
    constructor(
        address _dataContract,
        address _battleContract,
        address _tradingMonDataContract,
        address _monsterNFTContract,
        address _emon
    ) public {
        dataContract = _dataContract;
        battleContract = _battleContract;
        tradingMonDataContract = _tradingMonDataContract;
        monsterNFTContract = _monsterNFTContract;
        emon = IERC20(_emon);
    }

    function setContract(
        address _dataContract,
        address _battleContract,
        address _tradingMonDataContract,
        address _monsterNFTContract,
        address _emon
    ) public onlyModerators {
        dataContract = _dataContract;
        battleContract = _battleContract;
        tradingMonDataContract = _tradingMonDataContract;
        monsterNFTContract = _monsterNFTContract;
        emon = IERC20(_emon);
    }

    function updateConfig(uint16 _fee) public onlyModerators {
        tradingFeePercentage = _fee;
    }

    function withdraemoner(address _sendTo, uint256 _amount)
        public
        onlyModerators
    {
        uint256 balance = emon.balanceOf(address(this));
        // no user money is kept in this contract, only trasaction fee
        if (_amount > balance) {
            revert();
        }
        emon.transfer(_sendTo, _amount);
    }


    // public
    function placeSellOrder(uint64 _objId, uint256 _price) external isActive {
        if (_price == 0) revert();

        // not on borrowing
        EtheremonTradeData monTradeData = EtheremonTradeData(
            tradingMonDataContract
        );
        if (monTradeData.isOnBorrow(_objId)) revert();

        // not on battle
        EtheremonBattleInterface battle = EtheremonBattleInterface(
            battleContract
        );
        if (battle.isOnBattle(uint64(_objId))) revert();

        // check ownership
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (
            obj.monsterId,
            obj.classId,
            obj.trainer,
            obj.exp,
            obj.createIndex,
            obj.lastClaimIndex,
            obj.createTime
        ) = data.getMonsterObj(_objId);

        if (obj.trainer != msgSender()) {
            revert();
        }

        monTradeData.addSellingItem(_objId, _price, block.timestamp);
        emit EventPlaceSellOrder(msgSender(), _objId, _price);
    }

    function removeSellOrder(uint64 _objId) external isActive {
        // check ownership
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (
            obj.monsterId,
            obj.classId,
            obj.trainer,
            obj.exp,
            obj.createIndex,
            obj.lastClaimIndex,
            obj.createTime
        ) = data.getMonsterObj(uint64(_objId));

        if (obj.trainer != msgSender()) {
            revert();
        }

        EtheremonTradeData monTradeData = EtheremonTradeData(
            tradingMonDataContract
        );
        monTradeData.removeSellingItem(_objId);

        emit EventRemoveSellOrder(msgSender(), _objId);
    }

    function buyItem(uint64 _objId) external isActive {
        // check item is valid to sell
        EtheremonTradeData monTradeData = EtheremonTradeData(
            tradingMonDataContract
        );
        uint256 requestPrice = monTradeData.getSellPrice(_objId);

        if (requestPrice == 0 || requestPrice > emon.balanceOf(msgSender())) {
            revert();
        }

        // check obj
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (
            obj.monsterId,
            obj.classId,
            obj.trainer,
            obj.exp,
            obj.createIndex,
            obj.lastClaimIndex,
            obj.createTime
        ) = data.getMonsterObj(_objId);
        // can not buy from yourself
        if (obj.monsterId == 0 || obj.trainer == msgSender()) {
            revert();
        }

        EtheremonMonsterNFTInterface monsterNFT = EtheremonMonsterNFTInterface(
            monsterNFTContract
        );

        uint256 fee = (requestPrice * tradingFeePercentage) / 100;
        monTradeData.removeSellingItem(_objId);

        // transfer owner
        data.removeMonsterIdMapping(obj.trainer, obj.monsterId);
        data.addMonsterIdMapping(msgSender(), obj.monsterId);
        monsterNFT.triggerTransferEvent(obj.trainer, msgSender(), _objId);

        // transfer money
        emon.safeTransferFrom(
            msgSender(),
            obj.trainer,
            safeSubtract(requestPrice, fee)
        );

        //obj.trainer.transfer(safeSubtract(requestPrice, fee));

        emit EventCompleteSellOrder(
            obj.trainer,
            msgSender(),
            _objId,
            requestPrice
        );
    }

    // read access
    function getObjInfoWithBp(uint64 _objId)
        public
        view
        returns (
            address owner,
            uint32 classId,
            uint32 exp,
            uint32 createIndex,
            uint256 bp
        )
    {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (
            obj.monsterId,
            obj.classId,
            obj.trainer,
            obj.exp,
            obj.createIndex,
            obj.lastClaimIndex,
            obj.createTime
        ) = data.getMonsterObj(_objId);
        EtheremonMonsterNFTInterface monsterNFT = EtheremonMonsterNFTInterface(
            monsterNFTContract
        );
        bp = monsterNFT.getMonsterCP(_objId);
        owner = obj.trainer;
        classId = obj.classId;
        exp = obj.exp;
        createIndex = obj.createIndex;
    }

    function getTotalSellingMonsters() external view returns (uint256) {
        EtheremonTradeData monTradeData = EtheremonTradeData(
            tradingMonDataContract
        );
        return monTradeData.getTotalSellingItem();
    }

    function getTotalBorrowingMonsters() external view returns (uint256) {
        EtheremonTradeData monTradeData = EtheremonTradeData(
            tradingMonDataContract
        );
        return monTradeData.getTotalBorrowingItem();
    }

    function getSellingItem(uint256 _index)
        external
        view
        returns (
            uint64 objId,
            uint32 classId,
            uint32 exp,
            uint256 bp,
            address trainer,
            uint32 createIndex,
            uint256 price,
            uint256 createTime
        )
    {
        EtheremonTradeData monTradeData = EtheremonTradeData(
            tradingMonDataContract
        );
        (objId, price, createTime) = monTradeData.getSellingInfoByIndex(_index);
        if (objId > 0) {
            (trainer, classId, exp, createIndex, bp) = getObjInfoWithBp(
                objId
            );
        }
    }

    function getSellingItemByObjId(uint64 _objId)
        external
        view
        returns (
            uint32 classId,
            uint32 exp,
            uint256 bp,
            address trainer,
            uint32 createIndex,
            uint256 price,
            uint256 createTime
        )
    {
        EtheremonTradeData monTradeData = EtheremonTradeData(
            tradingMonDataContract
        );
        uint256 index;
        (index, price, createTime) = monTradeData.getSellInfo(_objId);
        if (price > 0) {
            (trainer, classId, exp, createIndex, bp) = getObjInfoWithBp(_objId);
        }
    }

    function getTradingInfo(uint64 _objId)
        external
        view
        returns (
            address owner,
            address borrower,
            uint256 sellingPrice,
            uint256 lendingPrice,
            bool lent,
            uint256 releaseTime
        )
    {
        EtheremonTradeData monTradeData = EtheremonTradeData(
            tradingMonDataContract
        );
        (
            sellingPrice,
            lendingPrice,
            lent,
            releaseTime,
            owner,
            borrower
        ) = monTradeData.getTradingInfo(_objId);
    }
}