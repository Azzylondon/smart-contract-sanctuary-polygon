/**
 *Submitted for verification at polygonscan.com on 2022-03-08
*/

// File: @openzeppelin/contracts/proxy/utils/Initializable.sol

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
        require(
            _initializing || !_initialized,
            "Initializable: contract is already initialized"
        );

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

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/utils/Strings.sol

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol

pragma solidity ^0.8.0;

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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/access/AccessControl.sol

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

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
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        override
        returns (bool)
    {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
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
    function grantRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
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
    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
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
    function renounceRole(bytes32 role, address account)
        public
        virtual
        override
    {
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

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
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
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
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: @openzeppelin/contracts/utils/Address.sol

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// File: contracts/libraries/employee.sol

pragma solidity ^0.8.0;

library EmployeeLibrary {
    struct EmployeeNFT {
        uint8 head;
        uint8 body;
        uint8 legs;
        uint8 hands;
        uint16 points;
    }

    struct EmployeeNFTData {
        EmployeeNFT employee;
        string uri;
    }

    struct EmployeeNFTExpanded {
        uint256 merges;
        bool usedForMulti;
    }

    struct EmployeeURI {
        uint8 head;
        uint8 body;
        uint8 hands;
        uint8 legs;
        uint16 points;
        uint256 id;
    }

    struct EmployeeChildrenNFT {
        uint8 head;
        uint8 body;
        uint8 legs;
        uint8 hands;
        uint8 net;
        uint16 xp;
        uint16 points;
    }

    struct EmployeeChildrenNFTData {
        EmployeeChildrenNFT employee;
        string uri;
    }

    struct EmployeesData {
        uint256 price;
        uint8 creatorFee;
        uint8 stakingFee;
        uint8 playToEarnFee;
        uint8 employeePoolFee;
    }

    struct EmployeesChildrensData {
        uint256 employeePrice;
        uint256 minterPointsPrice;
        uint16 payedMints;
        uint16 maxPayedMints;
        uint8 packageSize;
        uint8 packageDiscount;
        uint8 maxMerge;
        uint8 creatorFee;
        uint8 stakingFee;
        uint8 playToEarnFee;
        bool validatePayedMints;
    }

    struct SpecialEmployeesChildrensData {
        address specialToken;
        uint256 specialEmployeePrice;
        uint256 specialEmployeeInitPrice;
        uint256 specialEmployeeMaxPrice;
        uint256 specialQuantity;
        uint256 specialAugment;
        bool open;
    }

    struct EmployeeChildrenNFTExpanded {
        EmployeeChildrenNFTData employee;
    }

    struct DeployerData {
        uint8[] buildTypes;
        uint8[] buildModels;
        uint16[] typeProbabilities;
        uint16 probabilitiesTotal;
    }

    struct MultiEmployeesData {
        uint256 employeePrice;
        uint256 deployerPrice;
        uint8 CREATOR_FEE;
        uint8 LIQUIDITY_AGREGATOR_FEE;
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol

pragma solidity ^0.8.0;

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol

pragma solidity ^0.8.0;

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < ERC721.balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < ERC721Enumerable.totalSupply(),
            "ERC721Enumerable: global index out of bounds"
        );
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
        private
    {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// File: contracts/interfaces/randoms.sol

pragma solidity ^0.8.0;

interface Randoms {
    // Views
    function getRandomSeed(address user) external view returns (uint256 seed);

    function getRandomSeedUsingHash(address user, bytes32 hash)
        external
        view
        returns (uint256 seed);
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: contracts/randomUtil.sol

pragma solidity ^0.8.0;

library RandomUtil {
    using SafeMath for uint256;

    function randomSeededMinMax(
        uint256 min,
        uint256 max,
        uint256 seed,
        uint256 additional
    ) internal pure returns (uint256) {
        uint256 diff = max.sub(min).add(1);

        uint256 randomVar = uint256(
            keccak256(abi.encodePacked(seed, additional))
        ).mod(diff);

        randomVar = randomVar.add(min);

        return randomVar;
    }

    function expandedRandomSeededMinMax(
        uint256 min,
        uint256 max,
        uint256 seed,
        uint256 add,
        uint256 count
    ) internal pure returns (uint256[] memory) {
        uint256[] memory randoms = new uint256[](count);
        uint256 diff = max.sub(min).add(1);

        for (uint256 i = 0; i < count; i++) {
            randoms[i] = uint256(keccak256(abi.encodePacked(seed, add, i))).mod(
                diff
            );

            randoms[i].add(min);
        }

        return randoms;
    }

    function combineSeeds(uint256 seed1, uint256 seed2)
        internal
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(seed1, seed2)));
    }

    function combineSeeds(uint256[] memory seeds)
        internal
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(seeds)));
    }
}

// File: contracts/baseDeployer.sol

pragma solidity ^0.8.0;

contract BaseDeployer is Initializable, AccessControl {
    bytes32 public constant MAIN_OWNER = keccak256("MAIN_OWNER");

    uint16[] public typeProbabilities = [1, 5, 10, 30, 54];
    uint8[] public buildTypes = [1, 2, 3, 4, 5];
    uint8[] public buildModels = [1, 2, 3, 4];
    uint16 private _randomCounter = 1;

    string public constant INVALID_LENGTH = "BD: Invalid legth";
    string public constant INVALID_TYPE = "BD: Invalid type";
    string public constant INVALID_MODEL = "BD: Invalid model";

    Randoms private randoms;

    function initialize(Randoms _randoms) public initializer {
        _setupRole(MAIN_OWNER, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        randoms = _randoms;
    }

    // Getters

    function getBuildTypes() public view returns (uint8[] memory) {
        return buildTypes;
    }

    function getBuildModels() public view returns (uint8[] memory) {
        return buildModels;
    }

    function getTypeProbabilities() public view returns (uint16[] memory) {
        return typeProbabilities;
    }

    function getTypeProbability(uint8 build) public view returns (uint16) {
        require(isValidType(build), INVALID_TYPE);

        uint16 probability = 0;

        for (uint256 i = 0; i < buildTypes.length; i++) {
            if (build == buildTypes[i]) {
                probability = typeProbabilities[i];
                break;
            }
        }

        return probability;
    }

    function probabilitiesTotal(uint16[] memory probabilities)
        public
        pure
        returns (uint16)
    {
        uint16 adds = 0;

        for (uint8 i = 0; i < probabilities.length; i++) {
            adds += probabilities[i];
        }

        return adds;
    }

    function getProbabilitiesTotal() public view returns (uint16) {
        return probabilitiesTotal(typeProbabilities);
    }

    function getData()
        public
        view
        returns (EmployeeLibrary.DeployerData memory)
    {
        return
            EmployeeLibrary.DeployerData(
                buildTypes,
                buildModels,
                typeProbabilities,
                probabilitiesTotal(typeProbabilities)
            );
    }

    function getEmployeePoints(uint8 employee) public view returns (uint16) {
        return getProbabilitiesTotal() / getTypeProbability(employee);
    }

    function calcEmployeePoints(uint8[4] memory parts)
        public
        view
        returns (uint16)
    {
        uint16 points = 1;

        for (uint8 i = 0; i < parts.length; i++) {
            if (parts[i] == parts[0] && i != 0) {
                points += getEmployeePoints(parts[i]);
            }
        }

        return points;
    }

    // Alterators

    function addBuildTypes(uint8 build, uint16 probability)
        public
        onlyRole(MAIN_OWNER)
    {
        require(!isValidType(build), INVALID_TYPE);

        buildTypes.push(build);
        typeProbabilities.push(probability);
    }

    function removeBuildTypes(uint8 build) public onlyRole(MAIN_OWNER) {
        require(isValidType(build), INVALID_TYPE);

        for (uint256 i = 0; i < buildTypes.length; i++) {
            if (build == buildTypes[i]) {
                buildTypes[i] = buildTypes[buildTypes.length - 1];

                typeProbabilities[i] = typeProbabilities[
                    typeProbabilities.length - 1
                ];

                buildTypes.pop();
                typeProbabilities.pop();
                break;
            }
        }
    }

    function addBuildModel(uint8 model) public onlyRole(MAIN_OWNER) {
        require(!isValidModel(model), INVALID_MODEL);
        buildModels.push(model);
    }

    function removeBuildModel(uint8 model) public onlyRole(MAIN_OWNER) {
        require(isValidModel(model), INVALID_MODEL);

        for (uint256 i = 0; i < buildModels.length; i++) {
            if (model == buildModels[i]) {
                buildModels[i] = buildModels[buildModels.length - 1];
                buildModels.pop();
                break;
            }
        }
    }

    // Generators

    function addToRandomCounter() private {
        if (_randomCounter < 250) _randomCounter++;
        else _randomCounter = 0;
    }

    function randomBuildType() public returns (uint8) {
        return
            typeByRandom(
                newRandom(1, getProbabilitiesTotal()),
                typeProbabilities
            );
    }

    function randomBuildTypes(uint256 count) public returns (uint8[] memory) {
        uint8[] memory types = new uint8[](count);

        uint256[] memory random = newRandomBatch(
            1,
            getProbabilitiesTotal(),
            count
        );

        for (uint256 i = 0; i < count; i++) {
            types[i] = typeByRandom(random[i], typeProbabilities);
        }

        return types;
    }

    function randomTypeByProbabilities(uint16[] memory probabilities)
        public
        returns (uint8)
    {
        require(probabilities.length == buildTypes.length, INVALID_LENGTH);

        return
            typeByRandom(
                newRandom(1, probabilitiesTotal(probabilities)),
                probabilities
            );
    }

    function randomModel() public returns (uint8) {
        uint8 model = buildModels[newRandom(0, buildModels.length - 1)];
        require(isValidModel(model), INVALID_MODEL);
        return model;
    }

    function typeByRandom(uint256 random, uint16[] memory probabilities)
        public
        view
        returns (uint8)
    {
        uint256 momentAdd = 0;
        uint8 build = buildTypes[buildTypes.length - 1];

        for (uint256 i = 0; i < probabilities.length; i++) {
            uint256 nextAdd = (momentAdd + probabilities[i]);
            if (momentAdd <= random && random <= nextAdd) return buildTypes[i];
            momentAdd += probabilities[i];
        }

        require(isValidType(build), INVALID_TYPE);

        return build;
    }

    // Randoms

    function newRandom(uint256 min, uint256 max) private returns (uint256) {
        uint256 random = RandomUtil.randomSeededMinMax(
            min,
            max,
            randoms.getRandomSeed(msg.sender),
            _randomCounter
        );

        addToRandomCounter();

        return random;
    }

    function newRandomBatch(
        uint256 min,
        uint256 max,
        uint256 count
    ) private returns (uint256[] memory) {
        uint256[] memory randomSeed = (
            RandomUtil.expandedRandomSeededMinMax(
                min,
                max,
                randoms.getRandomSeed(msg.sender),
                _randomCounter,
                count
            )
        );

        addToRandomCounter();

        return randomSeed;
    }

    // Questions
    function isValidType(uint8 reqType) public view returns (bool) {
        bool isType = false;
        for (uint256 i = 0; i < buildTypes.length; i++) {
            if (buildTypes[i] == reqType) {
                isType = true;
                break;
            }
        }
        return isType;
    }

    function isValidModel(uint8 model) public view returns (bool) {
        bool isType = false;
        for (uint256 i = 0; i < buildModels.length; i++) {
            if (buildModels[i] == model) {
                isType = true;
                break;
            }
        }
        return isType;
    }
}

// File: contracts/employee.sol

pragma solidity ^0.8.0;

contract Employees is Context, AccessControl, ERC721Enumerable {
    string private _baseUri = "";
    uint256 private _count = 1;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURN_ROLE = keccak256("BURN_ROLE");

    mapping(uint256 => EmployeeLibrary.EmployeeNFT) private employees;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseUri
    ) ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(BURN_ROLE, _msgSender());
        _baseUri = baseUri;
    }

    function uri() public view virtual returns (string memory) {
        return _baseUri;
    }

    function getEmployee(uint256 id)
        public
        view
        virtual
        returns (EmployeeLibrary.EmployeeNFTData memory)
    {
        return EmployeeLibrary.EmployeeNFTData(employees[id], tokenURI(id));
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        string memory union = string(
            abi.encodePacked(
                "head:",
                Strings.toString(employees[id].head),
                ";body:",
                Strings.toString(employees[id].body),
                ";legs:",
                Strings.toString(employees[id].legs),
                ";hands:",
                Strings.toString(employees[id].hands),
                ";points:",
                Strings.toString(employees[id].points)
            )
        );

        return
            string(
                abi.encodePacked(
                    _baseUri,
                    "?a=",
                    union,
                    ";id:",
                    Strings.toString(id)
                )
            );
    }

    function mint(
        uint8 head,
        uint8 body,
        uint8 legs,
        uint8 hands,
        uint16 points,
        address to
    ) public virtual {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "Employees: Invalid minter"
        );

        employees[_count] = EmployeeLibrary.EmployeeNFT(
            head,
            body,
            legs,
            hands,
            points
        );

        _mint(to, _count);
        _count++;
    }

    function burn(uint256 id) public virtual {
        require(
            _exists(id) &&
                ((ownerOf(id) == _msgSender()) ||
                    hasRole(BURN_ROLE, _msgSender())),
            "Employees: Burn error."
        );

        delete employees[id];
        _burn(id);
    }

    //Getters

    function getParts(uint256 id)
        public
        view
        virtual
        returns (uint8[4] memory)
    {
        return [
            employees[id].head,
            employees[id].body,
            employees[id].legs,
            employees[id].hands
        ];
    }

    function getType(uint256 id) public view virtual returns (uint8) {
        return employees[id].head;
    }

    function getPoints(uint256 id) public view virtual returns (uint16) {
        return employees[id].points;
    }

    function getCustomerEmployees(address customer)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        uint256[] memory nfts = new uint256[](balanceOf(customer));
        for (uint256 i = 0; i < nfts.length; i++) {
            nfts[i] = tokenOfOwnerByIndex(customer, i);
        }
        return nfts;
    }

    function validate(uint256 id) public view returns (bool) {
        return _exists(id) && employees[id].points != 0;
    }

    function isOwnerOfAll(address owner, uint256[] calldata ids)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < ids.length; i++) {
            if (!validate(ids[i]) || (ownerOf(ids[i]) != owner)) {
                return false;
            }
        }

        return true;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// File: contracts/miniEmployee.sol

pragma solidity ^0.8.0;

contract MiniEmployees is Context, AccessControl, ERC721Enumerable {
    string private _baseUri = "";
    uint256 private _count = 1;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURN_ROLE = keccak256("BURN_ROLE");

    mapping(uint256 => EmployeeLibrary.EmployeeChildrenNFT) private employees;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseUri
    ) ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(BURN_ROLE, _msgSender());
        _baseUri = baseUri;
    }

    function uri() public view virtual returns (string memory) {
        return _baseUri;
    }

    function getEmployee(uint256 id)
        public
        view
        virtual
        returns (EmployeeLibrary.EmployeeChildrenNFTData memory)
    {
        return
            EmployeeLibrary.EmployeeChildrenNFTData(
                employees[id],
                tokenURI(id)
            );
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        string memory union = string(
            abi.encodePacked(
                "head:",
                Strings.toString(employees[id].head),
                ";body:",
                Strings.toString(employees[id].body),
                ";legs:",
                Strings.toString(employees[id].legs),
                ";hands:",
                Strings.toString(employees[id].hands),
                ";points:",
                Strings.toString(employees[id].points),
                ";xp:",
                Strings.toString(employees[id].xp),
                ";net:",
                Strings.toString(employees[id].net)
            )
        );

        return
            string(
                abi.encodePacked(
                    _baseUri,
                    "?a=",
                    union,
                    ";id:",
                    Strings.toString(id)
                )
            );
    }

    function mint(
        uint8 head,
        uint8 body,
        uint8 legs,
        uint8 hands,
        uint8 net,
        uint16 points,
        address to
    ) public virtual {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "Employees: Invalid minter"
        );

        employees[_count] = EmployeeLibrary.EmployeeChildrenNFT(
            head,
            body,
            legs,
            hands,
            net,
            0,
            points
        );

        _mint(to, _count);
        _count++;
    }

    function levelUp(uint256 id, uint16 xp) public onlyRole(MINTER_ROLE) {
        employees[id].xp += xp;
    }

    function burn(uint256 id) public virtual {
        require(
            _exists(id) &&
                ((ownerOf(id) == _msgSender()) ||
                    hasRole(BURN_ROLE, _msgSender())),
            "Employees: Burn error."
        );

        delete employees[id];
        _burn(id);
    }

    //Getters

    function getParts(uint256 id)
        public
        view
        virtual
        returns (uint8[4] memory)
    {
        return [
            employees[id].head,
            employees[id].body,
            employees[id].legs,
            employees[id].hands
        ];
    }

    function getXP(uint256 id) public view virtual returns (uint16) {
        return employees[id].xp;
    }

    function getType(uint256 id) public view virtual returns (uint8) {
        return employees[id].head;
    }

    function getPoints(uint256 id) public view virtual returns (uint16) {
        return employees[id].points;
    }

    function getSpecial(uint256 id) public view virtual returns (bool) {
        return employees[id].net == 1 ? true : false;
    }

    function getCustomerEmployees(address customer)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        uint256[] memory nfts = new uint256[](balanceOf(customer));
        for (uint256 i = 0; i < nfts.length; i++) {
            nfts[i] = tokenOfOwnerByIndex(customer, i);
        }
        return nfts;
    }

    function validate(uint256 id) public view returns (bool) {
        return _exists(id) && employees[id].points != 0;
    }

    function isOwnerOfAll(address owner, uint256[] calldata ids)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < ids.length; i++) {
            if (!validate(ids[i]) || (ownerOf(ids[i]) != owner)) {
                return false;
            }
        }

        return true;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.8.0;

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
    constructor(string memory name_, string memory symbol_) {
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
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
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
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
}

// File: contracts/libraries/factoryStaking.sol

pragma solidity ^0.8.0;

library FactoryStakingLibrary {
    struct Factory {
        address owner;
        uint256 factory;
        uint256 timestamp;
    }

    struct Info {
        uint256 inStakeFactories;
        uint256 inStakeCustomers;
        uint256 inStakePoints;
    }

    struct Customer {
        Factory[] stakedFactories;
        uint256 minterPoints;
        uint256 savedMinterPoints;
    }

    struct SendRewards {
        uint256 customerRewards;
        uint256 timestamp;
    }
}

// File: contracts/tokenController.sol

pragma solidity ^0.8.0;

contract TokenController is Context, Initializable, AccessControl {
    bytes32 public constant CONNECTION = keccak256("CONNECTION");
    bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");

    string public constant INVALID_ROLE = "TC: Invalid Role";
    string public constant INVALID_ADDRESS = "TC: Invalid Address";
    string public constant INVALID_TOKENS = "TC: Invalid Amount of tokens";
    string public constant INVALID_FEES = "TC: Invalid fees payment";
    string public constant INVALID_PAYMENT = "TC: Invalid payment";
    string public constant BLACKLIST = "TC: You are in blacklist";

    mapping(address => bool) private blacklist;

    uint8 public constant CREATOR_FEE = 5;

    ERC20 private token;

    address public creator;

    function initialize(ERC20 _token) public initializer {
        _setupRole(ROLE_ADMIN, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        creator = _msgSender();
        token = _token;
    }

    function addConnectionContract(address connection)
        public
        onlyRole(ROLE_ADMIN)
    {
        grantRole(CONNECTION, connection);
    }

    function sendTokens(address to, uint256 amount)
        public
        onlyRole(CONNECTION)
    {
        require(!blacklist[to], BLACKLIST);
        require(token.balanceOf(address(this)) > amount, INVALID_TOKENS);

        token.transfer(creator, (amount * CREATOR_FEE) / 100);
        token.transfer(to, (amount * (100 - CREATOR_FEE)) / 100);
    }

    function changeBlackListState(address bad, bool state)
        public
        onlyRole(ROLE_ADMIN)
    {
        blacklist[bad] = state;
    }
}

// File: contracts/libraries/factory.sol

pragma solidity ^0.8.0;

library FactoryLibrary {
    struct FactoryNFT {
        uint8 build;
        uint8 model;
        uint256 points;
    }

    struct FactoryNFTData {
        FactoryNFT factory;
        string uri;
    }

    struct FactoryNFTExpanded {
        FactoryNFTData factory;
        uint256 burnTokens;
    }

    struct FactoryURI {
        uint8 build;
        uint8 model;
        uint256 multiplier;
        uint256 id;
    }

    struct FactoriesData {
        uint256 price;
        uint8 burnEmployees;
        uint8 creatorFee;
        uint8 stakingFee;
        uint8 playToEarnFee;
    }

    struct DeployerData {
        uint8[] buildTypes;
        uint8[] buildModels;
        uint16[] typeProbabilities;
        uint16 probabilitiesTotal;
    }
}

// File: contracts/factory.sol

pragma solidity ^0.8.0;

contract Factories is Context, AccessControl, ERC721Enumerable {
    string private _baseUri = "";
    uint256 private _count = 1;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURN_ROLE = keccak256("BURN_ROLE");
    bytes32 public constant CONNECTION = keccak256("CONNECTION");

    mapping(uint256 => FactoryLibrary.FactoryNFT) private factories;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseUri
    ) ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(BURN_ROLE, _msgSender());
        _setupRole(CONNECTION, _msgSender());
        _baseUri = baseUri;
    }

    function uri() public view returns (string memory) {
        return _baseUri;
    }

    function getFactory(uint256 id)
        public
        view
        returns (FactoryLibrary.FactoryNFTData memory)
    {
        return FactoryLibrary.FactoryNFTData(factories[id], tokenURI(id));
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        string memory union = string(
            abi.encodePacked(
                "build:",
                Strings.toString(factories[id].build),
                ";model:",
                Strings.toString(factories[id].model),
                ";points:",
                Strings.toString(factories[id].points)
            )
        );

        return
            string(
                abi.encodePacked(
                    _baseUri,
                    "?a=",
                    union,
                    ";id:",
                    Strings.toString(id)
                )
            );
    }

    function mint(
        uint8 build,
        uint8 model,
        uint256 points,
        address to
    ) public virtual {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "Factories: Invalid minter"
        );

        factories[_count] = FactoryLibrary.FactoryNFT(build, model, points);

        _mint(to, _count);
        _count++;
    }

    function burn(uint256 id) public virtual {
        require(
            _exists(id) &&
                (ownerOf(id) == _msgSender() ||
                    hasRole(BURN_ROLE, _msgSender())),
            "Factories: Burn error"
        );

        delete factories[id];
        _burn(id);
    }

    // Getters

    function getMultiplier(uint256 id) public view virtual returns (uint256) {
        return factories[id].points;
    }

    function getType(uint256 id) public view virtual returns (uint8) {
        return factories[id].build;
    }

    function getModel(uint256 id) public view virtual returns (uint8) {
        return factories[id].model;
    }

    function addToMultiplier(uint256 id, uint256 points)
        public
        onlyRole(CONNECTION)
    {
        require(_exists(id), "Factories: Invalid factory.");
        factories[id].points += points;
    }

    function getCustomerFactories(address customer)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        uint256[] memory nfts = new uint256[](balanceOf(customer));
        for (uint256 i = 0; i < nfts.length; i++) {
            nfts[i] = tokenOfOwnerByIndex(customer, i);
        }
        return nfts;
    }

    function validate(uint256 id) public view returns (bool) {
        return _exists(id) && factories[id].points != 0;
    }

    function isOwnerOfAll(address owner, uint256[] calldata ids)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < ids.length; i++) {
            if (!validate(ids[i]) || (ownerOf(ids[i]) != owner)) {
                return false;
            }
        }

        return true;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// File: contracts/factoryStaking.sol

pragma solidity ^0.8.0;

contract FactoryStaking is Initializable, AccessControl {
    bytes32 public constant MAIN_OWNER = keccak256("MAIN_OWNER");
    bytes32 public constant CONNECTION = keccak256("CONNECTION");

    event StakeFactory(FactoryStakingLibrary.Factory);
    event Grow(FactoryStakingLibrary.SendRewards);
    event RemoveFactory(FactoryStakingLibrary.Factory);

    string public constant INVALID_FACTORY_DATA = "FS: Invalid factory data";
    string public constant INVALID_OWNER = "FS: Invalid owner";
    string public constant STAKED_FACTORY = "FS: The factory is staked";
    string public constant UNSTAKED_FACTORY = "FS: The factory isn't staked";
    string public constant INVALID_CUSTOMERS = "FS: Invalid customers";
    string public constant INVALID_REWARDS = "FS: Invalid rewards";
    string public constant INVALID_STAKE_POINTS = "FS: Invalid staking points";
    string public constant WAIT_MORE = "FS: wait more";
    string public constant INVALID_V1_STAKING = "FS: invalid V1 staking";

    Factories private factories;
    TokenController private manager;

    uint256 private _inStakeFactories = 0;
    uint256 private _inStakePoints = 0;

    uint256 private _factoryGrowReward = 7000000000000;
    uint32 private _maxGrowTime = 1728000;
    uint32 private _minGrowTime = 259200;
    uint32 private _timePerMinterPoints = 864;
    uint16 private _pointsPerTime = 10;

    address[] private _inStakeCustomers;

    mapping(address => bool) private _registered;
    mapping(address => uint256) private _stakedMinterPoints;
    mapping(address => uint256) private _stakedMinterTimestamp;
    mapping(address => uint256[]) private _stakedCustomerFactories;
    mapping(address => mapping(uint256 => uint256)) private _stakedFactories;

    address private _creator;

    function initialize(Factories _factories, TokenController _manager)
        public
        initializer
    {
        _setupRole(MAIN_OWNER, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _creator = msg.sender;

        factories = _factories;
        manager = _manager;
    }

    // Getters

    function getStakingInfo()
        public
        view
        returns (FactoryStakingLibrary.Info memory)
    {
        return
            FactoryStakingLibrary.Info(
                _inStakeFactories,
                _inStakeCustomers.length,
                _inStakePoints
            );
    }

    function getCustomerInfo(address customer)
        public
        view
        returns (FactoryStakingLibrary.Customer memory)
    {
        return
            FactoryStakingLibrary.Customer(
                getCustomerFactories(customer),
                getMinterPoints(customer),
                getSavedMinterPoints(customer)
            );
    }

    function getMinterPoints(address customer) public view returns (uint256) {
        return
            _stakedMinterTimestamp[customer] > 0
                ? ((block.timestamp - _stakedMinterTimestamp[customer]) /
                    _timePerMinterPoints) * _pointsPerTime
                : 0;
    }

    function getSavedMinterPoints(address customer)
        public
        view
        returns (uint256)
    {
        return _stakedMinterPoints[customer];
    }

    function getCustomerFactories(address customer)
        public
        view
        returns (FactoryStakingLibrary.Factory[] memory)
    {
        uint256 customerBalance = _stakedCustomerFactories[customer].length;

        FactoryStakingLibrary.Factory[]
            memory data = new FactoryStakingLibrary.Factory[](customerBalance);

        for (uint256 i = 0; i < customerBalance; i++) {
            data[i] = FactoryStakingLibrary.Factory(
                customer,
                _stakedCustomerFactories[customer][i],
                _stakedFactories[customer][
                    _stakedCustomerFactories[customer][i]
                ]
            );
        }

        return data;
    }

    function getAllRewards(address customer) public view returns (uint256) {
        uint256 rewards = 0;

        for (
            uint256 i = 0;
            i < _stakedCustomerFactories[customer].length;
            i++
        ) {
            if (
                canFactoryGrow(customer, _stakedCustomerFactories[customer][i])
            ) {
                rewards += getGrowReward(
                    customer,
                    _stakedCustomerFactories[customer][i]
                );
            }
        }

        return rewards;
    }

    // Setters

    function setFactoryGrowReward(uint256 reward) public onlyRole(MAIN_OWNER) {
        _factoryGrowReward = reward;
    }

    function setMinGrowTime(uint32 time) public onlyRole(MAIN_OWNER) {
        _minGrowTime = time;
    }

    function setMaxGrowTime(uint32 time) public onlyRole(MAIN_OWNER) {
        _maxGrowTime = time;
    }

    function setTimePerMinterPoints(uint32 time) public onlyRole(MAIN_OWNER) {
        _timePerMinterPoints = time;
    }

    function setPointsPerTime(uint16 points) public onlyRole(MAIN_OWNER) {
        _pointsPerTime = points;
    }

    //Calc

    function getRewardPerFactory(address owner, uint256 factory)
        public
        view
        returns (uint256)
    {
        return
            theFactoryIsStaked(factory)
                ? (_factoryGrowReward *
                    (block.timestamp - _stakedFactories[owner][factory]) *
                    (factories.getMultiplier(factory)))
                : 0;
    }

    function getBonusPerTime(address owner, uint256 factory)
        public
        view
        returns (uint256)
    {
        uint256 time = block.timestamp - _stakedFactories[owner][factory];
        if (time > _maxGrowTime) time = _maxGrowTime;

        return
            theFactoryIsStaked(factory)
                ? ((time**2) * _factoryGrowReward) / 4000
                : 0;
    }

    function getGrowReward(address owner, uint256 id)
        public
        view
        returns (uint256)
    {
        return getRewardPerFactory(owner, id) + getBonusPerTime(owner, id);
    }

    // Staking

    function sendFactoryToStaking(uint256 factory) public {
        require(factories.ownerOf(factory) == msg.sender, INVALID_OWNER);
        require(factories.validate(factory), INVALID_FACTORY_DATA);
        require(!theFactoryIsStaked(factory), STAKED_FACTORY);

        if (!_registered[msg.sender]) {
            _inStakeCustomers.push(msg.sender);
            _registered[msg.sender] = true;
        }

        if (_stakedMinterTimestamp[msg.sender] == 0) {
            _stakedMinterTimestamp[msg.sender] = block.timestamp;
        }

        uint256 factoryPoints = factories.getMultiplier(factory);

        _stakedCustomerFactories[msg.sender].push(factory);
        _inStakeFactories++;
        _inStakePoints += factoryPoints;
        _stakedFactories[msg.sender][factory] = block.timestamp;

        factories.transferFrom(msg.sender, address(this), factory);

        emit StakeFactory(
            FactoryStakingLibrary.Factory(msg.sender, factory, block.timestamp)
        );
    }

    function removeFactoryFromStaking(uint256 factory) public {
        require(theFactoryIsStaked(factory), UNSTAKED_FACTORY);
        require(factories.validate(factory), INVALID_FACTORY_DATA);

        require(_stakedFactories[msg.sender][factory] != 0, INVALID_OWNER);

        for (
            uint256 i = 0;
            i < _stakedCustomerFactories[msg.sender].length;
            i++
        ) {
            if (_stakedCustomerFactories[msg.sender][i] == factory) {
                _stakedCustomerFactories[msg.sender][
                    i
                ] = _stakedCustomerFactories[msg.sender][
                    _stakedCustomerFactories[msg.sender].length - 1
                ];

                _stakedCustomerFactories[msg.sender].pop();
                break;
            }
        }

        if (_stakedCustomerFactories[msg.sender].length == 0) {
            _stakedMinterTimestamp[msg.sender] = 0;
        }

        uint256 factoryPoints = factories.getMultiplier(factory);

        _inStakeFactories--;
        _inStakePoints -= factoryPoints;

        factories.transferFrom(address(this), msg.sender, factory);

        _stakedFactories[msg.sender][factory] = 0;

        emit RemoveFactory(
            FactoryStakingLibrary.Factory(msg.sender, factory, block.timestamp)
        );
    }

    function saveMinterPoints() public {
        _stakedMinterPoints[msg.sender] += getMinterPoints(msg.sender);
        _stakedMinterTimestamp[msg.sender] = block.timestamp;
    }

    // Alterators

    function growAllFactories() public {
        require(_registered[msg.sender], INVALID_CUSTOMERS);

        require(
            _stakedCustomerFactories[msg.sender].length > 0,
            INVALID_STAKE_POINTS
        );

        for (
            uint256 i = 0;
            i < _stakedCustomerFactories[msg.sender].length;
            i++
        ) {
            if (
                canFactoryGrow(
                    msg.sender,
                    _stakedCustomerFactories[msg.sender][i]
                )
            ) {
                _stakedFactories[msg.sender][
                    _stakedCustomerFactories[msg.sender][i]
                ] = block.timestamp;
            }
        }

        manager.sendTokens(msg.sender, getAllRewards(msg.sender));
    }

    function growFactory(uint256 factory) public {
        require(_registered[msg.sender], INVALID_CUSTOMERS);

        require(
            _stakedCustomerFactories[msg.sender].length > 0,
            INVALID_STAKE_POINTS
        );

        require(theFactoryIsStaked(factory), STAKED_FACTORY);
        require(canFactoryGrow(msg.sender, factory));

        manager.sendTokens(msg.sender, getGrowReward(msg.sender, factory));

        _stakedFactories[msg.sender][factory] = block.timestamp;
    }

    function useMinterPoints(address customer, uint256 amount)
        public
        onlyRole(CONNECTION)
    {
        _stakedMinterPoints[customer] -= amount;
    }

    // Questions

    function canFactoryGrow(address owner, uint256 id)
        public
        view
        returns (bool)
    {
        return
            theFactoryIsStaked(id) &&
            _stakedFactories[owner][id] <= block.timestamp - _minGrowTime;
    }

    function theFactoryIsStaked(uint256 factory) public view returns (bool) {
        return factories.ownerOf(factory) == address(this);
    }
}

// File: contracts/employeeExpanded.sol

pragma solidity ^0.8.0;

contract EmployeesExpanded is Context, AccessControl {
    bytes32 public constant LINK = keccak256("LINK");
    bytes32 public constant MAIN_OWNER = keccak256("MAIN_OWNER");

    uint8 public maxMerges = 10;

    mapping(uint256 => uint8) private employeeMerges;
    mapping(uint256 => bool) private usedForMultiEmployee;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(LINK, _msgSender());
        _setupRole(MAIN_OWNER, _msgSender());
    }

    function setMaxMerges(uint8 max) public onlyRole(MAIN_OWNER) {
        maxMerges = max;
    }

    function addMerge(uint256 id, uint8 merges) public onlyRole(LINK) {
        employeeMerges[id] += merges;
    }

    function useForMultiEmployee(uint256 id, bool used) public onlyRole(LINK) {
        usedForMultiEmployee[id] = used;
    }

    function getEmployeeData(uint256 id)
        public
        view
        returns (EmployeeLibrary.EmployeeNFTExpanded memory)
    {
        return
            EmployeeLibrary.EmployeeNFTExpanded(
                employeeMerges[id],
                usedForMultiEmployee[id]
            );
    }

    function getMergeRecord(uint256 id) public view returns (uint8) {
        return employeeMerges[id];
    }

    function canMerge(uint256 id) public view returns (bool) {
        return employeeMerges[id] < maxMerges;
    }

    function isUsedForMultiEmployee(uint256 id) public view returns (bool) {
        return usedForMultiEmployee[id];
    }
}

// File: contracts/miniEmployeeDeployer.sol

pragma solidity ^0.8.0;

contract MiniEmployeeDeployer is Initializable, AccessControl {
    event PayMint(address owner, uint256 amount, bool package);
    event StakingMint(address owner, uint256 amount, bool package);
    event Upgrade(address owner, uint256 id, uint16 points);
    event Merge(address owner, uint256 men, uint256 woman);

    bytes32 public constant MAIN_OWNER = keccak256("MAIN_OWNER");

    string public constant INVALID_TYPE = "ED: Invalid employee type";
    string public constant INVALID_PAYMENT = "ED: Invalid payment";
    string public constant INVALID_LENGTH = "ED: Invalid length";
    string public constant INVALID_CREATOR = "ED: Invalid creator";
    string public constant INVALID_OWNER = "ED: Invalid owner";
    string public constant INVALID_EMPLOYEE = "ED: Invalid employee";
    string public constant INVALID_PLAY_TO_EARN = "ED: Invalid play to earn";
    string public constant INVALID_BUY = "ED: Invalid buy";
    string public constant INVALID_MERGE = "ED: Invalid merge";
    string public constant INVALID_XP = "ED: Invalid xp";
    string public constant INVALID_FEES = "ED: Invalid fees";

    uint8 public creatorFee = 5;
    uint8 public employeeStakingFee = 1;
    uint8 public playToEarnFee = 94;
    uint8 public maxMerges = 10;
    uint8 public liquidityAgregatorFee = 95;

    bool public validateMaxPayedMints = false;
    bool public openSpecialEmployee = false;

    uint16 public minterPointsPrice = 2000;
    uint16 public maxPayedMints = 10000;
    uint16 public payedMints = 0;
    uint8 public packageDiscount = 5;
    uint8 public packageSize = 5;

    uint256 public employeePrice = 1000000000000000000000 wei;
    uint256 public specialEmployeePrice = 4000000000000000000 wei;
    uint256 public specialEmployeeMaxPrice = 50000000000000000000 wei;
    uint256 public specialEmployeeInitPrice = 4000000000000000000 wei;

    Randoms private randoms;
    IERC20 private token;
    IERC20 private specialToken;
    Employees private employees;
    MiniEmployees private miniEmployees;
    BaseDeployer private baseDeployer;
    FactoryStaking private factoryStaking;
    EmployeesExpanded private employeeExpanded;

    address public creator;
    address public liquidityAgregator;
    address public playToEarnPool;
    address public employeesStaking;

    uint256 public specialAugment = 3;
    uint256 public specialQuantity = 1;
    uint256 public specialCounter = 0;

    function initialize(
        ERC20 _token,
        ERC20 _specialToken,
        Randoms _randoms,
        Employees _employees,
        BaseDeployer _baseDeployer,
        MiniEmployees _miniEmployees,
        FactoryStaking _factoryStaking,
        EmployeesExpanded _employeeExpanded
    ) public initializer {
        _setupRole(MAIN_OWNER, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        creator = msg.sender;

        token = _token;
        specialToken = _specialToken;
        randoms = _randoms;
        employees = _employees;
        miniEmployees = _miniEmployees;
        baseDeployer = _baseDeployer;
        factoryStaking = _factoryStaking;
        employeeExpanded = _employeeExpanded;
    }

    // Getters

    function getEmployeesData()
        public
        view
        returns (EmployeeLibrary.EmployeesChildrensData memory)
    {
        return
            EmployeeLibrary.EmployeesChildrensData(
                employeePrice,
                minterPointsPrice,
                payedMints,
                maxPayedMints,
                packageSize,
                packageDiscount,
                maxMerges,
                creatorFee,
                employeeStakingFee,
                playToEarnFee,
                validateMaxPayedMints
            );
    }

    function getSpecialEmployeesData()
        public
        view
        returns (EmployeeLibrary.SpecialEmployeesChildrensData memory)
    {
        return
            EmployeeLibrary.SpecialEmployeesChildrensData(
                address(specialToken),
                specialEmployeePrice,
                specialEmployeeInitPrice,
                specialEmployeeMaxPrice,
                specialQuantity,
                specialAugment,
                openSpecialEmployee
            );
    }

    function getMiniEmployeeExpanded(uint256 mini)
        public
        view
        returns (EmployeeLibrary.EmployeeChildrenNFTExpanded memory)
    {
        return
            EmployeeLibrary.EmployeeChildrenNFTExpanded(
                miniEmployees.getEmployee(mini)
            );
    }

    function getNecessaryXP(uint256 employee) public view returns (uint256) {
        return miniEmployees.getPoints(employee) * 100;
    }

    // Setters

    function changeRedirectAddresses(
        address _creator,
        address _playToEarnPool,
        address _employeesStaking,
        address _liquidityAgregator,
        BaseDeployer _deployer,
        FactoryStaking _factoryStaking
    ) public onlyRole(MAIN_OWNER) {
        playToEarnPool = _playToEarnPool;
        employeesStaking = _employeesStaking;
        liquidityAgregator = _liquidityAgregator;
        factoryStaking = _factoryStaking;
        baseDeployer = _deployer;
        creator = _creator;
    }

    function changeConfigurations(IERC20 _token, IERC20 _specialToken)
        public
        onlyRole(MAIN_OWNER)
    {
        token = _token;
        specialToken = _specialToken;
    }

    function changeFees(
        uint8 _creator,
        uint8 _employeeStaking,
        uint8 _playToEarn
    ) public onlyRole(MAIN_OWNER) {
        require(_creator + _employeeStaking + _playToEarn == 100, INVALID_FEES);

        creatorFee = _creator;
        employeeStakingFee = _employeeStaking;
        playToEarnFee = _playToEarn;
    }

    function setMaxMerge(uint8 max) public onlyRole(MAIN_OWNER) {
        maxMerges = max;
    }

    function setEmployeePrice(uint256 _price) public onlyRole(MAIN_OWNER) {
        employeePrice = _price;
    }

    function changeSpecialData(
        uint256 price,
        uint256 augment,
        uint256 quantity,
        uint256 initPrice,
        uint256 maxPrice,
        bool open
    ) public onlyRole(MAIN_OWNER) {
        specialEmployeePrice = price;
        specialAugment = augment;
        specialQuantity = quantity;
        specialEmployeeInitPrice = initPrice;
        specialEmployeeMaxPrice = maxPrice;
        openSpecialEmployee = open;
    }

    function setMinterPointsPrice(uint16 _price) public onlyRole(MAIN_OWNER) {
        minterPointsPrice = _price;
    }

    function setPackageDiscount(uint8 discount) public onlyRole(MAIN_OWNER) {
        packageDiscount = discount;
    }

    function setValidateMaxMints(bool validate) public onlyRole(MAIN_OWNER) {
        validateMaxPayedMints = validate;
    }

    function setPackageSize(uint8 size) public onlyRole(MAIN_OWNER) {
        packageSize = size;
    }

    function setMaxPayedMints(uint16 max) public onlyRole(MAIN_OWNER) {
        maxPayedMints = max;
    }

    // Alterators

    function payMint(address customer, bool package) private returns (bool) {
        require(creator != address(0), INVALID_CREATOR);
        require(playToEarnPool != address(0), INVALID_PLAY_TO_EARN);
        require(employeesStaking != address(0), INVALID_PLAY_TO_EARN);

        uint256 totalAmount = package
            ? (((employeePrice * packageSize) / 100) * (100 - packageDiscount))
            : employeePrice;

        require(token.balanceOf(customer) >= totalAmount, INVALID_PAYMENT);

        if (creatorFee > 0) {
            token.transferFrom(
                customer,
                creator,
                (totalAmount * creatorFee) / 100
            );
        }

        if (playToEarnFee > 0) {
            token.transferFrom(
                customer,
                playToEarnPool,
                (totalAmount * playToEarnFee) / 100
            );
        }

        if (employeeStakingFee > 0) {
            token.transferFrom(
                customer,
                employeesStaking,
                (totalAmount * employeeStakingFee) / 100
            );
        }

        emit PayMint(customer, totalAmount, package);

        return true;
    }

    function normalMint() private {
        uint8[] memory parts = baseDeployer.randomBuildTypes(4);

        miniEmployees.mint(
            parts[0],
            parts[1],
            parts[2],
            parts[3],
            0,
            baseDeployer.calcEmployeePoints(
                [parts[0], parts[1], parts[2], parts[3]]
            ),
            msg.sender
        );
    }

    function packageMint() private {
        uint8[] memory parts = baseDeployer.randomBuildTypes(packageSize * 4);

        for (uint8 i = 0; i < packageSize * 4; i += 4) {
            miniEmployees.mint(
                parts[i],
                parts[i + 1],
                parts[i + 2],
                parts[i + 3],
                0,
                baseDeployer.calcEmployeePoints(
                    [parts[i], parts[i + 1], parts[i + 2], parts[i + 3]]
                ),
                msg.sender
            );
        }
    }

    function mintSpecialEmployee() public {
        require(openSpecialEmployee, INVALID_BUY);
        require(creator != address(0), INVALID_CREATOR);

        require(
            specialToken.balanceOf(msg.sender) >= specialEmployeePrice,
            INVALID_PAYMENT
        );

        specialToken.transferFrom(
            msg.sender,
            creator,
            (specialEmployeePrice * (100 - liquidityAgregatorFee)) / 100
        );

        specialToken.transferFrom(
            msg.sender,
            liquidityAgregator,
            (specialEmployeePrice * liquidityAgregatorFee) / 100
        );

        uint8[] memory parts = baseDeployer.randomBuildTypes(3);

        miniEmployees.mint(
            parts[0],
            parts[1],
            parts[2],
            parts[0],
            1,
            baseDeployer.calcEmployeePoints(
                [parts[0], parts[1], parts[2], parts[0]]
            ),
            msg.sender
        );

        specialCounter++;

        if (specialCounter == specialQuantity) {
            specialEmployeePrice += ((specialEmployeePrice * specialAugment) /
                100);

            specialCounter = 0;
        }

        if (specialEmployeePrice >= specialEmployeeMaxPrice) {
            specialEmployeePrice = specialEmployeeInitPrice;
        }
    }

    function mintPayedEmployee(bool package) public {
        require(payMint(msg.sender, package), INVALID_PAYMENT);
        if (package) packageMint();
        else normalMint();
    }

    function mintWithStakingPoints(bool package) public {
        uint256 pointsPrice = package
            ? (((minterPointsPrice * packageSize) / 100) *
                (100 - packageDiscount))
            : minterPointsPrice;

        factoryStaking.useMinterPoints(msg.sender, pointsPrice);

        if (package) packageMint();
        else normalMint();

        emit StakingMint(msg.sender, pointsPrice, package);
    }

    function upgradeEmployee(uint256 miniEmployee) public {
        require(miniEmployees.validate(miniEmployee), INVALID_EMPLOYEE);

        require(
            miniEmployees.ownerOf(miniEmployee) == msg.sender,
            INVALID_OWNER
        );

        require(
            miniEmployees.getXP(miniEmployee) >= getNecessaryXP(miniEmployee),
            INVALID_XP
        );

        uint8[4] memory parts = miniEmployees.getParts(miniEmployee);
        uint16 points = miniEmployees.getPoints(miniEmployee);

        employees.mint(
            parts[0],
            parts[1],
            parts[2],
            parts[3],
            points,
            msg.sender
        );

        miniEmployees.burn(miniEmployee);

        emit Upgrade(msg.sender, miniEmployee, points);
    }

    function mergeTwoEmployees(uint256 men, uint256 woman) public {
        require(
            employees.ownerOf(men) == msg.sender &&
                employees.ownerOf(woman) == msg.sender,
            INVALID_OWNER
        );

        require(
            employees.validate(men) && employees.validate(woman),
            INVALID_EMPLOYEE
        );

        require(employeeExpanded.canMerge(men), INVALID_MERGE);
        require(employeeExpanded.canMerge(woman), INVALID_MERGE);

        require(payMint(msg.sender, false), INVALID_PAYMENT);

        uint256 random = RandomUtil.randomSeededMinMax(
            0,
            99,
            randoms.getRandomSeed(msg.sender),
            miniEmployees.totalSupply()
        );

        uint8 employeeType = employees.getType(men);

        if (random < 50) employeeType = employees.getType(woman);

        uint8[] memory parts = baseDeployer.randomBuildTypes(3);

        miniEmployees.mint(
            employeeType,
            parts[0],
            parts[1],
            parts[2],
            0,
            baseDeployer.calcEmployeePoints(
                [employeeType, parts[0], parts[1], parts[2]]
            ),
            msg.sender
        );

        employeeExpanded.addMerge(men, 1);
        employeeExpanded.addMerge(woman, 1);

        emit Merge(msg.sender, men, woman);
    }
}