// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "./libraries/AddressPagination.sol";
import "./interfaces/IFirestarterSFT.sol";

contract FirestarterSFTVesting is Initializable {
    using AddressPagination for address[];
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct VestingParams {
        // Name of this tokenomics
        string vestingName;
        // Total amount to be vested
        uint256 amountToBeVested;
        // Period before release vesting starts, also it unlocks initialUnlock reward tokens. (in time unit of block.timestamp)
        uint256 lockPeriod;
        // Percent of tokens initially unlocked
        uint256 initialUnlock;
        // Period to release all reward token, after lockPeriod + vestingPeriod it releases 100% of reward tokens. (in time unit of block.timestamp)
        uint256 vestingPeriod;
        // Amount of time in seconds between withdrawal periods.
        uint256 releaseInterval;
        // Release percent in each withdrawing interval
        uint256 releaseRate;
    }

    /// @notice General decimal values ACCURACY unless specified differently (e.g. fees, exchange rates)
    uint256 public constant ACCURACY = 1e10;

    /*************************** Vesting Params *************************/

    /// @notice Total balance of this vesting contract
    uint256 public amountToBeVested;

    /// @notice Name of this vesting
    string public vestingName;

    /// @notice Start time of vesting
    uint256 public startTime;

    /// @notice Intervals that the release happens. Every interval, releaseRate of tokens are released.
    uint256 public releaseInterval;

    /// @notice Release percent in each withdrawing interval
    uint256 public releaseRate;

    /// @notice Percent of tokens initially unlocked
    uint256 public initialUnlock;

    /// @notice Period before release vesting starts, also it unlocks initialUnlock reward tokens. (in time unit of block.timestamp)
    uint256 public lockPeriod;

    /// @notice Period to release all reward token, after lockPeriod + vestingPeriod it releases 100% of reward tokens. (in time unit of block.timestamp)
    uint256 public vestingPeriod;

    /// @notice Reward token of the project.
    address public rewardToken;

    /*************************** Status Info *************************/
    /// @notice FirestarterSFT
    IFirestarterSFT public vestingSFT;

    /// @notice Owner address(presale)
    address public owner;

    /// @notice Sum of all user's vesting amount
    uint256 public totalVestingAmount;

    // Participants list
    address[] internal participants;
    mapping(address => uint256) internal indexOf;
    mapping(address => bool) internal inserted;

    /// @notice Worker's address allowed to modify whitelist
    address public worker;

    event InitVesting(address indexed rewardToken, address indexed sft, VestingParams params);

    /// @notice An event emitted when the vesting schedule is updated.
    event VestingInfoUpdated(address indexed registeredAddress, uint256 totalAmount);

    /// @notice An event emitted when withdraw happens
    event Withdraw(address indexed registeredAddress, uint256 amountWithdrawn);

    /// @notice An event emitted when startTime is set
    event StartTimeSet(uint256 startTime);

    /// @notice An event emitted when owner is updated
    event OwnerUpdated(address indexed newOwner);

    modifier onlyOwner() {
        require(owner == msg.sender, "Requires Owner Role");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner or the worker.
     */
    modifier onlyOwnerOrWorker() {
        require(owner == msg.sender || worker == msg.sender, "Vesting: caller is not the owner nor the worker");
        _;
    }

    function initialize(
        address _rewardToken,
        address _vestingSFT,
        VestingParams memory _params
    ) external initializer {
        require(_rewardToken != address(0), "initialize: rewardToken cannot be zero");
        require(_params.releaseRate > 0, "initialize: release rate cannot be zero");
        require(_params.releaseInterval > 0, "initialize: release interval cannot be zero");

        owner = msg.sender;
        rewardToken = _rewardToken;
        vestingSFT = IFirestarterSFT(_vestingSFT);

        vestingName = _params.vestingName;
        amountToBeVested = _params.amountToBeVested;
        initialUnlock = _params.initialUnlock;
        releaseInterval = _params.releaseInterval;
        releaseRate = _params.releaseRate;
        lockPeriod = _params.lockPeriod;
        vestingPeriod = _params.vestingPeriod;

        emit InitVesting(_rewardToken, _vestingSFT, _params);
    }

    /**
     * @notice Return the number of participants
     */
    function participantCount() external view returns (uint256) {
        return participants.length;
    }

    /**
     * @notice Return the list of participants
     */
    function getParticipants(uint256 page, uint256 limit) external view returns (address[] memory) {
        return participants.paginate(page, limit);
    }

    /**
     * @notice Init Presale contract
     * @dev Thic changes the owner to presale
     * @param presale Presale contract address
     */
    function init(address presale) external onlyOwner {
        require(presale != address(0), "init: owner cannot be zero");
        owner = presale;
        emit OwnerUpdated(presale);
        IERC20Upgradeable(rewardToken).safeApprove(presale, type(uint256).max);
    }

    /**
     * @notice Update user vesting information
     * @dev This is called by presale contract
     * @param recp Address of Recipient
     * @param amount Amount of reward token
     */
    function updateRecipient(address recp, uint256 amount) external onlyOwnerOrWorker {
        require(
            startTime == 0 || startTime >= block.timestamp,
            "updateRecipient: Cannot update the receipient after started"
        );
        require(amount > 0, "updateRecipient: Cannot vest 0");

        vestingSFT.mint(recp, amount, false);

        totalVestingAmount = totalVestingAmount + amount;

        uint256 depositedAmount = IERC20Upgradeable(rewardToken).balanceOf(address(this));
        require(depositedAmount >= totalVestingAmount, "updateRecipient: Vesting amount exceeds current balance");

        if (inserted[recp] == false) {
            inserted[recp] = true;
            indexOf[recp] = participants.length;
            participants.push(recp);
        }

        emit VestingInfoUpdated(recp, amount);
    }

    /**
     * @notice Set vesting start time
     * @dev This should be called before vesting starts
     * @param newStartTime New start time
     */
    function setStartTime(uint256 newStartTime) external onlyOwner {
        // Only allow to change start time before the counting starts
        require(startTime == 0 || startTime >= block.timestamp, "setStartTime: Already started");
        require(newStartTime > block.timestamp, "setStartTime: Should be time in future");

        startTime = newStartTime;

        emit StartTimeSet(newStartTime);
    }

    /**
     * @notice Withdraw tokens when vesting is ended
     * @dev Anyone can claim their tokens
     * Warning: Take care of re-entrancy attack here.
     * Reward tokens are from not our own, which means
     * re-entrancy can happen when the transfer happens.
     * For now, we do checks-effects-interactions, but
     * for absolute safety, we may use reentracny guard.
     */
    function withdraw(uint256 tokenId) external {
        IFirestarterSFT.VestingInfo memory vestingInfo = vestingSFT.getVestingInfo(tokenId);

        if (vestingInfo.totalAmount == 0) return;

        uint256 _vested = vested(tokenId);
        uint256 _withdrawable = _vested - vestingInfo.amountWithdrawn;

        require(_withdrawable > 0, "Nothing to withdraw");
        address beneficiary = IERC721Upgradeable(address(vestingSFT)).ownerOf(tokenId);
        vestingSFT.updateAmountWithdrawn(tokenId, _vested);

        IERC20Upgradeable(rewardToken).safeTransfer(beneficiary, _withdrawable);
        emit Withdraw(beneficiary, _withdrawable);
    }

    /**
     * @notice Returns the amount of vested reward tokens
     * @dev Calculates available amount depending on vesting params
     * @param tokenId SFT tokenId
     * @return amount : Amount of vested tokens
     */
    function vested(uint256 tokenId) public view virtual returns (uint256 amount) {
        IFirestarterSFT.VestingInfo memory vestingInfo = vestingSFT.getVestingInfo(tokenId);

        uint256 lockEndTime = startTime + lockPeriod;
        uint256 vestingEndTime = lockEndTime + vestingPeriod;

        if (startTime == 0 || vestingInfo.totalAmount == 0 || block.timestamp <= lockEndTime) {
            return 0;
        }

        if (block.timestamp > vestingEndTime) {
            return vestingInfo.totalAmount;
        }

        uint256 initialUnlockAmount = (vestingInfo.totalAmount * initialUnlock) / ACCURACY;
        uint256 unlockAmountPerInterval = (vestingInfo.totalAmount * releaseRate) / ACCURACY;
        uint256 vestedAmount = ((block.timestamp - lockEndTime) / releaseInterval) *
            unlockAmountPerInterval +
            initialUnlockAmount;

        uint256 withdrawnAmount = vestingInfo.amountWithdrawn;
        vestedAmount = withdrawnAmount > vestedAmount ? withdrawnAmount : vestedAmount;

        return vestedAmount > vestingInfo.totalAmount ? vestingInfo.totalAmount : vestedAmount;
    }

    /**
     * @notice Return locked amount
     * @return Locked reward token amount
     */
    function locked(uint256 tokenId) public view returns (uint256) {
        IFirestarterSFT.VestingInfo memory vestingInfo = vestingSFT.getVestingInfo(tokenId);

        uint256 totalAmount = vestingInfo.totalAmount;
        uint256 vestedAmount = vested(tokenId);
        return totalAmount - vestedAmount;
    }

    /**
     * @notice Return remaining withdrawable amount
     * @return Remaining vested amount of reward token
     */
    function withdrawable(uint256 tokenId) public view returns (uint256) {
        IFirestarterSFT.VestingInfo memory vestingInfo = vestingSFT.getVestingInfo(tokenId);

        uint256 vestedAmount = vested(tokenId);
        uint256 withdrawnAmount = vestingInfo.amountWithdrawn;
        return vestedAmount - withdrawnAmount;
    }

    /**
     * @notice Set worker
     * @param _worker worker's address
     */
    function setWorker(address _worker) external onlyOwner {
        worker = _worker;
    }

    /**
     * @notice Remove worker
     */
    function removeWorker() external onlyOwner {
        worker = address(0);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library AddressPagination {
    function paginate(
        address[] memory array,
        uint256 page,
        uint256 limit
    ) internal pure returns (address[] memory result) {
        result = new address[](limit);
        for (uint256 i = 0; i < limit; i++) {
            if (page * limit + i >= array.length) {
                result[i] = address(0);
            } else {
                result[i] = array[page * limit + i];
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFirestarterSFT {
    struct VestingInfo {
        // Total amount of tokens to be vested.
        uint256 totalAmount;
        // The amount that has been withdrawn.
        uint256 amountWithdrawn;
        // If true minter can specify the totalAmount after mint
        bool unset;
    }

    function getVestingInfo(uint256 tokenId) external view returns (VestingInfo memory);

    function updateAmountWithdrawn(uint256 tokenId, uint256 withdrawn) external;

    function mint(address to, uint256 vestAmount, bool unset) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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