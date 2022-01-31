//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Torikae is Ownable {
    uint256 public fee; // fee is out of 100000
    address public chainLinkCallerAddress;

    modifier onlyChainlink() {
        require(
            msg.sender == chainLinkCallerAddress,
            "Ownable: caller is not the owner"
        );
        _;
    }

    struct Pool {
        string xChain;
        address sToken; // ERC20 token in the same chain
        string xToken; // Token in the cross chain
    }

    mapping(bytes32 => uint256) public balances;
    mapping(bytes32 => bool) public poolIsPresent;

    constructor(uint256 _fee, address _chainLinkCallerAddress) {
        fee = _fee;
        chainLinkCallerAddress = _chainLinkCallerAddress;
    }

    function setFee(uint256 _fee) public onlyOwner {
        fee = _fee;
    }

    function setCaller(address newCallerAddress) public onlyOwner {
        chainLinkCallerAddress = newCallerAddress;
    }

    // Function to create pool
    function createPool(
        string memory _xChain,
        address _sToken,
        string memory _xToken
    ) public {
        require(_sToken != address(0), "sToken cannot be 0x0");

        bytes32 poolHash = keccak256(
            abi.encodePacked(_xChain, _sToken, _xToken)
        );

        require(!poolIsPresent[poolHash], "Pool already exists");

        poolIsPresent[poolHash] = true;
        balances[poolHash] = 0;
    }

    // Function to create pool with initial liquidity
    function createPoolWithLiquidity(
        string memory _xChain,
        address _sToken,
        string memory _xToken,
        uint256 _initialLiquidity
    ) public {
        require(_sToken != address(0), "sToken cannot be 0x0");

        bytes32 poolHash = keccak256(
            abi.encodePacked(_xChain, _sToken, _xToken)
        );

        require(!poolIsPresent[poolHash], "Pool already exists");

        // Take token from the caller
        IERC20(_sToken).transferFrom(
            msg.sender,
            address(this),
            _initialLiquidity
        );

        poolIsPresent[poolHash] = true;
        balances[poolHash] = _initialLiquidity;
    }

    // Function to add liquidity
    function addLiquidity(
        string memory _xChain,
        address _sToken,
        string memory _xToken,
        uint256 _amount
    ) public {
        bytes32 poolHash = getPoolHash(_xChain, _sToken, _xToken);
        require(poolIsPresent[poolHash], "Pool does not exist");

        // Take token from the caller
        IERC20(_sToken).transferFrom(msg.sender, address(this), _amount);
        balances[poolHash] += _amount;
    }

    // Function to get the balance of the pool
    function getPoolBalance(
        string memory _xChain,
        address _sToken,
        string memory _xToken
    ) public view returns (uint256) {
        bytes32 poolHash = keccak256(
            abi.encodePacked(_xChain, _sToken, _xToken)
        );

        return balances[poolHash];
    }

    // Function to call Chainlink external adpater

    // Function be be called by Chainlink external adapter
    function giveout(
        bytes32 poolHash,
        address tokenAddress,
        address receiverAddress,
        uint256 amount
    ) public onlyChainlink {
        require(tokenAddress != address(0), "Token address is not valid");
        require(receiverAddress != address(0), "Receiver address is not valid");
        require(amount > 0, "Amount is not valid");
        require(poolIsPresent[poolHash], "Pool does not exist");

        // Transfer the token
        IERC20(tokenAddress).transfer(receiverAddress, amount);

        // Reduce the balance from pool
        balances[poolHash] -= amount;
    }

    // Function to just get the hash of the pool
    function getPoolHash(
        string memory _xChain,
        address _sToken,
        string memory _xToken
    ) public pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(_xChain, _sToken, _xToken)
        );
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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