/**
 *Submitted for verification at polygonscan.com on 2022-05-25
*/

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

// SPDX-License-Identifier: MIT

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

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    constructor() internal {
        _registerInterface(
            ERC1155Receiver(0).onERC1155Received.selector ^
            ERC1155Receiver(0).onERC1155BatchReceived.selector
        );
    }
}

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

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

// File: @openzeppelin\contracts\access\Ownable.sol

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
library SafeMathUint8 {
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
    function add(uint8 a, uint8 b) internal pure returns (uint8) {
        uint8 c = a + b;
        require(c >= a, "SafeMathUnit8: addition overflow");

        return c;
    }
}

library SafeMath {
    function nadd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = _add(a,b);
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function _add(uint256 a, uint256 b) internal pure returns(uint256 c) {
        assembly {
            c := add(a, b)
        }
    }
    function nsub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint c = _sub(a,b);
        return c;
    }
    function _sub(uint256 a, uint256 b) internal pure returns(uint256 c) {
        assembly {
            c := sub(a, b)
        }
    }

    function nmul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = _mul(a,b);
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function _mul(uint256 a, uint256 b) internal pure returns(uint256 c) {
        assembly {
            c := mul(a, b)
        }
    }

    function ndiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = _div(a,b);
        return c;
    }
    function _div(uint256 a, uint256 b) internal pure returns(uint256 c) {
        assembly {
            c := div(a, b)
        }
    }

    function nmod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        uint256 c = _mod(a,b);
        return c;
    }

    function _mod(uint256 a, uint256 b) internal pure returns(uint256 c) {
        assembly {
            c := mod(a, b)
        }
    }
}

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
    /*
     * Minimum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

    /*
     * Maximum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /**
     * Calculate |x|.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function abs(int128 x) internal pure returns (int128) {
        require(x != MIN_64x64);
        return x < 0 ? -x : x;
    }

    /**
     * Calculate x * y rounding down, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
     * @param y unsigned 256-bit integer number
     * @return unsigned 256-bit integer number
     */
    function mulu(int128 x, uint256 y) internal pure returns (uint256) {
        if (y == 0) return 0;

        require(x >= 0);

        uint256 lo =
            (uint256(x) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
        uint256 hi = uint256(x) * (y >> 128);

        require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        hi <<= 64;

        require(
            hi <=
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF -
                    lo
        );
        return hi + lo;
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function divu(uint256 x, uint256 y) internal pure returns (int128) {
        require(y != 0);
        uint128 result = divuu(x, y);
        require(result <= uint128(MAX_64x64));
        return int128(result);
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return unsigned 64.64-bit fixed point number
     */
    function divuu(uint256 x, uint256 y) internal pure returns (uint128) {
        require(y != 0);

        uint256 result;

        if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            result = (x << 64) / y;
        else {
            uint256 msb = 192;
            uint256 xc = x >> 192;
            if (xc >= 0x100000000) {
                xc >>= 32;
                msb += 32;
            }
            if (xc >= 0x10000) {
                xc >>= 16;
                msb += 16;
            }
            if (xc >= 0x100) {
                xc >>= 8;
                msb += 8;
            }
            if (xc >= 0x10) {
                xc >>= 4;
                msb += 4;
            }
            if (xc >= 0x4) {
                xc >>= 2;
                msb += 2;
            }
            if (xc >= 0x2) msb += 1; // No need to shift xc anymore

            result = (x << (255 - msb)) / (((y - 1) >> (msb - 191)) + 1);
            require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

            uint256 hi = result * (y >> 128);
            uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

            uint256 xh = x >> 192;
            uint256 xl = x << 64;

            if (xl < lo) xh -= 1;
            xl -= lo; // We rely on overflow behavior here
            lo = hi << 128;
            if (xl < lo) xh -= 1;
            xl -= lo; // We rely on overflow behavior here

            assert(xh == hi >> 128);

            result += xl / y;
        }

        require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return uint128(result);
    }
}


pragma experimental ABIEncoderV2;

/// @title RigelGift is responsible for managing crypto rewards and airdrops
contract GiftDappInfluencer is Ownable {
    using SafeMath for uint256;
    using SafeMathUint8 for uint8;

    uint8 public _maxBuyableSpins;
    uint8 public _maxReferralSpins;

    address public _RGPTokenAddress;
    address public _RGPTokenReceiver;

    uint256 public _rewardProjectCounter;
    uint256 public _perSpinFee = 10 * 10**18;
    uint256 public _subscriptionFee = 10 * 10**18;

    // address _RGPTokenAddress = "0x4af5ff1a60a6ef6c7c8f9c4e304cd9051fca3ec0";

    constructor(address _rigel) public {
        _RGPTokenReceiver = _msgSender();
        _RGPTokenAddress = _rigel;
        _maxBuyableSpins = 5;
        _maxReferralSpins = 5;
        _rewardProjectCounter = 1;
    }
    // Defining a ticker reward inforamtion
    struct TickerInfo {
        uint8 textIndex;
        uint8 weight;
        address token;
        uint256 rewardAmount;
        uint256 cumulitiveSum;
        uint256 claims;
        uint256 initialClaimTotal;
    }

    // Defining a project reward inforamtion
    struct TokenInfo {
        address token;
        uint256 balance;
        uint256 totalFunds;
    }

    // Defining a Project Reward
    struct RewardProject {
        bool status;
        address projOwner;
        uint256 tryCount;
        uint256 retryPeriod;
        uint256 rewardProjectID;
        uint256 claimedCount;
        uint256 projectStartTime;
        uint256 activePeriodInDays;
        uint256 totalSumOfWeights;
    }

    // Defining a User Reward Claim Data
    struct UserClaimData {
        uint8 bSpinAvlb;
        uint8 bSpinUsed;
        uint8 rSpinAvlb;
        uint8 rSpinUsed;
        uint256 time;
        uint256 pSpin;
    }

    // All tickers for a given RewardProject
    mapping(uint256 => TickerInfo[]) public rewardTickers;

    // All rewards for a given RewardProject
    mapping(uint256 => TokenInfo[]) public rewardTokens;

    // Mapping of the ProjectReward and its information
    mapping(uint256 => RewardProject) public rewardProjMapping;

    // Mapping of the project, rewardees and their claim data
    mapping(uint256 => mapping(address => UserClaimData)) public projectClaims;

    mapping(address => uint256) private updateEvent;

    // Simply all projectIDs for traversing
    uint256[] public rewardProjects;

    // Event when a Reward Project is created
    event RewardProjectCreate(
        address indexed projectOwner,
        uint256 indexed projectIndex
    );
    // Event when a Reward Project is edited by owner
    event RewardProjectEdit(
        address indexed projectOwner,
        uint256 indexed projectIndex
    );
    // Event when a Reward Project is closed by owner
    event RewardProjectClose(
        address indexed projectOwner,
        uint256 indexed projectIndex
    );

    // Event when a Rewards in a Project is withdrawn
    event RewardsWithdrawn(
        address indexed projectOwner,
        uint256 indexed projectIndex
    );

    // Event when an user buys spins
    event SpinBought(
        uint256 indexed projectIndex,
        address indexed buyer,
        uint8 indexed count
    );

    // Event when an user earns a spin
    event SpinEarned(
        uint256 indexed projectIndex,
        address indexed linkCreator,
        address indexed linkUser
    );

    // Spin and Claim Rewards
    event RewardEarned(
        uint256 indexed projectIndex,
        address indexed winner,
        uint8 indexed ticker
    );

    function onlyActiveProject(uint256 projectID) private view {
        RewardProject memory proj = rewardProjMapping[projectID];
        require(proj.status == true, "RigelGift: Active Project Only");
    }

    //create the reward project
    function createRewardProject(
        uint256 tryCount,
        uint256 retryPeriod,
        uint256 activePeriodInDays,
        bytes[] calldata rewards,
        bytes[] calldata tickerInfo
    ) external {
        // RGP Tokens must be approved for transfer
        
        IERC20(_RGPTokenAddress).transferFrom(
            _msgSender(),
            _RGPTokenReceiver,
            _subscriptionFee
        );

        (bool status, uint256 sumOfWeights) =
            _setTickers(_rewardProjectCounter, tickerInfo);
        require(status == true, "RigelGift: _setTickers fail");

        status = _setRewards(_rewardProjectCounter, rewards);
        require(status == true, "RigelGift: _setRewards fail");

        RewardProject memory rewardProj =
            RewardProject(
                true,
                _msgSender(),
                tryCount,
                retryPeriod,
                _rewardProjectCounter,
                0,
                block.timestamp,
                activePeriodInDays,
                sumOfWeights
            );
        rewardProjMapping[_rewardProjectCounter] = rewardProj;
        rewardProjects.push(_rewardProjectCounter);
        updateEvent[_msgSender()] = updateEvent[_msgSender()].nadd(1);

        emit RewardProjectCreate(_msgSender(), _rewardProjectCounter);
        _rewardProjectCounter = _rewardProjectCounter.nadd(1);
    }
    function _setRewardProcess(bytes calldata reward) internal returns (TokenInfo memory t) {
        (address token, uint256 balance) = decodeTokenInfo(reward);

        require(token != address(0), "RigelGift: ZeroAddress");
        // transfer token to gift contract:
        
        IERC20(token).transferFrom(_msgSender(), address(this), balance);
        TokenInfo memory tI = TokenInfo(token, balance, balance);
        return tI;
    }
    function _setRewards(uint256 projectID, bytes[] calldata rewards)
        private
        returns (bool status)
    {
        require(rewards.length > 0 && rewards.length < 3, "RigelGift: Must have at least one token and not more than 2");
        TokenInfo memory t = _setRewardProcess(rewards[0]);
        rewardTokens[projectID].push(t);
        if(rewards.length == 2){
            TokenInfo memory t2 = _setRewardProcess(rewards[1]);
            rewardTokens[projectID].push(t2);
        }
        return true;
    }

    function _setTickers(uint256 projectID, bytes[] calldata tickerInfo)
        private
        returns (bool status, uint256 cumulitiveSum)
    {
        uint256 csum;

        for (uint8 i = 0; i < tickerInfo.length; i++) {
            ( 
                uint8 textIndex,
                uint8 weight, 
                address token, 
                uint256 amount
            ) = decodeTickerInfo(tickerInfo[i]);

            isValidWeight(token, weight);

            csum = csum.nadd(weight);

            TickerInfo memory ticker =
                TickerInfo(textIndex, weight, token, amount, csum, 0, 0);
            rewardTickers[projectID].push(ticker);
        }

        return (true, csum);
    }

    //edit rewards
    function editRewardProject(
        uint256 projectID,
        uint256 tryCount,
        uint256 retryPeriod,
        uint256 addToActivePeriod,
        bytes[] calldata rewards,
        bytes[] calldata tickerInfo
    ) external {
        RewardProject storage proj = rewardProjMapping[projectID];

        require(proj.projOwner == _msgSender(), "RigelGift: ProjectOwner Only");

        require(proj.status == true, "RigelGift: Active Project Only");

        proj.tryCount = tryCount;
        proj.retryPeriod = retryPeriod;
        proj.activePeriodInDays.nadd(addToActivePeriod);

        // delete rewardTickers[projectID];
        (bool status, uint256 sumOfWeights) =
            _editTickers(projectID, tickerInfo);
        require(status == true, "RigelGift: _editTickers fail");
        proj.totalSumOfWeights = sumOfWeights;

        status = _editRewards(projectID, rewards);
        require(status == true, "RigelGift: _editRewards fail");

        emit RewardProjectEdit(_msgSender(), projectID);
    }
    function _editRewardProcess (uint8 position, uint256 projectID, bytes calldata reward) private returns (bool) {
        TokenInfo[] storage rewards = rewardTokens[projectID];
        (address token, uint256 topup) = decodeTokenInfo(reward);
        if (topup != 0) {
            require(rewards[position].token == token, "RigelGift: Invalid Token");
            IERC20(token).transferFrom(
                _msgSender(),
                address(this),
                topup
            ); 
            rewards[position].balance = rewards[position].balance.nadd(topup);
            rewards[position].totalFunds = rewards[position].totalFunds.nadd(topup);
            // transfer token to gift contract:  
        }
        return true;
    }
    function _editRewards(uint256 projectID, bytes[] calldata editRewards)
        private
        returns (bool status)
    {
        if(editRewards.length > 0){
            _editRewardProcess(0, projectID, editRewards[0]);
            if(editRewards.length > 1){
                _editRewardProcess(1, projectID, editRewards[1]);
            }
        }
        return true;
    }
    function _editTickers(uint256 projectID, bytes[] calldata newTickerInfo)
        private
        returns (bool status, uint256 cumulitivieSum)
    {
        TickerInfo[] storage tickers = rewardTickers[projectID];

        require(
            tickers.length == newTickerInfo.length,
            "RigelGift: Invalid Ticker Count"
        );

        uint256 csum;

        for (uint8 i = 0; i < tickers.length; i++) {
            (
                uint8 textIndex, 
                uint8 weight, 
                address token, 
                uint256 amount 
            ) = decodeTickerInfo(newTickerInfo[i]);

            isValidWeight(token, weight);

            csum = csum.nadd(weight);

            require(tickers[i].token == token, "RigelGift: Invalid Token");

            tickers[i].initialClaimTotal = tickers[i].initialClaimTotal.nadd(
                tickers[i].claims.nmul(tickers[i].rewardAmount)
            );
            tickers[i].rewardAmount = amount;
            tickers[i].cumulitiveSum = csum;
            tickers[i].weight = weight;
            tickers[i].claims = 0;
            tickers[i].textIndex = textIndex;
        }
        return (true, csum);
    }

    function isValidWeight(address token, uint8 weight) private pure {
        if (token != address(0)) {
            require(weight != 0, "RigelGift: Invalid Weight");
        }
    }

    function decodeTokenInfo(bytes calldata rewardInfo)
        private
        pure
        returns (address, uint256)
    {
        return abi.decode(rewardInfo, (address, uint256));
    }

    function decodeTickerInfo(bytes calldata tickerInfo)
        private
        pure
        returns (
            uint8,
            uint8,
            address,
            uint256
        )
    {
        return abi.decode(tickerInfo, (uint8, uint8, address, uint256));
    }

    function closeProject(uint256 projectID) public {
        //set reward project to inactive status
        RewardProject storage proj = rewardProjMapping[projectID];

        require(proj.projOwner == _msgSender(), "RigelGift: ProjectOwner Only");

        require(
            block.timestamp >=
                proj.projectStartTime.nadd(proj.activePeriodInDays.nmul(1 days)),
            "RigelGift: Before Active Period"
        );

        proj.status = false;

        emit RewardProjectClose(proj.projOwner, projectID);
    }

    //withdraw tokens and close project
    function closeProjectWithdrawTokens(uint256 projectID) external {
        RewardProject storage proj = rewardProjMapping[projectID];

        //set reward project to inactive status
        closeProject(projectID);

        //transfer balance reward tokens to project owner
        TokenInfo[] memory rewards = rewardTokens[projectID];
        for (uint8 i = 0; i < rewards.length; i++) {
            TokenInfo memory reward = rewards[i];
            uint256 tempBalance = reward.balance;
            reward.balance = 0;
            IERC20(reward.token).transfer(proj.projOwner, tempBalance);
        }

        emit RewardsWithdrawn(proj.projOwner, projectID);
    }

    //claim rewards
    function claimReward(uint256 projectID, uint8 tickerNum) private {
        RewardProject storage proj = rewardProjMapping[projectID];
        require(proj.status == true, "RigelGift: Active Project Only");

        proj.claimedCount = proj.claimedCount.nadd(1);

        TickerInfo storage ticker = rewardTickers[projectID][tickerNum];

        if (ticker.token == address(0)) {
            setClaimData(projectID);
            return;
        }

        TokenInfo storage chosenReward;
        TokenInfo[] storage rewardInfos = rewardTokens[projectID];
        for (uint8 i = 0; i < rewardInfos.length; i++) {
            if (rewardInfos[i].token == ticker.token) {
                chosenReward = rewardInfos[i];
                break;
            }
        }

        isEligibleForReward(projectID);

        chosenReward.balance = chosenReward.balance.nsub(
            ticker.rewardAmount
        );

        setClaimData(projectID);
        ticker.claims = ticker.claims.nadd(1);

        require(
            IERC20(chosenReward.token).transfer(
                _msgSender(),
                ticker.rewardAmount
            )
        );
    }

    function isEligibleForReward(uint256 projectID) internal view {
        RewardProject memory proj = rewardProjMapping[projectID];

        require(proj.status == true, "RigelGift: Active Project Only");

        UserClaimData memory claim = projectClaims[projectID][_msgSender()];

        // If BoughtSpins Available and BoughtSpins Used are equal that means they are used up or
        // If RefferalSpinsAvailable and ReferralSpinsUsed are equal that means they are used up
        if (!(isBoughtSpinsAvlb(claim) || isReferrralSpinsAvlb(claim))) {
            require(
                block.timestamp >= (claim.time + proj.retryPeriod),
                "RigelGift: Claim before retry period"
            );

            require(
                claim.pSpin < proj.tryCount,
                "RigelGift: Claim limit reached"
            );
        }
        
    }

    // Checks if any bought spins are available
    function isBoughtSpinsAvlb(UserClaimData memory claim)
        private
        pure
        returns (bool)
    {
        // If BoughtSpins Available and BoughtSpins Used are equal that means they are used up
        if (claim.bSpinAvlb == claim.bSpinUsed) {
            return false;
        } else {
            return true;
        }
    }

    // Checks if any referral spins are available
    function isReferrralSpinsAvlb(UserClaimData memory claim)
        private
        pure
        returns (bool)
    {
        // If RefferalSpins Available and ReferralSpins Used are equal that means they are used up
        if (claim.rSpinAvlb == claim.rSpinUsed) {
            return false;
        } else {
            return true;
        }
    }

    // Captures and updates the claim Data w.r.t all spin types
    function setClaimData(uint256 projectID) private {
        UserClaimData storage claim = projectClaims[projectID][_msgSender()];

        if (isBoughtSpinsAvlb(claim)) {
            // If BoughtSpins Available and BoughtSpins Used are equal that means they are used up
            claim.bSpinUsed = claim.bSpinUsed.add(1);
        } else if (isReferrralSpinsAvlb(claim)) {
            // If RefferalSpins Available and ReferralSpins Used are equal that means they are used up
            claim.rSpinUsed = claim.rSpinUsed.add(1);
        } else {
            claim.time = now;
            claim.pSpin = claim.pSpin.nadd(1);
        }
        projectClaims[projectID][_msgSender()] = claim;
    }

    // Set the subscription fee, settable only be the owner
    function setSubscriptionFee(uint256 fee) external onlyOwner {
        _subscriptionFee = fee;
    }

    // Set the buy spin fee, settable only be the owner
    function setPerSpinFee(uint256 fee) external onlyOwner {
        _perSpinFee = fee;
    }

    // Set the RGP receiver address
    function setRGPReveiverAddress(address rgpReceiver) external onlyOwner {
        require(rgpReceiver != address(0), "RigelGift: ZeroAddress");

        _RGPTokenReceiver = rgpReceiver;
    }

    // Set the RGP Token address
    function setRGPTokenAddress(address rgpToken) external onlyOwner {
        _RGPTokenAddress = rgpToken;
    }

    // Set maxbuyable spins per user address, per project
    function setMaxBuyableSpins(uint8 count) external onlyOwner {
        _maxBuyableSpins = count;
    }

    // Allows user to buy specified spins for the specified project
    function buySpin(uint256 projectID, uint8 spinCount) external {
        onlyActiveProject(projectID);
        UserClaimData storage claim = projectClaims[projectID][_msgSender()];

        // Eligible to buy spins only upto specified limit
        require(
            claim.bSpinAvlb + spinCount <= _maxBuyableSpins,
            "RigelGift: Beyond Spin Limit"
        );

        // RGP Tokens must be approved for transfer
        
        IERC20(_RGPTokenAddress).transferFrom(
            _msgSender(),
            _RGPTokenReceiver,
            _perSpinFee * spinCount
        );

        // Update Available spins
        claim.bSpinAvlb = claim.bSpinAvlb.add(spinCount);
        projectClaims[projectID][_msgSender()] = claim;

        emit SpinBought(projectID, _msgSender(), spinCount);
    }

    // Set max referral spins per user address, per project that can be earned
    function setMaxReferralSpins(uint8 count) external onlyOwner {
        _maxReferralSpins = count;
    }

    function spinAndClaim(uint256 projectID, address linkCreator) external {
        onlyActiveProject(projectID);
        uint8 tickerNum = generateRandomTicker(projectID);
        // user claims reward
        claimReward(projectID, tickerNum);

        require(linkCreator != _msgSender(), "RigelGift: Self Refferal fail");

        if (linkCreator != address(0)) {
            UserClaimData storage claim = projectClaims[projectID][linkCreator];

            // Eligible to earn referral spins only upto specified limit
            if (claim.rSpinAvlb.add(1) <= _maxReferralSpins) {
                claim.rSpinAvlb = claim.rSpinAvlb.add(1);
                projectClaims[projectID][linkCreator] = claim;

                emit SpinEarned(projectID, linkCreator, _msgSender());
            }
        }
        emit RewardEarned(projectID, _msgSender(), tickerNum);
    }

    function generateRandomTicker(uint256 projectID)
        private
        view
        returns (uint8 tickerNum)
    {
        RewardProject memory proj = rewardProjMapping[projectID];
        TickerInfo[] memory tickers = rewardTickers[projectID];

        //calculateRandomNumber(): Calculates a random number in the range 0.00000 to 1.00000
        // with a presicion to 5 decimal places
        uint256 r =
            ABDKMath64x64.mulu(
                ABDKMath64x64.abs(calculateRandomNumber()),
                proj.totalSumOfWeights
            );

        uint8 i;
        for (i = 0; i < tickers.length; i++) {
            if (r <= tickers[i].cumulitiveSum) {
                break;
            }
        }
        return i;
    }

    // Calculates a random number in the range 0.00000 to 1.00000 with a presicion to 5 decimal places
    // function calculateRandomNumber(uint256 nonce)
    function calculateRandomNumber() private view returns (int128) {
        uint256 max = uint256(0) - uint256(1);
        uint256 scalifier = max / 100000;
        uint256 seed =
            uint256(
                keccak256(abi.encodePacked(block.timestamp, _msgSender(), block.difficulty))
            ) / scalifier;
        return ABDKMath64x64.divu(seed, 100000);
    }
    //DAPP GETTERS
    function projectClaimsByProjectId(uint256 projectID) external view returns (uint256) {
        RewardProject memory proj = rewardProjMapping[projectID];
        return proj.claimedCount;
    }
    function getProjectTokenBalance(uint256 projectID, address token) external view returns (uint256) {
        TokenInfo memory chosenReward;
        TokenInfo[] memory rewardInfos = rewardTokens[projectID];
        for (uint8 i = 0; i < rewardInfos.length; i++) {
            if (rewardInfos[i].token == token) {
                chosenReward = rewardInfos[i];
                break;
            }
        }
        return chosenReward.balance;
    }
    function getProjectTickers(uint256 projectID) external view returns(TickerInfo[] memory){
        return rewardTickers[projectID];
    }
    function getProjectTokens(uint256 projectID) external view returns (TokenInfo[] memory) {
        return rewardTokens[projectID];
    }

    function eventsCreated(address _creator) public view returns (uint256){
        return updateEvent[_creator];
    }
}