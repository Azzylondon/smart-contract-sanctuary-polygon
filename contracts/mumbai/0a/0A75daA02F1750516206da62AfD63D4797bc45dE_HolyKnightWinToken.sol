// SPDX-License-Identifier: MIT
// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
/* solhint-disable not-rely-on-time */
pragma solidity >0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IHolyKnightWinToken.sol";
import "./libs/Governance.sol";
import "./interfaces/IHolyCard.sol";

contract HolyKnightWinToken is IHolyKnightWinToken, Initializable, ERC20Upgradeable, Governance {
    using SafeMath for uint256;
    uint256 internal _totalSupply;
    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) public _allowances;
    mapping(address => mapping(uint256 => bool)) public unlockSchedule;
    mapping(uint256 => FundingMap) public fundMap;
    mapping(address => bool) private _isExcludedFromFee;
    bool public _openTransfer;
    uint256 public constant MAXRATE = 2000;
    uint256 public constant MINRATE = 0;
    uint256 public constant RATEBASE = 10000;
    uint256 public _burnRate;
    uint256 public _rewardRate;
    uint256 public _totalRewardToken;
    IHolyCards public holyCard;
    address public _rewardPool;
    event EventSetRate(uint256 burnRate, uint256 rewardRate);
    event EventRewardPool(address rewardPool);
    event EventTeamWallet(address teamWallet);
    uint256 public deployedTime;

    function initialize() public virtual initializer {
        __ERC20_init("Holy Knight Win Token", "HOLY");
        initGovernance();
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_governance] = true;
        _totalSupply = 1e28;
        _openTransfer = false;
        _burnRate = 0;
        _rewardRate = 0;
        _totalRewardToken = 0;
        _rewardPool = address(0);
        deployedTime = block.timestamp;
        _mint(address(this), _totalSupply);
    }

    function migrateFunction(address _holyCard, uint256[] calldata _tokenIds) public onlyGovernance {
        holyCard = IHolyCards(_holyCard);
        uint256 _price;
        deployedTime = block.timestamp;
        for (uint8 i = 0; i < _tokenIds.length; i++) {
            _price = IHolyCards(_holyCard).getCardPrice(_tokenIds[i]);
            fundMap[_tokenIds[i]].amount = _price;
            if (_price == 25 * 10**8) fundMap[_tokenIds[i]].unlockTime = deployedTime + 30 days; // done
            if (_price == 175 * 10**7) {
                fundMap[_tokenIds[i]].unlockTime = deployedTime + 30 days;
                _rewardPool = IHolyCards(_holyCard).getTokenOwner(_tokenIds[i]); // done
            }
            if (_price == 15 * 10**8) fundMap[_tokenIds[i]].unlockTime = deployedTime;
            if (_price == 19 * 10**8) fundMap[_tokenIds[i]].unlockTime = deployedTime + 365 days; // done
            if (_price == 10**9) fundMap[_tokenIds[i]].unlockTime = deployedTime + 180 days; // done
            if (_price == 3 * 10**8) fundMap[_tokenIds[i]].unlockTime = deployedTime;
            if (_price == 105 * 10**7) fundMap[_tokenIds[i]].unlockTime = deployedTime;
        }
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function unlockHolyKnightWinToken(uint256 _tokenId) public returns (uint256) {
        address _sender = holyCard.getTokenOwner(_tokenId);
        require(msg.sender == _sender, "Sender is not illegible");
        bool _req = false;
        uint256 _unlock = 0;
        uint8 _month = 0;
        uint256 _amount = fundMap[_tokenId].amount;
        if (_amount == 19 * 10**8) {
            require(block.timestamp > fundMap[_tokenId].unlockTime, "PentagonDevTeam! a Year!");
            _month = uint8(block.timestamp.sub(deployedTime).mod(30 days).sub(12));
            for (uint8 i = 0; i < _month; ++i) {
                if (!unlockSchedule[_sender][i]) _unlock += 1e26;
                unlockSchedule[_sender][i] = true;
            }
            _req = transfer(address(this), _sender, _unlock);
            _unlock = 0;
        }
        if (_amount == 10**9) {
            require(block.timestamp.sub(deployedTime) > 180 days, "Advisor! locked 6 months");
            _unlock = 1e27;
            _req = transfer(address(this), _sender, _unlock);
            _unlock = 0;
        }
        if (_amount == 175 * 10**7) {
            _month = uint8(block.timestamp.sub(deployedTime).mod(30 days));
            for (uint8 i = 0; i < _month; ++i) {
                if (!unlockSchedule[_sender][i]) _unlock += 4 * 1e25;
                unlockSchedule[_sender][i] = true;
            }
            _req = transfer(address(this), _sender, _unlock);
            _unlock = 0;
        }
        if ((_amount == 15 * 10**8) || (_amount == 3 * 10**8) || (_amount == 105 * 10**7))
            _req = transfer(address(this), _sender, _amount);
        if (msg.sender == _governance) {
            require(block.timestamp.sub(deployedTime) > 730 days, "Release at 2 years");
            _req = transfer(address(this), _governance, this.balanceOf(address(this)));
        }
        if (_amount == 25 * 10**8) {
            require(block.timestamp > fundMap[_tokenId].unlockTime, "Tournament 30 days");
            _month = uint8(block.timestamp.sub(deployedTime).mod(30 days));
            for (uint8 i = 0; i < _month; ++i) {
                if (!unlockSchedule[_sender][i]) _unlock += 1e26;
                unlockSchedule[_sender][i] = true;
            }
            _req = transfer(address(this), _sender, _unlock);
            _unlock = 0;
        }
        require(_req, "Nothing to Release");
        return _unlock;
    }

    receive() external payable {
        revert("Dont send ethers");
    }

    function _setRate(uint256 burnRate, uint256 rewardRate) internal {
        require(MAXRATE >= burnRate && burnRate >= MINRATE, "invalid burn rate");
        require(MAXRATE >= rewardRate && rewardRate >= MINRATE, "invalid reward rate");
        _burnRate = burnRate;
        _rewardRate = rewardRate;
    }

    function setRate(uint256 burnRate, uint256 rewardRate) public override onlyGovernance {
        _setRate(burnRate, rewardRate);
        emit EventSetRate(burnRate, rewardRate);
    }

    function isExcludedFromFee(address account) public view override returns (bool) {
        return _isExcludedFromFee[account];
    }

    function excludeFromFee(address account) public override onlyGovernance {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public override onlyGovernance {
        _isExcludedFromFee[account] = false;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override(ERC20Upgradeable, IHolyKnightWinToken) returns (bool) {
        uint256 allow = _allowances[from][msg.sender];
        _allowances[from][msg.sender] = allow.sub(value);
        return transfer(from, to, value);
    }

    function transfer(
        address from,
        address to,
        uint256 value
    ) internal returns (bool) {
        require(_openTransfer || (from == address(this)), "Transfer closed!!!");
        uint256 sendAmount = value;
        uint256 tmpBurnRate = _burnRate;
        uint256 tmpRewardRate = _rewardRate;
        if (isExcludedFromFee(from) || (isExcludedFromFee(to))) _setRate(0, 0);
        uint256 burnFee = (value.mul(_burnRate)).div(RATEBASE);
        if (burnFee > 0) {
            _totalSupply = _totalSupply.sub(burnFee);
            sendAmount = sendAmount.sub(burnFee);
            emit Transfer(from, address(0), burnFee);
        }
        uint256 rewardFee = (value.mul(_rewardRate)).div(RATEBASE);
        if (rewardFee > 0) {
            _balances[_rewardPool] = _balances[_rewardPool].add(rewardFee);
            sendAmount = sendAmount.sub(rewardFee);
            _totalRewardToken = _totalRewardToken.add(rewardFee);
            emit Transfer(from, _rewardPool, rewardFee);
        }
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(sendAmount);
        emit Transfer(from, to, sendAmount);
        _setRate(tmpBurnRate, tmpRewardRate);
        return true;
    }

    function enableOpenTransfer(bool isEnable) public override onlyGovernance {
        _openTransfer = isEnable;
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
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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

// SPDX-License-Identifier: MIT
// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity >0.8.0;
import "./IMedieverse.sol";

interface IHolyKnightWinToken is IMedieverse {
    struct FundingMap {
        uint256 unlockTime;
        uint256 amount;
    }

    function isExcludedFromFee(address account) external view returns (bool);

    function excludeFromFee(address account) external;

    function includeInFee(address account) external;

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function enableOpenTransfer(bool isEnable) external;

    function setRate(uint256 burnRate, uint256 rewardRate) external;
}

// SPDX-License-Identifier: MIT
// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity >0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract Governance is Initializable {
    address public _governance;
    mapping(address => bool) public isContractCaller;

    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyGovernance() {
        require(msg.sender == _governance, "not governance");
        _;
    }

    modifier onlyContractCaller() {
        require(isContractCaller[msg.sender], "not call by contract");
        _;
    }

    function initGovernance() public virtual initializer {
        _governance = msg.sender;
        isContractCaller[msg.sender] = true;
    }

    function setGovernance(address governance) public onlyGovernance {
        require(governance != address(0), "new governance the zero address");
        emit GovernanceTransferred(_governance, governance);
        _governance = governance;
    }

    function setContractCaller(address _caller) external onlyGovernance {
        require(_caller != address(0), "Cannot called by address zero");
        isContractCaller[_caller] = true;
    }
}

// SPDX-License-Identifier: MIT
// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity >0.8.0;
import "./IMedieverse.sol";

interface IHolyCards is IMedieverse {
    function getRarityByIndex(uint8 _index) external view returns (uint256);

    function getRarityByTokenId(uint256 _tokenId) external view returns (uint8);

    function getName(uint256 _tokenId) external view returns (string memory);

    function getCardPrice(uint256 _tokenId) external view returns (uint256);

    function getHolyCardsByIndex(uint256 holyCardIndex) external view returns (HolyCardsIndex memory);

    function setHolyCardByIndex(HolyCardsIndex memory _newHolyCard, uint256 _tokenIndex) external;

    function createHolyCard(
        address _account,
        uint8 _holyType,
        uint256 _holyShit,
        string memory _uri,
        string memory _holyName,
        uint256 _price
    ) external returns (uint256);

    function burn(uint256 _tokenId) external;

    function transferCards(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function getTokenMetaData(uint _tokenId) external view returns (string memory);

    //function getTotalSupply() external view returns (uint256);

    function getAccountBalance(address _account) external view returns (uint256);

    function getTokenExists(uint256 _tokenId) external view returns (bool);

    function getTokenOwner(uint256 _tokenId) external view returns (address);

    function getCardTypeByIndex(uint8 _index) external view returns (uint256);

    function getCardTypeByTokenId(uint256 _tokenId) external view returns (uint8);

    function addCardType(string memory _type) external;

    function buyHolyCard(uint256 _tokenId) external payable;

    function changeCardPrice(uint256 _tokenId, uint256 _newPrice) external;

    function changeCardName(uint256 _tokenId, string memory _name) external;

    function changeCardRarity(uint256 _tokenId, uint8 _newRarity) external;

    function toggleForSale(uint256 _tokenId) external;

    /* 
    function getRequireHoly(
        address _account,
        uint256 _holyAmount,
        bool _isAllow
    ) external view returns (uint256 requiredHoly);

    function getHolyToSubtract(
        uint256 _inGameOnlyFunds,
        uint256 _tokenRewards,
        uint256 _holyAmount
    )
        external
        pure
        returns (
            uint256 fromInGameOnlyFunds,
            uint256 fromTokenRewards,
            uint256 fromUserWallet
        );

    function getMonsterPower(uint32 _target) external pure returns (uint24);

    function getHolyGained(uint24 _monsterPower) external view returns (uint256);

    function getExpGained(uint24 _playerPower, uint24 _monsterPower) external view returns (uint16);

    function getPlayerPowerRoll(
        uint24 _playerFightPower,
        uint24 _element,
        uint256 _seed
    ) external view returns (uint24);

    function getMonsterPowerRoll(uint24 _monsterPower, uint256 _seed) external pure returns (uint24);

    function getPlayerPower(
        uint24 _basePower,
        int128 _weaponMultiplier,
        uint24 _bonusPower
    ) external pure returns (uint24);

    function getPlayerElementBonusAgainst(uint24 _element) external view returns (int128);

    function getTargets(uint256 _knightId, uint256 _weaponId) external view returns (uint32[5] memory);

    function isElementEffectiveAgainst(uint8 _attacker, uint8 _defender) external pure returns (bool);

    function getTokenRewards() external view returns (uint256);

    function getExpRewards(uint256 knightId) external view returns (uint256);

    function getTokenRewardsFor(address _account) external view returns (uint256);

    function getTotalHolyOwnedBy(address _account) external view returns (uint256);

    function getDataTable(uint256 _index) external returns (uint256); */

    event CreatHolyCard(address _to, string _holyName, uint8 _holyType, uint8 _holyRarity, uint256 _price);
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
// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity >0.8.0;

interface IMedieverse {
    struct HolyCardsIndex {
        string holyName;
        uint8 holyType;
        uint8 holyRarity;
        string tokenURI;
        address mintedBy;
        address curOwner;
        address prevOwner;
        uint256 price;
        uint16 transferCount;
        bool forSale;
    }
    struct HolyKnight {
        uint16 exp;
        uint8 level;
        uint8 element;
        uint8 turnLeft;
        uint64 hitpoint;
    }
    struct KnightKit {
        uint8 version;
        uint256 armor;
        uint256 weapon;
        uint256 shield;
        uint256 land;
        uint256 seed;
    }
    struct HolyBlacksmith {
        string engrave;
        uint8 rareBonusReturn;
        uint8 legendBonusReturn;
        uint8 exoticBonusReturn;
        uint8 version;
        uint256 seed;
    }
    struct HolyMaxBonus {
        uint16 maxRare;
        uint16 maxLegend;
        uint16 maxExotic;
    }
    struct MintPayment {
        bytes32 blockHash;
        uint256 blockNumber;
        address nftAddress;
        uint count;
    }
    struct MintPaymentHolyDeposited {
        uint256 holy4Wallet;
        uint256 holy4Rewards;
        uint256 holy4Igo;
        uint256 holy1Wallet;
        uint256 holy1Rewards;
        uint256 holy1Igo;
        uint256 refund4Timestamp;
    }
    struct HolyArmors {
        // right2left: 3bit=rarity, 2b=element, 7b=pattern, 4b=reserve, each point refers to .25% improvement
        uint16 properties;
        uint16 extraHP;
        uint16 vitality;
        uint16 superior;
    }
    struct HolyLand {
        uint8 landTier;
        string landName;
        uint16 chunkId;
        uint8 cordX;
        uint8 cordY;
    }
    struct HolyShields {
        // right2left: 3bit=rarity, 2b=element, 7b=pattern, 4b=reserve, each point refers to .25% improvement
        uint16 properties;
        uint16 guardian;
        uint16 resistance;
        uint16 blocked;
    }
    struct HolyTrinket {
        uint8 rarity;
        uint16 rareBonus;
        uint16 legendBonus;
        uint16 exoticBonus;
        uint8 effect;
    }
    struct HolyWeapons {
        // right2left: 3bit=rarity, 2b=element, 7b=pattern, 4b=reserve, each point refers to .25% improvement
        uint16 properties;
        uint16 haste;
        uint16 flawless;
        uint16 critical;
        uint8 level;
    }
    struct WeaponBonusMultiply {
        uint bonusBase; // 2
        uint bonusRare; // 15
        uint bonusLegend; // 30
        uint bonusExotic; // 60
    }
    struct WeaponPowerBase {
        int128 weaponBase; // 1.0
        int128 powBasic; // 0.25%
        int128 powAdvanced; // 0.2575% (+3%)
        int128 powExpert; // 0.2675% (+7%)
    }
    struct BankingSystem {
        uint256 gold;
        uint8[] noble;
        uint256[] knight;
    }
    struct StakeCardInfo {
        uint256 landId;
        uint64 timestamp;
        int128 apy;
        uint256 certificate;
    }
    struct UserKnightSlot {
        uint256[] slot;
        uint8 limit;
    }
    struct HolyMaps {
        uint256 one;
        uint256 two;
        uint256 three;
        uint256 four;
        uint256 five;
        uint256 six;
        uint256 seven;
        uint256 eight;
        uint256 nine;
    }
    struct BattleMap {
        uint8 position;
        uint8 element;
        uint256 hitpoint;
        uint256 power;
    }
}