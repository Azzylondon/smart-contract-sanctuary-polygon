// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Game2Types.sol";
import "./Game2BiomeV1.sol";

contract Game2Biome1 is Game2BiomeV1 {
  constructor(
    address _world,
    address _player,
    address _registry
  ) Game2BiomeV1(_world, _player, _registry) {}

  function id() internal pure override returns (uint) {
    return 1;
  }

  function size() internal pure override returns (Vec2 memory) {
    return Vec2(100, 100);
  }

  function initialize() external {
    Player.initialize(msg.sender);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Vec2 {
  uint x;
  uint y;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./Game2Types.sol";
import "./Game2Player.sol";
import "./Game2World.sol";
import "./Game2Utils.sol" as Utils;
import "../core/CozyRegistry.sol";

abstract contract Game2BiomeV1 is AccessControl {
  bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

  Game2World internal World;
  Game2Player internal Player;
  CozyRegistry internal Registry;

  error InvalidToken();
  error InvalidLocation(Vec2 location);
  error InvalidBiome(uint biome);

  constructor(
    address _world,
    address _player,
    address _registry
  ) {
    World = Game2World(_world);
    Player = Game2Player(_player);
    Registry = CozyRegistry(_registry);

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(OPERATOR_ROLE, msg.sender);
  }

  // ----------- Setters -----------

  function setWorld(address world) external onlyRole(DEFAULT_ADMIN_ROLE) {
    World = Game2World(world);
  }

  function setPlayer(address player) external onlyRole(DEFAULT_ADMIN_ROLE) {
    Player = Game2Player(player);
  }

  // ----------- Getters -----------

  function id() internal pure virtual returns (uint);

  function size() internal pure virtual returns (Vec2 memory);

  // ----------- Actions -----------

  function move(uint tokenId, Vec2 calldata nextLocation) external {
    checkValidToken(tokenId);
    checkValidLocation(nextLocation);

    Game2Player.State memory state = Player.getState(msg.sender);

    checkValidBiome(state);

    uint elapsedTime = block.timestamp - state.moveTime;
    uint steps = elapsedTime / state.moveSpeed;

    Vec2 memory currLocation = Utils.getLocation(state.prevLocation, state.nextLocation, steps);

    Player.move(msg.sender, currLocation, nextLocation, 1);
  }

  // --------- Validations ---------

  function checkValidToken(uint tokenId) internal view {
    if (msg.sender != Registry.ownerOf(tokenId)) {
      revert InvalidToken();
    }
  }

  function checkValidLocation(Vec2 calldata location) internal pure {
    Vec2 memory _size = size();
    if (location.x >= _size.x || location.y >= _size.y) {
      revert InvalidLocation(location);
    }
  }

  function checkValidBiome(Game2Player.State memory state) internal pure {
    if (state.biome != id()) {
      revert InvalidBiome(state.biome);
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
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

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./Game2Types.sol";

contract Game2Player is AccessControl {
  bytes32 public constant GAME_ROLE = keccak256("GAME_ROLE");

  struct State {
    uint biome;
    Vec2 prevLocation;
    Vec2 nextLocation;
    uint moveTime;
    uint moveSpeed;
  }

  mapping(address => State) private states;

  event StateChanged(address indexed owner, State state);

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(GAME_ROLE, msg.sender);
  }

  // ----------- Getters -----------

  function getState(address owner) external view returns (State memory) {
    return states[owner];
  }

  // ----------- Actions -----------

  function initialize(address owner) external onlyRole(GAME_ROLE) {
    State storage state = states[owner];
    state.biome = 1;
    state.moveSpeed = 1;
  }

  function move(
    address owner,
    Vec2 calldata prevLocation,
    Vec2 calldata nextLocation,
    uint moveSpeed
  ) external onlyRole(GAME_ROLE) {
    State storage state = states[owner];

    state.prevLocation = prevLocation;
    state.nextLocation = nextLocation;
    state.moveTime = block.timestamp;
    state.moveSpeed = moveSpeed;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Game2World {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Game2Types.sol";

/**
 * Using manhattan pathfinding to find the location between two grid locations.
 */
function getLocation(
  Vec2 memory prevLocation,
  Vec2 memory nextLocation,
  uint steps
) pure returns (Vec2 memory) {
  uint dx = nextLocation.x > prevLocation.x
    ? nextLocation.x - prevLocation.x
    : prevLocation.x - nextLocation.x;

  uint dy = nextLocation.y > prevLocation.y
    ? nextLocation.y - prevLocation.y
    : prevLocation.y - nextLocation.y;

  if (steps >= dx + dy) {
    return nextLocation;
  }

  uint diag = dx < dy ? dx : dy;

  uint x;
  uint y;
  if (steps > uint(2) * diag) {
    (x, y) = (steps - diag, diag);
  } else {
    uint half = steps / 2;
    (x, y) = (half, steps - half);
  }

  (x, y) = dx > dy ? (x, y) : (y, x);

  if (nextLocation.x < prevLocation.x) {
    x = prevLocation.x - x;
  } else {
    x = prevLocation.x + x;
  }

  if (nextLocation.y < prevLocation.y) {
    y = prevLocation.y - y;
  } else {
    y = prevLocation.y + y;
  }

  return Vec2(x, y);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract CozyRegistry is AccessControl {
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
  bytes32 public constant WRITER_ROLE = keccak256("WRITER_ROLE");

  error InvalidPartnerAddress(address partnerAddress);

  uint public totalSupply;

  struct PartnerToken {
    address partnerAddress;
    uint partnerTokenId;
  }

  // Mapping from registry ID to owner addresses
  mapping(uint => address) private _owners;

  // Mapping from registry ID to partner token
  mapping(uint => PartnerToken) private _partnerTokens;

  // Mapping from partner token contents to registry ID
  mapping(address => mapping(uint => uint)) private _fromPartnerToken;

  // The allowlist for partner tokens
  mapping(address => bool) private _partnerAddressAllowlist;

  event RegistryEntryCreated(uint registryId, address indexed partnerAddress, uint partnerTokenId);
  event RegistryEntryTransferred(uint registryId, address indexed from, address indexed to);

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(ADMIN_ROLE, msg.sender);
    _setupRole(WRITER_ROLE, msg.sender);
  }

  // ----------- Getters -----------

  /**
   * Returns the owner of the given registry ID.
   *
   * Will return a zero address if there is no owner or if the registry entry
   * is invalidated by the allow list.
   */
  function ownerOf(uint registryId) external view returns (address) {
    PartnerToken storage token = _partnerTokens[registryId];
    if (_partnerAddressAllowlist[token.partnerAddress]) {
      return _owners[registryId];
    } else {
      return address(0);
    }
  }

  /**
   * Returns the registry ID given partner token information.
   *
   * Will return zero if registry entry does not exist.
   */
  function getRegistryId(address partnerAddress, uint partnerTokenId) external view returns (uint) {
    return _fromPartnerToken[partnerAddress][partnerTokenId];
  }

  /**
   * Returns the partner token associated with the given registry ID.
   *
   * Will return an empty partner token with a zero address if there is none.
   */
  function getPartnerToken(uint registryId) external view returns (PartnerToken memory) {
    return _partnerTokens[registryId];
  }

  /**
   * Returns whether the partner address is allowed in the registry.
   */
  function isPartnerAddressAllowed(address partnerAddress) external view returns (bool) {
    return _partnerAddressAllowlist[partnerAddress];
  }

  // ----------- Registration -----------

  /**
   * Registers a new owner to partner token information.
   *
   * Will create a new registry ID for the partner token information if the
   * partner token information has not been registered before.
   */
  function register(
    address owner,
    address partnerAddress,
    uint partnerTokenId
  ) public onlyRole(WRITER_ROLE) {
    if (!_partnerAddressAllowlist[partnerAddress]) {
      revert InvalidPartnerAddress(partnerAddress);
    }

    uint id = _getOrCreateRegistryId(partnerAddress, partnerTokenId);

    if (_owners[id] != owner) {
      address prevOwner = _owners[id];
      _owners[id] = owner;
      emit RegistryEntryTransferred(id, prevOwner, owner);
    }
  }

  /**
   * Internally get or create a registry ID associated with partner token
   * information.
   */
  function _getOrCreateRegistryId(address partnerAddress, uint partnerTokenId)
    internal
    returns (uint)
  {
    uint id = _fromPartnerToken[partnerAddress][partnerTokenId];

    if (id == 0) {
      totalSupply += 1;
      id = totalSupply;

      _fromPartnerToken[partnerAddress][partnerTokenId] = id;
      _partnerTokens[id] = PartnerToken(partnerAddress, partnerTokenId);

      emit RegistryEntryCreated(id, partnerAddress, partnerTokenId);
    }

    return id;
  }

  // -------- Administration -------

  function revokeOwner(uint registryId) external onlyRole(ADMIN_ROLE) {
    delete _owners[registryId];
  }

  function addPartnerAddress(address partnerAddress) external onlyRole(ADMIN_ROLE) {
    _partnerAddressAllowlist[partnerAddress] = true;
  }

  function removePartnerAddress(address partnerAddress) external onlyRole(ADMIN_ROLE) {
    delete _partnerAddressAllowlist[partnerAddress];
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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