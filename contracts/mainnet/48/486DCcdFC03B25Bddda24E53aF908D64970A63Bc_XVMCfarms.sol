/**
 *Submitted for verification at polygonscan.com on 2021-12-06
*/

/**
 *Submitted for verification at polygonscan.com on 2021-11-17
*/

/**
 *Submitted for verification at polygonscan.com on 2021-11-01
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: newo.sol



pragma solidity 0.8.0;


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

interface IXVMCgovernor {
    function costToVote() external returns (uint256);
    function maximumVoteTokens() external returns (uint256);
    function delayBeforeEnforce() external returns (uint256);
    function setPool(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) external; 
    function changeGovernorEnforced() external returns (bool);
    function eligibleNewGovernor() external returns (address);
    function setDurationForCalculation(uint256 _newDuration) external;
    function updateAllPools() external;
}

interface IMasterChef {
    function totalAllocPoint() external returns (uint256);
    function poolInfo(uint256) external returns (address, uint256, uint256, uint256, uint16);
    function XVMCPerBlock() external returns (uint256);
    function owner() external view returns (address);
}

//contract that regulates the farms for XVMC
contract XVMCfarms is Ownable {
    using SafeERC20 for IERC20;
    
	struct ProposalFarm {
        bool valid;
        uint256 poolid;
        uint256 newAllocation;
        uint256 tokensSacrificedForVoting;
        uint256 firstCallTimestamp;
        uint16 newDepositFee;
    }
    struct ProposalDurationForCalculation {
        bool valid;
        uint256 duration;
        uint256 tokensSacrificedForVoting;
        uint256 firstCallTimestamp;
    }
    struct ProposalDecreaseLeaks {
        bool valid;
        uint256 farmMultiplier;
        uint256 memeMultiplier;
        uint256 tokensSacrificedForVoting;
        uint256 firstCallTimestamp;
    }
    
    ProposalFarm[] public proposalFarmUpdate;
    ProposalDurationForCalculation[] public proposeDurationCalculation;
    ProposalDecreaseLeaks[] public proposeRewardReduction;
    
    //masterchef address
    address public immutable masterchef = 0x9BD741F077241b594EBdD745945B577d59C8768e;
    address public immutable token = 0x6d0c966c8A09e354Df9C48b446A474CE3343D912; //XVMC token
    
    uint256 maxRewards = 26 * 1e18; //maximum reward/block when boosts inactivated
    
    //farms and meme pools rewards have no lock 
    //reduce the rewards during inflation boost
    //to prevent tokens reaching the market
    uint256 farmMultiplierDuringBoost = 500;
    uint256 memeMultiplierDuringBoost = 500;
    bool isReductionEnforced; 
    
    event InitiateFarmProposal(
            uint256 proposalID, uint256 depositingTokens, uint256 poolid,
            uint256 newAllocation, uint16 depositFee, address indexed enforcer
        );
    event VetoFarmProposal(uint256 proposalID, address indexed enforcer);
    event UpdateFarm(uint256 proposalID, uint256 poolid, address indexed enforcer);
    
    event InitiateProposalDurationForCalculation(uint256 proposalID, uint256 duration, uint256 tokensSacrificedForVoting, address enforcer);
    event VetoProposalDurationForCalculation(uint256 proposalID, address enforcer);
    event ExecuteProposalDurationForCalculation(uint256 proposalID, address enforcer);
    
    //reward reduction for farms and meme pools during reward boosts
    event ProposeRewardReduction(address enforcer, uint256 proposalID, uint256 farmMultiplier, uint256 memeMultiplier, uint256 depositingTokens, uint256 firstCallTimestamp);
    event VetoRewardReduction(uint256 proposalID, address enforcer);
    event ExecuteRewardReduction(uint256 proposalID, address enforcer);
    
    
    /**
     * Regulatory process to regulate farm rewards (maximum 5% of total allocation collectively)
     * And Meme pools
    */    
    function initiateFarmProposal(
            uint256 depositingTokens, uint256 poolid, uint256 newAllocation, uint16 depositFee
        ) external { 
        require(IMasterChef(masterchef).XVMCPerBlock() < maxRewards, "reward boost is active"); //only when reward boosts are NOT running
    	require(depositingTokens <= IXVMCgovernor(owner()).maximumVoteTokens(), "preventing tyranny, maximum 0.05% of tokens");
    	require(depositingTokens >= IXVMCgovernor(owner()).costToVote(), "there is a minimum cost to vote");
    	require(poolid == 0 || poolid == 1 || poolid == 11 || poolid == 34 || poolid == 35, "only allowed for these pools"); 
		
		//cumulative allocation for pool 0 and 1 can be max 5%
		//you can propose any amount, but it can not be enforced
    	if(poolid == 0 || poolid == 1) {
    	    require(
    	        newAllocation <= (IMasterChef(masterchef).totalAllocPoint() * 25 / 1000),
    	        "Maximum 2.5% of total allocation"
    	       );
    	} else {
    	    require(
    	        newAllocation <= (IMasterChef(masterchef).totalAllocPoint() * 15 / 1000),
    	        "Maximum 1.5% of total allocation"
    	       ); 
    	}
    
    	IERC20(token).safeTransferFrom(msg.sender, owner(), depositingTokens); 
    	proposalFarmUpdate.push(
    	    ProposalFarm(true, poolid, newAllocation, depositingTokens, block.timestamp, depositFee)
    	    ); 
    	emit InitiateFarmProposal(proposalFarmUpdate.length - 1, depositingTokens, poolid, newAllocation, depositFee, msg.sender);
    }
    function vetoFarmProposal(uint256 proposalID) external {
    	require(proposalFarmUpdate[proposalID].valid, "already invalid");
    	
		IERC20(token).safeTransferFrom(msg.sender, owner(), proposalFarmUpdate[proposalID].tokensSacrificedForVoting); 
    	proposalFarmUpdate[proposalID].valid = false; 
    	
    	emit VetoFarmProposal(proposalID, msg.sender);
    }
    
    /**
     * Updates the rewards for the corresponding farm in the proposal
    */
    function updateFarm(uint256 proposalID) external {
        require(IMasterChef(masterchef).XVMCPerBlock() < maxRewards, "reward boost is active"); //only when reward boosts are NOT running
        require(proposalFarmUpdate[proposalID].valid, "invalid proposal");
        require(
            proposalFarmUpdate[proposalID].firstCallTimestamp + IXVMCgovernor(owner()).delayBeforeEnforce() < block.timestamp,
            "delay before enforce not met"
            );
        
        IXVMCgovernor(owner()).setPool(proposalFarmUpdate[proposalID].poolid, proposalFarmUpdate[proposalID].newAllocation, proposalFarmUpdate[proposalID].newDepositFee, true);
        proposalFarmUpdate[proposalID].valid = false;
        
        emit UpdateFarm(proposalID, proposalFarmUpdate[proposalID].poolid, msg.sender);
    }

    /**
     * Regulatory process for determining rewards for 
     * farms and meme pools during inflation boosts
     * The rewards should be reduced for farms and pool tha toperate without time lock
     * to prevent tokens from hitting the market
    */
    function initiateRewardsReduction(uint256 depositingTokens, uint256 multiplierFarms, uint256 multiplierMemePools) external {
    	require(depositingTokens <= IXVMCgovernor(owner()).maximumVoteTokens(), "no tyranny");
    	
		IERC20(token).safeTransferFrom(msg.sender, owner(), depositingTokens); 
		    proposeRewardReduction.push(
		        ProposalDecreaseLeaks(true, multiplierFarms, multiplierMemePools, depositingTokens, block.timestamp)
		        );
    	
    	emit ProposeRewardReduction(msg.sender, proposeRewardReduction.length - 1, multiplierFarms, multiplierMemePools, depositingTokens, block.timestamp);
    }
    function vetoRewardsReduction(uint256 proposalID) external {
    	require(proposeRewardReduction[proposalID].valid == true, "Proposal already invalid");

    	IERC20(token).safeTransferFrom(msg.sender, owner(), proposeRewardReduction[proposalID].tokensSacrificedForVoting); 
    	proposeRewardReduction[proposalID].valid = false;  
    	
    	emit VetoRewardReduction(proposalID, msg.sender);
    }
    function executeRewardsReduction(uint256 proposalID) external {
    	require(
    	    proposeRewardReduction[proposalID].valid &&
    	    proposeRewardReduction[proposalID].firstCallTimestamp + IXVMCgovernor(owner()).delayBeforeEnforce() < block.timestamp,
    	    "Conditions not met"
    	   );

    	farmMultiplierDuringBoost = proposeRewardReduction[proposalID].farmMultiplier;
    	memeMultiplierDuringBoost = proposeRewardReduction[proposalID].memeMultiplier;
    	proposeRewardReduction[proposalID].valid = false;
    	
    	emit ExecuteRewardReduction(proposalID, msg.sender);
    }
    
    /**
     * When event is active, reduction of rewards must be manually activated
     * Reduces the rewards by a factor
     * Call this to enforce and "un-enforce"
     * NOTE: Must manually update all pools
     * Made it separate in case tx ran out of gas(is it necessary?)
    */
    function enforceRewardReduction() public {
        uint256 allocPoint; uint16 depositFeeBP;
        if (IMasterChef(masterchef).XVMCPerBlock() > maxRewards && !isReductionEnforced) {
            
            (, allocPoint, , , depositFeeBP) = IMasterChef(masterchef).poolInfo(0);
            IXVMCgovernor(owner()).setPool(
                0, allocPoint * farmMultiplierDuringBoost / 10000, depositFeeBP, false
            );
            
            (, allocPoint, , , depositFeeBP) = IMasterChef(masterchef).poolInfo(1);
            IXVMCgovernor(owner()).setPool(
                1, allocPoint * farmMultiplierDuringBoost / 10000, depositFeeBP, false
            );

            (, allocPoint, , , depositFeeBP) = IMasterChef(masterchef).poolInfo(11);
            IXVMCgovernor(owner()).setPool(
                11, allocPoint * memeMultiplierDuringBoost / 10000, depositFeeBP, false
            );

            (, allocPoint, , , depositFeeBP) = IMasterChef(masterchef).poolInfo(34);
            IXVMCgovernor(owner()).setPool(
                34, allocPoint * memeMultiplierDuringBoost / 10000, depositFeeBP, false
            );

            (, allocPoint, , , depositFeeBP) = IMasterChef(masterchef).poolInfo(35);
            IXVMCgovernor(owner()).setPool(
                35, allocPoint * memeMultiplierDuringBoost / 10000, depositFeeBP, false
            );
            
            isReductionEnforced = true;
            
        } else if(IMasterChef(masterchef).XVMCPerBlock() < maxRewards && isReductionEnforced) {

        //inverses the formula... perhaps should keep last Reward
        //the mutliplier shall not change during event!
            (, allocPoint, , , depositFeeBP) = IMasterChef(masterchef).poolInfo(0);
            IXVMCgovernor(owner()).setPool(
                0, allocPoint * 10000 / farmMultiplierDuringBoost, depositFeeBP, false
            );
            
            (, allocPoint, , , depositFeeBP) = IMasterChef(masterchef).poolInfo(1);
            IXVMCgovernor(owner()).setPool(
                1, allocPoint * 10000 / farmMultiplierDuringBoost, depositFeeBP, false
            );

            (, allocPoint, , , depositFeeBP) = IMasterChef(masterchef).poolInfo(11);
            IXVMCgovernor(owner()).setPool(
                11, allocPoint * 10000 / memeMultiplierDuringBoost, depositFeeBP, false
            );

            (, allocPoint, , , depositFeeBP) = IMasterChef(masterchef).poolInfo(34);
            IXVMCgovernor(owner()).setPool(
                34, allocPoint * 10000 / memeMultiplierDuringBoost, depositFeeBP, false
            );

            (, allocPoint, , , depositFeeBP) = IMasterChef(masterchef).poolInfo(35);
            IXVMCgovernor(owner()).setPool(
                35, allocPoint * 10000 / memeMultiplierDuringBoost, depositFeeBP, false
            );
            
            isReductionEnforced = false;
        }
    }

    /**
     * All in one transaction
    */
    function aEnforceRewardReduction() external {
        enforceRewardReduction();
        IXVMCgovernor(owner()).updateAllPools();
    }

    function updateAllPools() external {
        IXVMCgovernor(owner()).updateAllPools();
    }
    
    /**
     * Regulatory process for determining "durationForCalculation"
     * Not of great Use
     * Bitcoin difficulty adjusts to create new blocks every 10minutes
     * Our inflation is tied to the block production of Polygon network
     * In case the average block time changes significantly on the Polygon network  
     * the durationForCalculation is a period that we use to calculate 
     * average block time and consequentially use it to rebalance inflation
    */
    function initiateProposalDurationForCalculation(uint256 depositingTokens, uint256 duration) external  { 
    	require(depositingTokens <= IXVMCgovernor(owner()).maximumVoteTokens(), "No tyranny");
    	require(depositingTokens >= IXVMCgovernor(owner()).costToVote(), "minimum cost to vote");
    
    	IERC20(token).safeTransferFrom(msg.sender, owner(), depositingTokens);
    	proposeDurationCalculation.push(
    	    ProposalDurationForCalculation(true, duration, depositingTokens, block.timestamp)
    	    );  
    	    
        emit InitiateProposalDurationForCalculation(proposeDurationCalculation.length - 1, duration,  depositingTokens, msg.sender);
    }
    function vetoProposalDurationForCalculation(uint256 proposalID) external {
    	require(proposeDurationCalculation[proposalID].valid, "already invalid"); 
    	
    	IERC20(token).safeTransferFrom(msg.sender, owner(), proposeDurationCalculation[proposalID].tokensSacrificedForVoting);
    	proposeDurationCalculation[proposalID].valid = false;  
    	
    	emit VetoProposalDurationForCalculation(proposalID, msg.sender);
    }

    function executeProposalDurationForCalculation(uint256 proposalID) external {
    	require(
    	    proposeDurationCalculation[proposalID].valid &&
    	    proposeDurationCalculation[proposalID].firstCallTimestamp + IXVMCgovernor(owner()).delayBeforeEnforce() < block.timestamp,
    	    "conditions not met"
    	);
        
        IXVMCgovernor(owner()).setDurationForCalculation(proposeDurationCalculation[proposalID].duration); 
    	proposeDurationCalculation[proposalID].valid = false; 
    	
    	emit ExecuteProposalDurationForCalculation(proposalID, msg.sender);
    }
    
    /**
     * If governing contract is changed, this function must be called
     * Updates owner of the contract to the owner of masterchef(governing contract)
    */
	function changeGovernor() external {
        require(IMasterChef(masterchef).owner() != owner(), "nothing to change");

        _transferOwnership(IMasterChef(masterchef).owner());
    }
}