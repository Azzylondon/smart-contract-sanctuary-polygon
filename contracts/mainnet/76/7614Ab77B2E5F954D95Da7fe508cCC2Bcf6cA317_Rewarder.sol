/**
 *Submitted for verification at polygonscan.com on 2021-10-14
*/

pragma solidity 0.8.3;


library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

contract Custody is Ownable {
    using Address for address;

    mapping(address => bool) public authorized;
    IERC20 public token;

    modifier onlyAuthorized() {
        require(authorized[msg.sender], "Not authorized");
        _;
    }

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
        authorized[owner()] = true;
    }

    // Reject any ethers sent to this smart-contract
    receive() external payable {
        revert("Rejecting tx with ethers sent");
    }

    function authorize(address _account) public onlyOwner {
        authorized[_account] = true;
    }

    function forbid(address _account) public onlyOwner {
        require(_account != owner(), "Owner access cannot be forbidden!");

        authorized[_account] = false;
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        authorized[owner()] = false;
        super.transferOwnership(newOwner);
        authorized[owner()] = true;
    }

    function withdraw(uint256 amount) onlyAuthorized public {
        token.transfer(msg.sender, amount);
    }

    // Allow to withdraw any arbitrary token, should be used by
    // contract owner to recover accidentally received funds.
    function recover(address _tokenAddress, uint256 amount) onlyOwner public {
        IERC20(_tokenAddress).transfer(msg.sender, amount);
    }

    // Allows to withdraw funds into many addresses in one tx
    // (or to do mass bounty payouts)
    function payout(address[] calldata _recipients, uint256[] calldata _amounts) onlyAuthorized public {
        require(_recipients.length == _amounts.length, "Invalid array length");

        for (uint256 i = 0; i < _recipients.length; i++) {
            token.transfer(_recipients[i], _amounts[i]);
        }
    }
}

contract Rewarder is Ownable {
    using MerkleProof for bytes32[];

    IERC20 public token;
    Custody public custody;
    mapping(uint256 => bytes32) public claimRoots;
    mapping(address => uint256) public totalPayoutsFor;
    uint256 public totalClaimed;
    uint256 public lastRootBlock;

    event RootUpdated(bytes32 root, uint256 blockNumber, uint256 _totalAmount);
    event Airdrop(uint256 totalDropped);
    event ClaimedChanged(uint256 totalUnclaimed);

    constructor(
                address _token,
                address payable _custody
                ) {
        token = IERC20(_token);
        custody = Custody(_custody);
        lastRootBlock = block.number;
        emit RootUpdated(0x0, block.number, 0);
    }

    function airdrop(address[] calldata _beneficiaries, uint256[] calldata _totalEarnings) external onlyOwner {
        require(_beneficiaries.length == _totalEarnings.length, "Invalid array length");

        uint256[] memory amounts = new uint256[](_totalEarnings.length);

        uint256 _total = 0;
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            address _beneficiary = _beneficiaries[i];
            uint256 _totalEarned = _totalEarnings[i];
            uint256 _totalReceived = totalPayoutsFor[_beneficiary];
            require(_totalEarned >= _totalReceived, "Invalid batch");
            uint256 _amount = _totalEarned - _totalReceived;

            if (_amount == 0) continue;

            amounts[i] = _amount;
            _total = _total + _amount;
            totalPayoutsFor[_beneficiary] = _totalEarned;
        }

        if (_total == 0) return;

        increaseClaimed(_total);
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            token.transfer(_beneficiaries[i], amounts[i]);
        }
        emit Airdrop(_total);
    }

    function updateRoot(bytes32 _claimRoot, uint256 _blockNumber, uint256 _totalReward) public onlyOwner {
        require(_blockNumber < block.number, "Given block number must be less than current block number");
        require(_blockNumber > lastRootBlock, "Given block number must be more than last root block");
        require(_totalReward > totalClaimed, "Total reward must be bigger than total claimed");

        uint256 _requiredTokens = _totalReward - totalClaimed;
        uint256 _currentBalance = token.balanceOf(address(this));
        if (_requiredTokens > _currentBalance) {
            custody.withdraw(_requiredTokens - _currentBalance);
        }

        lastRootBlock = _blockNumber;
        claimRoots[_blockNumber] = _claimRoot;
        emit RootUpdated(_claimRoot, _blockNumber, _totalReward);
    }

    function claim(address _recipient, uint256 _totalEarned, uint256 _blockNumber, bytes32[] calldata _proof) external {
        require(isValidProof(_recipient, _totalEarned, _blockNumber, _proof), "Invalid proof");

        uint256 _totalReceived = totalPayoutsFor[_recipient];
        require(_totalEarned >= _totalReceived, "Already paid");

        uint256 _amount = _totalEarned - _totalReceived;
        if (_amount == 0) return;

        totalPayoutsFor[_recipient] = _totalEarned;
        increaseClaimed(_amount);
        token.transfer(_recipient, _amount);
    }

    function isValidProof(address _recipient, uint256 _totalEarned, uint256 _blockNumber, bytes32[] calldata _proof) public view returns (bool) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        bytes32 leaf = keccak256(abi.encodePacked(_recipient, _totalEarned, chainId, address(this)));
        bytes32 root = claimRoots[_blockNumber];
        return _proof.verify(root, leaf);
    }

    function recoverTokens(IERC20 _erc20, address _to) public onlyOwner {
        require(address(_erc20) != address(token), "You can't recover default token");
        uint256 _balance = _erc20.balanceOf(address(this));
        _erc20.transfer(_to, _balance);
    }

    function increaseClaimed(uint256 delta) internal {
        totalClaimed = totalClaimed + delta;
        emit ClaimedChanged(totalClaimed);
    }
}