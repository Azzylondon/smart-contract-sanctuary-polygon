// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./Common/ICollectionFactory.sol";
import "./Common/ICollectionConfig.sol";
import "./Common/Collection.sol";

import "./Common/StrLib.sol";
import "./Common/SignLib.sol";

//-----------------------------------------
// Collection factory
//-----------------------------------------
contract CollectionFactory is Ownable, ICollectionFactory, ICollectionConfig {
    //-----------------------------------------
    // Constant
    //-----------------------------------------
    uint256 constant private COLLECTION_ID_OFFSET = 1;

    //-----------------------------------------
    // Setting items
    //-----------------------------------------
    address private _signer_public_key;     // Signer's address
    bool private _sign_required;            // Do you need a signature for your personal collection?
    bool private _sign_required_for_public; // Do you need a signature on your public collection?

    //-----------------------------------------
    // Storage
    //-----------------------------------------
    address[] private _collections;

    //-----------------------------------------
    // Constructor
    //-----------------------------------------
    constructor() Ownable() {
        _signer_public_key = 0x46b72010BF08b9cC80564162dBa1b1a347580F75;    // Owner address of Mumbai (because it is troublesome to set each time at the time of testing)
        _sign_required = false;
        _sign_required_for_public = false;

        // event
        emit SignerPublicKeyModified( _signer_public_key );
        emit SignRequiredModified( _sign_required );
        emit SignRequiredForPublicModified( _sign_required_for_public );
    }

    //-----------------------------------------
    // [external] Check settings
    //-----------------------------------------
    function signerPublicKey() external view override returns (address) {
        return( _signer_public_key );
    }

    function signRequired() external view override returns (bool) {
        return( _sign_required );
    }

    function signRequiredForPublic() external view override returns (bool) {
        return( _sign_required_for_public );
    }

    //-----------------------------------------
    // [external/onlyOwner] Setting
    //-----------------------------------------
    function setSignerPublicKey( address signer ) external override onlyOwner {
        _signer_public_key = signer;

        // event
        emit SignerPublicKeyModified( _signer_public_key );
    }

    function setSignRequired( bool flag ) external override onlyOwner {
        _sign_required = flag;

        // event
        emit SignRequiredModified( _sign_required );
    }

    function setSignRequiredForPublic( bool flag ) external override onlyOwner {
        _sign_required_for_public = flag;

        // event
        emit SignRequiredForPublicModified( _sign_required_for_public );
    }

    //-----------------------------------------
    // [external] Signature verification
    //-----------------------------------------
    function checkSignature( string calldata signature, string calldata message ) external view override returns (bool){
        return( SignLib.getSigner( signature, message ) == _signer_public_key );
    }

    //---------------------------------------------------------------------------------------
    // [external] Create a collection (sign if the caller owns / controls the collection)
    //---------------------------------------------------------------------------------------
    function createCollection( string calldata tokenName, string calldata tokenSymbol, string calldata signature ) external override {
        // Signature confirmation (personal collection)
        if( _sign_required ){
            string memory strSender = StrLib.numToStrHex( uint256(uint160(msg.sender)), 40 );
            string memory message = string( abi.encodePacked( strSender, tokenName, tokenSymbol ) );
            require( SignLib.getSigner( signature, message ) == _signer_public_key, "invalid signature" );
        }

        uint256 collectionId = _collections.length + COLLECTION_ID_OFFSET;

        // Creating a collection
        address contractAddress = address( new Collection( collectionId, ICollectionConfig(this), tokenName, tokenSymbol, msg.sender ) );
        _collections.push( contractAddress );

        // event
        emit CollectionCreated( msg.sender, tokenName, tokenSymbol, collectionId, contractAddress );
    }

    //-----------------------------------------
    // [external] Get a collection
    //-----------------------------------------
    function collections( uint256 collectionId ) external view returns (address) {
        require( _exists(collectionId), "nonexistent collection" );

        return( _collections[collectionId-COLLECTION_ID_OFFSET] );
    }

    //-----------------------------------------
    // [internal] Check collection
    //-----------------------------------------
    function _exists( uint256 collectionId ) internal view returns (bool) {
        return( collectionId >= COLLECTION_ID_OFFSET && collectionId < (_collections.length+COLLECTION_ID_OFFSET) );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
pragma solidity >=0.8.7 <0.9.0;

//-----------------------------------------------------------------------
// ICollectionFactory
//-----------------------------------------------------------------------
interface ICollectionFactory {
	//----------------------------------------
	// Events
	//----------------------------------------
	event CollectionCreated( address indexed creator, string tokenName, string tokenSymbol, uint256 collectionId, address contractAddress );

    //----------------------------------------
    // Functions
    //----------------------------------------
    function createCollection( string calldata tokenName, string calldata tokenSymbol, string calldata signature ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

//-----------------------------------------------------------------------
// ICollectionConfig
//-----------------------------------------------------------------------
interface ICollectionConfig {
	//----------------------------------------
	// Events
	//----------------------------------------
    event SignerPublicKeyModified( address publicKey );
    event SignRequiredModified( bool signRequired );
    event SignRequiredForPublicModified( bool signRequired );

    //----------------------------------------
    // Functions
    //----------------------------------------
    function signerPublicKey() external view returns (address);
    function setSignerPublicKey( address signer ) external;

    function signRequired() external view returns (bool);
    function setSignRequired( bool flag ) external;

    function signRequiredForPublic() external view returns (bool);
    function setSignRequiredForPublic( bool flag ) external;

    function checkSignature( string calldata signature, string calldata message ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./ICollection.sol";
import "./ICollectionConfig.sol";

import "./StrLib.sol";

//-----------------------------------
// Collection(ERC721)
//-----------------------------------
contract Collection is Ownable, ERC721, ICollection {
    //--------------------------------------
    // Constant
    //--------------------------------------
    uint256 constant private TOKEN_ID_OFFSET = 1;

    //--------------------------------------
    // Management information
    //--------------------------------------
    uint256 private _collectionId;
    ICollectionConfig private _collectionConfig;

    //--------------------------------------
    // Storage
    //--------------------------------------
    string[] private _meta_hashes;

    //--------------------------------------
    // [external] Information acquisition
    //--------------------------------------
    function totalSupply() external view override returns (uint256) {
        return( _meta_hashes.length );
    }

    function collectionId() external view override returns (uint256) {
        return( _collectionId );
    }

    function collectionConfig() external view override returns (address) {
        return( address(_collectionConfig) );
    }

    //--------------------------------------
    // Constructor
    //--------------------------------------
    constructor( uint256 id, ICollectionConfig config, string memory name, string memory symbol, address creator ) Ownable() ERC721( name, symbol ) {
        // Transfer Owner permissions
        transferOwnership( creator );

        // This value is set only in the constructor (* because it's one-to-one with the parent CollectionFactory)
        _collectionId = id;
        _collectionConfig = config;
    }

    //--------------------------------------
    // [public] Token URI
    //--------------------------------------
    function tokenURI( uint256 tokenId ) public view override returns (string memory) {
        require( _exists( tokenId ), "nonexistent token" );

        return( string( abi.encodePacked( "ipfs://", _meta_hashes[tokenId-TOKEN_ID_OFFSET] ) ) );
    }

    //-------------------------------------------------------------------
    // [external/onlyOwner] Creating a token (signing to restrict calls)
    //-------------------------------------------------------------------
    function createToken( string calldata metaHash, string calldata signature ) external override onlyOwner {
        // Signature confirmation (personal collection)
        if( _collectionConfig.signRequired() ){
            string memory strContract = StrLib.numToStrHex( uint256(uint160(address(this))), 40 );
            string memory strSender = StrLib.numToStrHex( uint256(uint160(msg.sender)), 40 );
            string memory message = string( abi.encodePacked( strContract, strSender, metaHash ) );
            require( _collectionConfig.checkSignature( signature, message ), "invalid signature" );
        }

        uint256 tokenId = _meta_hashes.length + TOKEN_ID_OFFSET;

        // event
        emit TokenCreated( address(this), msg.sender, metaHash, tokenId );

        // Token issuance: [Transfer] fires after [Token Created]
        _safeMint( msg.sender, tokenId );

        // Saving hash
        _meta_hashes.push( metaHash );
    }

    //------------------------------------------------------------------------------
    // [external/onlyOwner] Update metadata hash (sign to limit calls)
    //------------------------------------------------------------------------------
    function updateMetaHash( uint256 tokenId, string calldata metaHash, string calldata signature ) external override onlyOwner {
        require( _exists( tokenId ), "nonexistent token" );

        // Signature confirmation (personal collection)
        if( _collectionConfig.signRequired() ){
            string memory strContract = StrLib.numToStrHex( uint256(uint160(address(this))), 40 );
            string memory strSender = StrLib.numToStrHex( uint256(uint160(msg.sender)), 40 );
            string memory strId = StrLib.numToStr( tokenId, 0 );
            string memory message = string( abi.encodePacked( strContract, strSender, strId, metaHash ) );
            require( _collectionConfig.checkSignature( signature, message ), "invalid signature" );
        }

        _meta_hashes[tokenId-TOKEN_ID_OFFSET] = metaHash;

        // event
        emit MetaHashUpdated( address(this), tokenId, msg.sender, metaHash );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.7 < 0.9.0;

//-----------------------------
// String: Library
//-----------------------------
library StrLib {
    //---------------------------
    // Returns a number as a decimal string
    //---------------------------
    function numToStr( uint256 val, uint256 zeroFill ) internal pure returns (string memory) {
        // Number digits
        uint256 len = 1;
        uint256 temp = val;
        while( temp >= 10 ){
            temp = temp / 10;
            len++;
        }

        // Number of zero padding digits
        uint256 padding = 0;
        if( zeroFill > len ){
            padding = zeroFill - len;
        }

        // Secure buffer
        bytes memory buf = new bytes(padding + len);

        // Fill with 0
        for( uint256 i=0; i<padding; i++ ){
            buf[i] = bytes1(uint8(48));
        }

        // Numeric output
        temp = val;
        for( uint256 i=0; i<len; i++ ){
            uint c = 48 + (temp%10);    // ascii: '0' 〜 '9'
            buf[padding+len-(i+1)] = bytes1(uint8(c));
            temp /= 10;
        }

        return( string(buf) );
    }

    //----------------------------
    // Returns a number as a hexadecimal string
    //----------------------------
    function numToStrHex( uint256 val, uint256 zeroFill ) internal pure returns (string memory) {
        // Number digits
        uint256 len = 1;
        uint256 temp = val;
        while( temp >= 16 ){
            temp = temp / 16;
            len++;
        }

        // Number of zero padding digits
        uint256 padding = 0;
        if( zeroFill > len ){
            padding = zeroFill - len;
        }

        // Secure buffer
        bytes memory buf = new bytes(padding + len);

        // Fill with 0
        for( uint256 i=0; i<padding; i++ ){
            buf[i] = bytes1(uint8(48));
        }

        // Numeric output
        temp = val;
        for( uint256 i=0; i<len; i++ ){
            uint c = 48 + (temp%16);    // ascii: '0' 〜 '15'
            if( c >= 58 ){
                c += 7;                 // ascii: 'A' 〜 'F' 
            }
            buf[padding+len-(i+1)] = bytes1(uint8(c));
            temp /= 16;
        }

        return( string(buf) );
    }

    //---------------------------
    // Returns a number as a binary string
    //---------------------------
    function numToStrBit( uint256 val, uint256 zeroFill ) internal pure returns (string memory) {
        // Number digits
        uint256 len = 1;
        uint256 temp = val;
        while( temp >= 2 ){
            temp = temp / 2;
            len++;
        }

        // Number of zero padding digits
        uint256 padding = 0;
        if( zeroFill > len ){
            padding = zeroFill - len;
        }

        // Secure buffer
        bytes memory buf = new bytes(padding+len);

        // Fill with 0
        for( uint256 i=0; i<padding; i++ ){
            buf[i] = bytes1(uint8(48));
        }

        // Numeric output
        temp = val;
        for( uint256 i=0; i<len; i++ ){
            uint c = 48 + (temp%2);     // ascii: '0' 〜 '1'
            buf[padding+len-(i+1)] = bytes1(uint8(c));
            temp /= 2;
        }

        return( string(buf) );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.7 < 0.9.0;

import "./StrLib.sol";

//-------------------------
// Signature library
//-------------------------
library SignLib {
    //---------------
    // Obtaining a signer
    //---------------
    function getSigner( string memory signature, string memory message ) internal pure returns (address){
    	bytes memory bStr = bytes( signature );

    	int start = 0;

        // "0x"
        if( bStr[0] == 0x30 && (bStr[1] == 0x58 || bStr[1] == 0x78) ){
            start = 2;
        }

        int num;
        int ofs;

        // v
        num = 2;
    	ofs = int(bStr.length - 2);
    	if( ofs < start ){
    		num -= (start-ofs);
    		ofs = start;
    	}
    	uint8 v = uint8(_str2uintHex( bStr, ofs, num ));

    	// s
        num = 64;
    	ofs = int(bStr.length - (64+2));
    	if( ofs < start ){
    		num -= (start-ofs);
    		ofs = start;
    	}
    	uint s = _str2uintHex( bStr, ofs, num );

    	// r
        num = 64;
    	ofs = int(bStr.length - (64+64+2));
    	if( ofs < start ){
    		num -= (start-ofs);
    		ofs = start;
    	}
    	uint r = _str2uintHex( bStr, ofs, num );

        // Recover and return
        return( recoverSigner( message, v, bytes32(r), bytes32(s) ) );
    }

    //-------------------------------
    // Signer recoveration
    //-------------------------------
	function recoverSigner( string memory message, uint8 v, bytes32 r, bytes32 s ) internal pure returns (address) {
		string memory prefix = "\x19Ethereum Signed Message:\n";

		bytes memory bufMessage = bytes( message );
        string memory strLen = StrLib.numToStr( bufMessage.length, 0 );

	 	bytes32 hash = keccak256( abi.encodePacked( prefix, strLen, message ) );
	  	return( ecrecover( hash, v, r, s ) );
  	}

    //----------------------------------------------
    // Convert to a number by specifying the position and length for a hexadecimal character string
    //----------------------------------------------
    function _str2uintHex( bytes memory data, int ofs, int num ) internal pure returns (uint) {       
        uint val = 0;
        uint c;
        int end = ofs + num;
        while( ofs < end ){
            val <<= 4;

            c = uint8( data[uint(ofs)] );

            // 0-9
            if( c >= 0x30 && c <= 0x39  ){
                val |= ( c - 0x30 );
            }
            // a-f
            else if( c >= 0x41 && c <= 0x46 ){
                val |= ( 10 + c - 0x41 );
            }
            // A-F
            else if( c >= 0x61 && c <= 0x66 ){
                val |= ( 10 + c - 0x61 );
            }

            ofs++;
        }

        return( val );
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
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
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
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
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
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
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
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

        _afterTokenTransfer(address(0), to, tokenId);
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

        _afterTokenTransfer(owner, address(0), tokenId);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
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
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

//-----------------------------------------------------------------------
// ICollection
//-----------------------------------------------------------------------
interface ICollection {
	//----------------------------------------
	// Events
	//----------------------------------------
	event TokenCreated( address indexed contractAddress, address indexed creator, string metaHash, uint256 tokenId );
	event MetaHashUpdated( address indexed contractAddress, uint256 indexed tokenId, address indexed creator, string metaHash );

    //----------------------------------------
    // Functions
    //----------------------------------------
    function totalSupply() external view returns( uint256);
    function collectionId() external view returns (uint256);
    function collectionConfig() external view returns (address);

    function createToken( string calldata metaHash, string calldata signature ) external;
    function updateMetaHash( uint256 tokenId, string calldata metaHash, string calldata signature ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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