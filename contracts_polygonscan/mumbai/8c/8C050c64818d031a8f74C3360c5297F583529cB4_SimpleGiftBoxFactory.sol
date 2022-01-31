// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./SimpleGiftBox.sol";
import "./aiySimpleGiftBox.sol";
import "./interfaces/ISimpleGiftBoxFactory.sol";
import "./interfaces/IGiftRegistry.sol";

contract SimpleGiftBoxFactory is ISimpleGiftBoxFactory {

  IGiftRegistry registry;
  address internal wethGateway; //AAVE lending ETH
  address internal lendingPoolAddressProvider; //AAVE lending pool address provider

  // @name Setup Factory
  constructor(address _giftRegistry, address _lendingPoolAddressProvider, address _wethGateway) {
    registry = IGiftRegistry(_giftRegistry);
    lendingPoolAddressProvider = _lendingPoolAddressProvider;
    wethGateway = _wethGateway;
  }

  // @name Create Simple Gift Box
  function createSimpleGiftBox(address _recipient) external returns(address) {
    SimpleGiftBox box = new SimpleGiftBox(address(registry), _recipient, msg.sender);
    registry.registerGiftBox(_recipient, address(box));
    registry.registerWatcher(address(box), msg.sender);
    return address(box);
  }

  // @name Create AAVE Interest Yielding Simple Gift Box
  function createAIYSimpleGiftBox(address _recipient) external returns(address) {
    aiySimpleGiftBox box = new aiySimpleGiftBox(address(registry), _recipient, msg.sender, lendingPoolAddressProvider, wethGateway);
    registry.registerGiftBox(_recipient, address(box));
    registry.registerWatcher(address(box), msg.sender);
    return address(box);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.10;

// @name WETH Gateway Interface
// @notice Methods removed unless explicitly needed
interface IWETHGateway {
    function depositETH(address lendingPool, address onBehalfOf, uint16 referralCode) external payable;
    function withdrawETH(address lendingPool, uint256 amount, address onBehalfOf) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// @name ISimpleGiftBoxFactory
interface ISimpleGiftBoxFactory {

  // @name Create Simple Gift Box
  function createSimpleGiftBox(address _recipient) external returns(address);

  // @name Create AAVE Interest Yielding Simple Gift Box
  function createAIYSimpleGiftBox(address _recipient) external returns(address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.10;

/**
 * @title LendingPoolAddressesProvider (slim) contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 * @notice Methods removed unless explicitly needed
 **/
interface ILendingPoolAddressesProvider {
    function getLendingPool() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;

import './ILendingPoolAddressesProvider.sol';

// @notice Methods removed unless explicitly needed
interface ILendingPool {

    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IGiftRegistry {

  function registerGiftBox(address _recipient, address _giftBox) external;
  function registerConservator(address _giftBox, address _conservator) external;
  function registerNewConservator(address _conservator) external;
  function registerWatcher(address _giftBox, address _watcher) external;
  function watchGiftBox(address _giftBox) external;

  function deregisterGiftBox(address _recipient) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

interface IGiftBox is IERC777Recipient, IERC1155Receiver {

  // @name Unwrap Gift
  // @notice Recipient can call if gift is ready to receive all gifted assets
  function unwrap() external;

  // @name Re-Gift
  // @notice Allows recipient to transfer gift to new address
  function reGift(address _newRecipient) external;

  // @name Allow ERC20 Token
  // @dev Can be called before or after receiving the token, only need to call once per token type being gifted
  function allowERC20(address _token) external;

  // @name Receive
  // @notice Allow receiving native token as gift
  receive() external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./interfaces/ILendingPool.sol";
import "./interfaces/ILendingPoolAddressesProvider.sol";
import "./interfaces/IWETHGateway.sol";
import "./interfaces/IGiftBox.sol";
import "./ComplexGiftBox.sol";
import "./SimpleGiftBox.sol";

// @name AAVE Interest Yielding (AIY) Simple Gift Box
// @name Simple Gift Box with added AAVE integration
contract aiySimpleGiftBox is SimpleGiftBox {

  address[] public aiyTokens; //tokens that have been registered for automatic interest yielding
  mapping(address => uint256) internal depositedTokens; //interest yielding token's underlying deposit amounts
  uint256 internal aWETH; //aWETH received for depositing ETH into AAVE
  IWETHGateway internal wethGateway; //AAVE lending ETH
  address internal pool; //AAVE lending pool

  // @name Constructor
  constructor(address _registry, address _recipient, address _from, address _lendingPoolAddressProvider, address _wethGateway)
  SimpleGiftBox(_registry, _recipient, _from) {
    //Setup AAVE integration
    ILendingPoolAddressesProvider _provider = ILendingPoolAddressesProvider(_lendingPoolAddressProvider);
    pool = _provider.getLendingPool();
    wethGateway = IWETHGateway(_wethGateway);
  }

  // @name Unwrap Gift
  // @notice Recipient can call if gift is ready to receive all gifted assets
  function unwrap() public override isGiftReady {
    // Withdraw ETH directly to recipient
    //TODO: set the relevant ERC20 allowance of aWETH, before calling this function, so the WETHGateway contract can burn the associated aWETH
    wethGateway.withdrawETH(pool, aWETH, recipient);

    // Withdraw aTokens directly to recipient
    for(uint256 i = 0; i < aiyTokens.length; i++){
      ILendingPool(pool).withdraw(aiyTokens[i], depositedTokens[aiyTokens[i]], recipient);
    }

    // All normal gift box functionality
    super.unwrap();
  }

  // @name Deposit
  // @notice Allows depositing ERC20 tokens into AAVE to yield interest
  function deposit(address _token, uint256 _amount) external {
    /// Retrieve LendingPool address
    ILendingPool(pool).deposit(_token, _amount, address(this), uint16(0)); //TODO: get referral code for recipient

    //Register new aToken
    if(depositedTokens[_token] == 0) {
      aiyTokens.push(_token);
    }
    //Track deposited amounts
    depositedTokens[_token] = _amount;
  }

  // @name Receive
  // @notice Allow receiving native token as gift
  receive() external payable override {
    wethGateway.depositETH{value: msg.value}(pool, address(this), uint16(0)); //TODO: get referral code for recipient
    //Track deposited ETH
    aWETH += msg.value;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./interfaces/IGiftBox.sol";
import "./GiftLibrary.sol";
import "./interfaces/IGiftRegistry.sol";

// @name Simple Gift Box
// @notice Simple gift with not string attached - recipient can unwrap at any time
contract SimpleGiftBox is IGiftBox, ERC721Holder, ERC165 {

  address[] public erc20Tokens; //ERC20 token contracts of received/tracked tokens
  GiftLibrary.TokenWithID[] public erc721Tokens; //ERC721 token contracts of received/tracked tokens
  GiftLibrary.TokenWithID[] public erc1155Tokens; //ERC1155 token contracts of received/tracked tokens
  IGiftRegistry internal registry; //Gift registry - used to remove this box when unwrapping

  // --- Required configurations
  address public recipient;
  address public from;

  // @name Constructor
  constructor(address _registry, address _recipient, address _from) {
    registry = IGiftRegistry(_registry);
    recipient = _recipient;
    from = _from;
  }

  modifier isGiftReady() {
    require(msg.sender == recipient, "Only recipient can unwrap");
    _;
  }

  // @name Unwrap Gift
  // @notice Recipient can call if gift is ready to receive all gifted assets
  function unwrap() public virtual isGiftReady {
    // Send native token
    if(address(this).balance > 0){
      payable(recipient).transfer(address(this).balance);
    }

    // Send ERC-20 and ERC-777 tokens
    for(uint256 i = 0; i < erc20Tokens.length; i++){
      IERC20 token = IERC20(erc20Tokens[i]);
      token.transfer(recipient, token.balanceOf(address(this)));
    }

    // Send ERC-721 tokens
    for(uint256 j = 0; j < erc721Tokens.length; j++){
      GiftLibrary.TokenWithID memory giftedToken = erc721Tokens[j];
      IERC721 token = IERC721(giftedToken.token);
      token.safeTransferFrom(address(this), recipient, giftedToken.tokenId);
    }

    // Send ERC-1155 tokens
    for(uint256 k = 0; k < erc1155Tokens.length; k++){
      GiftLibrary.TokenWithID memory giftedToken = erc1155Tokens[k];
      IERC1155 token = IERC1155(giftedToken.token);
      uint256 balance = token.balanceOf(address(this), giftedToken.tokenId);
      token.safeTransferFrom(address(this), recipient, giftedToken.tokenId, balance, ""); //TODO: where to get data
    }

    //Remove from registry
    registry.deregisterGiftBox(recipient);
  }

  // @name Re-Gift
  // @notice Allows recipient to transfer gift to new address
  function reGift(address _newRecipient) public {
    require(msg.sender == recipient, "Only recipient can re-gift");
    recipient = _newRecipient;
  }

  // @name Allow ERC20 Token
  // @dev Can be called before or after receiving the token, only need to call once per token type being gifted
  function allowERC20(address _token) public {
    erc20Tokens.push(_token);
  }

  // Allow receiving ERC721 tokens for gift box
  function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data)
  public override returns(bytes4){
    erc721Tokens.push(GiftLibrary.TokenWithID(msg.sender, _tokenId));
    return super.onERC721Received(_operator, _from, _tokenId, _data);
  }

  // Support for receiving ERC-777
  function tokensReceived(address _operator, address, address, uint256, bytes memory, bytes memory) public {
    erc20Tokens.push(_operator);
  }

  // Support for receiving ERC-1155
  function onERC1155Received(address _token, address, uint256 _tokenId, uint256, bytes calldata)
  public override returns (bytes4) {
    erc1155Tokens.push(GiftLibrary.TokenWithID(_token, _tokenId));
    return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
  }

  // Support for receiving ERC-1155 batches
  function onERC1155BatchReceived(address _token, address, uint256[] calldata _tokenIds, uint256[] calldata, bytes calldata)
  external override returns (bytes4){
    for(uint256 i; i < _tokenIds.length; i++){
      erc1155Tokens.push(GiftLibrary.TokenWithID(_token, _tokenIds[i]));
    }
    return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
  }

  // @name Receive
  // @notice Allow receiving native token as gift
  receive() external payable virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// @name Gift Library
library GiftLibrary {
    //Track received ERC-721 / ERC-1155 tokens
    struct TokenWithID {
        address token;
        uint256 tokenId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./GiftLibrary.sol";
import "./interfaces/IGiftBox.sol";
import "./interfaces/IGiftRegistry.sol";

// @name Complex Gift Box
contract ComplexGiftBox is IGiftBox, ERC721Holder, ERC165 {

  address[] public erc20Tokens; //ERC20 token contracts of received/tracked tokens
  GiftLibrary.TokenWithID[] public erc721Tokens; //ERC721 token contracts of received/tracked tokens
  GiftLibrary.TokenWithID[] public erc1155Tokens; //ERC1155 token contracts of received/tracked tokens

  // --- Required configurations
  IGiftRegistry internal registry;
  address public recipient;
  address public from;

  // --- Optional configurations
  // Cannot be unwrapped until a certain date - default of 0 means redeem whenever
  uint256 public targetDate;
  // Cannot be unwrapped until a certain balance is met - default of 0 means redeem whenever
  uint256 public targetBalance;
  // Cannot be unwrapped until a certain token balance is met - defaults to no tokens
  address public targetToken;
  uint256 public targetTokenBalance;
  // Appoint conservator(s) that can reduce planned targets - defaults to no conservators
  mapping(address => bool) public isConservator;

  constructor(address _registry, address _recipient, address _from, address _conservator, uint256 _targetDate, uint256 _targetBalance, address _targetToken, uint256 _targetTokenBalance) {
    registry = IGiftRegistry(_registry);
    recipient = _recipient;
    from = _from;

    // Initialize any optional parameters
    if(_conservator != address(0)){
      isConservator[_conservator] = true;
    }

    targetDate = _targetDate;
    targetBalance = _targetBalance;

    if(_targetToken != address(0)){
      targetToken = _targetToken;
      targetTokenBalance = _targetTokenBalance;
    }
  }

  modifier isGiftReady() {
    require(msg.sender == recipient, "Only recipient can unwrap");
    require(block.timestamp >= targetDate, "Gift not ready yet");
    require(address(this).balance >= targetBalance, "Gift not ready yet");
    if(targetToken != address(0)){
      IERC20 token = IERC20(targetToken);
      if(token.balanceOf(address(this)) < targetTokenBalance){
        revert("Gift not ready yet");
      }
    }
    _;
  }

  // @name Unwrap Gift
  // @notice Recipient can call if gift is ready to receive all gifted assets
  function unwrap() public virtual isGiftReady {
    // Send native token
    if(address(this).balance > 0){
      payable(recipient).transfer(address(this).balance);
    }

    // Send ERC-20 and ERC-777 tokens
    for(uint256 i = 0; i < erc20Tokens.length; i++){
      IERC20 token = IERC20(erc20Tokens[i]);
      token.transfer(recipient, token.balanceOf(address(this)));
    }

    // Send ERC-721 tokens
    for(uint256 j = 0; j < erc721Tokens.length; j++){
      GiftLibrary.TokenWithID memory giftedToken = erc721Tokens[j];
      IERC721 token = IERC721(giftedToken.token);
      token.safeTransferFrom(address(this), recipient, giftedToken.tokenId);
    }

    // Send ERC-1155 tokens
    for(uint256 k = 0; k < erc1155Tokens.length; k++){
      GiftLibrary.TokenWithID memory giftedToken = erc1155Tokens[k];
      IERC1155 token = IERC1155(giftedToken.token);
      uint256 balance = token.balanceOf(address(this), giftedToken.tokenId);
      token.safeTransferFrom(address(this), recipient, giftedToken.tokenId, balance, ""); //TODO: where to get data
    }

    //Remove from registry
    registry.deregisterGiftBox(recipient);
  }

  // @name Re-Gift
  // @notice Allows recipient to transfer gift to new address
  function reGift(address _newRecipient) external {
    require(msg.sender == recipient, "Only recipient can re-gift");
    recipient = _newRecipient;
  }

  // @name Add Conservator
  function addConservator(address _conservator) external {
    require(isConservator[msg.sender], "Only conservator can add other conservators");
    require(_conservator != address(0), "Zero address can not be a conservator");
    isConservator[_conservator] = true;
    registry.registerNewConservator(_conservator);
  }

  //Conservator + TargetBalance functionality
  function reduceTargetBalance(uint256 _targetBalance) external {
    require(_targetBalance < targetBalance, "Can only reduce target");
    require(isConservator[msg.sender], "Only conservator can reduce");
    targetBalance = _targetBalance;
  }

  // @name Allow ERC20 Token
  // @dev Can be called before or after receiving the token, only need to call once per token type being gifted
  function allowERC20(address _token) external {
    erc20Tokens.push(_token);
  }

  // Allow receiving ERC721 tokens for gift box
  function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) public override returns(bytes4){
    erc721Tokens.push(GiftLibrary.TokenWithID(msg.sender, _tokenId));
    return super.onERC721Received(_operator, _from, _tokenId, _data);
  }

  // Support for receiving ERC-777
  function tokensReceived(address _operator, address, address, uint256, bytes memory, bytes memory)
  public {
    erc20Tokens.push(_operator);
  }

  // Support for receiving ERC-1155
  function onERC1155Received(address _token, address, uint256 _tokenId, uint256, bytes calldata) public override returns (bytes4) {
    erc1155Tokens.push(GiftLibrary.TokenWithID(_token, _tokenId));
    return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
  }

  // Support for receiving ERC-1155 batches
  function onERC1155BatchReceived(address _token, address, uint256[] calldata _tokenIds, uint256[] calldata, bytes calldata)
  external override returns (bytes4){
    for(uint256 i; i < _tokenIds.length; i++){
      erc1155Tokens.push(GiftLibrary.TokenWithID(_token, _tokenIds[i]));
    }
    return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
  }

  // @name Receive
  // @notice Allow receiving native token as gift
  receive() external payable virtual {}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC777/IERC777Recipient.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777TokensRecipient standard as defined in the EIP.
 *
 * Accounts can be notified of {IERC777} tokens being sent to them by having a
 * contract implement this interface (contract holders can be their own
 * implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Recipient {
    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}