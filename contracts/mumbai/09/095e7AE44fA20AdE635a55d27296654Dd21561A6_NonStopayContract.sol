/**
 *Submitted for verification at polygonscan.com on 2022-10-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct  TMerchant
{
    string      name;
    address     wallet;
    bool        enabled;
    uint        invoiceFeeInM100;
    uint        soldQuantity;
    uint        totalSoldAmount;
    uint        totalAmountWithoutFee;
    uint        totalFeeAmount;
    uint        timestamp;          // date when created
    uint        id;
}

struct  TInvoice
{
    address     buyerWallet;
    address     merchantWallet;
    uint        merchantId;
    uint        feePercentInM100;
    uint        amount;
    uint        merchantAmount;     // After cutting the fees, how much left for the merchant
    uint        feeAmount;          // Fee amount for our service
    uint        timestamp;          // date when the fund deposit was made
    string      merchantRef;        // invoice ID from the merchant database
    string      title;
    uint        id;
}

struct  TMerchantBalance
{
    uint        merchantId;
    uint        soldQuantity;
    uint        totalSoldAmount;
    uint        totalAmountWithoutFee;
    uint        totalFeeAmount;
}

struct TOperator
{
    address     wallet;
    uint8       rights;
}

struct  TRevenue
{
    uint        ourRevenue;
    uint        merchantsRevenue;
    uint        grossRevenue;
}

struct  TCurrency
{
    address     token;
    string      name;
    string      symbol;
    uint        decimalCount;
}

//==============================================================================
interface iERC20 
{
    function    balanceOf(address guy)                              external view   returns (uint);
    function     transfer(address dst, uint amount)                 external        returns (bool);
    function transferFrom(address src, address dst, uint amount)    external        returns (bool);
}
//==============================================================================
interface IERC165
{
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
//==============================================================================
interface IERC721 is IERC165
{
    event   Transfer(      address indexed from,  address indexed to,       uint  indexed tokenId);
    event   Approval(      address indexed owner, address indexed approved, uint  indexed tokenId);
    event   ApprovalForAll(address indexed owner, address indexed operator, bool             approved);

    function balanceOf(        address owner)                               external view returns (uint balance);
    function ownerOf(          uint tokenId)                                external view returns (address owner);
    function safeTransferFrom( address from,     address to, uint tokenId)  external;
    function transferFrom(     address from,     address to, uint tokenId)  external;
    function approve(          address to,       uint tokenId)              external;
    function getApproved(      uint tokenId)                                external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved)            external;
    function isApprovedForAll( address owner,    address operator)          external view returns (bool);
    function safeTransferFrom( address from,     address to, uint tokenId, bytes calldata data) external;
}
//==============================================================================
interface IERC721Metadata is IERC721
{
    function name()                     external view returns (string memory);
    function symbol()                   external view returns (string memory);
    function tokenURI(uint tokenId)     external view returns (string memory);
}
//==============================================================================
interface IERC721Receiver
{
    function onERC721Received(address operator, address from, uint tokenId, bytes calldata data) external returns (bytes4);
}
//================================================================================
library Strings
{
    bytes16 private constant alphabet = "0123456789abcdef";

    function toString(uint value) internal pure returns (string memory)
    {
        if (value==0)       return "0";
   
        uint temp = value;
        uint digits;
   
        while (temp!=0)
        {
            digits++;
            temp /= 10;
        }
       
        bytes memory buffer = new bytes(digits);
       
        while (value!=0)
        {
            digits        -= 1;
            buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
            value         /= 10;
        }
       
        return string(buffer);
    }
}
//================================================================================
library Address
{
    function isContract(address account) internal view returns (bool)
    {
        uint size;
       
        assembly { size := extcodesize(account) }   // solhint-disable-next-line no-inline-assembly
        return size > 0;
    }
    //---------------------------------------------------------------------
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) 
    {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    //---------------------------------------------------------------------
    function functionCallWithValue(
        address         target,
        bytes memory    data,
        uint256         value,
        string memory   errorMessage) 
            internal 
            returns (bytes memory) 
    {
        require(address(this).balance >= value, "Address: insufficient balance for call");
    
        (bool success, bytes memory returndata) = target.call{value: value}(data);
    
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }
    //---------------------------------------------------------------------
    function verifyCallResultFromTarget(
        address         target,
        bool            success,
        bytes memory    returndata,
        string memory   errorMessage) 
            internal 
            view 
            returns (bytes memory) 
    {
        if (success) 
        {
            if (returndata.length == 0) 
            {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            
            return returndata;
        } 
        else 
        {
            _revert(returndata, errorMessage);
        }
    }
    //---------------------------------------------------------------------
    function _revert(bytes memory returndata, string memory errorMessage) private pure 
    {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) 
        {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } 
        else 
        {
            revert(errorMessage);
        }
    }
}
//==============================================================================
contract ERC165 is IERC165
{
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool)
    {
        return (interfaceId == type(IERC165).interfaceId);
    }
}
//==============================================================================
contract Context
{
    function _msgSender() internal view virtual returns (address)
    {
        return msg.sender;
    }
    //----------------------------------------------------------------
    function _msgData() internal view virtual returns (bytes calldata)
    {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
//--------------------------------------------------------------------------------
contract Ownable is Context
{
    address private _owner;

    event   OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor ()
    {
        address msgSender = _msgSender();
                   _owner = msgSender;
                   
        emit OwnershipTransferred(address(0), msgSender);
    }
   
    function owner() public view virtual returns (address)
    {
        return _owner;
    }
   
    modifier onlyOwner()
    {
        require(owner() == _msgSender(),    "Not owner");
        _;
    }
   
    function transferOwnership(address newOwner) public virtual onlyOwner
    {
        require(newOwner != address(0), "Bad addr");
       
        emit OwnershipTransferred(_owner, newOwner);
       
        _owner = newOwner;
    }
}
//==============================================================================
contract ReentrancyGuard 
{
    uint private constant _NOT_ENTERED = 1;
    uint private constant _ENTERED     = 2;

    uint private _status;

    constructor() 
    {       
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant()         // Prevents a contract from calling itself, directly or indirectly.
    {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");    // On the first call to nonReentrant, _notEntered will be true
        _status = _ENTERED;                                                 // Any calls to nonReentrant after this point will fail
        _;
        _status = _NOT_ENTERED;                                             // By storing the original value once again, a refund is triggered (see // https://eips.ethereum.org/EIPS/eip-2200)
    }
}
//==============================================================================
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, Ownable, ReentrancyGuard
{
    using Address for address;
    using Strings for uint;

    string private _name;   // Token name
    string private _symbol; // Token symbol

    mapping(uint => address)                  internal _owners;              // Mapping from token ID to owner address
    mapping(address => uint)                  internal _balances;            // Mapping owner address to token count
    mapping(uint => address)                  private  _tokenApprovals;      // Mapping from token ID to approved address
    mapping(address => mapping(address => bool)) private  _operatorApprovals;   // Mapping from owner to operator approvals
   
    constructor(string memory name_, string memory symbol_)
    {
        _name   = name_;
        _symbol = symbol_;
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool)
    {
        return  interfaceId == type(IERC721).interfaceId         ||
                interfaceId == type(IERC721Metadata).interfaceId ||
                super.supportsInterface(interfaceId);
    }
    function balanceOf(address owner) public view virtual override returns (uint)
    {
        require(owner != address(0), "ERC721: balance query for the zero address");
       
        return _balances[owner];
    }
    function ownerOf(uint tokenId) public view virtual override returns (address)
    {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }
    function name() public view virtual override returns (string memory)
    {
        return _name;
    }
    function symbol() public view virtual override returns (string memory)
    {
        return _symbol;
    }
    function tokenURI(uint tokenId) public view virtual override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
       
        return (bytes(baseURI).length>0) ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
    function _baseURI() internal view virtual returns (string memory)
    {
        return "";
    }
    function approve(address to, uint tokenId) public virtual override
    {
        address owner = ERC721.ownerOf(tokenId);
   
        require(to!=owner, "ERC721: approval to current owner");
        require(_msgSender()==owner || ERC721.isApprovedForAll(owner, _msgSender()), "ERC721: approve caller is not owner nor approved for all");

        _approve(to, tokenId);
    }
    function getApproved(uint tokenId) public view virtual override returns (address)
    {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }
    function setApprovalForAll(address operator, bool approved) public virtual override
    {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
   
        emit ApprovalForAll(_msgSender(), operator, approved);
    }
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }
    function transferFrom(address from, address to, uint tokenId) public virtual override
    {
        //----- solhint-disable-next-line max-line-length
       
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint tokenId) public virtual override
    {
        safeTransferFrom(from, to, tokenId, "");
    }
    function safeTransferFrom(address from, address to, uint tokenId, bytes memory _data) public virtual override
    {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
       
        _safeTransfer(from, to, tokenId, _data);
    }
    function _safeTransfer(address from, address to, uint tokenId, bytes memory _data) internal virtual
    {
        _transfer(from, to, tokenId);
   
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    function _exists(uint tokenId) internal view virtual returns (bool)
    {
        return _owners[tokenId] != address(0);
    }
    function _isApprovedOrOwner(address spender, uint tokenId) internal view virtual returns (bool)
    {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
       
        address owner = ERC721.ownerOf(tokenId);
       
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
    }
    function _safeMint(address to, uint tokenId) internal virtual
    {
        _safeMint(to, tokenId, "");
    }
    function _safeMint(address to, uint tokenId, bytes memory _data) internal virtual
    {
        _mint(to, tokenId);
   
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    function _mint(address to, uint tokenId) internal virtual
    {
        require(to != address(0),  "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to]   += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }
    function _batchMint(address to, uint[] memory tokenIds) internal virtual
    {
        require(to != address(0), "ERC721: mint to the zero address");
       
        _balances[to] += tokenIds.length;

        for (uint i=0; i < tokenIds.length; i++)
        {
            require(!_exists(tokenIds[i]), "ERC721: token already minted");

            _beforeTokenTransfer(address(0), to, tokenIds[i]);

            _owners[tokenIds[i]] = to;

            emit Transfer(address(0), to, tokenIds[i]);
        }
    }
    function _burn(uint tokenId) internal virtual
    {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        _approve(address(0), tokenId);      // Clear approvals

        _balances[owner] -= 1;

        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }
    function _transfer(address from, address to, uint tokenId) internal virtual
    {
        require(ERC721.ownerOf(tokenId)==from,  "ERC721: transfer of token that is not own");
        require(to != address(0),               "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0), tokenId);      // Clear approvals from the previous owner

        _balances[from] -= 1;
        _balances[to]   += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }
    function _approve(address to, uint tokenId) internal virtual
    {
        _tokenApprovals[tokenId] = to;
   
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }
    function _checkOnERC721Received(address from,address to,uint tokenId,bytes memory _data) private returns (bool)
    {
        if (to.isContract())
        {
            try
           
                IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data)
           
            returns (bytes4 retval)
            {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            }
            catch (bytes memory reason)
            {
                if (reason.length==0)
                {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                }
                else
                {
                    assembly { revert(add(32, reason), mload(reason)) }     //// solhint-disable-next-line no-inline-assembly
                }
            }
        }
        else
        {
            return true;
        }
    }
    function _beforeTokenTransfer(address from, address to, uint tokenId) internal virtual
    {
        //
    }
}
//==============================================================================
//==============================================================================
//==============================================================================
contract    NonStopayContract     is  ERC721
{
    using Address for address;
    using Strings for uint;

    address public      currencyToken;
    string  public      currencyName         = "USD Coin";
    string  public      currencySymbol       = "USDC";
    uint    public      currencyDecimalCount = 6;

    string  private     baseURI;

    //constructor() ERC721("NonStopay", "NSTP")
    constructor() ERC721("NSTpay", "NSTP01")
    {
        serviceWallet = owner();
        baseURI       = "https://ipfs.nonstopay.net/usdc/";
        currencyToken = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;         // USDC on polygon mainnet

        setOperator(owner(),                                    127);
        setOperator(0xffFFe388e1e4cFaAB94F0b883d28b8a424Cb45a1, 127);
        setOperator(0x8D1296697d93fA30310C390E2825e3b45c3024dc, 127);

        if (block.chainid==5) 
        {
            setOperator(0x4d0463a8B25463cbEcF9F60463362DC9BDCf6E00, 127);
            setOperator(0xEe5f763b6480EACd4A4Dbc6F551b7734d08de93f, 127);

            baseURI       = "https://ipfsdev.nonstopay.net/usdc/";
            currencyToken = 0x879bad9DcD7e7f79B598a632103984FC090DA00D;     // ERC-20 for the WERT service (similar to USDC on mumbai)
        }
    }

    uint    private     hexLimit = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0;

    address private     ownerWallet;
    address private     serviceWallet;

    uint    private     baseCommissionInM100 = 10 * 100;

    mapping(address => bool)        private registeredOperators;
    mapping(address => uint8)       private operatorsRights;        // List of existing operators with their right.  &1: enable  &2: managecollection  &4: revertNft  &8: changePrice  &16: changeMaxFund%
                    address[]       private operatorList;

    mapping(address => bool)        private registeredMerchants;
    mapping(address => TMerchant)   private merchants;
                       TMerchant[]  private merchantList;

    mapping(uint => TInvoice)       private invoices;
                    TInvoice[]      private invoiceList;


    uint    public      nftIndex = 0;

    uint    private     totalCommission      = 0;       // Total commission collected for the service
    uint    private     totalPaidToMerchants = 0;       // Total amount paid to all merchants since the beginning

    //-----

    string                  private     signHeader    = "\x19Ethereum Signed Message:\n32";
    address                 private     signingEntity;
    mapping(address => bool)private     registeredSigningEntities;

    mapping(uint => bool)   private     proposedHashes;         // Used to avoid using the same hash on CreateLoan calls

    //-----

    event SetOperator(address wallet, uint rights, uint isEnabled, uint8 canChangeMerchantWallet, uint8 canChangeFees, uint8 canChangeMerchantName, uint8 canChangeDefaultFee, uint8 canChangeSigner, uint8 canCreateMerchant);
    event SetServiceWallet(address oldWallet, address newWallet);
    event SetMerchant(uint merchantId, string name, address wallet, uint invoiceFeeInM100, bool isEnabled, address operator);
    event CreateInvoice(TInvoice invoice);
    event SetInvoiceFee(uint oldFeeInM100, uint newFeeInM100);
    event SetSigningEntity(bool done);
    event OperatorSetMerchant(uint merchantId, bool isEnabled, address newWallet, uint newFeeInM100, string newName, uint operatorRights);

    //------------------------------------------------------------------------
    function    setOperator(address wallet, uint8 rights) public onlyOwner
    {
        require(wallet != address(0), "Bad guy");

        operatorsRights[wallet] = rights;     // 64 bits :   6 possible rights  &1: enable  &2: managecollection  &4: revertNft  &8: changePrice  &16: changeMaxFund%
        
        if (registeredOperators[wallet]==false)
        {
            registeredOperators[wallet] = true;
            operatorList.push(wallet);
        }

        uint8 isEnabled               =  (rights     & 1);    // Enabled
        uint8 canChangeMerchantWallet = ((rights>>1) & 1);    // canChange merchant WALLET
        uint8 canChangeFees           = ((rights>>2) & 1);    // canChange merchant FEES
        uint8 canChangeMerchantName   = ((rights>>3) & 1);    // canChange merchant NAME
        uint8 canChangeDefaultFee     = ((rights>>4) & 1);    // canChangeDefaultFee
        uint8 canChangeSigner         = ((rights>>5) & 1);    // canChange the Signing Entity
        uint8 canCreateMerchant       = ((rights>>6) & 1);    // can Create Merchants

        emit SetOperator(wallet, rights, isEnabled, canChangeMerchantWallet, canChangeFees, canChangeMerchantName, canChangeDefaultFee, canChangeSigner, canCreateMerchant);
    }
    //-----------------------------------------------------------------------------
    function    listOperators(uint indexFrom, uint indexTo) external view returns(TOperator[] memory) 
    {
        uint nOperator = operatorList.length;

        require(indexFrom < indexTo && indexTo < nOperator, "Bad RNG");

      unchecked
      {
        TOperator[] memory ops = new TOperator[](indexTo - indexFrom + 1);

        uint g = 0;
        for (uint i=indexFrom; i<=indexTo; i++) 
        {
            address wallet = operatorList[i];

            TOperator memory operator = TOperator
            (
                wallet,
                operatorsRights[wallet]
            );
            
            ops[g] = operator;
            g++;
        }
      
        return ops;
      }
    }
    //-----------------------------------------------------------------------------
    function    getOperatorCount() external view returns(uint) 
    {
        return operatorList.length;
    }
    //-----------------------------------------------------------------------------
    function    setServiceWallet(address newAddr) external onlyOwner 
    {
        require(newAddr != address(0), "Bad ADDR");

        address oldWallet = serviceWallet;
            serviceWallet = newAddr;

        emit SetServiceWallet(oldWallet, newAddr);
    }
    //------------------------------------------------------------------------
    //------------------------------------------------------------------------
    //------------------------------------------------------------------------
    function    setBaseTokenURI(string memory newUri) external onlyOwner
    {
        baseURI = newUri;
    }
    //------------------------------------------------------------------------
    function    baseTokenURI() external view returns (string memory)
    {
        return baseURI;
    }
    //------------------------------------------------------------------------
    function    _baseURI() internal view virtual override returns (string memory)
    {
        return baseURI;
    }
    //---------------------------------------------------------------------------
    //---------------------------------------------------------------------------
    //---------------------------------------------------------------------------
    //---------------------------------------------------------------------------
    function    createInvoice(  bytes32         proposedHash, uint8 v, bytes32 r, bytes32 s,
                                uint            nonce,
                                uint            merchantId, 
                                address         toWallet,            // buyWallet & msg.sender can be different (like if using crossMint service)
                                uint            payAmount, 
                                string memory   merchantInvoiceRef,
                                string memory   invoiceTitle)            
                    external 
                    nonReentrant
    {
        uint hash256 = uint(proposedHash);

        require(proposedHashes[hash256]!=true,  "Hash?");
        require(uint256(s) < hexLimit,          "Bad S");
        require(ecrecover(keccak256(abi.encodePacked(signHeader, proposedHash)), v, r, s) == signingEntity, "SignError");
        require(keccak256(abi.encodePacked(payAmount, merchantId, nonce))==proposedHash, "Havoc");

        //-----

        require(toWallet!=address(0),           "Blackhole forbidden");
        require(merchantId<merchantList.length, "Bad merchantId");

        TMerchant storage merchant = merchantList[merchantId];
        
        require(merchant.enabled==true,         "Disabled merchant");
        require(iERC20(currencyToken).balanceOf(msg.sender)>=payAmount, "Not enough balance to pay");

        receivePayment(payAmount, "Failed to receive ERC20 payment");

      unchecked
      {
        uint merchantAmount = payAmount * ( (100*100) - merchant.invoiceFeeInM100 ) / (100*100);
        uint feeAmount      = payAmount - merchantAmount;
      
        totalCommission      += feeAmount;
        totalPaidToMerchants += merchantAmount;

        //----- Creating the invoice

        uint invoiceId = invoiceList.length;

        TInvoice memory invoice = TInvoice
        (
            toWallet,
            merchant.wallet,
            merchantId,
            merchant.invoiceFeeInM100,
            payAmount,
            merchantAmount,
            feeAmount,
            block.timestamp,            // Date of the invoice
            merchantInvoiceRef,
            invoiceTitle,
            invoiceId
        );

        invoices[invoiceId] = invoice;
        
        invoiceList.push(invoice);        

        proposedHashes[hash256] = true;

        //-----

        merchant.soldQuantity++;
        merchant.totalSoldAmount       += payAmount;
        merchant.totalAmountWithoutFee += merchantAmount;
        merchant.totalFeeAmount        += feeAmount;

        merchant = merchants[merchant.wallet];

        merchant.soldQuantity++;
        merchant.totalSoldAmount       += payAmount;
        merchant.totalAmountWithoutFee += merchantAmount;
        merchant.totalFeeAmount        += feeAmount;

        //----- NFT Minting

        ++nftIndex;

        _mint(toWallet, nftIndex);

        //----- Dispatching revenue

        transferPayment(merchant.wallet, merchantAmount,   "Failed sending merchant payment");
        transferPayment(  serviceWallet,      feeAmount,   "Failed sending FEE payment");

        emit CreateInvoice(invoice);
      }
    }
    //---------------------------------------------------------------------------
    //---------------------------------------------------------------------------
    //---------------------------------------------------------------------------
    //---------------------------------------------------------------------------
    function    createMerchant(string memory name, address wallet) external 
    {
        require(registeredMerchants[wallet]==false, "Already registered");

        createMerchantEx(name, wallet, baseCommissionInM100, true, false);
    }
    //---------------------------------------------------------------------------
    function    operatorCreateMerchants
    (
        string[]    memory  names, 
        address[]   memory  wallets, 
        uint[]      memory  invoiceFeesInM100, 
        bool[]      memory  areEnabled) 
            external 
    {
        require(registeredOperators[msg.sender]==true,  "Bad guy");
        require((operatorsRights[msg.sender] & 65)==65, "Bad rights");     // Operator needs to have full rights to use this feature

        require(names.length==wallets.length,                   "Invalid array(1)");
        require(wallets.length==invoiceFeesInM100.length,       "Invalid array(2)");
        require(invoiceFeesInM100.length==areEnabled.length,    "Invalid array(3)");

        uint n = names.length;
        for(uint i; i<n; i++)
        {
            createMerchantEx(names[i], wallets[i], invoiceFeesInM100[i], areEnabled[i], true);
        }
    }
    //---------------------------------------------------------------------------
    function    createMerchantEx(string memory name, address wallet, uint commissionInM100, bool isEnabled, bool isOperatorCall) internal 
    {
        uint merchantId = 0;

        if (isOperatorCall==false && registeredMerchants[wallet]==true)
        {
            revert("You cannot change");
        }

        if (registeredMerchants[wallet]==true)      // This merchant exists
        {
            TMerchant storage merchant = merchants[wallet];

                merchant.name             = name;
                merchant.invoiceFeeInM100 = commissionInM100;
                merchant.enabled          = isEnabled;

            merchant = merchantList[merchant.id];

                merchant.name             = name;
                merchant.invoiceFeeInM100 = commissionInM100;
                merchant.enabled          = isEnabled;
        
            merchantId = merchant.id;
        }
        else                                        // Create the merchant
        {
            TMerchant memory newMerchant = TMerchant
            (
                name,
                wallet,
                isEnabled,
                commissionInM100,
                0,                                  // soldQuantity
                0,                                  // totalSoldAmount
                0,                                  // totalAmountWithoutFee
                0,                                  // totalFeeAmount
                block.timestamp,
                merchantList.length                 // merchant ID
            );

            registeredMerchants[wallet] = true;
            merchants[wallet]           = newMerchant;

            merchantId = merchantList.length;

            merchantList.push(newMerchant);
        }

        emit SetMerchant(merchantId, name, wallet, commissionInM100, isEnabled, msg.sender);
    }
    //---------------------------------------------------------------------------
    function    operatorSetMerchant(uint merchantId, bool isEnabled, address newWallet, uint newFeeInM100, string memory newName) external
    {
        require(registeredOperators[msg.sender]==true,  "Bad guy");
        require(merchantId<merchantList.length,         "Bad IDX"); 

        TMerchant storage m1     = merchantList[merchantId];
        address           wallet = m1.wallet;
        TMerchant storage m2     = merchants[wallet];

        if (registeredMerchants[wallet]==false)     return;

        //-----

        if ((operatorsRights[msg.sender] & 3)==3)
        {
            m1.wallet  = newWallet;
            m2.wallet  = newWallet;
            m1.enabled = isEnabled;
            m2.enabled = isEnabled;
        }
        
        //-----

        if ((operatorsRights[msg.sender] & 5)==5)
        {
            m1.invoiceFeeInM100 = newFeeInM100;
            m2.invoiceFeeInM100 = newFeeInM100;
        }
        
        //-----

        if ((operatorsRights[msg.sender] & 9)==9)
        {
            m1.name = newName;
            m2.name = newName;
        }

        emit OperatorSetMerchant(merchantId, isEnabled, newWallet, newFeeInM100, newName, operatorsRights[msg.sender]);
    }
    //---------------------------------------------------------------------------
    function    operatorSetDefaultInvoiceFee(uint newFee) external
    {
        require(registeredOperators[msg.sender]==true,  "Bad guy");
        require((operatorsRights[msg.sender] & 17)==17, "Bad rights");

        require(newFee<=100*100, "Bad Fee");

        uint          oldFee = baseCommissionInM100;
        baseCommissionInM100 = newFee;

        emit SetInvoiceFee(oldFee, newFee);
    }
    //---------------------------------------------------------------------------
    function    getDefaultInvoiceFee() external view returns(uint defaultFeeInM100)
    {
        return baseCommissionInM100;
    }
    //---------------------------------------------------------------------------
    //---------------------------------------------------------------------------
    function    getRevenues() external view returns(TRevenue memory)
    {
        return TRevenue
        (
            totalCommission + totalPaidToMerchants,     // grossRevenue
            totalCommission,                            // ourRevenue
            totalPaidToMerchants                        // merchantsRevenue
        );
    }
    //---------------------------------------------------------------------------
    function    getClientsRevenue() external view returns(uint)
    {
        return totalPaidToMerchants;
    }
    //---------------------------------------------------------------------------
    function    getGrossRevenue() external view returns(uint)
    {
        return totalCommission + totalPaidToMerchants;
    }
    //---------------------------------------------------------------------------
    function    getPaidToMerchants() external view returns(uint)
    {
        return totalPaidToMerchants;
    }
    //---------------------------------------------------------------------------
    //---------------------------------------------------------------------------
    //---------------------------------------------------------------------------
    function    getInvoiceCount() external view returns(uint)
    {
        return invoiceList.length;
    }
    //---------------------------------------------------------------------------
    function    getInvoice(uint index) external view returns(TInvoice memory)
    {
        require(index<invoiceList.length, "Bad IDX");

        return invoiceList[index];
    }
    //---------------------------------------------------------------------------
    function    getInvoices(uint from, uint to) external view returns(TInvoice[] memory)
    {
        require(from < invoiceList.length, "Bad FROM");
        require(to   < invoiceList.length, "Bad TO");

        if (from > to) 
        {
            uint v = from;
              from = to;
                to = v;
        }

      unchecked
      {
        uint nToExtract = (to - from) + 1;

        TInvoice[] memory list = new TInvoice[](nToExtract);

        uint g = 0;

        for (uint i = from; i <= to; i++) 
        {
            list[g] = invoiceList[i];
            g++;
        }

        return list;
      }
    }
    //---------------------------------------------------------------------------
    //---------------------------------------------------------------------------
    //---------------------------------------------------------------------------
    function    getMerchantCount() external view returns(uint)
    {
        return merchantList.length;
    }
    //---------------------------------------------------------------------------
    function    getMerchant(uint index) external view returns(TMerchant memory)
    {
        require(index<merchantList.length, "Bad IDX");

        return merchantList[index];
    }
    //---------------------------------------------------------------------------
    function    getMerchants(uint from, uint to) external view returns(TMerchant[] memory)
    {
        require(from < merchantList.length, "Bad FROM");
        require(to   < merchantList.length, "Bad TO");

        if (from > to) 
        {
            uint v = from;
              from = to;
                to = v;
        }

      unchecked
      {
        uint nToExtract = (to - from) + 1;

        TMerchant[] memory list = new TMerchant[](nToExtract);

        uint g = 0;

        for (uint i = from; i <= to; i++) 
        {
            list[g] = merchantList[i];
            g++;
        }

        return list;
      }
    }
    //---------------------------------------------------------------------------
    function    getMerchantBalances(uint index) external view returns(TMerchantBalance memory)
    {
        require(index<merchantList.length, "Bad IDX");

        TMerchant memory merchant = merchantList[index];

        TMerchantBalance memory balanceObj = TMerchantBalance
        (
            merchant.id,
            merchant.soldQuantity, 
            merchant.totalSoldAmount, 
            merchant.totalAmountWithoutFee, 
            merchant.totalFeeAmount
        );

        return balanceObj;
    }
    //---------------------------------------------------------------------------
    function    getMerchantAddressByIndex(uint index) external view returns(address)
    {
        require(index<merchantList.length, "Bad IDX");

        return merchantList[index].wallet;
    }
    //---------------------------------------------------------------------------
    function    getMerchantIndexByAddress(address wallet) external view returns(uint)
    {
        require(registeredMerchants[wallet]==true, "Unknown wallet");

        TMerchant memory merchant = merchants[wallet];

        return merchant.id;
    }
    //---------------------------------------------------------------------------
    //---------------------------------------------------------------------------
    //---------------------------------------------------------------------------
    function    getCurrency() external view returns(TCurrency memory)
    {
        return TCurrency(currencyToken, currencyName, currencySymbol, currencyDecimalCount);
    }
    //---------------------------------------------------------------------------
    //---------------------------------------------------------------------------
    //---------------------------------------------------------------------------
    function    setSigningEntity(address signer) external  
    {
        require(registeredOperators[msg.sender]==true,  "Bad guy");
        require((operatorsRights[msg.sender] & 33)==33, "Unallowed");

        require(registeredSigningEntities[signer]==false, "Signer known");      // always use a new signer to avoid cache-replayin

        registeredSigningEntities[signer] = true;

        signingEntity = signer;

        emit SetSigningEntity(true);     // Show the last signing entity in the blockchain
    }
    //---------------------------------------------------------------------------
    //---------------------------------------------------------------------------
    //---------------------------------------------------------------------------
    function    transferPayment(address to, uint amount, string memory errorMsg) internal
    {
        bytes memory rt = address(iERC20(currencyToken)).functionCall
        ( 
            abi.encodeWithSelector
            (
                iERC20(currencyToken).transfer.selector, 
                to, 
                amount
            )
            , 
            errorMsg
        );

        if (rt.length > 0) 
        {
            require(abi.decode(rt, (bool)), "SafeERC20: transferPayment FAILED");
        }
    }
    //---------------------------------------------------------------------------
    function    receivePayment(uint amount, string memory errorMsg) internal
    {
        bytes memory rt = address(iERC20(currencyToken)).functionCall
        ( 
            abi.encodeWithSelector
            (
                iERC20(currencyToken).transferFrom.selector, 
                msg.sender,
                address(this), 
                amount
            )
            , 
            errorMsg
        );

        if (rt.length > 0) 
        {
            require(abi.decode(rt, (bool)), "SafeERC20: receivePayment FAILED");
        }
    }
}