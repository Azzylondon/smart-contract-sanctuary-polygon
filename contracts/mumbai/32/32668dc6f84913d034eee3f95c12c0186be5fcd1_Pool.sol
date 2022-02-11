// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC1363Receiver} from "../ERC/IERC1363Receiver.sol";
import {Master} from "../Master/Master.sol";
import {ListingGateway} from "../Gateway/ListingGateway.sol";
import {PlatformData} from "../Data/PlatformData.sol";
import {IDaiPermit} from "../ERC/IDaiPermit.sol";
import {EIP712} from "../EIP/EIP712.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Pool is IERC1363Receiver, Master, Initializable {
    // using SafeERC20 for ERC20;

    // State Variables
    ListingGateway private lg;
    PlatformData private platformData;
    ERC20Burnable internal infiToken;
    address public devWallet;
    address public daiTokenAddr;
    address public usdtTokenAddr;
    address public usdcTokenAddr;
    bytes32 public DOMAIN_SEPARATOR;

    // Constants
    bytes4 internal constant _INTERFACE_ID_ERC1363_RECEIVER = 0x88a7ca5c;
    bytes32 private constant COIN_TYPE_HASH =
        keccak256(
            "CoinPricingInfo(string coinId,string coinSymbol,uint256 coinPrice,uint256 lastUpdatedAt)"
        );
    bytes32 private constant CREATE_COVER_REQUEST =
        keccak256("CREATE_COVER_REQUEST");
    bytes32 private constant CREATE_COVER_OFFER =
        keccak256("CREATE_COVER_OFFER");

    // Event
    event TokensReceived(
        address indexed operator,
        address indexed from,
        uint256 value,
        bytes data
    );

    function initialize() public initializer {
        DOMAIN_SEPARATOR = EIP712.makeDomainSeparator("insured-finance", "v1");
    }

    function changeDependentContractAddress() external {
        // Only admin allowed to call this function
        require(
            IAccessControl(address(cg)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "ERR_AUTH_1"
        );
        infiToken = ERC20Burnable(cg.infiTokenAddr());
        lg = ListingGateway(cg.getLatestAddress("LG"));
        devWallet = cg.getLatestAddress("DW");
        daiTokenAddr = cg.getLatestAddress("DT");
        usdtTokenAddr = cg.getLatestAddress("UT");
        usdcTokenAddr = cg.getLatestAddress("UC");
        platformData = PlatformData(cg.getLatestAddress("PD"));
    }

    /**
     * @dev function only able to call by InfiToken Smart Contract when user create Cover Request & Cover Offer
     * read : https://github.com/vittominacori/erc1363-payable-token/blob/master/contracts/token/ERC1363/IERC1363Receiver.sol
     */
    function onTransferReceived(
        address operator,
        address from,
        uint256 value,
        bytes memory data
    ) external override returns (bytes4) {
        require(msg.sender == address(infiToken), "ERR_AUTH_2"); // Only specific token accepted (on this case only INFI)

        // Emit Event
        emit TokensReceived(operator, from, value, data);

        // Decode bytes data
        (bytes32 payType, bytes memory payData) = abi.decode(
            data,
            (bytes32, bytes)
        );

        if (payType == CREATE_COVER_REQUEST) {
            lg.createCoverRequest(from, value, payData);
        } else if (payType == CREATE_COVER_OFFER) {
            lg.createCoverOffer(from, value, payData);
        } else {
            revert("ERC1363Receiver: INVALID_PAY_TYPE");
        }

        return _INTERFACE_ID_ERC1363_RECEIVER;
    }

    /**
     * @dev Burn half of listing fee & transfer half of listing fee to developer wallet
     */
    function transferAndBurnInfi(uint256 listingFee) external onlyInternal {
        // Calculation half of listing fee
        uint256 halfListingFee = listingFee / 2;
        infiToken.burn(halfListingFee); // burn half of listing fee
        if (listingFee % 2 == 1) {
            require(
                infiToken.transfer(devWallet, (halfListingFee + 1)),
                "Infi : transfer failed"
            ); // transfer to dev wallet + 1
        } else {
            require(
                infiToken.transfer(devWallet, halfListingFee),
                "Infi : transfer failed"
            ); // transfer to dev wallet
        }
    }

    /**
     * @dev Calculate listing fee (in infi token)
     * NOTE : This one need to take price from chainlink
     */
    function getListingFee(
        CurrencyType insuredSumCurrency,
        uint256 insuredSum,
        uint256 feeCoinPrice,
        uint80 roundId
    ) external view returns (uint256) {
        uint256 feeCoinPriceDecimal = 6;
        // uint insuredSumInUSD = insuredSum * insuredSumCurrencyPriceOnCL / 10**insuredSumCurrencyDecimalOnCL / 10**insuredSumCurrencyDecimal; // insuredSum in USD
        // uint insuredSumInInfi = insuredSumInUSD * 10**feeCoinPriceDecimal / feeCoinPrice;
        // uint listingFeeInInfi = insuredSumInInfi / 100;  // 1% of insured sum
        // 100_000_000 * 10_000 * 1_000_000 * 10**18 / 100_000 / 100 / 10_000 / 1_000_000

        uint256 insuredSumCurrencyDecimal = cg.getCurrencyDecimal(
            uint8(insuredSumCurrency)
        );

        // Get price on chainlink
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            platformData.getOraclePriceFeedAddress(
                cg.getCurrencyName(uint8(insuredSumCurrency))
            )
        );
        (, int256 insuredSumCurrencyPriceOnCL, , , ) = priceFeed.getRoundData(
            roundId
        );

        return
            (insuredSum *
                uint256(insuredSumCurrencyPriceOnCL) *
                10**feeCoinPriceDecimal *
                10**infiToken.decimals()) /
            feeCoinPrice /
            100 /
            10**priceFeed.decimals() /
            10**insuredSumCurrencyDecimal;
    }

    /**
     * @dev Used for transfer token from External Account to this smart contract
     * Called on Create Request, Create Offer, Take Request & Take Offer
     * Only accept DAI, USDT & USDC
     */
    function acceptAsset(
        address from,
        CurrencyType currentyType,
        uint256 amount,
        bytes memory premiumPermit
    ) external onlyInternal {
        if (currentyType == CurrencyType.DAI) {
            // Approve
            DAIPermit memory permitData = abi.decode(
                premiumPermit,
                (DAIPermit)
            );
            IDaiPermit(daiTokenAddr).permit(
                permitData.holder,
                permitData.spender,
                permitData.nonce,
                permitData.expiry,
                permitData.allowed,
                permitData.sigV,
                permitData.sigR,
                permitData.sigS
            );
            // Transfer from member to smart contract
            require(
                IDaiPermit(daiTokenAddr).transferFrom(
                    from,
                    address(this),
                    amount
                ),
                "DAI : accept asset failed"
            );
        } else if (currentyType == CurrencyType.USDT) {
            // ERC20(usdtTokenAddr).safeTransferFrom(from, address(this), amount);
        } else if (currentyType == CurrencyType.USDC) {
            // Approve
            EIP2612Permit memory permitData = abi.decode(
                premiumPermit,
                (EIP2612Permit)
            );
            IERC20Permit(usdcTokenAddr).permit(
                permitData.owner,
                permitData.spender,
                permitData.value,
                permitData.deadline,
                permitData.sigV,
                permitData.sigR,
                permitData.sigS
            );
            // Transfer from member to smart contract
            require(
                IERC20(usdcTokenAddr).transferFrom(from, address(this), amount),
                "USDC : accept asset failed"
            );
        }
    }

    /**
     * @dev Used for transfer token from this smart contract to External Account
     * Called on Send Premium to Funder, Claim & Refund
     * Only able to send DAI, USDT & USDC
     */
    function transferAsset(
        address to,
        CurrencyType currentyType,
        uint256 amount
    ) external onlyInternal {
        if (currentyType == CurrencyType.DAI) {
            require(
                IERC20(daiTokenAddr).transfer(to, amount),
                "DAI : transfer failed"
            );
        } else if (currentyType == CurrencyType.USDT) {
            // ERC20(usdtTokenAddr).safeTransfer(to, amount);
        } else if (currentyType == CurrencyType.USDC) {
            require(
                IERC20(usdcTokenAddr).transfer(to, amount),
                "USDC : transfer failed"
            );
        }
    }

    /**
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function verifyMessage(CoinPricingInfo memory coinPricing, address whose)
        external
        view
    {
        require(
            EIP712.recover(
                DOMAIN_SEPARATOR,
                coinPricing.sigV,
                coinPricing.sigR,
                coinPricing.sigS,
                hash(coinPricing)
            ) == whose,
            "ERR_SIGN_NOT_VALID"
        );
    }

    function hash(CoinPricingInfo memory coinPricing)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encode(
                COIN_TYPE_HASH,
                keccak256(bytes(coinPricing.coinId)),
                keccak256(bytes(coinPricing.coinSymbol)),
                coinPricing.coinPrice,
                coinPricing.lastUpdatedAt
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
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
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
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
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IERC1363Receiver Interface
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev Interface for any contract that wants to support transferAndCall or transferFromAndCall
 *  from ERC1363 token contracts as defined in
 *  https://eips.ethereum.org/EIPS/eip-1363
 */
interface IERC1363Receiver {

    /**
     * @notice Handle the receipt of ERC1363 tokens
     * @dev Any ERC1363 smart contract calls this function on the recipient
     * after a `transfer` or a `transferFrom`. This function MAY throw to revert and reject the
     * transfer. Return of other than the magic value MUST result in the
     * transaction being reverted.
     * Note: the token contract address is always the message sender.
     * @param operator address The address which called `transferAndCall` or `transferFromAndCall` function
     * @param sender address The address which are token transferred from
     * @param amount uint256 The amount of tokens transferred
     * @param data bytes Additional data with no specified format
     * @return `bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))` unless throwing
     */
    function onTransferReceived(address operator, address sender, uint256 amount, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {IConfig} from "./IConfig.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract Master {
    // Used publicly
    IConfig internal cg;
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

    // Storage and Payload
    enum CoverType {
        SMART_PROTOCOL_FAILURE,
        STABLECOIN_DEVALUATION,
        CUSTODIAN_FAILURE,
        RUGPULL_LIQUIDITY_SCAM
    }
    enum CurrencyType {
        USDT,
        USDC,
        DAI,
        END_ENUM
    }
    enum InsuredSumRule {
        PARTIAL,
        FULL
    }
    enum ListingType {
        REQUEST,
        OFFER
    }

    enum ClaimState {
        MONITORING,
        INVALID,
        VALID,
        INVALID_AFTER_EXPIRED,
        VALID_AFTER_EXPIRED
    }

    // For passing parameter and store state variables
    struct CoverRequest {
        uint256 coverQty; // coverQty decimals depends on coinIdToDecimals mapping
        uint8 coverMonths; // represent month value 1-12
        uint256 insuredSum;
        uint256 insuredSumTarget; // if full funding : insuredSum - 2$
        CurrencyType insuredSumCurrency;
        uint256 premiumSum;
        CurrencyType premiumCurrency;
        uint256 expiredAt; // now + 14 days
        string coinId; // CoinGecko
        CoverLimit coverLimit;
        InsuredSumRule insuredSumRule;
        address holder; // may validate or not validate if same as msg.sender
    }

    // For passing parameter and store state variables
    struct CoverOffer {
        uint8 minCoverMonths; // represent month value 1-12 (expiredAt + 1 month - now >= minCoverMonths)
        uint256 insuredSum;
        CurrencyType insuredSumCurrency;
        uint256 premiumCostPerMonth; // $0.02 per $1 insured per Month (2000) a.k.a Premium Cost Per month per asset
        CurrencyType premiumCurrency;
        // IMPORTANT: max date for buying cover = expiredAt + 1 month
        uint256 expiredAt; // despositEndDate - 14 days beforeDepositEndDate
        string coinId; // CoinGecko
        CoverLimit coverLimit;
        InsuredSumRule insuredSumRule;
        address funder; // may validate or not validate if same as msg.sender
    }

    // Storage struct
    // Relationship: CoverCoverOffer ||--< Cover
    // Relationship: CoverRequest ||--< Cover
    // Relationship: One cover can have only one offer
    // Relationship: One cover can have only one request
    struct InsuranceCover {
        // type computed from (offerId != 0) or (requestId != 0)

        // If BuyCover (take offer)
        uint256 offerId; // from BuyCover.offerId
        // If CoverFunding (take request)
        uint256 requestId; // from CoverFunding.requestId
        // uint[] provideIds;

        ListingType listingType;
        // will validate claimSender
        address holder; // from BuyCover.buyer or CoverRequest.buyer
        // will validate maximum claimSum
        uint256 insuredSum; // from BuyCover.insuredSum or sum(CoverFunding.fundingSum)
        // will validate maximum claimQuantity
        uint256 coverQty; // from BuyCover.coverQty or CoverRequest.coverQty
    }

    // Storage: "Booking" object when take request
    // Relationship: CoverRequest ||--< CoverFunding
    struct CoverFunding {
        uint256 requestId;
        address funder;
        // insurance data:
        uint256 fundingSum; // part or portion of total insuredSum
    }

    // Payload: object when take offer
    // Virtual struct/type for payload (type of payloadBuyCover)
    struct BuyCover {
        uint256 offerId;
        address buyer;
        // insurance data:
        uint8 coverMonths; // represent month value 1-12
        uint256 coverQty; // coverQty decimals depends on coinIdToDecimals mapping
        uint256 insuredSum; // need validation : coverQty * assetPricing.coinPrice
        CoinPricingInfo assetPricing;
        bytes premiumPermit;
    }

    // Payload: object when take request
    // Virtual struct/type for payload (type of payloadBuyCover)
    struct ProvideCover {
        uint256 requestId;
        address provider;
        // insurance data:
        uint256 fundingSum;
        CoinPricingInfo assetPricing;
        bytes assetPermit;
    }

    // For passing Coin and Listing Fee info, required for validation
    struct CoinPricingInfo {
        string coinId;
        string coinSymbol;
        uint256 coinPrice; // decimals 6
        uint256 lastUpdatedAt;
        uint8 sigV;
        bytes32 sigR;
        bytes32 sigS;
    }

    struct CoverLimit {
        CoverType coverType;
        uint256[] territoryIds; // Platform Id, Price Feed Id, Custodian Id , (Dex Pool Id not Yet implemented)
    }

    struct Platform {
        string name;
        string website;
    }

    struct Oracle {
        string name;
        string website;
    }

    struct PriceFeed {
        uint256 oracleId;
        uint256 chainId;
        uint8 decimals;
        address proxyAddress;
    }

    struct Custodian {
        string name;
        string website;
    }

    struct EIP2612Permit {
        address owner;
        uint256 value;
        address spender;
        uint256 deadline;
        uint8 sigV;
        bytes32 sigR;
        bytes32 sigS;
    }

    struct DAIPermit {
        address holder;
        address spender;
        uint256 nonce;
        uint256 expiry;
        bool allowed;
        uint8 sigV;
        bytes32 sigR;
        bytes32 sigS;
    }

    struct CreateCoverRequestData {
        CoverRequest request; //
        CoinPricingInfo assetPricing; //
        CoinPricingInfo feePricing; //
        uint80 roundId; // insured sum to usd for calculate fee price
        bytes premiumPermit; // for transfer DAI, USDT, USDC
    }

    struct CreateCoverOfferData {
        CoverOffer offer; //
        CoinPricingInfo assetPricing;
        uint8 depositPeriod;
        CoinPricingInfo feePricing; //
        uint80 roundId; // insured sum to usd for calculate fee price
        bytes fundingPermit; // for transfer DAI, USDT, USDC
    }

    // Structs
    struct Claim {
        uint80 roundId; // round id that represent start of dropping value
        uint256 claimTime;
        uint256 payout;
        ClaimState state;
    }

    struct CollectiveClaim {
        uint80 roundId; // round id that represent start of dropping value
        uint256 claimTime;
        uint256 payout;
        ClaimState state;
    }

    // Modifier
    modifier onlyInternal() {
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
        _;
    }

    /**
     * @dev change config contract address
     * @param configAddress is the new address
     */
    function changeConfigAddress(address configAddress) external {
        // Only admin allowed to call this function
        if (address(cg) != address(0)) {
            require(
                IAccessControl(address(cg)).hasRole(
                    DEFAULT_ADMIN_ROLE,
                    msg.sender
                ),
                "ERR_AUTH_1"
            );
        }
        // Change config address
        cg = IConfig(configAddress);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ListingData} from "../Data/ListingData.sol";
import {ClaimData} from "../Data/ClaimData.sol";
import {PlatformData} from "../Data/PlatformData.sol";
import {Master} from "../Master/Master.sol";
import {CoverGateway} from "./CoverGateway.sol";
import {CoverData} from "../Data/CoverData.sol";
import {Pool} from "../Capital/Pool.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract ListingGateway is Master {
    CoverData private cd;
    ListingData private ld;
    ClaimData private claimData;
    CoverGateway private coverGateway;
    Pool private pool;
    PlatformData private platformData;
    ERC20Burnable internal infiToken;
    address public coinSigner;

    /**
    @dev Check balance of member/sender, minimal have 5000 Infi token. Used in Create Offer, Take Offer and Take Request
    @param _from member/sender's address
    @param _tokenAmount amount of token that used for create listing (will be 0 for take offer and take request)
     */
    modifier minimumBalance(address _from, uint256 _tokenAmount) {
        uint256 tokenAfterTransfer = infiToken.balanceOf(_from);
        uint256 tokenBeforeTransfer = tokenAfterTransfer + _tokenAmount;
        uint256 infiTokenDecimal = 18;
        require(
            tokenBeforeTransfer >= (5000 * (10**infiTokenDecimal)),
            "ERR_AUTH_4"
        );
        _;
    }

    /**
     @dev Tier system for check capability of member
     @param _from member's address
     @param _tokenAmount amount of infi token that transfered
     @param _insuredSum value of asset in USD
     @param _currencyType insuredsum's currency
     */
    modifier verifyMemberLevel(
        address _from,
        uint256 _tokenAmount,
        uint256 _insuredSum,
        CurrencyType _currencyType
    ) {
        uint256 tokenAfterTransfer = infiToken.balanceOf(_from);
        uint256 tokenBeforeTransfer = tokenAfterTransfer + _tokenAmount;
        uint256 infiTokenDecimal = 18;
        uint256 insuredSumCurrencyDecimal = cg.getCurrencyDecimal(
            uint8(_currencyType)
        );

        if (_insuredSum <= (10000 * (10**insuredSumCurrencyDecimal))) {
            // Bronze
            require(
                tokenBeforeTransfer >= (5000 * (10**infiTokenDecimal)),
                "ERR_AUTH_4"
            );
        } else if (_insuredSum <= (50000 * (10**insuredSumCurrencyDecimal))) {
            // Silver
            require(
                tokenBeforeTransfer >= (10000 * (10**infiTokenDecimal)),
                "ERR_AUTH_4"
            );
        } else if (_insuredSum <= (100000 * (10**insuredSumCurrencyDecimal))) {
            // Gold
            require(
                tokenBeforeTransfer >= (25000 * (10**infiTokenDecimal)),
                "ERR_AUTH_4"
            );
        } else if (_insuredSum > (100000 * (10**insuredSumCurrencyDecimal))) {
            // Diamond
            require(
                tokenBeforeTransfer >= (50000 * (10**infiTokenDecimal)),
                "ERR_AUTH_4"
            );
        }

        _;
    }

    function changeDependentContractAddress() external {
        // Only admin allowed to call this function
        require(
            IAccessControl(address(cg)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "ERR_AUTH_1"
        );
        ld = ListingData(cg.getLatestAddress("LD"));
        infiToken = ERC20Burnable(cg.infiTokenAddr());
        coverGateway = CoverGateway(cg.getLatestAddress("CG"));
        cd = CoverData(cg.getLatestAddress("CD"));
        pool = Pool(cg.getLatestAddress("PL"));
        coinSigner = cg.getLatestAddress("CS");
        claimData = ClaimData(cg.getLatestAddress("CM"));
        platformData = PlatformData(cg.getLatestAddress("PD"));
    }

    /**
     * @dev Called when member create a new Cover Request Listing, to stored listing data
     */
    function createCoverRequest(
        address from,
        uint256 value,
        bytes memory payData
    ) external onlyInternal {
        CreateCoverRequestData memory payload = abi.decode(
            payData,
            (CreateCoverRequestData)
        );

        require(payload.request.holder == from, "ERR_LG_1");

        require(
            payload.request.coverMonths >= 1 &&
                payload.request.coverMonths <= 12,
            "ERR_LG_2"
        ); // Validate Cover Period

        // expired at must between now and next 1 year
        // add 1 day as buffer, in case transaction pending on mempool
        require(
            payload.request.expiredAt >= block.timestamp &&
                payload.request.expiredAt <=
                (block.timestamp + (14 * 1 days) + 1 days),
            "ERR_LG_3"
        );

        // Set Listing Fee
        uint256 listingFee = pool.getListingFee(
            payload.request.insuredSumCurrency,
            payload.request.insuredSum,
            payload.feePricing.coinPrice,
            payload.roundId
        );

        // Verify listing fee amount
        require(listingFee == value, "ERR_LG_4");

        // Transfer 50% of listing fee to dev wallet and burn 50%
        pool.transferAndBurnInfi(listingFee);

        // Verify Coin Info Signature
        pool.verifyMessage(payload.assetPricing, coinSigner); // Validate signature Asset Price
        pool.verifyMessage(payload.feePricing, coinSigner); // Validate signature Fee Price

        // Transfer Premium to smart contract
        pool.acceptAsset(
            from,
            payload.request.insuredSumCurrency,
            payload.request.premiumSum,
            payload.premiumPermit
        );

        // verify and stored data
        _createRequest(payload, from, value);
    }

    function _createRequest(
        CreateCoverRequestData memory payload,
        address from,
        uint256 value
    )
        internal
        verifyMemberLevel(
            from,
            value,
            payload.request.insuredSum,
            payload.request.insuredSumCurrency
        )
    {
        // Set up value for Request Cover
        if (payload.request.insuredSumRule == InsuredSumRule.FULL) {
            uint8 decimal = cg.getCurrencyDecimal(
                uint8(payload.request.insuredSumCurrency)
            );
            uint256 tolerance = 2 * (10**decimal); // tolerance 2 tokens
            payload.request.insuredSumTarget =
                payload.request.insuredSum -
                tolerance;
        } else if (payload.request.insuredSumRule == InsuredSumRule.PARTIAL) {
            payload.request.insuredSumTarget = payload.request.insuredSum / 4;
        }
        // Stored data listing
        ld.storedRequest(
            payload.request,
            payload.assetPricing,
            payload.feePricing,
            from
        );
    }

    /**
     * @dev Called when member create a new Cover Offer Listing, to stored listing data
     */

    function createCoverOffer(
        address from,
        uint256 value,
        bytes memory payData
    ) external onlyInternal {
        CreateCoverOfferData memory payload = abi.decode(
            payData,
            (CreateCoverOfferData)
        );

        // expired at must between now and next 1 year
        // add 1 day as buffer, in case transaction pending on mempool
        require(
            payload.offer.expiredAt >= block.timestamp &&
                payload.offer.expiredAt <=
                (block.timestamp + (366 days) + 1 days),
            "ERR_LG_3"
        );

        // verify funder
        require(payload.offer.funder == from, "ERR_LG_1");

        uint256 insuredSumCurrencyDecimal = cg.getCurrencyDecimal(
            uint8(payload.offer.insuredSumCurrency)
        );

        // minimal deposit $1000
        require(
            payload.offer.insuredSum >= (10**insuredSumCurrencyDecimal),
            "ERR_LG_5"
        );

        // Set Listing Fee
        uint256 listingFee = pool.getListingFee(
            payload.offer.insuredSumCurrency,
            payload.offer.insuredSum,
            payload.feePricing.coinPrice,
            payload.roundId
        );

        // Note : verify insured sum worth 1000$

        // Verify listing fee amount
        require(listingFee == value, "ERR_LG_4");

        // Transfer 50% of listing fee to dev wallet and burn 50%
        pool.transferAndBurnInfi(listingFee);

        // Verify Coin Info Signature
        pool.verifyMessage(payload.feePricing, coinSigner); // Validate signature Fee Price
        pool.verifyMessage(payload.assetPricing, coinSigner); // Validate signature Asset Price

        // Transfer collateral to current smart contract
        pool.acceptAsset(
            from,
            payload.offer.insuredSumCurrency,
            payload.offer.insuredSum,
            payload.fundingPermit
        );

        // verify and stored data
        _createOffer(payload, from, value);
    }

    function _createOffer(
        CreateCoverOfferData memory payload,
        address from,
        uint256 value
    ) internal minimumBalance(from, value) {
        // Stored data listing
        ld.storedOffer(
            payload.offer,
            payload.feePricing,
            payload.assetPricing,
            payload.depositPeriod,
            from
        );
    }

    /**
     * @dev get list of id(s) of active cover offer
     */
    function getListActiveCoverOffer()
        external
        view
        returns (uint256 listLength, uint256[] memory coverOfferIds)
    {
        // Because "push" is not available in uint256[] memory outside of storage
        // Need to create workaround for push to array
        uint256 coverOfferLength = ld.getCoverOfferLength();
        coverOfferIds = new uint256[](coverOfferLength);
        uint256 iteration = 0;

        for (uint256 i = 0; i < coverOfferLength; i++) {
            CoverOffer memory coverOffer = ld.getCoverOfferById(i);
            if (coverOffer.expiredAt >= block.timestamp) {
                coverOfferIds[iteration] = i;
                iteration = iteration + 1;
            }
        }

        return (iteration, coverOfferIds);
    }

    /**
     * @dev get insured sum taken, return value will based on calculation of covers
     */
    function getInsuredSumTakenOfCoverOffer(uint256 coverOfferId)
        external
        view
        returns (uint256 insuredSumTaken)
    {
        uint256[] memory listCoverIds = cd.getCoversByOfferId(coverOfferId);

        for (uint256 i = 0; i < listCoverIds.length; i++) {
            if (block.timestamp < coverGateway.getEndAt(listCoverIds[i])) {
                InsuranceCover memory cover = cd.getCoverById(listCoverIds[i]);
                // Cover still active
                insuredSumTaken += cover.insuredSum;
            } else {
                // Cover not active, check the payout for the cover
                insuredSumTaken += claimData.coverToPayout(listCoverIds[i]);
            }
        }
    }

    function getChainlinkPrice(uint8 currencyType)
        external
        view
        returns (
            uint80 roundId,
            int256 price,
            uint8 decimals
        )
    {
        require(currencyType < uint8(CurrencyType.END_ENUM), "ERR_CHNLNK_2");
        address priceFeedAddr = platformData.getOraclePriceFeedAddress(
            cg.getCurrencyName(currencyType)
        );
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddr);
        (roundId, price, , , ) = priceFeed.latestRoundData();
        decimals = priceFeed.decimals();
        return (roundId, price, decimals);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Master} from "../Master/Master.sol";

contract PlatformData is Master {
    // State variables
    Platform[] public platforms;
    Oracle[] public oracles;
    PriceFeed[] public usdPriceFeeds;
    Custodian[] public custodians;
    mapping(string => uint256[]) internal symbolToUsdPriceFeeds;

    // Events
    event NewPlatform(uint256 id, string name, string website);
    event NewOracle(uint256 id, string name, string website);
    event NewCustodian(uint256 id, string name, string website);
    event NewPriceFeed(
        string symbol,
        uint256 usdPriceFeedsId,
        uint256 oracleId,
        uint256 chainId,
        uint8 decimals,
        address proxyAddress
    );

    /**
     * @dev Add New Platform
     */
    function addNewPlatform(string calldata name, string calldata website)
        external
    {
        // Only admin allowed to call
        require(
            IAccessControl(address(cg)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "ERR_AUTH_1"
        );

        // Store Data
        platforms.push(Platform(name, website));
        uint256 platformId = platforms.length - 1;
        emit NewPlatform(platformId, name, website);
    }

    /**
     * @dev Add New Oracle
     */
    function addNewOracle(string calldata name, string calldata website)
        external
    {
        // Only admin allowed to call
        require(
            IAccessControl(address(cg)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "ERR_AUTH_1"
        );

        // Store Data
        oracles.push(Oracle(name, website));
        uint256 oracleId = oracles.length - 1;
        emit NewOracle(oracleId, name, website);
    }

    /**
     * @dev Add New Custodians
     */
    function addNewCustodian(string calldata name, string calldata website)
        external
    {
        // Only admin allowed to call
        require(
            IAccessControl(address(cg)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "ERR_AUTH_1"
        );

        // Store Data
        custodians.push(Custodian(name, website));
        uint256 custodianId = custodians.length - 1;
        emit NewCustodian(custodianId, name, website);
    }

    /**
     * @dev Add New Price Feed
     */
    function addNewPriceFeed(
        string calldata symbol,
        uint256 oracleId,
        uint256 chainId,
        uint8 decimals,
        address proxyAddress
    ) external {
        // Only admin allowed to call
        require(
            IAccessControl(address(cg)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "ERR_AUTH_1"
        );

        // Store Data
        usdPriceFeeds.push(
            PriceFeed(oracleId, chainId, decimals, proxyAddress)
        );
        uint256 usdPriceFeedsId = usdPriceFeeds.length - 1;
        symbolToUsdPriceFeeds[symbol].push(usdPriceFeedsId);
        emit NewPriceFeed(
            symbol,
            usdPriceFeedsId,
            oracleId,
            chainId,
            decimals,
            proxyAddress
        );
    }

    /**
     * @dev get price feed address by coin id/symbol
     * @dev coin id reference to coingecko
     */
    function getOraclePriceFeedAddress(string calldata symbol)
        external
        view
        returns (address)
    {
        uint256[] memory priceFeeds = symbolToUsdPriceFeeds[symbol];
        if (priceFeeds.length <= 0) {
            return address(0);
        } else {
            uint256 priceFeedId = priceFeeds[priceFeeds.length - 1];
            PriceFeed memory selectedPriceFeed = usdPriceFeeds[priceFeedId];
            return selectedPriceFeed.proxyAddress;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IDaiPermit {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);
}

/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2018-2020 CENTRE SECZ
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity ^0.8.0;

import { ECRecover } from "./ECRecover.sol";

/**
 * @title EIP712
 * @notice A library that provides EIP712 helper functions
 */
library EIP712 {
    /**
     * @notice Make EIP712 domain separator
     * @param name      Contract name
     * @param version   Contract version
     * @return Domain separator
     */
    function makeDomainSeparator(string memory name, string memory version)
        internal
        view
        returns (bytes32)
    {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return
            keccak256(
                abi.encode(
                    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
                    keccak256(bytes(name)),
                    keccak256(bytes(version)),
                    chainId,
                    address(this)
                )
            );
    }

    /**
     * @notice Recover signer's address from a EIP712 signature
     * @param domainSeparator   Domain separator
     * @param v                 v of the signature
     * @param r                 r of the signature
     * @param s                 s of the signature
     * @param typeHashAndData   Type hash concatenated with data
     * @return Signer's address
     */
    function recover(
        bytes32 domainSeparator,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes memory typeHashAndData
    ) internal pure returns (address) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(typeHashAndData)
            )
        );
        return ECRecover.recover(digest, v, r, s);
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
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

import "../IERC20.sol";

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IConfig {
    /**
     * @dev return address of Infi Token
     */
    function infiTokenAddr() external returns (address);

    /**
     * @dev return address of contract based on Initial Contract Name
     */
    function getLatestAddress(bytes2 _contractName)
        external
        returns (address payable contractAddress);

    /**
     * @dev check whether caller is internal smart contract
     * @dev internal smart contracts are smart contracts that used on Infi Project
     */
    function isInternal(address _add) external returns (bool);

    /**
     * @dev get decimals of given currency code/number
     */
    function getCurrencyDecimal(uint8 _currencyType)
        external
        view
        returns (uint8);

    /**
     * @dev get name of given currency code/number
     */
    function getCurrencyName(uint8 _currencyType)
        external
        view
        returns (string memory);

    function maxDevaluation() external view returns (uint256);

    function monitoringPeriod() external view returns (uint256);

    function maxPayoutPeriod() external view returns (uint256);

    function validationPreviousPeriod() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {Master} from "../Master/Master.sol";

contract ListingData is Master {
    // State Variable
    // Cover Request
    CoverRequest[] internal requests; // CoverRequest.id
    mapping(uint256 => uint256) public requestIdToInsuredSumTaken;
    mapping(address => uint256[]) internal buyerToRequests;
    mapping(string => uint256[]) internal coinIdToRequests;
    mapping(uint256 => uint256) public coverRequestFullyFundedAt;
    mapping(uint256 => bool) public requestIdToRefundPremium;
    mapping(uint256 => bool) public isDepositTakenBack; // coverId -> true/false
    // Cover Offer
    CoverOffer[] internal offers; // CoverOffer.id
    mapping(uint256 => uint256) public offerIdToInsuredSumTaken;
    mapping(address => uint256[]) internal funderToOffers;
    mapping(string => uint256[]) internal coinIdToOffers;
    mapping(uint256 => bool) public isDepositOfOfferTakenBack; // offer id => state of take back deposit

    // Events
    event CreateRequest(
        uint256 id,
        address indexed holder,
        CoverRequest request,
        CoinPricingInfo assetPricing,
        CoinPricingInfo feePricing
    );
    event CreateOffer(
        uint256 id,
        address indexed funder,
        CoverOffer coverOffer,
        CoinPricingInfo feePricing,
        CoinPricingInfo assetPricing,
        uint8 depositPeriod
    );
    event DepositOfOfferTakenBack(uint256 offerId);
    event DepositTakenBack(uint256 coverId);
    event RequestFullyFunded(uint256 requestId, uint256 fullyFundedAt);
    event PremiumRefunded(uint256 requestId);

    /**
     * @dev Save listing data of cover request
     */
    function storedRequest(
        CoverRequest memory inputRequest,
        CoinPricingInfo memory assetPricing,
        CoinPricingInfo memory feePricing,
        address member
    ) external {
        requests.push(inputRequest);
        uint256 requestId = requests.length - 1;
        buyerToRequests[member].push(requestId);
        coinIdToRequests[inputRequest.coinId].push(requestId);
        requestIdToInsuredSumTaken[requestId] = 0; // set insured sum taken to 0 as iniitial value
        emit CreateRequest(
            requestId,
            member,
            inputRequest,
            assetPricing,
            feePricing
        );
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Get cover request detail
     */
    function getCoverRequestById(uint256 requestId)
        external
        view
        returns (CoverRequest memory coverRequest)
    {
        return requests[requestId];
    }

    /**
     * @dev Get length of array contains Cover Request(s)
     */
    function getCoverRequestLength() external view returns (uint256) {
        return requests.length;
    }

    /**
     * @dev Save cover offer listing data
     */
    function storedOffer(
        CoverOffer memory inputOffer,
        CoinPricingInfo memory feePricing,
        CoinPricingInfo memory assetPricing,
        uint8 depositPeriod,
        address member
    ) external {
        offers.push(inputOffer);
        uint256 offerId = offers.length - 1;
        funderToOffers[member].push(offerId);
        coinIdToOffers[inputOffer.coinId].push(offerId);
        offerIdToInsuredSumTaken[offerId] = 0; // set insured sum remaining to 0 as initial
        emit CreateOffer(
            offerId,
            member,
            inputOffer,
            feePricing,
            assetPricing,
            depositPeriod
        );
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Get detail of Cover Offer
     */
    function getCoverOfferById(uint256 offerId)
        external
        view
        returns (CoverOffer memory coverOffer)
    {
        return offers[offerId];
    }

    /**
     * @dev Get list of offer id(s) that funded by member/funder
     */
    function getCoverOffersListByAddr(address member)
        external
        view
        returns (uint256[] memory)
    {
        return funderToOffers[member];
    }

    /**
     * @dev Get length of array contains Cover Offer(s)
     */
    function getCoverOfferLength() external view returns (uint256) {
        return offers.length;
    }

    /**
     * @dev Called when member take offer to update insured sum taken on Cover Offer
     */
    function updateOfferInsuredSumTaken(
        uint256 offerId,
        uint256 insuredSumTaken
    ) external {
        offerIdToInsuredSumTaken[offerId] = insuredSumTaken;
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Called when member take request to update insured sum taken on Cover Request
     */
    function updateRequestInsuredSumTaken(
        uint256 requestId,
        uint256 insuredSumTaken
    ) external {
        requestIdToInsuredSumTaken[requestId] = insuredSumTaken;
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Check whether Cover Request reach target
     * @dev For Partial : must reach minimal 25% of insured sum
     * @dev For Full : must react minimal 100% - 2 token of insured sum
     */
    function isRequestReachTarget(uint256 requestId)
        external
        view
        returns (bool)
    {
        CoverRequest memory request = requests[requestId];
        return
            requestIdToInsuredSumTaken[requestId] >= request.insuredSumTarget;
    }

    /**
     * @dev Check whether Cover Request fully funded
     * @dev Must react minimal 100% - 2 token of insured sum
     */
    function isRequestFullyFunded(uint256 requestId)
        external
        view
        returns (bool)
    {
        CoverRequest memory request = requests[requestId];
        uint8 decimal = cg.getCurrencyDecimal(
            uint8(request.insuredSumCurrency)
        );
        uint256 tolerance = 2 * (10**decimal);

        return
            (request.insuredSum - requestIdToInsuredSumTaken[requestId]) <=
            tolerance;
    }

    /**
     * @dev Called when Cover Request fully funded
     */
    function setCoverRequestFullyFundedAt(
        uint256 requestId,
        uint256 fullyFundedAt
    ) external {
        coverRequestFullyFundedAt[requestId] = fullyFundedAt;
        emit RequestFullyFunded(requestId, fullyFundedAt);
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Called when holder refund premium
     * @dev Refund premium condition :
     * @dev Withdraw premium of fail Cover Request or Withdraw of remaining premium on Cover Request
     */
    function setRequestIdToRefundPremium(uint256 requestId) external {
        requestIdToRefundPremium[requestId] = true;
        emit PremiumRefunded(requestId);
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Called when funder refund/take back deposit
     * @dev Withdraw of remaining deposit on Cover Offer
     */
    function setDepositOfOfferTakenBack(uint256 offerId) external {
        isDepositOfOfferTakenBack[offerId] = true;
        emit DepositOfOfferTakenBack(offerId);
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Called when funder refund/take back deposit, to mark deposit had taken
     */
    function setIsDepositTakenBack(uint256 coverId) external {
        isDepositTakenBack[coverId] = true;
        emit DepositTakenBack(coverId);
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Get list of request id(s) that funded by member
     */
    function getBuyerToRequests(address holder)
        external
        view
        returns (uint256[] memory)
    {
        return buyerToRequests[holder];
    }

    /**
     * @dev Get list of offer id(s) that funded by member/funder
     */
    function getFunderToOffers(address funder)
        external
        view
        returns (uint256[] memory)
    {
        return funderToOffers[funder];
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {Master} from "../Master/Master.sol";

contract ClaimData is Master {
    // State variable
    Claim[] internal claims;
    mapping(uint256 => uint256[]) internal coverToClaims;
    mapping(uint256 => uint256) public claimToCover;

    CollectiveClaim[] internal collectiveClaims;
    mapping(uint256 => uint256[]) internal requestToCollectiveClaims;
    mapping(uint256 => uint256) public collectiveClaimToRequest;

    // total payout from claim of offer cover,
    // it will record how much payout already done for cover offer
    mapping(uint256 => uint256) public offerIdToPayout;
    mapping(uint256 => uint256) public coverToPayout;
    // Mapping status is valid claim exists on Insurance Cover
    // InsuranceCover.id => true/false
    mapping(uint256 => bool) public isValidClaimExistOnCover;
    // To make sure Cover from Take Offer only used unique roundId to claim
    // Mapping Insurance Cover ||--< Round Id => true/false
    mapping(uint256 => mapping(uint80 => bool)) public coverIdToRoundId;

    // it will record how much payout already done for cover request
    mapping(uint256 => uint256) public requestIdToPayout;
    // Mapping status is valid claim exists on Cover Request
    // CoverRequest.id => true/false
    mapping(uint256 => bool) public isValidClaimExistOnRequest;
    // To make sure Cover from Create Request only used unique roundId to claim
    // Mapping Cover Request ||--< ROund Id => true/false
    mapping(uint256 => mapping(uint80 => bool)) public requestIdToRoundId;

    // total amount of expired payout that owned by platform
    mapping(CurrencyType => uint256) public totalExpiredPayout;

    // Calculate pending claims
    mapping(uint256 => uint16) public offerToPendingClaims;
    mapping(uint256 => uint16) public coverToPendingClaims;
    mapping(uint256 => uint16) public requestToPendingCollectiveClaims;

    // Event
    event ClaimRaise(
        uint256 claimId,
        uint256 coverId,
        uint256 claimTime,
        address holder,
        uint80 roundId,
        uint256 roundTimestamp
    );
    event CollectiveClaimRaise(
        uint256 collectiveClaimId,
        uint256 requestId,
        uint256 claimTime,
        address holder,
        uint256 roundId,
        uint256 roundTimestamp
    );

    /**
     * @dev Create a new Claim
     */
    function addClaim(
        uint256 coverId,
        uint256 offerId,
        uint80 roundId,
        uint256 roundTimestamp,
        address holder
    ) external returns (uint256) {
        // Store Data Claim
        claims.push(Claim(roundId, block.timestamp, 0, ClaimState.MONITORING));
        uint256 claimId = claims.length - 1;
        coverToClaims[coverId].push(claimId);
        claimToCover[claimId] = coverId;
        coverToPendingClaims[coverId]++;
        offerToPendingClaims[offerId]++;

        // Emit event claim
        emit ClaimRaise(
            claimId,
            coverId,
            block.timestamp,
            holder,
            roundId,
            roundTimestamp
        );

        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");

        return claimId;
    }

    /**
     * @dev change payout value over Cover
     */
    function setCoverToPayout(uint256 coverId, uint256 payout) external {
        coverToPayout[coverId] += payout;
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev change payout value over Cover Offer
     */
    function setOfferIdToPayout(uint256 offerId, uint256 payout) external {
        offerIdToPayout[offerId] += payout;
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Get list of claim id(s) over cover
     */
    function getCoverToClaims(uint256 coverId)
        external
        view
        returns (uint256[] memory)
    {
        return coverToClaims[coverId];
    }

    function setCoverIdToRoundId(uint256 coverId, uint80 roundId) external {
        coverIdToRoundId[coverId][roundId] = true;
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    function updateClaimState(
        uint256 claimId,
        uint256 offerId,
        ClaimState state
    ) external {
        Claim storage claim = claims[claimId];

        if (
            state != ClaimState.MONITORING &&
            claim.state == ClaimState.MONITORING
        ) {
            coverToPendingClaims[claimToCover[claimId]]--;
            offerToPendingClaims[offerId]--;
        }
        // Update state of Claim
        claim.state = state;

        // Update state of mark Valid  Claim existance
        if (state == ClaimState.VALID) {
            isValidClaimExistOnCover[claimToCover[claimId]] = true;
        }
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Get Claim Detail
     */
    function getClaimById(uint256 claimId)
        external
        view
        returns (Claim memory)
    {
        return claims[claimId];
    }

    /**
     * @dev Called when user create claim over Cover Request
     */
    function addCollectiveClaim(
        uint256 requestId,
        uint80 roundId,
        uint256 roundTimestamp,
        address holder
    ) external returns (uint256) {
        collectiveClaims.push(
            CollectiveClaim(roundId, block.timestamp, 0, ClaimState.MONITORING)
        );
        uint256 collectiveClaimId = collectiveClaims.length - 1;
        requestToCollectiveClaims[requestId].push(collectiveClaimId);
        collectiveClaimToRequest[collectiveClaimId] = requestId;
        requestToPendingCollectiveClaims[requestId]++;

        emit CollectiveClaimRaise(
            collectiveClaimId,
            requestId,
            block.timestamp,
            holder,
            roundId,
            roundTimestamp
        );

        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");

        return collectiveClaimId;
    }

    function setRequestIdToRoundId(uint256 requestId, uint80 roundId) external {
        requestIdToRoundId[requestId][roundId] = true;
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    function setIsValidClaimExistOnRequest(uint256 requestId) external {
        isValidClaimExistOnRequest[requestId] = true;
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Used for update claim status to INVALID, VALID, INVALID_AFTER_EXPIRED & VALID_AFTER_EXPIRED
     */
    function updateCollectiveClaimState(
        uint256 collectiveClaimId,
        ClaimState state
    ) external {
        CollectiveClaim storage collectiveClaim = collectiveClaims[
            collectiveClaimId
        ];

        // Decrease number of pending claims on Cover Request
        if (
            state != ClaimState.MONITORING &&
            collectiveClaim.state == ClaimState.MONITORING
        ) {
            requestToPendingCollectiveClaims[
                collectiveClaimToRequest[collectiveClaimId]
            ]--;
        }

        // Update state
        collectiveClaim.state = state;

        // Give a mark
        if (state == ClaimState.VALID) {
            isValidClaimExistOnRequest[
                collectiveClaimToRequest[collectiveClaimId]
            ] = true;
        }

        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev change payout value over Cover Request
     */
    function setRequestIdToPayout(uint256 requestId, uint256 payout) external {
        requestIdToPayout[requestId] += payout;
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Get detail of collective claim
     */
    function getCollectiveClaimById(uint256 collectiveClaimId)
        external
        view
        returns (CollectiveClaim memory)
    {
        return collectiveClaims[collectiveClaimId];
    }

    /**
     * @dev Add total payout for valid expired claim
     * @dev totalExpiredPayout variable contain amount of token that own by dev because valid claim is expired
     */
    function addTotalExpiredPayout(CurrencyType currencyType, uint256 amount)
        external
    {
        totalExpiredPayout[currencyType] += amount;
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Set total payout to 0, called when developer withdraw token of expired calid claim
     */
    function resetTotalExpiredPayout(CurrencyType currencyType) external {
        totalExpiredPayout[currencyType] = 0;
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    function getRequestToCollectiveClaims(uint256 requestId)
        external
        view
        returns (uint256[] memory)
    {
        return requestToCollectiveClaims[requestId];
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Master} from "../Master/Master.sol";
import {CoverData} from "../Data/CoverData.sol";
import {ListingData} from "../Data/ListingData.sol";
import {Pool} from "../Capital/Pool.sol";
import {ListingGateway} from "./ListingGateway.sol";

contract CoverGateway is Master {
    // State variables
    CoverData private cd;
    ListingData private ld;
    Pool private pool;
    ListingGateway private lg;
    address public coinSigner;
    address public devWallet;
    ERC20Burnable internal infiToken;

    /**
    @dev Check balance of member/sender, minimal have 5000 Infi token. Used in Create Offer, Take Offer and Take Request
    @param _from member/sender's address
    @param _tokenAmount amount of token that used for create listing (will be 0 for take offer and take request)
     */
    modifier minimumBalance(address _from, uint256 _tokenAmount) {
        uint256 tokenAfterTransfer = infiToken.balanceOf(_from);
        uint256 tokenBeforeTransfer = tokenAfterTransfer + _tokenAmount;
        uint256 infiTokenDecimal = 18;
        require(
            tokenBeforeTransfer >= (5000 * (10**infiTokenDecimal)),
            "ERR_AUTH_4"
        );
        _;
    }

    function changeDependentContractAddress() external {
        // Only admin allowed to call this function
        require(
            IAccessControl(address(cg)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "ERR_AUTH_1"
        );
        cd = CoverData(cg.getLatestAddress("CD"));
        ld = ListingData(cg.getLatestAddress("LD"));
        lg = ListingGateway(cg.getLatestAddress("LG"));
        pool = Pool(cg.getLatestAddress("PL"));
        coinSigner = cg.getLatestAddress("CS");
        devWallet = cg.getLatestAddress("DW");
        infiToken = ERC20Burnable(cg.infiTokenAddr());
    }

    /**
     * @dev Called when member take an offer
     */
    function buyCover(BuyCover calldata buyCoverData)
        external
        minimumBalance(msg.sender, 0)
    {
        // Get listing data
        CoverOffer memory offer = ld.getCoverOfferById(buyCoverData.offerId);

        // Funder cannot buy own offer
        require(msg.sender != offer.funder, "ERR_CG_1");

        // Check if offer still valid
        require(block.timestamp <= offer.expiredAt, "ERR_CG_2");
        require(buyCoverData.coverMonths >= offer.minCoverMonths, "ERR_CG_3");

        // Check if offer still be able to take (not biggetrthan offer.insuredSumRemaining)
        require(
            buyCoverData.insuredSum <=
                (offer.insuredSum -
                    lg.getInsuredSumTakenOfCoverOffer(buyCoverData.offerId)),
            "ERR_CG_4"
        );

        // verify assetPriceInfo signature
        pool.verifyMessage(buyCoverData.assetPricing, coinSigner);

        //  Validate insured sum
        uint256 insuredSumCurrencyDecimal = cg.getCurrencyDecimal(
            uint8(offer.insuredSumCurrency)
        );

        // Check cover qty validity
        require(buyCoverData.coverQty / 10**18 > 0, "ERR_CLG_28");

        uint256 calculationInsuredSum = (buyCoverData.coverQty *
            10**insuredSumCurrencyDecimal) / // make result to insuredSumDecimals
            buyCoverData.assetPricing.coinPrice / // to convert to insured sum price
            (10**(12)); // 10**12 is coming from 10**18/10**6, 10**18 => coverQty Decimals, 10**6 => Coin Price decimals

        require(
            (buyCoverData.insuredSum - calculationInsuredSum) <= 10**18,
            "ERR_CG_5"
        );

        // If full uptake
        if (offer.insuredSumRule == InsuredSumRule.FULL) {
            require(offer.insuredSum == buyCoverData.insuredSum, "ERR_CG_6");
        }

        // Collect Premium, Premium Currenty will follow CoverOffer.premiumCostPerMonth
        uint256 premiumCurrencyDecimal = cg.getCurrencyDecimal(
            uint8(offer.premiumCurrency)
        );
        uint256 totalPremium = (buyCoverData.coverQty *
            offer.premiumCostPerMonth *
            buyCoverData.coverMonths) / 10**18; // 10**18 is cover qty decimal

        // Check total premium amount
        require(totalPremium > 0, "ERR_CLG_29");

        // Accept Asset from buyer to pool
        pool.acceptAsset(
            msg.sender,
            offer.premiumCurrency,
            totalPremium,
            buyCoverData.premiumPermit
        );

        // Transfer Premium to Provider (80%) and Dev (20%)
        pool.transferAsset(
            offer.funder,
            offer.premiumCurrency,
            (totalPremium * 8) / 10
        ); // send premium to provider
        pool.transferAsset(
            devWallet,
            offer.premiumCurrency,
            (totalPremium - (totalPremium * 8) / 10)
        ); // send premium to devx

        // Deduct remaining insured sum
        uint256 insuredSumTaken = ld.offerIdToInsuredSumTaken(
            buyCoverData.offerId
        ) + buyCoverData.insuredSum;
        ld.updateOfferInsuredSumTaken(buyCoverData.offerId, insuredSumTaken);

        // Stored Data
        uint8 coverMonths = buyCoverData.coverMonths;
        InsuranceCover memory coverData;
        coverData.offerId = buyCoverData.offerId;
        coverData.requestId = 0;
        coverData.listingType = ListingType.OFFER;
        coverData.holder = buyCoverData.buyer;
        coverData.insuredSum = buyCoverData.insuredSum;
        coverData.coverQty = buyCoverData.coverQty;
        cd.storeCoverByTakeOffer(coverData, coverMonths, offer.funder);
    }

    /**
     * @dev Called when member take a request
     */
    function provideCover(ProvideCover calldata provideCoverData)
        external
        minimumBalance(msg.sender, 0)
    {
        // Get listing data
        CoverRequest memory request = ld.getCoverRequestById(
            provideCoverData.requestId
        );

        // Holder cannot provide own request
        require(msg.sender != request.holder, "ERR_CG_1");

        // Check if request still valid
        require(block.timestamp <= request.expiredAt, "ERR_CG_2");

        require(!isRequestCoverSucceed(provideCoverData.requestId), "ERR_CG_7");

        // Check if request still be able to take (not bigger than insuredSumRemaining)
        require(
            provideCoverData.fundingSum <=
                (request.insuredSum -
                    ld.requestIdToInsuredSumTaken(provideCoverData.requestId)),
            "ERR_CG_4"
        );

        // verify assetPriceInfo signature
        pool.verifyMessage(provideCoverData.assetPricing, coinSigner);

        // Collect Collateral
        CurrencyType insuredSumCurrency = request.insuredSumCurrency;
        pool.acceptAsset(
            msg.sender,
            insuredSumCurrency,
            provideCoverData.fundingSum,
            provideCoverData.assetPermit
        );

        // Deduct remaining insured sum
        uint256 insuredSumTaken = ld.requestIdToInsuredSumTaken(
            provideCoverData.requestId
        ) + provideCoverData.fundingSum;
        ld.updateRequestInsuredSumTaken(
            provideCoverData.requestId,
            insuredSumTaken
        );

        //
        uint256 insuredSumCurrencyDecimal = cg.getCurrencyDecimal(
            uint8(request.insuredSumCurrency)
        );

        // minimal deposit $1000
        require(
            provideCoverData.fundingSum >= (10**insuredSumCurrencyDecimal),
            "ERR_CG_8"
        );

        // Stored Data
        CoverFunding memory booking;
        booking.requestId = provideCoverData.requestId;
        booking.funder = provideCoverData.provider;
        booking.fundingSum = provideCoverData.fundingSum;
        cd.storeBookingByTakeRequest(booking);

        // Set startAt as 0 to identified as cover not started
        InsuranceCover memory coverData;
        coverData.offerId = 0;
        coverData.requestId = provideCoverData.requestId;
        coverData.listingType = ListingType.REQUEST;
        coverData.holder = request.holder;
        coverData.insuredSum = provideCoverData.fundingSum;
        // Multiply by 10**12, 10**6 for cover qty decimals & 10**6 for neutralize division by coinPrice
        coverData.coverQty =
            (provideCoverData.fundingSum * 10**12) /
            provideCoverData.assetPricing.coinPrice;
        cd.storeCoverByTakeRequest(
            coverData,
            request.coverMonths,
            provideCoverData.provider
        );

        // either its full or partial funding, as long as its fully funded then start cover
        if (ld.isRequestFullyFunded(provideCoverData.requestId)) {
            ld.setCoverRequestFullyFundedAt(
                provideCoverData.requestId,
                block.timestamp
            );
        }
    }

    /**
     * @dev get actual state of cover request
     */
    function isRequestCoverSucceed(uint256 requestId)
        public
        view
        returns (bool state)
    {
        CoverRequest memory coverRequest = ld.getCoverRequestById(requestId);

        if (
            ld.isRequestFullyFunded(requestId) ||
            (coverRequest.insuredSumRule == InsuredSumRule.PARTIAL &&
                block.timestamp > coverRequest.expiredAt &&
                ld.isRequestReachTarget(requestId))
        ) {
            state = true;
        } else {
            state = false;
        }
    }

    /**
     * @dev calculate startAt of cover
     */
    function getStartAt(uint256 coverId) public view returns (uint256 startAt) {
        InsuranceCover memory cover = cd.getCoverById(coverId);

        if (cover.listingType == ListingType.REQUEST) {
            CoverRequest memory coverRequest = ld.getCoverRequestById(
                cover.requestId
            );

            if (ld.isRequestFullyFunded(cover.requestId)) {
                startAt = ld.coverRequestFullyFundedAt(cover.requestId);
            } else if (
                coverRequest.insuredSumRule == InsuredSumRule.PARTIAL &&
                block.timestamp > coverRequest.expiredAt &&
                ld.isRequestReachTarget(cover.requestId)
            ) {
                startAt = coverRequest.expiredAt;
            }
        } else if (cover.listingType == ListingType.OFFER) {
            startAt = cd.insuranceCoverStartAt(coverId);
        }
    }

    /**
     * @dev calculate endAt for cover
     */
    function getEndAt(uint256 coverId) external view returns (uint256 endAt) {
        InsuranceCover memory cover = cd.getCoverById(coverId);
        uint8 coverMonths = 0;
        if (cover.listingType == ListingType.REQUEST) {
            CoverRequest memory coverRequest = ld.getCoverRequestById(
                cover.requestId
            );
            coverMonths = coverRequest.coverMonths;
        } else if (cover.listingType == ListingType.OFFER) {
            // CoverOffer memory coverOffer = ld.getCoverOfferById(cover.offerId);
            coverMonths = cd.getCoverMonths(coverId);
        }
        return (getStartAt(coverId) + (uint256(coverMonths) * 30 days));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {Master} from "../Master/Master.sol";

contract CoverData is Master {
    // State Variables
    InsuranceCover[] internal covers; // InsuranceCover.id
    mapping(address => uint256[]) internal holderToCovers;
    mapping(address => uint256[]) internal funderToCovers;
    mapping(address => uint256[]) internal funderToRequestId;
    mapping(uint256 => uint256[]) internal offerIdToCovers;
    mapping(uint256 => uint256[]) internal requestIdToCovers;
    mapping(uint256 => bool) public isPremiumCollected; //  coverId -> true/false
    mapping(uint256 => uint8) public coverIdToCoverMonths; // Only for Buy Cover / Take Offer
    mapping(uint256 => uint256) public insuranceCoverStartAt; // Only for Buy Cover / Take Offer
    CoverFunding[] internal coverFundings;
    mapping(uint256 => uint256[]) internal requestIdToCoverFundings;
    mapping(address => uint256[]) internal funderToCoverFundings;
    // Funder Address ||--< coverId => true/false
    mapping(address => mapping(uint256 => bool)) public isFunderOfCover;
    // Mapping offer to the most last cover end time
    mapping(uint256 => uint256) public offerIdToLastCoverEndTime;

    // Events
    event Cover(
        uint256 id,
        InsuranceCover cover,
        uint256 startAt,
        uint8 coverMonths,
        address funder
    );
    event Booking(uint256 id, CoverFunding coverFunding);
    event CoverPremiumCollected(uint256 coverId);

    /**
     * @dev Save cover data when user take offer
     */
    function storeCoverByTakeOffer(
        InsuranceCover memory cover,
        uint8 coverMonths,
        address funder
    ) external {
        covers.push(cover);
        uint256 coverId = covers.length - 1;
        offerIdToCovers[cover.offerId].push(coverId);
        holderToCovers[cover.holder].push(coverId);
        funderToCovers[funder].push(coverId);
        coverIdToCoverMonths[coverId] = coverMonths;
        insuranceCoverStartAt[coverId] = block.timestamp;
        isPremiumCollected[coverId] = true;
        isFunderOfCover[funder][coverId] = true;

        // Update the most last cover end time
        uint256 endAt = block.timestamp + (uint256(coverMonths) * 30 days);
        if (endAt > offerIdToLastCoverEndTime[cover.offerId]) {
            offerIdToLastCoverEndTime[cover.offerId] = endAt;
        }

        emit Cover(coverId, cover, block.timestamp, coverMonths, funder);
        emit CoverPremiumCollected(coverId);

        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Save cover data when user take request
     */
    function storeBookingByTakeRequest(CoverFunding memory booking) external {
        coverFundings.push(booking);
        uint256 coverFundingId = coverFundings.length - 1;
        requestIdToCoverFundings[booking.requestId].push(coverFundingId);
        funderToCoverFundings[booking.funder].push(coverFundingId);
        emit Booking(coverFundingId, booking);

        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Save cover data when user take request
     */
    function storeCoverByTakeRequest(
        InsuranceCover memory cover,
        uint8 coverMonths,
        address funder
    ) external {
        covers.push(cover);
        uint256 coverId = covers.length - 1;
        requestIdToCovers[cover.requestId].push(coverId);
        holderToCovers[cover.holder].push(coverId);
        funderToCovers[funder].push(coverId);
        funderToRequestId[funder].push(cover.requestId);
        isFunderOfCover[funder][coverId] = true;
        emit Cover(coverId, cover, 0, coverMonths, funder);
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Get cover detail
     */
    function getCoverById(uint256 coverId)
        external
        view
        returns (InsuranceCover memory cover)
    {
        cover = covers[coverId];
    }

    /**
     * @dev Get booking detail
     */
    function getBookingById(uint256 bookingId)
        external
        view
        returns (CoverFunding memory coverFunding)
    {
        coverFunding = coverFundings[bookingId];
    }

    /**
     * @dev get cover months for cover that crated from take offer only
     */
    function getCoverMonths(uint256 coverId) external view returns (uint8) {
        return coverIdToCoverMonths[coverId];
    }

    /**
     * @dev get list of cover id over covef offer
     */
    function getCoversByOfferId(uint256 offerId)
        external
        view
        returns (uint256[] memory)
    {
        return offerIdToCovers[offerId];
    }

    /**
     * @dev get list of cover id(s) that funded by member
     */
    function getFunderToCovers(address member)
        external
        view
        returns (uint256[] memory)
    {
        return funderToCovers[member];
    }

    /**
     * @dev called when funder collected premium over success cover
     */
    function setPremiumCollected(uint256 coverId) external {
        isPremiumCollected[coverId] = true;
        emit CoverPremiumCollected(coverId);
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev get list of cover id(s) over Cover Request
     */
    function getCoversByRequestId(uint256 requestId)
        external
        view
        returns (uint256[] memory)
    {
        return requestIdToCovers[requestId];
    }

    /**
     * @dev get list of cover request id(s) that funded by member
     */
    function getFunderToRequestId(address funder)
        external
        view
        returns (uint256[] memory)
    {
        return funderToRequestId[funder];
    }
}

/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2016-2019 zOS Global Limited
 * Copyright (c) 2018-2020 CENTRE SECZ
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity ^0.8.0;

/**
 * @title ECRecover
 * @notice A library that provides a safe ECDSA recovery function
 */
library ECRecover {
    /**
     * @notice Recover signer's address from a signed message
     * @dev Adapted from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/65e4ffde586ec89af3b7e9140bdc9235d1254853/contracts/cryptography/ECDSA.sol
     * Modifications: Accept v, r, and s as separate arguments
     * @param digest    Keccak-256 hash digest of the signed message
     * @param v         v of the signature
     * @param r         r of the signature
     * @param s         s of the signature
     * @return Signer address
     */
    function recover(
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            revert("ECRecover: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECRecover: invalid signature 'v' value");
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(digest, v, r, s);
        require(signer != address(0), "ECRecover: invalid signature");

        return signer;
    }
}