/**
 *Submitted for verification at polygonscan.com on 2022-01-31
*/

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

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


// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

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
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
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
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
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
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
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
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: contracts/NftMarket.sol


  pragma solidity ^0.8.3;



  contract MCNFT {
      function getContractFee() public view virtual returns (uint256) {}
      function getContractFeeRecipient() public view virtual returns (address) {}
      function getRoyaltyFee() public view virtual returns (uint256) {}
      function getTokenCreator(uint tokenID) public view virtual returns (address) {}
      function approve_contract() public {}
      function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {}
  }

  contract NFTMarket is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    address payable owner;

    constructor() {
        owner = payable(msg.sender);
    }

    struct MarketItem {
        uint itemId;
        uint256 tokenId;
        address nftContract;
        address payable listedBy;
        address payable previousOwner;
        address payable currentOwner;
        uint256 numberOfTransfers;
        bool on_sell;
        uint256 price;
        bool on_auction;
        uint minBid;
        uint endDate;
        address highestBidAddress;
        uint highestBidAmount;
        bool toMarket;
    }
    struct Items{
      uint256 itemId;
      uint256 tokenId;
      address payable currentOwner;
      uint256 numberOfTransfers;
      bool toMarket;
      bool on_sell;
      bool on_auction;
    }
    struct Offer {
      address from;
      uint256 tokenid;
      uint256 price;
    }
    struct TokenIdExist {
        uint itemId;
        bool exist;
    }

  mapping(uint256 => MarketItem) private idToMarketItem;
  mapping(uint256 => TokenIdExist) private tokenIdToItemId;
  mapping(uint256 => Offer[]) private offers;

    event OfferCreated (
        address from,
        uint256 tokenid,
        uint256 price
    );
    event MarketCreated (
        uint indexed itemId,
        uint256 indexed tokenId,
        address indexed nftContract,
        address listedBy,
        address previousOwner,
        address currentOwner,
        uint256 numberOfTransfers,
        bool on_sell,
        uint256 price,
        bool on_auction,
        uint minBid,
        uint endDate,
        address highestBidAddress,
        uint highestBidAmount,
        bool toMarket
    );

  function updateOwner(address nftContract, uint256 tokenId) public {
    if(tokenIdToItemId[tokenId].exist == true){
      uint itemid = tokenIdToItemId[tokenId].itemId;
      if(idToMarketItem[itemid].toMarket == false){
        if(idToMarketItem[itemid].currentOwner != IERC721(nftContract).ownerOf(tokenId)){
          for(uint i=0; i<offers[tokenId].length; i++){
            if(offers[tokenId][i].from != address(0)){
              payable(offers[tokenId][i].from).transfer(offers[tokenId][i].price);
            }
          }
          delete offers[tokenId];
          idToMarketItem[itemid].currentOwner = payable(IERC721(nftContract).ownerOf(tokenId));
        }
      }
    }
  }

  function createoffer(address nftaddress, uint tokenid) public payable {
    require(IERC721(nftaddress).ownerOf(tokenid) != address(0), "Not Found");
    if(tokenIdToItemId[tokenid].exist == true){
      uint itemid = tokenIdToItemId[tokenid].itemId;
      require(idToMarketItem[itemid].toMarket == false, "Already on sale");
    }
    require(msg.value > 0 , "Offer Too Low");
    offers[tokenid].push(Offer(
      payable(msg.sender), 
      tokenid,
      msg.value
    ));
    emit OfferCreated(
      msg.sender, 
      tokenid,
      msg.value
    );
  }

  function getOffers(uint tokenid) public view returns(Offer[] memory){
    return  offers[tokenid];
  }

  function declineOffer(address nftaddress, uint tokenid, uint index) public {
    Offer memory offer = offers[tokenid][index];
    require(IERC721(nftaddress).ownerOf(tokenid) == msg.sender || offer.from == msg.sender , "Not Authorized");
    payable(offer.from).transfer(offer.price);
    delete offers[tokenid][index];
  }

  function declineAllOffers(address nftaddress, uint tokenid) public payable {
    require(IERC721(nftaddress).ownerOf(tokenid) == msg.sender, "Not Authorized");
    for(uint i=0; i<offers[tokenid].length; i++){
      if(offers[tokenid][i].from != address(0)){
        payable(offers[tokenid][i].from).transfer(offers[tokenid][i].price);
      }
    }
    delete offers[tokenid];
  }

  function acceptOffer(address nftaddress, uint tokenid, uint index) public payable {
    Offer memory offer = offers[tokenid][index];
    require(IERC721(nftaddress).ownerOf(tokenid) == msg.sender, "Not Authorized");
    require(MCNFT(nftaddress).isApprovedForAll(msg.sender, address(this)) == true, "Contract not Approved");
    require(offer.from != address(0) && offer.price > 0, "Offer Not valid");
    address offerSender = offer.from;
    uint256 price = offer.price;
    address _contractFeeRecipient = MCNFT(nftaddress).getContractFeeRecipient();
    uint _contractFee = MCNFT(nftaddress).getContractFee();
    address _tokenCreator = MCNFT(nftaddress).getTokenCreator(tokenid);
    address cOwner = IERC721(nftaddress).ownerOf(tokenid);
    uint _royaltyFee = MCNFT(nftaddress).getRoyaltyFee();
    uint fee = (_contractFee * price) / 100 ;
    if (cOwner == _tokenCreator) {
      uint sellerValue = price - fee;
      payable(cOwner).transfer(sellerValue);
      payable(_contractFeeRecipient).transfer(fee);
    } else {
      uint creatorRoyaltyFee = (_royaltyFee * price) / 100;
      uint sellerValue = price - ( fee + creatorRoyaltyFee );
      payable(cOwner).transfer(sellerValue);
      payable(_tokenCreator).transfer(creatorRoyaltyFee);
      payable(_contractFeeRecipient).transfer(fee);
    }
    if(tokenIdToItemId[tokenid].exist == true){
      uint itemId = tokenIdToItemId[tokenid].itemId;
      idToMarketItem[itemId].previousOwner = idToMarketItem[itemId].currentOwner;
      idToMarketItem[itemId].price = price;
      idToMarketItem[itemId].toMarket = false;
      idToMarketItem[itemId].numberOfTransfers += 1;
    }
    delete offers[tokenid][index];
    IERC721(nftaddress).transferFrom(cOwner, offerSender, tokenid);
  }

  function createMarketItem(
    address nftContract,
    uint256 tokenId,
    uint256 price
  ) public payable nonReentrant {
    require(msg.sender != address(0));
    require(price > 0, "Price Too low");
    require(msg.sender == IERC721(nftContract).ownerOf(tokenId), " Not Authorized.");
    require(MCNFT(nftContract).isApprovedForAll(msg.sender, address(this)) == true, "Contract not Approved");
    uint256 itemId = 0;
    if(tokenIdToItemId[tokenId].exist){
      itemId = tokenIdToItemId[tokenId].itemId;
      require(idToMarketItem[itemId].toMarket == false && idToMarketItem[itemId].on_auction == false, "On sale/auction");
      idToMarketItem[itemId].price = price;
      idToMarketItem[itemId].currentOwner = payable(msg.sender);
      idToMarketItem[itemId].toMarket = true;
      idToMarketItem[itemId].on_sell = true;
      IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
    }else{
      _itemIds.increment();
      itemId = _itemIds.current();
      idToMarketItem[itemId] =  MarketItem(
        itemId,
        tokenId,
        nftContract,
        payable(msg.sender),
        payable(address(0)),
        payable(msg.sender),
        0,
        true,
        price,
        false,
        0,
        0,
        address(0),
        0,
        true
      ); 
      tokenIdToItemId[tokenId] = TokenIdExist(
        itemId,
        true
      );
      IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
    }
    emit MarketCreated(
      itemId,
      tokenId,
      nftContract,
      msg.sender,
      address(0),
      msg.sender,
      0,
      true,
      price,
      false,
      0,
      0,
      payable(address(0)),
      0,
      true
    );
  }

  function editMarketSale(
    uint256 itemId,
    uint256 price
    ) public payable nonReentrant {
    require(msg.sender != address(0));
    require(idToMarketItem[itemId].currentOwner == msg.sender, "Not Authorized.");
    require(idToMarketItem[itemId].on_sell == true, "Not on-Sale.");
    require(price > 0, "Price must be at least 1 wei");
    idToMarketItem[itemId].price = price;
  }

  function createMarketSale(
    address nftContract,
    uint256 itemId
    ) public payable nonReentrant {
    uint price = idToMarketItem[itemId].price;
    uint tokenId = idToMarketItem[itemId].tokenId;
    require(msg.sender != address(0));
    require(idToMarketItem[itemId].toMarket == true && idToMarketItem[itemId].on_sell == true, "Item is not on Sale.");
    require(msg.value >= price, "Please submit the asking price in order to complete the purchase");
    address _contractFeeRecipient = MCNFT(nftContract).getContractFeeRecipient();
    uint _contractFee = MCNFT(nftContract).getContractFee();
    address _tokenCreator = MCNFT(nftContract).getTokenCreator(tokenId);
    uint _royaltyFee = MCNFT(nftContract).getRoyaltyFee();
    uint fee = (_contractFee * msg.value) / 100 ;
    if (idToMarketItem[itemId].currentOwner == _tokenCreator) {
      uint sellerValue = msg.value - fee;
      idToMarketItem[itemId].currentOwner.transfer(sellerValue);
      payable(_contractFeeRecipient).transfer(fee);
    } else {
      uint creatorRoyaltyFee = (_royaltyFee * msg.value) / 100;
      uint sellerValue = msg.value - ( fee + creatorRoyaltyFee );
      idToMarketItem[itemId].currentOwner.transfer(sellerValue);
      payable(_tokenCreator).transfer(creatorRoyaltyFee);
      payable(_contractFeeRecipient).transfer(fee);
    }
    idToMarketItem[itemId].previousOwner = idToMarketItem[itemId].currentOwner;
    idToMarketItem[itemId].currentOwner = payable(msg.sender);
    idToMarketItem[itemId].toMarket = false;
    idToMarketItem[itemId].on_sell = false;
    idToMarketItem[itemId].numberOfTransfers += 1;
    IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
  }
  function giveawayNft(
    address nftContract,
    address giveawayAddress,
    uint256 itemId
    ) public payable nonReentrant returns(bool){
    uint tokenId = idToMarketItem[itemId].tokenId;
    require(idToMarketItem[itemId].on_auction == false, "Giveaway not Possible during auction.");
    require(idToMarketItem[itemId].currentOwner == msg.sender, "Not Authorized");
    require(idToMarketItem[itemId].toMarket == true, "Contract not authorized for giveaway");
    require(MCNFT(nftContract).isApprovedForAll(msg.sender, address(this)) == true, "Contract not Approved");
    idToMarketItem[itemId].previousOwner = idToMarketItem[itemId].currentOwner;
    idToMarketItem[itemId].currentOwner = payable(giveawayAddress);
    idToMarketItem[itemId].toMarket = false;
    idToMarketItem[itemId].on_sell = false;
    idToMarketItem[itemId].numberOfTransfers += 1;
    IERC721(nftContract).transferFrom(address(this), address(giveawayAddress), tokenId);
    return true;
  }
  function createAuction(
    address _nftContract, 
    uint tokenId,
    uint _minBid,
    uint256 _days
  ) 
  external 
  {
    require(msg.sender != address(0));
    require(msg.sender == IERC721(_nftContract).ownerOf(tokenId), "Not Authorized.");
    require(MCNFT(_nftContract).isApprovedForAll(msg.sender, address(this)) == true, "Contract not Approved");
    require(_minBid > 0, "Min Bid must be at least 1 wei");
    require(_days > 0, "Day must be greater than 0");
    uint256 itemId = 0;
    if(tokenIdToItemId[tokenId].exist){
        itemId = tokenIdToItemId[tokenId].itemId;
        require(idToMarketItem[itemId].toMarket == false, "Token already Exist on Sell/Auction.");
        MarketItem storage Item = idToMarketItem[itemId];
        Item.on_auction = true;
        Item.minBid = _minBid;
        Item.endDate = block.timestamp + _days * 86400;
        Item.highestBidAddress = payable(address(0));
        Item.highestBidAmount = 0;
        Item.toMarket = true;
        Item.currentOwner = payable(msg.sender);
    }else{
        _itemIds.increment();
        itemId = _itemIds.current();
        idToMarketItem[itemId] =  MarketItem(
            itemId,
            tokenId,
            _nftContract,
            payable(msg.sender),
            payable(address(0)),
            payable(msg.sender),
            0,
            false,
            0,
            true,
            _minBid,
            block.timestamp + _days * 86400,
            address(0),
            0,
            true
        ); 
        tokenIdToItemId[tokenId] = TokenIdExist(
        itemId,
        true
    );
    }
    IERC721(_nftContract).transferFrom(msg.sender, address(this), tokenId);
    emit MarketCreated(
        itemId,
        tokenId,
        _nftContract,
        msg.sender,
        address(0),
        msg.sender,
        0,
        false,
        0,
        true,
        _minBid,
        block.timestamp + _days * 86400,
        payable(address(0)),
        0,
        true
    );
  }

  function createBid(uint itemId) external payable {
    MarketItem storage Item = idToMarketItem[itemId];
    require(Item.toMarket == true && Item.on_auction == true, 'auction does not exist');
    require(Item.endDate >= block.timestamp, 'auction is finished');
    require(
      Item.highestBidAmount < msg.value && Item.minBid < msg.value, 
      'Low Bid Amount'
    );
    payable(Item.highestBidAddress).transfer(Item.highestBidAmount);
    Item.highestBidAddress = msg.sender;
    Item.highestBidAmount = msg.value;
  }

  function closeBid(address nftContract, uint itemId) external {
    uint tokenId = idToMarketItem[itemId].tokenId;
    MarketItem storage Item = idToMarketItem[itemId];
    require(Item.on_auction == true, 'auction does not exist');
    require(Item.endDate < block.timestamp, 'auction is not finished');
    require(msg.sender == owner || msg.sender == Item.currentOwner || msg.sender == Item.highestBidAddress, "Not Authorized");
    if(Item.highestBidAmount == 0) {
        Item.toMarket = false;
        Item.on_auction = false;
        IERC721(nftContract).transferFrom(address(this), Item.currentOwner, tokenId);
    } else {
        address _contractFeeRecipient = MCNFT(nftContract).getContractFeeRecipient();
        uint _contractFee = MCNFT(nftContract).getContractFee();
        address _tokenCreator = MCNFT(nftContract).getTokenCreator(tokenId);
        uint _royaltyFee = MCNFT(nftContract).getRoyaltyFee();
        uint fee = (_contractFee * Item.highestBidAmount) / 100 ;
        if (Item.currentOwner == _tokenCreator) {
            uint sellerValue = Item.highestBidAmount - fee;
            Item.currentOwner.transfer(sellerValue);
            payable(_contractFeeRecipient).transfer(fee);
        } else {
            uint creatorRoyaltyFee = (_royaltyFee * Item.highestBidAmount) / 100;
            uint sellerValue = Item.highestBidAmount - ( fee + creatorRoyaltyFee );
            Item.currentOwner.transfer(sellerValue);
            payable(_tokenCreator).transfer(creatorRoyaltyFee);
            payable(_contractFeeRecipient).transfer(fee);
            Item.price = Item.highestBidAmount;
        }
        Item.previousOwner = Item.currentOwner;
        Item.currentOwner = payable(Item.highestBidAddress);
        Item.toMarket = false;
        Item.on_auction = false;
        Item.numberOfTransfers += 1;
        IERC721(nftContract).transferFrom(address(this), Item.highestBidAddress, tokenId);
    }
  }

  function fetchItemByTokenId(uint tokenId) public view returns (MarketItem[] memory) {
    require(tokenIdToItemId[tokenId].exist == true, "Not Exist");
    uint itemId = tokenIdToItemId[tokenId].itemId;
    MarketItem[] memory items = new MarketItem[](1);
    MarketItem storage currentItem = idToMarketItem[itemId];
    items[0] = currentItem;
    return items;
  }
  function fetchItemByItemId(uint itemId) public view returns (MarketItem[] memory) {
    MarketItem[] memory items = new MarketItem[](1);
    MarketItem storage currentItem = idToMarketItem[itemId];
    items[0] = currentItem;
    return items;
  }

  function fetchMarketItems() public view returns (MarketItem[] memory) {
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;
    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].toMarket == true) {
        itemCount += 1;
      }
    }
    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].toMarket == true) {
        uint currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

  function fetchItemsOwnByAddress(address nftaddress) public view returns (MarketItem[] memory) {
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;
    for (uint i = 0; i < totalItemCount; i++) {
      if (IERC721(nftaddress).ownerOf(idToMarketItem[i + 1].tokenId) == msg.sender && idToMarketItem[i + 1].toMarket == false) {
        itemCount += 1;
      }
    }
    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      if (IERC721(nftaddress).ownerOf(idToMarketItem[i + 1].tokenId) == msg.sender && idToMarketItem[i + 1].toMarket == false) {
        uint currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

  function fetchItemsOnSaleByAddress() public view returns (MarketItem[] memory) {
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;
    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].currentOwner == msg.sender && idToMarketItem[i + 1].toMarket == true) {
        itemCount += 1;
      }
    }
    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].currentOwner == msg.sender  && idToMarketItem[i + 1].toMarket == true) {
        uint currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }
  function getOwners() public view returns (address[] memory) {
    uint totalItemCount = _itemIds.current();
    uint currentIndex = 0;
    address[] memory items = new address[](totalItemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      uint currentId = i + 1;
      items[currentIndex] = idToMarketItem[currentId].currentOwner;
      currentIndex += 1;
    }
    return items;
  }
  function getItemsInfo() public view returns (Items[] memory) {
    uint totalItemCount = _itemIds.current();
    uint currentIndex = 0;
    Items[] memory items = new Items[](totalItemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      uint currentId = i + 1;
      items[currentIndex] = Items(
        idToMarketItem[currentId].itemId,
        idToMarketItem[currentId].tokenId,
        idToMarketItem[currentId].currentOwner,
        idToMarketItem[currentId].numberOfTransfers,
        idToMarketItem[currentId].toMarket,
        idToMarketItem[currentId].on_sell,
        idToMarketItem[currentId].on_auction
      );
      currentIndex += 1;
    }
    return items;
  }
}