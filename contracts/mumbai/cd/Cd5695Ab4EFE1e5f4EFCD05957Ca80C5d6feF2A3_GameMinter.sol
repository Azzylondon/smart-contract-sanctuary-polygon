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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "../common/BaseWithStorage/ImmutableERC721.sol";
import "../common/BaseWithStorage/WithMinter.sol";
import "../common/interfaces/IAssetToken.sol";
import "../common/interfaces/IGameToken.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract GameBaseToken is ImmutableERC721, WithMinter, Initializable, IGameToken {
    ///////////////////////////////  Data //////////////////////////////

    IAssetToken internal _asset;

    bytes4 private constant ERC1155_RECEIVED = 0xf23a6e61;
    bytes4 private constant ERC1155_BATCH_RECEIVED = 0xbc197c81;

    mapping(uint256 => mapping(uint256 => uint256)) private _gameAssets;
    mapping(uint256 => address) private _creatorship; // creatorship transfer

    mapping(uint256 => bytes32) private _metaData;
    mapping(address => mapping(address => bool)) private _gameEditors;
    mapping(uint256 => uint256) internal _exactNumOfLandsRequired;
    ///////////////////////////////  Events //////////////////////////////

    /// @dev Emits when a game is updated.
    /// @param oldId The id of the previous erc721 GAME token.
    /// @param newId The id of the newly minted token.
    /// @param update The changes made to the Game: new assets, removed assets, uri

    event GameTokenUpdated(uint256 indexed oldId, uint256 indexed newId, IGameToken.GameData update);

    /// @dev Emits when creatorship of a GAME token is transferred.
    /// @param original The original creator of the GAME token.
    /// @param from The current 'creator' of the token.
    /// @param to The new 'creator' of the token.
    event CreatorshipTransfer(address indexed original, address indexed from, address indexed to);

    /// @dev Emits when an address has its gameEditor status changed.
    /// @param gameOwner The owner of the GAME token.
    /// @param gameEditor The address whose editor rights to update.
    /// @param isEditor WHether the address 'gameEditor' should be an editor.
    event GameEditorSet(address indexed gameOwner, address gameEditor, bool isEditor);

    function initV1(
        address trustedForwarder,
        address admin,
        IAssetToken asset,
        uint8 chainIndex
    ) public initializer() {
        _admin = admin;
        _asset = asset;
        ERC721BaseToken.__ERC721BaseToken_initialize(chainIndex);
        ERC2771Handler.__ERC2771Handler_initialize(trustedForwarder);
    }

    ///////////////////////////////  Modifiers //////////////////////////////

    modifier notToZero(address to) {
        require(to != address(0), "DESTINATION_ZERO_ADDRESS");
        _;
    }

    modifier notToThis(address to) {
        require(to != address(this), "DESTINATION_GAME_CONTRACT");
        _;
    }

    ///////////////////////////////  Functions //////////////////////////////

    /// @notice Create a new GAME token.
    /// @param from The address of the one creating the game (may be different from msg.sender if metaTx).
    /// @param to The address who will be assigned ownership of this game.
    /// @param creation The struct containing ids & ammounts of assets to add to this game,
    /// along with the uri to set.
    /// @param editor The address to allow to edit (can also be set later).
    /// @param subId A random id created on the backend.
    /// @return id The id of the new GAME token (erc721).
    function createGame(
        address from,
        address to,
        GameData calldata creation,
        address editor,
        uint64 subId
    ) external override onlyMinter() notToZero(to) notToThis(to) returns (uint256 id) {
        require(creation.exactNumOfLandsRequired > 0, "EXACT_NUM_OF_LANDS_REQUIRED_ZERO");
        (uint256 gameId, uint256 strgId) = _mintGame(from, to, subId, 0, true);

        if (editor != address(0)) {
            _setGameEditor(to, editor, true);
        }
        if (creation.assetIdsToAdd.length != 0) {
            _addAssets(from, strgId, creation.assetIdsToAdd, creation.assetAmountsToAdd);
        }

        _metaData[strgId] = creation.uri;
        _exactNumOfLandsRequired[strgId] = creation.exactNumOfLandsRequired;
        emit GameTokenUpdated(0, gameId, creation);
        return gameId;
    }

    /// @notice Update an existing GAME token.This actually burns old token
    /// and mints new token with same basId & incremented version.
    /// @param from The one updating the GAME token.
    /// @param gameId The current id of the GAME token.
    /// @param update The values to use for the update.
    /// @return The new gameId.
    function updateGame(
        address from,
        uint256 gameId,
        IGameToken.GameData memory update
    ) external override onlyMinter() returns (uint256) {
        require(update.exactNumOfLandsRequired > 0, "EXACT_NUM_OF_LANDS_REQUIRED_ZERO");
        uint256 id = _storageId(gameId);
        _addAssets(from, id, update.assetIdsToAdd, update.assetAmountsToAdd);
        _removeAssets(id, update.assetIdsToRemove, update.assetAmountsToRemove, _ownerOf(gameId));
        _metaData[id] = update.uri;
        _exactNumOfLandsRequired[id] = update.exactNumOfLandsRequired;
        uint256 newId = _bumpGameVersion(from, gameId);
        emit GameTokenUpdated(gameId, newId, update);
        return newId;
    }

    /// @notice Allow token owner to set game editors.
    /// @param gameOwner The address of a GAME token creator.
    /// @param editor The address of the editor to set.
    /// @param isEditor Add or remove the ability to edit.
    function setGameEditor(
        address gameOwner,
        address editor,
        bool isEditor
    ) external override {
        require(_msgSender() == gameOwner, "EDITOR_ACCESS_DENIED");
        _setGameEditor(gameOwner, editor, isEditor);
    }

    /// @notice Transfers creatorship of `original` from `sender` to `to`.
    /// @param gameId The current id of the GAME token.
    /// @param sender The address of current registered creator.
    /// @param to The address to transfer the creatorship to
    function transferCreatorship(
        uint256 gameId,
        address sender,
        address to
    ) external override notToZero(to) {
        require(_ownerOf(gameId) != address(0), "NONEXISTENT_TOKEN");
        uint256 id = _storageId(gameId);
        address msgSender = _msgSender();
        require(msgSender == sender || _superOperators[msgSender], "TRANSFER_ACCESS_DENIED");
        require(sender != address(0), "NOT_FROM_ZEROADDRESS");
        address originalCreator = address(uint160(id / CREATOR_OFFSET_MULTIPLIER));
        address current = creatorOf(gameId);
        require(current != to, "CURRENT_=_TO");
        require(current == sender, "CURRENT_!=_SENDER");
        _creatorship[id] = to;
        emit CreatorshipTransfer(originalCreator, current, to);
    }

    /// @notice Burn a GAME token and recover assets.
    /// @param from The address of the one destroying the game.
    /// @param to The address to send all GAME assets to.
    /// @param gameId The id of the GAME to destroy.
    /// @param assetIds The assets to recover from the burnt GAME.
    function burnAndRecover(
        address from,
        address to,
        uint256 gameId,
        uint256[] calldata assetIds
    ) external override {
        _burnGame(from, gameId);
        _recoverAssets(from, to, gameId, assetIds);
    }

    /// @notice Burn a GAME token.
    /// @param gameId The id of the GAME to destroy.
    function burn(uint256 gameId) external override(ERC721BaseToken, IGameToken) {
        _burnGame(_msgSender(), gameId);
    }

    /// @notice Burn a GAME token on behalf of owner.
    /// @param from The address whose GAME is being burnt.
    /// @param gameId The id of the GAME to burn.
    function burnFrom(address from, uint256 gameId) external override(ERC721BaseToken, IGameToken) {
        require(from != address(0), "NOT_FROM_ZEROADDRESS");
        _burnGame(from, gameId);
    }

    /// @notice Transfer assets from a burnt GAME.
    /// @param from Previous owner of the burnt game.
    /// @param to Address that will receive the assets.
    /// @param gameId Id of the burnt GAME token.
    /// @param assetIds The assets to recover from the burnt GAME.
    function recoverAssets(
        address from,
        address to,
        uint256 gameId,
        uint256[] memory assetIds
    ) public override {
        _recoverAssets(from, to, gameId, assetIds);
    }

    /// @notice Get the amount of each assetId in a GAME.
    /// @param gameId The game to query.
    /// @param assetIds The assets to get balances for.
    function getAssetBalances(uint256 gameId, uint256[] calldata assetIds)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256 storageId = _storageId(gameId);
        require(_ownerOf(gameId) != address(0), "NONEXISTENT_TOKEN");
        uint256 length = assetIds.length;
        uint256[] memory assets;
        assets = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            assets[i] = _gameAssets[storageId][assetIds[i]];
        }
        return assets;
    }

    function getExactNumOfLandsRequired(uint256 gameId) external view override returns (uint256) {
        uint256 storageId = _storageId(gameId);
        return _exactNumOfLandsRequired[storageId];
    }

    /// @notice Get game editor status.
    /// @param gameOwner The address of the owner of the GAME.
    /// @param editor The address of the editor to set.
    /// @return isEditor Editor status of editor for given tokenId.
    function isGameEditor(address gameOwner, address editor) external view override returns (bool isEditor) {
        return _gameEditors[gameOwner][editor];
    }

    /// @notice Called by other contracts to check if this can receive erc1155 batch.
    /// @param operator The address of the operator in the current tx.
    /// @return the bytes4 value 0xbc197c81.
    function onERC1155BatchReceived(
        address operator,
        address, /*from*/
        uint256[] calldata, /*ids*/
        uint256[] calldata, /*values*/
        bytes calldata /*data*/
    ) external view override returns (bytes4) {
        if (operator == address(this)) {
            return ERC1155_BATCH_RECEIVED;
        }
        revert("ERC1155_BATCH_REJECTED");
    }

    /// @notice Called by other contracts to check if this can receive erc1155 tokens.
    /// @param operator The address of the operator in the current tx.
    /// @return the bytes4 value 0xf23a6e61.
    function onERC1155Received(
        address operator,
        address, /*from*/
        uint256, /*id*/
        uint256, /*value*/
        bytes calldata /*data*/
    ) external view override returns (bytes4) {
        if (operator == address(this)) {
            return ERC1155_RECEIVED;
        }
        revert("ERC1155_REJECTED");
    }

    /// @notice Return the name of the token contract.
    /// @return The name of the token contract.
    function name() external pure override returns (string memory) {
        return "The Sandbox: GAME token";
    }

    /// @notice Get the symbol of the token contract.
    /// @return the symbol of the token contract.
    function symbol() external pure override returns (string memory) {
        return "GAME";
    }

    /// @notice Get the creator of the token type `id`.
    /// @param gameId The id of the token to get the creator of.
    /// @return the creator of the token type `id`.
    function creatorOf(uint256 gameId) public view override returns (address) {
        require(gameId != uint256(0), "GAME_NEVER_MINTED");
        uint256 id = _storageId(gameId);
        address originalCreator = address(uint160(id / CREATOR_OFFSET_MULTIPLIER));
        address newCreator = _creatorship[id];
        if (newCreator != address(0)) {
            return newCreator;
        }
        return originalCreator;
    }

    /// @notice Return the URI of a specific token.
    /// @param gameId The id of the token.
    /// @return uri The URI of the token metadata.
    function tokenURI(uint256 gameId) public view override returns (string memory uri) {
        require(_ownerOf(gameId) != address(0), "BURNED_OR_NEVER_MINTED");
        uint256 id = _storageId(gameId);
        return _toFullURI(_metaData[id]);
    }

    /// @notice Check if the contract supports an interface.
    /// 0x01ffc9a7 is ERC-165.
    /// 0x80ac58cd is ERC-721.
    /// @param id The id of the interface.
    /// @return if the interface is supported.
    function supportsInterface(bytes4 id) public pure override returns (bool) {
        return id == 0x01ffc9a7 || id == 0x80ac58cd || id == 0x5b5e139f;
    }

    /// @notice Add assets to an existing GAME.
    /// @param from The address of the current owner of assets.
    /// @param strgId The storageId of the GAME to add assets to.
    /// @param assetIds The id of the asset to add to GAME.
    /// @param amounts The amount of each asset to add to GAME.
    function _addAssets(
        address from,
        uint256 strgId,
        uint256[] memory assetIds,
        uint256[] memory amounts
    ) internal {
        if (assetIds.length == 0) {
            return;
        }
        require(assetIds.length == amounts.length, "INVALID_INPUT_LENGTHS");
        uint256 currentValue;
        for (uint256 i = 0; i < assetIds.length; i++) {
            currentValue = _gameAssets[strgId][assetIds[i]];
            require(amounts[i] != 0, "INVALID_ASSET_ADDITION");
            _gameAssets[strgId][assetIds[i]] = currentValue + amounts[i];
        }
        if (assetIds.length == 1) {
            _asset.safeTransferFrom(from, address(this), assetIds[0], amounts[0], "");
        } else {
            _asset.safeBatchTransferFrom(from, address(this), assetIds, amounts, "");
        }
    }

    /// @notice Remove assets from a GAME.
    /// @param id The storageId of the GAME to remove assets from.
    /// @param assetIds An array of asset Ids to remove.
    /// @param values An array of the number of each asset id to remove.
    /// @param to The address to send removed assets to.
    function _removeAssets(
        uint256 id,
        uint256[] memory assetIds,
        uint256[] memory values,
        address to
    ) internal {
        if (assetIds.length == 0) {
            return;
        }
        require(assetIds.length == values.length && assetIds.length != 0, "INVALID_INPUT_LENGTHS");
        uint256 currentValue;
        for (uint256 i = 0; i < assetIds.length; i++) {
            currentValue = _gameAssets[id][assetIds[i]];
            require(currentValue != 0 && values[i] != 0 && values[i] <= currentValue, "INVALID_ASSET_REMOVAL");
            _gameAssets[id][assetIds[i]] = currentValue - values[i];
        }

        if (assetIds.length == 1) {
            _asset.safeTransferFrom(address(this), to, assetIds[0], values[0], "");
        } else {
            _asset.safeBatchTransferFrom(address(this), to, assetIds, values, "");
        }
    }

    /// @dev See burn / burnFrom.
    function _burnGame(address from, uint256 gameId) internal {
        uint256 storageId = _storageId(gameId);
        (address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(storageId);
        address msgSender = _msgSender();
        require(
            msgSender == owner ||
                (operatorEnabled && _operators[storageId] == msgSender) ||
                _superOperators[msgSender] ||
                _operatorsForAll[from][msgSender],
            "UNAUTHORIZED_BURN"
        );

        delete _metaData[storageId];
        delete _exactNumOfLandsRequired[storageId];
        _creatorship[gameId] = address(0);
        _burn(from, owner, gameId);
    }

    /// @dev See recoverAssets.
    function _recoverAssets(
        address from,
        address to,
        uint256 gameId,
        uint256[] memory assetIds
    ) internal notToZero(to) notToThis(to) {
        require(_ownerOf(gameId) == address(0), "ONLY_FROM_BURNED_TOKEN");
        uint256 storageId = _storageId(gameId);
        require(from == _msgSender(), "INVALID_RECOVERY");
        _check_withdrawal_authorized(from, gameId);
        require(assetIds.length > 0, "WITHDRAWAL_COMPLETE");
        uint256[] memory values;
        values = new uint256[](assetIds.length);
        for (uint256 i = 0; i < assetIds.length; i++) {
            values[i] = _gameAssets[storageId][assetIds[i]];
            delete _gameAssets[storageId][assetIds[i]];
        }
        _asset.safeBatchTransferFrom(address(this), to, assetIds, values, "");

        GameData memory recovery;
        recovery.assetIdsToRemove = assetIds;
        recovery.assetAmountsToRemove = values;
        emit GameTokenUpdated(gameId, 0, recovery);
    }

    /// @dev Create a new gameId and associate it with an owner.
    /// @param from The address of one creating the game.
    /// @param to The address of the Game owner.
    /// @param subId The id to use when generating the new GameId.
    /// @param version The version number part of the gameId.
    /// @param isCreation Whether this is a brand new GAME (as opposed to an update).
    /// @return id The newly created gameId.
    function _mintGame(
        address from,
        address to,
        uint64 subId,
        uint16 version,
        bool isCreation
    ) internal returns (uint256 id, uint256 storageId) {
        uint16 idVersion;
        uint256 gameId;
        uint256 strgId;
        if (isCreation) {
            idVersion = 1;
            gameId = _generateTokenId(from, subId, _chainIndex, idVersion);
            strgId = _storageId(gameId);
            require(_owners[strgId] == 0, "STORAGE_ID_REUSE_FORBIDDEN");
        } else {
            idVersion = version;
            gameId = _generateTokenId(from, subId, _chainIndex, idVersion);
            strgId = _storageId(gameId);
        }

        _owners[strgId] = (uint256(idVersion) << 200) + uint256(uint160(to));
        _numNFTPerAddress[to]++;
        emit Transfer(address(0), to, gameId);
        return (gameId, strgId);
    }

    /// @dev Allow token owner to set game editors.
    /// @param gameCreator The address of a GAME creator,
    /// @param editor The address of the editor to set.
    /// @param isEditor Add or remove the ability to edit.
    function _setGameEditor(
        address gameCreator,
        address editor,
        bool isEditor
    ) internal {
        emit GameEditorSet(gameCreator, editor, isEditor);
        _gameEditors[gameCreator][editor] = isEditor;
    }

    /// @dev Bumps the version number of a game token, buring the previous
    /// version and minting a new one.
    /// @param from The address of the GAME token owner.
    /// @param gameId The Game token to bump the version of.
    /// @return The new gameId.
    function _bumpGameVersion(address from, uint256 gameId) internal returns (uint256) {
        address originalCreator = address(uint160(gameId / CREATOR_OFFSET_MULTIPLIER));
        uint64 subId = uint64(gameId / SUBID_MULTIPLIER);
        uint16 version = uint16(gameId);
        version++;
        address owner = _ownerOf(gameId);
        if (from == owner) {
            // caller is owner or metaTx on owner's behalf
            _burn(from, owner, gameId);
        } else if (_gameEditors[owner][from]) {
            // caller is editor or metaTx on editor's behalf, so we need to pass owner
            // instead of from or _burn will fail
            _burn(owner, owner, gameId);
        }
        (uint256 newId, ) = _mintGame(originalCreator, owner, subId, version, false);
        address newOwner = _ownerOf(newId);
        assert(owner == newOwner);
        return newId;
    }

    /// @dev Get the a full URI string for a given hash + gameId.
    /// @param hash The 32 byte IPFS hash.
    /// @return The URI string.
    function _toFullURI(bytes32 hash) internal pure override returns (string memory) {
        return string(abi.encodePacked("ipfs://bafybei", hash2base32(hash), "/", "game.json"));
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

import "./GameBaseToken.sol";
import "../common/interfaces/IGameMinter.sol";
import "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";
import "../common/BaseWithStorage/ERC2771Handler.sol";

contract GameMinter is ERC2771Handler, IGameMinter {
    ///////////////////////////////  Data //////////////////////////////

    GameBaseToken internal immutable _gameToken;
    // @todo confirm actual fees
    uint256 internal immutable _gameMintingFee;
    uint256 internal immutable _gameUpdateFee;
    address internal immutable _feeBeneficiary;
    IERC20 internal immutable _sand;

    ///////////////////////////////  Functions /////////////////////////

    constructor(
        GameBaseToken gameTokenContract,
        address trustedForwarder,
        uint256 gameMintingFee,
        uint256 gameUpdateFee,
        address feeBeneficiary,
        IERC20 sand
    ) {
        _gameToken = gameTokenContract;
        _gameMintingFee = gameMintingFee;
        _gameUpdateFee = gameUpdateFee;
        _feeBeneficiary = feeBeneficiary;
        _sand = sand;
        ERC2771Handler.__ERC2771Handler_initialize(trustedForwarder);
    }

    /// @notice Function to create a new GAME token
    /// @param to The address who will be assigned ownership of this game.
    /// @param creation The struct containing ids & ammounts of assets to add to this game,
    /// along with the uri to set.
    /// @param editor The address to allow to edit (can also be set later).
    /// @param subId A random id created on the backend.
    /// @return gameId The id of the new GAME token (erc721)
    function createGame(
        address to,
        GameBaseToken.GameData calldata creation,
        address editor,
        uint64 subId
    ) external override returns (uint256 gameId) {
        address msgSender = _msgSender();
        _chargeSand(msgSender, _gameMintingFee);
        return _gameToken.createGame(msgSender, to, creation, editor, subId);
    }

    /// @notice Update an existing GAME token.This actually burns old token
    /// and mints new token with same basId & incremented version.
    /// @param gameId The current id of the GAME token.
    /// @param update The values to use for the update.
    /// @return newId The new gameId.
    function updateGame(uint256 gameId, GameBaseToken.GameData memory update)
        external
        override
        returns (uint256 newId)
    {
        address gameOwner = _gameToken.ownerOf(gameId);
        address msgSender = _msgSender();
        require(msgSender == gameOwner || _gameToken.isGameEditor(gameOwner, msgSender), "AUTH_ACCESS_DENIED");
        _chargeSand(msgSender, _gameUpdateFee);
        return _gameToken.updateGame(msgSender, gameId, update);
    }

    /// @dev Charge a fee in Sand if conditions are met.
    /// @param from The address responsible for paying the fee.
    /// @param sandFee The fee that applies to the current operation (create || update).
    function _chargeSand(address from, uint256 sandFee) internal {
        if (_feeBeneficiary != address(0) && sandFee != 0) {
            _sand.transferFrom(from, _feeBeneficiary, sandFee);
        }
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/// @dev minimal ERC2771 handler to keep bytecode-size down.
/// based on: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/metatx/ERC2771Context.sol

contract ERC2771Handler {
    address internal _trustedForwarder;

    function __ERC2771Handler_initialize(address forwarder) internal {
        _trustedForwarder = forwarder;
    }

    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function getTrustedForwarder() external view returns (address trustedForwarder) {
        return _trustedForwarder;
    }

    function _msgSender() internal view virtual returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}

//SPDX-License-Identifier: MIT
/* solhint-disable func-order, code-complexity */
pragma solidity 0.8.2;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "./WithSuperOperators.sol";
import "../interfaces/IERC721MandatoryTokenReceiver.sol";
import "./ERC2771Handler.sol";

contract ERC721BaseToken is IERC721Upgradeable, WithSuperOperators, ERC2771Handler {
    using AddressUpgradeable for address;

    bytes4 internal constant _ERC721_RECEIVED = 0x150b7a02;
    bytes4 internal constant _ERC721_BATCH_RECEIVED = 0x4b808c46;

    bytes4 internal constant ERC165ID = 0x01ffc9a7;
    bytes4 internal constant ERC721_MANDATORY_RECEIVER = 0x5e8bf644;

    uint256 internal constant NOT_ADDRESS = 0xFFFFFFFFFFFFFFFFFFFFFFFF0000000000000000000000000000000000000000;
    uint256 internal constant OPERATOR_FLAG = (2**255);
    uint256 internal constant NOT_OPERATOR_FLAG = OPERATOR_FLAG - 1;
    uint256 internal constant BURNED_FLAG = (2**160);

    mapping(address => uint256) internal _numNFTPerAddress;
    mapping(uint256 => uint256) internal _owners;
    mapping(address => mapping(address => bool)) internal _operatorsForAll;
    mapping(uint256 => address) internal _operators;
    uint8 internal _chainIndex;

    function __ERC721BaseToken_initialize(uint8 chainIndex) internal {
        _chainIndex = chainIndex;
    }

    /// @notice Approve an operator to spend tokens on the senders behalf.
    /// @param operator The address receiving the approval.
    /// @param id The id of the token.
    function approve(address operator, uint256 id) external override {
        uint256 ownerData = _owners[_storageId(id)];
        address owner = _ownerOf(id);
        address msgSender = _msgSender();
        require(owner != address(0), "NONEXISTENT_TOKEN");
        require(
            owner == msgSender || _superOperators[msgSender] || _operatorsForAll[owner][msgSender],
            "UNAUTHORIZED_APPROVAL"
        );
        _approveFor(ownerData, operator, id);
    }

    /// @notice Approve an operator to spend tokens on the sender behalf.
    /// @param sender The address giving the approval.
    /// @param operator The address receiving the approval.
    /// @param id The id of the token.
    function approveFor(
        address sender,
        address operator,
        uint256 id
    ) external {
        uint256 ownerData = _owners[_storageId(id)];
        address msgSender = _msgSender();
        require(sender != address(0), "ZERO_ADDRESS_SENDER");
        require(
            msgSender == sender || _superOperators[msgSender] || _operatorsForAll[sender][msgSender],
            "UNAUTHORIZED_APPROVAL"
        );
        require(address(uint160(ownerData)) == sender, "OWNER_NOT_SENDER");
        _approveFor(ownerData, operator, id);
    }

    /// @notice Transfer a token between 2 addresses.
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    /// @param id The id of the token.
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) external override {
        _checkTransfer(from, to, id);
        _transferFrom(from, to, id);
        if (to.isContract() && _checkInterfaceWith10000Gas(to, ERC721_MANDATORY_RECEIVER)) {
            require(_checkOnERC721Received(_msgSender(), from, to, id, ""), "ERC721_TRANSFER_REJECTED");
        }
    }

    /// @notice Transfer a token between 2 addresses letting the receiver know of the transfer.
    /// @param from The send of the token.
    /// @param to The recipient of the token.
    /// @param id The id of the token.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) external override {
        safeTransferFrom(from, to, id, "");
    }

    /// @notice Transfer many tokens between 2 addresses.
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    /// @param ids The ids of the tokens.
    /// @param data Additional data.
    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        bytes calldata data
    ) external {
        _batchTransferFrom(from, to, ids, data, false);
    }

    /// @notice Transfer many tokens between 2 addresses, while
    /// ensuring the receiving contract has a receiver method.
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    /// @param ids The ids of the tokens.
    /// @param data Additional data.
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        bytes calldata data
    ) external {
        _batchTransferFrom(from, to, ids, data, true);
    }

    /// @notice Set the approval for an operator to manage all the tokens of the sender.
    /// @param sender The address giving the approval.
    /// @param operator The address receiving the approval.
    /// @param approved The determination of the approval.
    function setApprovalForAllFor(
        address sender,
        address operator,
        bool approved
    ) external {
        require(sender != address(0), "Invalid sender address");
        address msgSender = _msgSender();
        require(msgSender == sender || _superOperators[msgSender], "UNAUTHORIZED_APPROVE_FOR_ALL");

        _setApprovalForAll(sender, operator, approved);
    }

    /// @notice Set the approval for an operator to manage all the tokens of the sender.
    /// @param operator The address receiving the approval.
    /// @param approved The determination of the approval.
    function setApprovalForAll(address operator, bool approved) external override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /// @notice Burns token `id`.
    /// @param id The token which will be burnt.
    function burn(uint256 id) external virtual {
        _burn(_msgSender(), _ownerOf(id), id);
    }

    /// @notice Burn token`id` from `from`.
    /// @param from address whose token is to be burnt.
    /// @param id The token which will be burnt.
    function burnFrom(address from, uint256 id) external virtual {
        require(from != address(0), "NOT_FROM_ZEROADDRESS");
        (address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(id);
        address msgSender = _msgSender();
        require(
            msgSender == from ||
                (operatorEnabled && _operators[id] == msgSender) ||
                _superOperators[msgSender] ||
                _operatorsForAll[from][msgSender],
            "UNAUTHORIZED_BURN"
        );
        _burn(from, owner, id);
    }

    /// @notice Get the number of tokens owned by an address.
    /// @param owner The address to look for.
    /// @return The number of tokens owned by the address.
    function balanceOf(address owner) external view override returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS_OWNER");
        return _numNFTPerAddress[owner];
    }

    /// @notice Get the owner of a token.
    /// @param id The id of the token.
    /// @return owner The address of the token owner.
    function ownerOf(uint256 id) external view override returns (address owner) {
        owner = _ownerOf(id);
        require(owner != address(0), "NONEXISTANT_TOKEN");
    }

    /// @notice Get the approved operator for a specific token.
    /// @param id The id of the token.
    /// @return The address of the operator.
    function getApproved(uint256 id) external view override returns (address) {
        (address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(id);
        require(owner != address(0), "NONEXISTENT_TOKEN");
        if (operatorEnabled) {
            return _operators[id];
        } else {
            return address(0);
        }
    }

    /// @notice Check if the sender approved the operator.
    /// @param owner The address of the owner.
    /// @param operator The address of the operator.
    /// @return isOperator The status of the approval.
    function isApprovedForAll(address owner, address operator) external view override returns (bool isOperator) {
        return _operatorsForAll[owner][operator] || _superOperators[operator];
    }

    /// @notice Transfer a token between 2 addresses letting the receiver knows of the transfer.
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    /// @param id The id of the token.
    /// @param data Additional data.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public override {
        _checkTransfer(from, to, id);
        _transferFrom(from, to, id);
        if (to.isContract()) {
            require(_checkOnERC721Received(_msgSender(), from, to, id, data), "ERC721_TRANSFER_REJECTED");
        }
    }

    /// @notice Check if the contract supports an interface.
    /// 0x01ffc9a7 is ERC-165.
    /// 0x80ac58cd is ERC-721
    /// @param id The id of the interface.
    /// @return Whether the interface is supported.
    function supportsInterface(bytes4 id) public pure virtual override returns (bool) {
        return id == 0x01ffc9a7 || id == 0x80ac58cd;
    }

    function isBurned(uint256 estateId) public view returns (bool) {
        uint256 storageId = _storageId(estateId);
        return (_owners[storageId] & BURNED_FLAG) == BURNED_FLAG;
    }

    /// @dev By overriding this function in an implementation which inherits this contract, you can enable versioned tokenIds without the extra overhead of writing to a new storage slot in _owners each time a version is incremented. See GameToken._storageId() for an example, where the storageId is the tokenId minus the version number.
    /// !!! Caution !!! Overriding this function without taking appropriate care could lead to
    /// ownerOf() returning an owner for non-existent tokens. Tests should be written to
    /// guard against introducing this bug.
    /// @param id The id of a token.
    /// @return The id used for storage mappings.
    function _storageId(uint256 id) internal view virtual returns (uint256) {
        return id;
    }

    function _updateOwnerData(
        uint256 id,
        uint256 oldData,
        address newOwner,
        bool hasOperator
    ) internal virtual {
        if (hasOperator) {
            _owners[_storageId(id)] = (oldData & NOT_ADDRESS) | OPERATOR_FLAG | uint256(uint160(newOwner));
        } else {
            _owners[_storageId(id)] = ((oldData & NOT_ADDRESS) & NOT_OPERATOR_FLAG) | uint256(uint160(newOwner));
        }
    }

    function _transferFrom(
        address from,
        address to,
        uint256 id
    ) internal {
        _numNFTPerAddress[from]--;
        _numNFTPerAddress[to]++;
        _updateOwnerData(id, _owners[_storageId(id)], to, false);
        emit Transfer(from, to, id);
    }

    /// @dev See approveFor.
    function _approveFor(
        uint256 ownerData,
        address operator,
        uint256 id
    ) internal {
        address owner = _ownerOf(id);
        if (operator == address(0)) {
            _updateOwnerData(id, ownerData, owner, false);
        } else {
            _updateOwnerData(id, ownerData, owner, true);
            _operators[id] = operator;
        }
        emit Approval(owner, operator, id);
    }

    /// @dev See batchTransferFrom.
    function _batchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        bytes memory data,
        bool safe
    ) internal {
        address msgSender = _msgSender();
        bool authorized = msgSender == from || _superOperators[msgSender] || _operatorsForAll[from][msgSender];

        require(from != address(0), "NOT_FROM_ZEROADDRESS");
        require(to != address(0), "NOT_TO_ZEROADDRESS");

        uint256 numTokens = ids.length;
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            if (id == 0) {
                numTokens--;
                continue;
            }
            (address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(id);
            require(owner == from, "BATCHTRANSFERFROM_NOT_OWNER");
            require(authorized || (operatorEnabled && _operators[id] == msgSender), "NOT_AUTHORIZED");
            _updateOwnerData(id, _owners[_storageId(id)], to, false);
            emit Transfer(from, to, id);
        }
        if (from != to) {
            _numNFTPerAddress[from] -= numTokens;
            _numNFTPerAddress[to] += numTokens;
        }
        if (to.isContract() && (safe || _checkInterfaceWith10000Gas(to, ERC721_MANDATORY_RECEIVER))) {
            require(_checkOnERC721BatchReceived(msgSender, from, to, ids, data), "ERC721_BATCH_TRANSFER_REJECTED");
        }
    }

    /// @dev See setApprovalForAll.
    function _setApprovalForAll(
        address sender,
        address operator,
        bool approved
    ) internal {
        require(!_superOperators[operator], "INVALID_APPROVAL_CHANGE");
        _operatorsForAll[sender][operator] = approved;

        emit ApprovalForAll(sender, operator, approved);
    }

    /// @dev See burn.
    function _burn(
        address from,
        address owner,
        uint256 id
    ) internal {
        require(from == owner, "NOT_OWNER");
        uint256 storageId = _storageId(id);
        _owners[storageId] = (_owners[storageId] & NOT_OPERATOR_FLAG) | BURNED_FLAG; // record as non owner but keep track of last owner
        _numNFTPerAddress[from]--;
        emit Transfer(from, address(0), id);
    }

    /// @dev Check if receiving contract accepts erc721 transfers.
    /// @param operator The address of the operator.
    /// @param from The from address, may be different from msg.sender.
    /// @param to The adddress we want to transfer to.
    /// @param tokenId The id of the token we would like to transfer.
    /// @param _data Any additional data to send with the transfer.
    /// @return Whether the expected value of 0x150b7a02 is returned.
    function _checkOnERC721Received(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal returns (bool) {
        bytes4 retval = IERC721ReceiverUpgradeable(to).onERC721Received(operator, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    /// @dev Check if receiving contract accepts erc721 batch transfers.
    /// @param operator The address of the operator.
    /// @param from The from address, may be different from msg.sender.
    /// @param to The adddress we want to transfer to.
    /// @param ids The ids of the tokens we would like to transfer.
    /// @param _data Any additional data to send with the transfer.
    /// @return Whether the expected value of 0x4b808c46 is returned.
    function _checkOnERC721BatchReceived(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        bytes memory _data
    ) internal returns (bool) {
        bytes4 retval = IERC721MandatoryTokenReceiver(to).onERC721BatchReceived(operator, from, ids, _data);
        return (retval == _ERC721_BATCH_RECEIVED);
    }

    /// @dev See ownerOf
    function _ownerOf(uint256 id) internal view virtual returns (address) {
        uint256 data = _owners[_storageId(id)];
        if ((data & BURNED_FLAG) == BURNED_FLAG) {
            return address(0);
        }
        return address(uint160(data));
    }

    /// @dev Get the owner and operatorEnabled status of a token.
    /// @param id The token to query.
    /// @return owner The owner of the token.
    /// @return operatorEnabled Whether or not operators are enabled for this token.
    function _ownerAndOperatorEnabledOf(uint256 id)
        internal
        view
        virtual
        returns (address owner, bool operatorEnabled)
    {
        uint256 data = _owners[_storageId(id)];
        if ((data & BURNED_FLAG) == BURNED_FLAG) {
            owner = address(0);
        } else {
            owner = address(uint160(data));
        }
        operatorEnabled = (data & OPERATOR_FLAG) == OPERATOR_FLAG;
    }

    /// @dev Check whether a transfer is a meta Transaction or not.
    /// @param from The address who initiated the transfer (may differ from msg.sender).
    /// @param to The address recieving the token.
    /// @param id The token being transferred.
    /// @return isMetaTx Whether or not the transaction is a MetaTx.
    function _checkTransfer(
        address from,
        address to,
        uint256 id
    ) internal view returns (bool isMetaTx) {
        (address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(id);
        address msgSender = _msgSender();
        require(owner != address(0), "NONEXISTENT_TOKEN");
        require(owner == from, "CHECKTRANSFER_NOT_OWNER");
        require(to != address(0), "NOT_TO_ZEROADDRESS");
        require(
            msgSender == owner ||
                _superOperators[msgSender] ||
                _operatorsForAll[from][msgSender] ||
                (operatorEnabled && _operators[id] == msgSender),
            "UNAUTHORIZED_TRANSFER"
        );
        return true;
    }

    /// @dev Check if there was enough gas.
    /// @param _contract The address of the contract to check.
    /// @param interfaceId The id of the interface we want to test.
    /// @return Whether or not this check succeeded.
    function _checkInterfaceWith10000Gas(address _contract, bytes4 interfaceId) internal view returns (bool) {
        bool success;
        bool result;
        bytes memory callData = abi.encodeWithSelector(ERC165ID, interfaceId);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let call_ptr := add(0x20, callData)
            let call_size := mload(callData)
            let output := mload(0x40) // Find empty storage location using "free memory pointer"
            mstore(output, 0x0)
            success := staticcall(10000, _contract, call_ptr, call_size, output, 0x20) // 32 bytes
            result := mload(output)
        }
        // (10000 / 63) "not enough for supportsInterface(...)" // consume all gas, so caller can potentially know that there was not enough gas
        assert(gasleft() > 158);
        return success && result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseWithStorage/ERC721BaseToken.sol";

contract ImmutableERC721 is ERC721BaseToken {
    uint256 internal constant CREATOR_OFFSET_MULTIPLIER = uint256(2)**(256 - 160);
    uint256 internal constant SUBID_MULTIPLIER = uint256(2)**(256 - 224);
    uint256 internal constant CHAIN_INDEX_OFFSET_MULTIPLIER = uint256(2)**(256 - 160 - 64 - 16);
    uint256 internal constant STORAGE_ID_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000;
    uint256 internal constant VERSION_MASK = 0x000000FFFFFFFF00000000000000000000000000000000000000000000000000;

    bytes32 internal constant base32Alphabet = 0x6162636465666768696A6B6C6D6E6F707172737475767778797A323334353637;

    /// @dev An implementation which handles versioned tokenIds.
    /// @param id The tokenId to get the owner of.
    /// @return The address of the owner.
    function _ownerOf(uint256 id) internal view virtual override returns (address) {
        uint256 packedData = _owners[_storageId(id)];
        uint16 idVersion = uint16(id);
        uint16 storageVersion = uint16((packedData & VERSION_MASK) >> 200);

        if (((packedData & BURNED_FLAG) == BURNED_FLAG) || idVersion != storageVersion) {
            return address(0); //should be here
        }

        return address(uint160(packedData));
    }

    /// @dev Check if a withdrawal is allowed.
    /// @param from The address requesting the withdrawal.
    /// @param tokenId The id of the token to withdraw assets from.
    function _check_withdrawal_authorized(address from, uint256 tokenId) internal view virtual {
        require(from != address(uint160(0)), "SENDER_ZERO_ADDRESS");
        require(from == _withdrawalOwnerOf(tokenId), "LAST_OWNER_NOT_EQUAL_SENDER");
    }

    /// @dev Get the address allowed to withdraw associated tokens from the parent token.
    /// If too many associated tokens in TOKEN, block.gaslimit won't allow detroy and withdraw in 1 tx.
    /// An owner may destroy their token, then withdraw associated tokens in a later tx (even
    /// though ownerOf(id) would be address(0) after burning.)
    /// @param id The id of the token to query.
    /// @return the address of the owner before burning.
    function _withdrawalOwnerOf(uint256 id) internal view virtual returns (address) {
        uint256 packedData = _owners[_storageId(id)];
        return address(uint160(packedData));
    }

    /// @notice Get the storageID (no chainIndex or version data), which is constant for a given token.
    /// @param tokenId The tokenId for which to find the first token Id.
    /// @return The storage id for this token.
    function getStorageId(uint256 tokenId) external pure virtual returns (uint256) {
        return _storageId(tokenId);
    }

    /// @dev Get the storageId (full id without the version number) from the full tokenId.
    /// @param id The full tokenId for the GAME token.
    /// @return The storageId.
    function _storageId(uint256 id) internal pure virtual override returns (uint256) {
        return uint256(id & STORAGE_ID_MASK);
    }

    /// @dev Get the a full URI string for a given hash + gameId.
    /// @param hash The 32 byte IPFS hash.
    /// @return The URI string.
    function _toFullURI(bytes32 hash) internal pure virtual returns (string memory) {
        return string(abi.encodePacked("ipfs://bafybei", hash2base32(hash), "/", "token.json"));
    }

    /// @dev Create a new tokenId and associate it with an owner.
    /// This is a packed id, consisting of 4 parts:
    /// the creator's address, a uint64 subId, a uint18 chainIndex and a uint16 version.
    /// @param creator The address of the Token creator.
    /// @param subId The id used to generate the id.
    /// @param version The publicversion used to generate the id.
    function _generateTokenId(
        address creator,
        uint64 subId,
        uint8 chainIndex,
        uint16 version
    ) internal pure returns (uint256) {
        return
            uint256(uint160(creator)) *
            CREATOR_OFFSET_MULTIPLIER +
            uint64(subId) *
            SUBID_MULTIPLIER +
            chainIndex *
            CHAIN_INDEX_OFFSET_MULTIPLIER +
            uint16(version);
    }

    /// @dev Convert a 32 byte hash to a base 32 string.
    /// @param hash A 32 byte (IPFS) hash.
    /// @return _uintAsString The hash as a base 32 string.
    // solhint-disable-next-line security/no-assign-params
    function hash2base32(bytes32 hash) internal pure returns (string memory _uintAsString) {
        uint256 _i = uint256(hash);
        uint256 k = 52;
        bytes memory bstr = new bytes(k);
        bstr[--k] = base32Alphabet[uint8((_i % 8) << 2)]; // uint8 s = uint8((256 - skip) % 5);  // (_i % (2**s)) << (5-s)
        _i /= 8;
        while (k > 0) {
            bstr[--k] = base32Alphabet[_i % 32];
            _i /= 32;
        }
        return string(bstr);
    }
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

contract WithAdmin {
    address internal _admin;

    /// @dev Emits when the contract administrator is changed.
    /// @param oldAdmin The address of the previous administrator.
    /// @param newAdmin The address of the new administrator.
    event AdminChanged(address oldAdmin, address newAdmin);

    modifier onlyAdmin() {
        require(msg.sender == _admin, "ADMIN_ONLY");
        _;
    }

    /// @dev Get the current administrator of this contract.
    /// @return The current administrator of this contract.
    function getAdmin() external view returns (address) {
        return _admin;
    }

    /// @dev Change the administrator to be `newAdmin`.
    /// @param newAdmin The address of the new administrator.
    function changeAdmin(address newAdmin) external {
        require(msg.sender == _admin, "ADMIN_ACCESS_DENIED");
        emit AdminChanged(_admin, newAdmin);
        _admin = newAdmin;
    }
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

import "./WithAdmin.sol";

contract WithMinter is WithAdmin {
    address internal _minter;

    /// @dev Emits when the Minter address is changed
    /// @param oldMinter The previous Minter address
    /// @param newMinter The new Minter address
    event MinterChanged(address oldMinter, address newMinter);

    modifier onlyMinter() {
        require(msg.sender == _minter, "MINTER_ACCESS_DENIED");
        _;
    }

    /// @dev Get the current minter of this contract.
    /// @return The current minter of this contract.
    function getMinter() external view returns (address) {
        return _minter;
    }

    /// @dev Change the minter to be `newMinter`.
    /// @param newMinter The address of the new minter.
    function changeMinter(address newMinter) external onlyAdmin() {
        emit MinterChanged(_minter, newMinter);
        _minter = newMinter;
    }
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

import "./WithAdmin.sol";

contract WithSuperOperators is WithAdmin {
    mapping(address => bool) internal _superOperators;

    event SuperOperator(address superOperator, bool enabled);

    /// @notice Enable or disable the ability of `superOperator` to transfer tokens of all (superOperator rights).
    /// @param superOperator address that will be given/removed superOperator right.
    /// @param enabled set whether the superOperator is enabled or disabled.
    function setSuperOperator(address superOperator, bool enabled) external {
        require(msg.sender == _admin, "only admin is allowed to add super operators");
        _superOperators[superOperator] = enabled;
        emit SuperOperator(superOperator, enabled);
    }

    /// @notice check whether address `who` is given superOperator rights.
    /// @param who The address to query.
    /// @return whether the address has superOperator rights.
    function isSuperOperator(address who) public view returns (bool) {
        return _superOperators[who];
    }
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

interface IAssetToken {
    function mint(
        address creator,
        uint40 packId,
        bytes32 hash,
        uint256 supply,
        uint8 rarity,
        address owner,
        bytes calldata data
    ) external returns (uint256 id);

    function mintMultiple(
        address creator,
        uint40 packId,
        bytes32 hash,
        uint256[] calldata supplies,
        bytes calldata rarityPack,
        address owner,
        bytes calldata data
    ) external returns (uint256[] memory ids);

    // fails on non-NFT or nft who do not have collection (was a mistake)
    function collectionOf(uint256 id) external view returns (uint256);

    function balanceOf(address owner, uint256 id) external view returns (uint256);

    // return true for Non-NFT ERC1155 tokens which exists
    function isCollection(uint256 id) external view returns (bool);

    function collectionIndexOf(uint256 id) external view returns (uint256);

    function extractERC721From(
        address sender,
        uint256 id,
        address to
    ) external returns (uint256 newId);

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;

    function isSuperOperator(address who) external view returns (bool);
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

/// @dev Note: The ERC-165 identifier for this interface is 0x5e8bf644.
interface IERC721MandatoryTokenReceiver {
    function onERC721BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        bytes calldata data
    ) external returns (bytes4); // needs to return 0x4b808c46

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4); // needs to return 0x150b7a02

    // needs to implements EIP-165
    // function supportsInterface(bytes4 interfaceId)
    //     external
    //     view
    //     returns (bool);
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

import "./IGameToken.sol";

interface IGameMinter {
    function createGame(
        address to,
        IGameToken.GameData calldata creation,
        address editor,
        uint64 subId
    ) external returns (uint256 gameId);

    function updateGame(uint256 gameId, IGameToken.GameData memory update) external returns (uint256 newId);
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

/// @title Interface for the Game token

interface IGameToken {
    struct GameData {
        uint256[] assetIdsToRemove;
        uint256[] assetAmountsToRemove;
        uint256[] assetIdsToAdd;
        uint256[] assetAmountsToAdd;
        bytes32 uri; // ipfs hash (without the prefix, assume cidv1 folder)
        uint256 exactNumOfLandsRequired;
    }

    function createGame(
        address from,
        address to,
        GameData calldata creation,
        address editor,
        uint64 subId
    ) external returns (uint256 id);

    function burn(uint256 gameId) external;

    function burnFrom(address from, uint256 gameId) external;

    function recoverAssets(
        address from,
        address to,
        uint256 gameId,
        uint256[] calldata assetIds
    ) external;

    function burnAndRecover(
        address from,
        address to,
        uint256 gameId,
        uint256[] calldata assetIds
    ) external;

    function updateGame(
        address from,
        uint256 gameId,
        GameData calldata update
    ) external returns (uint256);

    function getAssetBalances(uint256 gameId, uint256[] calldata assetIds) external view returns (uint256[] calldata);

    function getExactNumOfLandsRequired(uint256 gameId) external view returns (uint256);

    function setGameEditor(
        address gameCreator,
        address editor,
        bool isEditor
    ) external;

    function isGameEditor(address gameOwner, address editor) external view returns (bool isEditor);

    function creatorOf(uint256 id) external view returns (address);

    function transferCreatorship(
        uint256 gameId,
        address sender,
        address to
    ) external;

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function tokenURI(uint256 gameId) external returns (string memory uri);

    function onERC1155Received(
        address operator,
        address, /*from*/
        uint256, /*id*/
        uint256, /*value*/
        bytes calldata /*data*/
    ) external view returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address, /*from*/
        uint256[] calldata, /*ids*/
        uint256[] calldata, /*values*/
        bytes calldata /*data*/
    ) external view returns (bytes4);
}