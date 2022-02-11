// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./utils/TutellusERC20.sol";
import "./TutellusRoleManager.sol";
import "./TutellusHoldersVault.sol";
import "./TutellusRewardsVault.sol";
import "./TutellusClientsVault.sol";
import "./TutellusTreasuryVault.sol";

contract TutellusDeployer {

    address public token;
    address public rolemanager;
    address public treasury;
    address public holdersVault;
    address public teamVault;
    address public rewardsVault;
    address public clientsVault;
    address public treasuryVault;

    constructor(address treasury_, uint startBlock) {
        treasury = treasury_;
        rolemanager = address(new TutellusRoleManager());
        token = address(new TutellusERC20('Tutellus Token', 'TUT', 2e26, rolemanager));
        holdersVault = address(new TutellusHoldersVault(rolemanager, token, 10000000e18, startBlock, startBlock + 10519200)); //
        teamVault = address(new TutellusHoldersVault(rolemanager, token, 6000000e18, startBlock + 10519200, startBlock + 27612900));
        rewardsVault = address(new TutellusRewardsVault(rolemanager, token, 64000000e18, startBlock, startBlock + 47336400)); // 47336400 = 3 años
        clientsVault = address(new TutellusClientsVault(rolemanager, token));
        treasuryVault = address(new TutellusTreasuryVault(rolemanager, treasury, token, 29600000e18, startBlock, startBlock + 78894000)); // 78894000 = 5 años

        TutellusRoleManager rolemanagerInstance = TutellusRoleManager(rolemanager);
        rolemanagerInstance.grantMinterRole(address(this));
        rolemanagerInstance.grantMinterRole(holdersVault);
        rolemanagerInstance.grantMinterRole(teamVault);
        
        TutellusERC20 tokenInstance = TutellusERC20(token);
        tokenInstance.mint(treasury, 400000e18);
        tokenInstance.mint(rewardsVault, 64000000e18);
        tokenInstance.mint(clientsVault, 90000000e18);
        tokenInstance.mint(treasuryVault, 29600000e18);

        // TEST DATA
        // treasury = treasury_;
        // rolemanager = address(new TutellusRoleManager());
        // token = address(new TutellusERC20('Tutellus Token', 'TUT', 2e26, rolemanager));
        // holdersVault = address(new TutellusHoldersVault(rolemanager, token, 10000000e18, startBlock, startBlock + 8)); //
        // teamVault = address(new TutellusHoldersVault(rolemanager, token, 6000000e18, startBlock + 8, startBlock + 21));
        // rewardsVault = address(new TutellusRewardsVault(rolemanager, token, 64000000e18, startBlock, startBlock + 36)); // 47336400 = 3 años
        // clientsVault = address(new TutellusClientsVault(rolemanager, token));
        // treasuryVault = address(new TutellusTreasuryVault(rolemanager, treasury, token, 29600000e18, startBlock, startBlock + 60)); // 78894000 = 5 años

        // TutellusRoleManager rolemanagerInstance = TutellusRoleManager(rolemanager);
        // rolemanagerInstance.grantMinterRole(address(this));
        // rolemanagerInstance.grantMinterRole(holdersVault);
        // rolemanagerInstance.grantMinterRole(teamVault);
        
        // TutellusERC20 tokenInstance = TutellusERC20(token);
        // tokenInstance.mint(treasury, 400000e18);
        // tokenInstance.mint(rewardsVault, 64000000e18);
        // tokenInstance.mint(clientsVault, 90000000e18);
        // tokenInstance.mint(treasuryVault, 29600000e18);

        // after deployment:
        //      1. deploy staking and farming
        //      2. add staking and farming to the rewardsVault
        //      3. add holders to the holdersVault
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./AccessControlProxyPausable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";

contract TutellusERC20 is AccessControlProxyPausable, ERC20CappedUpgradeable {

    uint256 public burned;

    event Mint(address account, uint256 amount);
    event Burn(address account, uint256 amount);

    constructor(string memory name, string memory symbol, uint256 cap, address rolemanager) {
        __TutellusERC20_init(name, symbol, cap, rolemanager);
    }

    function __TutellusERC20_init(string memory name, string memory symbol, uint256 cap, address rolemanager) internal initializer {
        __AccessControlProxyPausable_init(rolemanager);
        __ERC20_init(name, symbol);
        __ERC20Capped_init(cap);
        __TutellusERC20_init_unchained();
    }

    function __TutellusERC20_init_unchained() internal initializer {
    }

    function _mint(address account, uint256 amount) virtual internal override {
        require(totalSupply() + burned + amount <= cap(), "TutellusERC20: mint amount exceeds cap");
        super._mint(account, amount);
        emit Mint(account, amount);
    }

    function _burn(address account, uint256 amount) virtual internal override {
        burned += amount;
        super._burn(account, amount);
        emit Burn(account, amount);
    }

    function mint(address account, uint256 amount) public onlyRole(keccak256('MINTER_ROLE')) {
        _mint(account, amount);
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract TutellusRoleManager is AccessControlUpgradeable {
    
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() {
        __TutellusRoleManager_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, tx.origin);
    }

    function __TutellusRoleManager_init() internal initializer {
      __AccessControl_init();
      __TutellusRoleManager_init_unchained();
    }

    function __TutellusRoleManager_init_unchained() internal initializer {
    }

    function grantAdminRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
      _setupRole(DEFAULT_ADMIN_ROLE, account);
    }
    
    function grantMinterRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
      _setupRole(MINTER_ROLE, account);
    }

    function grantUpgraderRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
      _setupRole(MINTER_ROLE, account);
    }

    function grantPauserRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
      _setupRole(MINTER_ROLE, account);
    }

    function grantAllRoles(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
      grantPauserRole(account);
      grantMinterRole(account);
      grantUpgraderRole(account);
      grantAdminRole(account);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces/ITutellusERC20.sol";
import "./utils/AccessControlProxyPausable.sol";

contract TutellusHoldersVault is AccessControlProxyPausable {

    address public token;
    uint private _startBlock;
    uint private _endBlock;
    uint256 private _limit;
    uint256 private _minted;
    mapping(address=>uint256) public distributed;
    mapping(address=>uint256) public allocated;

    event Update(address account);
    event Distribute(address sender, address account, uint256 amount);
    event Add(address holder, uint256 allocated);
    event AddBatch(uint256 length);
    event Init(uint startBlock, uint endBlock, uint256 limit);

    constructor(address rolemanager, address token_, uint256 limit, uint256 startBlock_, uint endBlock_) {
        require(endBlock_ > startBlock_, "TutellusHoldersVault: start block exceeds end block");
      __TutellusHoldersVault_init(rolemanager, token_, limit, startBlock_, endBlock_);
    }

    function __TutellusHoldersVault_init(address rolemanager, address token_, uint256 limit, uint256 startBlock_, uint endBlock_) internal initializer {
      __AccessControlProxyPausable_init(rolemanager);
      __TutellusHoldersVault_init_unchained(token_, limit, startBlock_, endBlock_);
    }

    function __TutellusHoldersVault_init_unchained(address token_, uint256 limit, uint256 startBlock_, uint endBlock_) internal initializer {
      token = token_;
      _limit = limit;
      _startBlock = startBlock_;
      _endBlock = endBlock_;
      emit Init(_startBlock, _endBlock, limit);
    }

    function released(address account) public view returns(uint256) {
      uint current = block.number;
      if (current > _endBlock) {
        return allocated[account];
      } else if (current < _startBlock) {
        return 0;
      } else {
        uint blocks = current - _startBlock;
        return allocated[account] * blocks / (_endBlock - _startBlock);
      }
    }

    function available(address account) public view returns(uint256) {
      return released(account) - distributed[account];
    }

    function distribute(address account) public whenNotPaused {
      ITutellusERC20 tokenInterface = ITutellusERC20(token);
      uint256 amount = available(account);
      require(amount > 0, "TutellusHoldersVault: no available tokens");
      distributed[account] += amount;
      tokenInterface.transfer(account, amount);
      emit Distribute(msg.sender, account, amount);
    }

    function claim() public {
        address account = msg.sender;
        distribute(account);
    }

    function addBatch(address[] memory account, uint256[] memory allocated_) public onlyRole(DEFAULT_ADMIN_ROLE) {
      require(account.length == allocated_.length, 'TutellusHoldersVault: length must be the same');
      require(account.length != 0, 'TutellusHoldersVault: length cannot be null');
      uint256 length = account.length;
      for(uint256 i=0; i< account.length; i++) {
        add(account[i], allocated_[i]);
      }
      emit AddBatch(length);
    }

    function add(address account, uint256 allocated_) public onlyRole(DEFAULT_ADMIN_ROLE) {
      require(allocated_ > 0, "TutellusHoldersVault: cannot mint 0 tokens");
      _minted += allocated_;
      require(_minted <= _limit, "TutellusHoldersVault: minted exceeds limit");
      allocated[account] += allocated_;
      ITutellusERC20 tokenInterface = ITutellusERC20(token);
      tokenInterface.mint(address(this), allocated_);
      emit Add(account, allocated_);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./utils/AccessControlProxyPausable.sol";
import "./interfaces/ITutellusERC20.sol";

contract TutellusRewardsVault is AccessControlProxyPausable {

    struct Info {
      uint256 allocation;
      uint256 released;
      uint256 distributed;
    }

    mapping(address=>Info) private info;
    mapping(uint256=>address) private id;
    
    uint private _lastUpdate;
    uint private _startBlock;
    uint private _endBlock;
    uint256 private _increment;
    uint256 private _total;

    address public token;

    event Init(uint startBlock, uint endBlock, uint256 increment);
    event Add(address account);
    event UpdateAllocation(uint256[] allocation);
    event DistributeTokens(address sender, address account, uint256 amount);

    constructor (
      address rolemanager,
      address token_, 
      uint256 amount, 
      uint startBlock_,
      uint endBlock_
    )  
    {
      __TutellusRewardsVault_init(
        rolemanager,
        token_, 
        amount, 
        startBlock_,
        endBlock_
      );
    }

    function startBlock() public view returns (uint) {
      return _startBlock;
    } 

    function endBlock() public view returns (uint) {
      return _endBlock;
    }

    function add(address account, uint256[] memory allocation) public onlyRole(DEFAULT_ADMIN_ROLE) {
      id[_total] = account;
      info[account] = Info(0,0,0);
      _total+=1;
      updateAllocation(allocation);
      emit Add(account);
    }

    function updateAllocation(uint256[] memory allocation) public onlyRole(DEFAULT_ADMIN_ROLE) {
      uint256 sum = 0;
      uint256 length = allocation.length;
      require(length == _total, "TutellusRewardsVault: allocation array must have same length as number of accounts");
      for(uint256 i=0; i<length; i++) {
        info[id[i]].released = releasedId(id[i]);
        info[id[i]].allocation = allocation[i];
        sum+=allocation[i];
      }
      _lastUpdate = block.number;
      require(sum==1e20, "TutellusRewardsVault: total allocation must be 1e20");
      emit UpdateAllocation(allocation);
    }

    function released() public view returns (uint256) {
      return releasedRange(_startBlock, block.number);
    }

    function availableId(address account) public view returns (uint256) {
      return releasedId(account) - info[account].distributed;
    }

    function releasedRange(uint from, uint to) public view returns (uint256) {
      require(from <= to, "TutellusRewardsVault: {from} is after {to}");
      if (to > _endBlock) {
        to = _endBlock;
      }
      if (from < _startBlock) {
        from = _startBlock;
      }
      uint256 comp0 = (_increment * ((to - _startBlock) ** 2)) / 2;
      uint256 comp1 = (_increment * ((from - _startBlock) ** 2)) / 2;
      return comp0 - comp1;
    }

    function releasedId(address account) public view returns (uint256) {
      return info[account].released + ((releasedRange(_lastUpdate, block.number) * info[account].allocation) / 1e20);
    }

    function distributeTokens(address account, uint256 amount) public {
      require(amount <= availableId(msg.sender), "TutellusRewardsVault: amount exceeds available");
      info[msg.sender].distributed += amount;
      ITutellusERC20 tokenInterface = ITutellusERC20(token);
      tokenInterface.transfer(account, amount);
      emit DistributeTokens(msg.sender, account, amount);
    }

    function __TutellusRewardsVault_init(
      address rolemanager,
      address token_, 
      uint256 amount, 
      uint startBlock_,
      uint endBlock_
    ) 
      internal 
      initializer 
    {
      __AccessControlProxyPausable_init(rolemanager);
      __TutellusRewardsVault_init_unchained(
        token_,
        amount, 
        startBlock_,
        endBlock_
      );
    }

    function __TutellusRewardsVault_init_unchained(
      address token_, 
      uint256 amount, 
      uint startBlock_,
      uint endBlock_
    ) 
      internal 
      initializer 
    {   
        require(endBlock_ > startBlock_, "TutellusRewardsVault: start block exceeds end block");
        token = token_;
        _startBlock = startBlock_;
        _endBlock = endBlock_;
        uint blocks = endBlock_ - startBlock_;
        _increment = (2 * amount) / (blocks ** 2);
        _lastUpdate = block.number;
        emit Init(_startBlock, _endBlock, _increment);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "./utils/AccessControlProxyPausable.sol";
import "./interfaces/ITutellusERC20.sol";

contract TutellusClientsVault is AccessControlProxyPausable {

    address public token;
    bytes32 public merkleRoot;
    string public uri;

    mapping(address => uint256) private _alreadyClaimed;

    event Claim(uint256 index, address account, uint256 amount);
    event UpdateMerkleRoot(bytes32 merkleRoot, string uri);

    function updateMerkleRoot(bytes32 merkleRoot_, string memory uri_) public onlyRole(DEFAULT_ADMIN_ROLE){
      merkleRoot = merkleRoot_;
      uri = uri_;
      emit UpdateMerkleRoot(merkleRoot, uri);
    }

    function alreadyClaimed(address account) public view returns(uint256){
      return _alreadyClaimed[account];
    }

    function leftToClaim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) public view returns(uint256) {
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProofUpgradeable.verify(merkleProof, merkleRoot, node), "TutellusClientsVault: Invalid proof.");
        uint256 alreadyClaimed_ = alreadyClaimed(account);
        if(amount > alreadyClaimed_){
          return amount - alreadyClaimed_;
        }else{
          return 0;
        }
    }

    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external whenNotPaused {
        uint256 claimed = leftToClaim(index, account, amount, merkleProof);
        require(claimed > 0,"TutellusClientsVault: Nothing to claim.");
        _alreadyClaimed[account] += claimed;
        ITutellusERC20 tokenInterface = ITutellusERC20(token);
        tokenInterface.transfer(account, amount);
        emit Claim(index, account, claimed);
    }

    constructor(address rolemanager, address token_) {
      __TutellusClientsVault_init(rolemanager, token_);
    }

    function __TutellusClientsVault_init(address rolemanager, address token_) internal initializer {
      __AccessControlProxyPausable_init(rolemanager);
      __TutellusClientsVault_init_unchained(token_);
    }

    function __TutellusClientsVault_init_unchained(address token_) internal initializer {
      token = token_;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./utils/AccessControlProxyPausable.sol";
import "./interfaces/ITutellusERC20.sol";

contract TutellusTreasuryVault is AccessControlProxyPausable {

    address public token;
    address public treasury;

    uint256 private _distributed;
    uint private _startBlock;
    uint private _endBlock;
    uint private _increment;

    event Claim(address sender, address treasury, uint256 amount);
    event Init(uint startBlock, uint endBlock, uint256 increment);
    event UpdateTreasury(address previous, address next);

    constructor (address rolemanager,
      address treasury_,
      address token_,
      uint256 amount, 
      uint startBlock_,
      uint endBlock_
    )
    {
      __TutellusTreasuryVault_init(
        rolemanager,
        treasury_,
        token_,
        amount, 
        startBlock_,
        endBlock_
      );
    }

    function released() public view returns (uint256) {
      return releasedRange(_startBlock, block.number);
    }

    function releasedRange(uint from, uint to) public view returns (uint256) {
      require(from < to, "TutellusTreasuryVault: {from} is after {to}");
      if (to > _endBlock) to = _endBlock;
      if (from < _startBlock) from = _startBlock;
      uint256 comp0 = (_increment * ((to - _startBlock) ** 2)) / 2;
      uint256 comp1 = (_increment * ((from - _startBlock) ** 2)) / 2;
      return comp0 - comp1;
    }

    function updateTreasury(address treasury_) public onlyRole(DEFAULT_ADMIN_ROLE) {
      address previous = treasury;
      treasury = treasury_;
      address next = treasury;
      emit UpdateTreasury(previous, next);
    }

    function claim() public {
      uint256 amount = released() - _distributed;
      _distributed += amount;
      require(amount > 0, "TutellusTreasuryVault: nothing to claim");
      ITutellusERC20 tokenInterface = ITutellusERC20(token);
      tokenInterface.transfer(treasury, amount);
      emit Claim(msg.sender, treasury, amount);
    }

    function __TutellusTreasuryVault_init(
      address rolemanager,
      address treasury_,
      address token_,
      uint256 amount, 
      uint startBlock_,
      uint endBlock_
    ) 
      internal 
      initializer 
    {
      __AccessControlProxyPausable_init(rolemanager);
      __TutellusTreasuryVault_init_unchained(
        treasury_,
        token_,
        amount, 
        startBlock_,
        endBlock_
      );
    }

    function __TutellusTreasuryVault_init_unchained(
      address treasury_,
      address token_,
      uint256 amount,
      uint startBlock_,
      uint endBlock_
    ) 
      internal 
      initializer 
    {   
      require(endBlock_ > startBlock_, "TutellusTreasuryVault: start block exceeds end block");
      token = token_;
      treasury = treasury_;
      _startBlock = startBlock_;
      _endBlock = endBlock_;
      uint blocks = endBlock_ - startBlock_;
      _increment = (2 * amount) / (blocks ** 2);
      emit Init(_startBlock, _endBlock, _increment);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

abstract contract AccessControlProxyPausable is PausableUpgradeable {

    address private _manager;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    modifier onlyRole(bytes32 role) {
        address account = msg.sender;
        require(hasRole(role, account), string(
                    abi.encodePacked(
                        "AccessControlProxyPausable: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                ));
        _;
    }

    function hasRole(bytes32 role, address account) public view returns (bool) {
        IAccessControlUpgradeable manager = IAccessControlUpgradeable(_manager);
        return manager.hasRole(role, account);
    }

    function __AccessControlProxyPausable_init(address manager) internal initializer {
        __Pausable_init();
        __AccessControlProxyPausable_init_unchained(manager);
    }

    function __AccessControlProxyPausable_init_unchained(address manager) internal initializer {
        _manager = manager;
    }

    function pause() public onlyRole(PAUSER_ROLE){
        _pause();
    }
    
    function unpause() public onlyRole(PAUSER_ROLE){
        _unpause();
    }

    function updateManager(address manager) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _manager = manager;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 */
abstract contract ERC20CappedUpgradeable is Initializable, ERC20Upgradeable {
    uint256 private _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    function __ERC20Capped_init(uint256 cap_) internal initializer {
        __Context_init_unchained();
        __ERC20Capped_init_unchained(cap_);
    }

    function __ERC20Capped_init_unchained(uint256 cap_) internal initializer {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        require(ERC20Upgradeable.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ITutellusERC20 {

    /**
     * @dev Returns the amount of tokens burned.
     */
    function burned() external view returns (uint256);
    
    /**
     * @dev Mints `amount` tokens to `account`.
     */
    function mint(address account, uint256 amount) external;

    /**
     * @dev Burns `amount` tokens.
     */
    function burn(uint256 amount) external;

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

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProofUpgradeable {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
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