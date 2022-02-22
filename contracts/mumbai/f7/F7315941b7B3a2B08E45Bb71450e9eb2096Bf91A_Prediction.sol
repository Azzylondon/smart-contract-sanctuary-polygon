pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./utils/AccessProtected.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Prediction is AccessProtected, Pausable {
    using Address for address;
    using SafeERC20 for IERC20;

    IERC20 public immutable bund;

    address public treasury;

    uint256 public treasuryPercentage;

    struct League {
        string name;
        string sport;
    }

    League[] public leagues;

    struct Match {
        uint8 leagueId;
        uint256 espnMatchId;
        uint16 season;
    }

    Match[] public matches;

    //league to espnMatchId to Index
    mapping(uint8 => mapping(uint256 => uint256)) public matchIndex;

    struct Pool {
        uint256[] matchIds;
        uint16[] results;
        uint256 startTime;
        uint256 endTime;
        uint256 fee;
    }

    struct PoolPrediction {
        uint256[] matchIds;
        uint16[] choices;
        uint8 poolId;
        address predictor;
    }

    Pool[] public pools;

    PoolPrediction[] public predictions;

    // Address to poolId to Index of prediction
    mapping(address => mapping(uint256 => bool)) public isPredictedByPool;

    event MatchAdded(
        uint8 indexed leagueId,
        uint256 espnMatchId,
        uint16 indexed season,
        uint256 indexed matchId
    );

    event MatchUpdated(
        uint8 indexed leagueId,
        uint256 espnMatchId,
        uint16 indexed season,
        uint256 indexed matchId
    );

    event LeagueAdded(uint8 indexed leagueId, string name, string sport);

    event PoolAdded(
        uint256 indexed poolId,
        uint256[] matchIds,
        uint256 startTime,
        uint256 endTime,
        uint256 fee
    );

    event PoolUpdated(
        uint256 indexed poolId,
        uint256[] matchIds,
        uint256 startTime,
        uint256 endTime,
        uint256 fee
    );

    event PoolPredicted(
        uint256 indexed predictionId,
        uint256[] matchIds,
        uint16[] choices,
        uint256 poolId,
        address predictor
    );

    event PredictionUpdated(
        uint256 indexed predictionId,
        uint256[] matchIds,
        uint16[] choices,
        uint256 poolId,
        address predictor
    );

    event RewardedPools(uint256 poolId, address[] winners, uint256[] amount);

    event GradedPools(uint256 poolId, uint16[] results);

    constructor(IERC20 _bund) {
        bund = _bund;
    }

    function updateTreasuryPercentage(uint256 _percent) external onlyAdmin {
        treasuryPercentage = _percent;
    }

    function updateTreasury(address _treasury) external onlyAdmin {
        require(_treasury != address(0), "Null Address cannot be used");
        require(
            !_treasury.isContract(),
            "Cannot update contract address as treasury"
        );
        treasury = _treasury;
    }

    function addLeague(League calldata _league)
        external
        onlyAdmin
        whenNotPaused
    {
        require(
            bytes(_league.name).length != 0 && bytes(_league.sport).length != 0
        );
        leagues.push(_league);
        emit LeagueAdded(
            uint8(leagues.length - 1),
            _league.name,
            _league.sport
        );
    }

    function updateLeague(uint8 _id, League calldata _league)
        external
        onlyAdmin
        whenNotPaused
    {
        require(bytes(leagues[_id].name).length != 0, "Invalid league Id");
        leagues[_id] = _league;
    }

    function addPool(Pool calldata _pool) external onlyAdmin whenNotPaused {
        require(
            _pool.startTime >= block.timestamp &&
                _pool.endTime > block.timestamp &&
                _pool.startTime < _pool.endTime,
            "Invalid start/end time"
        );
        require(_pool.results.length == 0, "Incorrect Results");
        for (uint256 i = 0; i < _pool.matchIds.length; i++) {
            uint256 matchId = _pool.matchIds[i];
            require(matches[matchId].espnMatchId != 0, "Match Not present");
        }
        pools.push(_pool);
        emit PoolAdded(
            pools.length - 1,
            _pool.matchIds,
            _pool.startTime,
            _pool.endTime,
            _pool.fee
        );
    }

    function updatePool(uint256 _poolId, Pool calldata _pool)
        external
        onlyAdmin
        whenNotPaused
    {
        require(pools[_poolId].endTime > 0, "Invalid Pool Id");
        require(block.timestamp <= pools[_poolId].startTime, "Pool started");
        require(
            _pool.startTime >= block.timestamp &&
                _pool.endTime > block.timestamp &&
                _pool.startTime < _pool.endTime,
            "Invalid start/end time"
        );
        require(_pool.results.length == 0, "Incorrect Results");
        for (uint256 i = 0; i < _pool.matchIds.length; i++) {
            uint256 matchId = _pool.matchIds[i];
            require(matches[matchId].espnMatchId != 0, "Match Not present");
        }
        pools[_poolId] = _pool;
        emit PoolUpdated(
            _poolId,
            _pool.matchIds,
            _pool.startTime,
            _pool.endTime,
            _pool.fee
        );
    }

    function updateMatch(uint256 matchId, Match memory matchData)
        external
        onlyAdmin
        whenNotPaused
    {
        uint8 leagueId = matchData.leagueId;
        require(bytes(leagues[leagueId].name).length != 0, "Invalid league Id");
        require(matches[matchId].espnMatchId > 0, "Match doesn't exist");
        matches[matchId] = matchData;
        emit MatchUpdated(
            leagueId,
            matchData.espnMatchId,
            matchData.season,
            matchId
        );
    }

    function _addMatch(Match memory matchData) private {
        uint8 leagueId = matchData.leagueId;
        uint256 espnMatchId = matchData.espnMatchId;
        require(matchIndex[leagueId][espnMatchId] == 0, "Match already added");
        if (matches.length >= 1) {
            if (matches[0].leagueId == leagueId) {
                require(
                    matches[0].espnMatchId != espnMatchId,
                    "Match already added"
                );
            }
        }
        require(bytes(leagues[leagueId].name).length != 0, "Invalid league Id");
        matches.push(matchData);
        matchIndex[leagueId][espnMatchId] = matches.length - 1;
        emit MatchAdded(
            leagueId,
            matchData.espnMatchId,
            matchData.season,
            matches.length - 1
        );
    }

    function addMatch(Match calldata _matchData)
        external
        onlyAdmin
        whenNotPaused
    {
        _addMatch(_matchData);
    }

    function addMatches(Match[] calldata _matchData)
        external
        onlyAdmin
        whenNotPaused
    {
        for (uint256 i = 0; i < _matchData.length; i++) {
            _addMatch(_matchData[i]);
        }
    }

    function isMatchExistsInPool(uint256 _poolId, uint256 _matchId)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < pools[_poolId].matchIds.length; i++) {
            if (pools[_poolId].matchIds[i] == _matchId) {
                return true;
            }
        }
    }

    function addPoolPrediction(PoolPrediction calldata prediction)
        external
        whenNotPaused
    {
        address sender = _msgSender();
        require(prediction.predictor == sender);
        require(
            prediction.matchIds.length == prediction.choices.length,
            "matchIds.length != choices.length"
        );
        require(pools[prediction.poolId].startTime > 0, "Invalid Pool Id");
        for (uint256 i = 0; i < prediction.matchIds.length; i++) {
            require(
                isMatchExistsInPool(prediction.poolId, prediction.matchIds[i]),
                "Invalid match Id"
            );
        }
        require(
            pools[prediction.poolId].startTime <= block.timestamp &&
                pools[prediction.poolId].endTime >= block.timestamp,
            "Pools open/closed for Predictions"
        );
        require(
            !isPredictedByPool[sender][prediction.poolId],
            "Match Predicted"
        );
        predictions.push(prediction);
        isPredictedByPool[sender][prediction.poolId] = true;
        if (treasury != address(0) && treasuryPercentage != 0) {
            uint256 contractFee = ((pools[prediction.poolId].fee *
                treasuryPercentage) / 100) / 100;
            bund.transferFrom(sender, treasury, contractFee);
            bund.transferFrom(
                sender,
                address(this),
                pools[prediction.poolId].fee - contractFee
            );
        } else {
            bund.transferFrom(
                sender,
                address(this),
                pools[prediction.poolId].fee
            );
        }
        emit PoolPredicted(
            predictions.length - 1,
            prediction.matchIds,
            prediction.choices,
            prediction.poolId,
            sender
        );
    }

    function updatePoolPrediction(
        uint256 _predictionId,
        PoolPrediction calldata prediction
    ) external whenNotPaused {
        address sender = _msgSender();
        require(
            isPredictedByPool[sender][prediction.poolId],
            "Pool not yet Predicted"
        );
        require(
            predictions[_predictionId].poolId == prediction.poolId,
            "Invalid Pool Id"
        );
        require(
            predictions[_predictionId].predictor == sender &&
                prediction.predictor == sender,
            "Invalid predictor"
        );
        require(
            prediction.matchIds.length == prediction.choices.length,
            "matchIds.length != choices.length"
        );
        for (uint256 i = 0; i < prediction.matchIds.length; i++) {
            require(
                isMatchExistsInPool(prediction.poolId, prediction.matchIds[i]),
                "Invalid match Id"
            );
        }
        require(
            pools[prediction.poolId].endTime >= block.timestamp,
            "Pools closed"
        );
        predictions[_predictionId] = prediction;
        emit PredictionUpdated(
            _predictionId,
            prediction.matchIds,
            prediction.choices,
            prediction.poolId,
            sender
        );
    }

    function rewardPools(
        uint256 _poolId,
        address[] memory _winners,
        uint256[] memory _amounts
    ) external onlyAdmin whenNotPaused {
        address sender = _msgSender();
        require(
            _winners.length == _amounts.length,
            "winners.length != _amounts.length"
        );
        require(
            pools[_poolId].endTime < block.timestamp,
            "Pool is still active"
        );
        for (uint256 i = 0; i < _winners.length; i++) {
            address winner = _winners[i];
            uint256 amount = _amounts[i];
            bund.transferFrom(sender, winner, amount);
        }
        emit RewardedPools(_poolId, _winners, _amounts);
    }

    function gradePools(uint256 _poolId, uint16[] calldata _results)
        external
        onlyAdmin
        whenNotPaused
    {
        require(
            pools[_poolId].matchIds.length == _results.length,
            "matchIds.length != _results.length"
        );
        require(
            block.timestamp > pools[_poolId].endTime,
            "Pool is still active"
        );
        pools[_poolId].results = _results;
        emit GradedPools(_poolId, _results);
    }

    function getMatchIdsOfPool(uint256 _poolId)
        public
        view
        returns (uint256[] memory)
    {
        return pools[_poolId].matchIds;
    }

    function getResultsOfPool(uint256 _poolId)
        public
        view
        returns (uint16[] memory)
    {
        return pools[_poolId].results;
    }

    function getChoicesOfPrediction(uint256 _predictionId)
        public
        view
        returns (uint16[] memory)
    {
        return predictions[_predictionId].choices;
    }

    function pause() external whenNotPaused onlyAdmin {
        super._pause();
    }

    function unpause() external whenPaused onlyAdmin {
        super._unpause();
    }

    function withdrawERC20(IERC20 _token) external onlyAdmin {
        address sender = _msgSender();
        uint256 balance = _token.balanceOf(address(this));
        _token.transfer(sender, balance);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

abstract contract AccessProtected is Context, Ownable {
    mapping(address => bool) private _admins; // user address => admin? mapping

    event AdminAccessSet(address _admin, bool _enabled);

    /**
     * @notice Set Admin Access
     *
     * @param admin - Address of Minter
     * @param enabled - Enable/Disable Admin Access
     */
    function setAdmin(address admin, bool enabled) external onlyOwner {
        _admins[admin] = enabled;
        emit AdminAccessSet(admin, enabled);
    }

    /**
     * @notice Check Admin Access
     *
     * @param admin - Address of Admin
     * @return whether minter has access
     */
    function isAdmin(address admin) public view returns (bool) {
        return _admins[admin];
    }

    /**
     * Throws if called by any account other than the Admin.
     */
    modifier onlyAdmin() {
        require(_admins[_msgSender()] || _msgSender() == owner(), "Caller does not have Admin Access");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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