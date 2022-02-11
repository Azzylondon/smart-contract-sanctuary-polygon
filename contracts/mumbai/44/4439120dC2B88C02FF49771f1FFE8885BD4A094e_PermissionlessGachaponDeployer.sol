// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../interfaces/IGachaponControlTower.sol";
import "../interfaces/ITreasuryManager.sol";

/// @title Permissionless gachapon deployer
/// @author KirienzoEth for DokiDoki
contract PermissionlessGachaponDeployer is Ownable, Pausable {
  /// @notice Price for deploying a gachapon
  uint256 public price;
  /// @notice Control tower contract that deploys gachapons
  address public controlTowerAddress;

  event PermissionlessGachaponCreated(string _title, address _gachapon, address indexed _currency);
  
  constructor(address _controlTowerAddress) {
    controlTowerAddress = _controlTowerAddress;
    price = 20 ether;
    _pause();
  }
  
  /// @notice Set the price for deploying a gachapon
  function setPrice(uint _price) onlyOwner external {
    price = _price;
  }

  function pause() onlyOwner external {
    _pause();
  }

  function unpause() onlyOwner external {
    _unpause();
  }

  /// @notice Will create a new gachapon machine with the provided title and currency
  function deploy(string memory _title, address _currency) whenNotPaused payable public returns(address) {
    require(msg.value == price, "Value sent by the transaction does not match the current price");

    // Redirect payment to treasury
    _sendPaymentTotreasury();

    // Create the gachapon contract
    IGachaponControlTower(controlTowerAddress).createGachapon(_title, _currency);

    // Get the newly created gachapon contract address
    address _gachaponAddress = IGachaponControlTower(controlTowerAddress).gachapons(IGachaponControlTower(controlTowerAddress).gachaponAmount() - 1);
    // Transfer ownership of this gachapon to the caller
    Ownable(_gachaponAddress).transferOwnership(msg.sender);

    emit PermissionlessGachaponCreated(_title, _gachaponAddress, _currency);

    return _gachaponAddress;
  }
  
  function _sendPaymentTotreasury() internal {
    address _to = ITreasuryManager(controlTowerAddress).teamTreasuryAddress();
    (bool sent, bytes memory data) = _to.call{value: msg.value}("");
    require(sent, "Failed to send payment");
  }

  receive() external payable {
    revert("Use the deploy(string,address) function instead");
  }

  fallback() external payable {
    revert("Use the deploy(string,address) function instead");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IGachaponControlTower {
  function createGachapon(string memory _machineTitle, address _currency) external;
  function gachaponAmount() external returns (uint);
  function gachapons(uint _index) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface ITreasuryManager {
  /// @notice Address of the wallet of the doki team funds
  function teamTreasuryAddress() external returns(address);
  /// @notice Address of the wallet of the DAO treasury
  function daoTreasuryAddress() external returns(address);
  /// @notice Address of the wallet managing buybacks\burns
  function tokenomicsManagerAddress() external returns(address);
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

pragma solidity ^0.8.0;

/*
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