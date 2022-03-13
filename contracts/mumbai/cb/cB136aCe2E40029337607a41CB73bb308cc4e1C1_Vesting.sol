//SPDX-License-Identifier: UNLICENSED
/*
*@author Arnab Ray
*/

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract Vesting is Ownable{

    IERC20 public token;

    struct Investor {
        address account;
        uint amount;
        uint8 saleType;
    }

    struct InvestorDetails {
        uint totalBalance;
        uint timeDifference;
        uint lastVestedTime;
        uint reminingUnitsToVest;
        uint tokensPerUnit;
        uint vestingBalance;
        uint investorType;
        uint initialAmount;
        bool isInitialAmountClaimed;
    }

    uint public startDate;

    uint day = 24 * 60 * 60;

    event TokenWithdraw(address indexed buyer, uint value);

    mapping(address => InvestorDetails) public Investors;
    mapping (address => bool) public claimedIntermediate;
    mapping (address => uint) public initialToIntermediate;
    uint public seedStartDate;
    uint public privateStartDate;
    uint public publicStartDate;
    uint public activeLockDate;
    uint public activeIntermediateLockDate;
    uint intermediateReleaseDay;
    uint public seedLockEndDate;
    uint public privateLockEndDate;
    uint public publicLockEndDate;

    uint public seedVestingEndDate;
    uint public privateVestingEndDate;
    uint public publicVestingEndDate;

    receive() external payable {
    }

    constructor(address _tokenAddress, uint _seedStartDate, uint _privateStartDate, uint _publicStartDate ) {
        token = IERC20(_tokenAddress);
        seedStartDate = _seedStartDate;
        privateStartDate = _privateStartDate;
        publicStartDate = _publicStartDate;
        intermediateReleaseDay = 14 days;
        seedLockEndDate = seedStartDate + 90 days;
        privateLockEndDate = privateStartDate + 30 days;
        publicLockEndDate = publicStartDate + 30 days;
        seedVestingEndDate = seedLockEndDate + 270 days;
        privateVestingEndDate = privateLockEndDate + 270 days;
        publicVestingEndDate = publicLockEndDate + 90 days;
    }


    /* Withdraw the contract's BNB balance to owner wallet*/
    function extractBNB() external {
        payable(owner()).transfer(address(this).balance);
    }

    /* 
        Transfer the remining token to different wallet. 
        Once the ICO is completed and if there is any remining tokens it can be transfered other wallets.
    */

    function transferToken(address _addr) external onlyOwner {
        token.transfer(_addr, token.balanceOf(address(this)));
    }

    /* Utility function for testing. The token address used in this ICO contract can be changed. */
    function setTokenAddress(address _addr) external onlyOwner {
        token = IERC20(_addr);
    }

    function setStartDate(uint _value) external onlyOwner {
        startDate = _value;
    }

    function addInvestorDetails(Investor[] memory investorArray) external onlyOwner {
        require(investorArray.length <= 25, "Array length exceeding 25, You might probably run out of gas");
        for(uint16 i = 0; i < investorArray.length; i++) {
            InvestorDetails memory investor;
            uint8 saleType = investorArray[i].saleType;
            investor.totalBalance = investorArray[i].amount*(10 ** 18);
            investor.investorType = investorArray[i].saleType;
            investor.vestingBalance = investor.totalBalance;

            if(saleType == 1) {
                investor.reminingUnitsToVest = 270;
                investor.initialAmount = (investor.totalBalance*5)/100;
                investor.tokensPerUnit = (investor.totalBalance-investor.initialAmount)/270;
            }

            if(saleType == 2) {
                investor.reminingUnitsToVest = 270;
                investor.initialAmount = (investor.totalBalance*10)/100;
                investor.tokensPerUnit = (investor.totalBalance-investor.initialAmount)/270;
            }

            if(saleType == 3) {
                investor.reminingUnitsToVest = 90;
                investor.initialAmount = investor.totalBalance*(30)/(100);
                investor.tokensPerUnit = (investor.totalBalance-(investor.initialAmount))/(90);
            }

            Investors[investorArray[i].account] = investor;
        }
    }

    function isValidInvestor (address _investor) view internal returns(bool) {
        if (Investors[_investor].investorType<=3 && Investors[_investor].investorType !=0)
        return true;
        else return false;
    }

    function calculateTime(address _user) view internal returns (bool) {
        if (block.timestamp - initialToIntermediate[_user] >= 14 days)
        return true;
        else
        return false;
    }

    function calculateMoney(address _sender) view internal returns (uint) {
        return ((Investors[_sender].vestingBalance)*5)/100;
    }

    function claimIntermediate() external {
        require (claimedIntermediate[_msgSender()] == false, 'Already claimed');
        require (Investors[_msgSender()].isInitialAmountClaimed, "Initial Not withdrawn!");
        require (isValidInvestor(_msgSender()),'Not valid investor');
        require (calculateTime(_msgSender()), 'Wait!');
        claimedIntermediate[msg.sender] = true;
        uint _tokensToRelease = calculateMoney(_msgSender());
        Investors[msg.sender].vestingBalance -= _tokensToRelease;
        token.transfer(_msgSender(), _tokensToRelease);
        emit TokenWithdraw(_msgSender(), _tokensToRelease);
    }


    function withdrawTokens() external {
        //InvestorDetails memory investor = Investors[msg.sender];
        // activeLockDate = seedLockEndDate;
        if(Investors[msg.sender].isInitialAmountClaimed && claimedIntermediate[msg.sender] == true) {
            if(Investors[msg.sender].investorType == 1) {
                require(block.timestamp >= seedLockEndDate, "Wait until locking period to over!");
                activeLockDate = seedLockEndDate;
            }

            else if(Investors[msg.sender].investorType == 2) {
                require(block.timestamp >= privateLockEndDate, "Wait");
                activeLockDate = privateLockEndDate;
            }

            else if(Investors[msg.sender].investorType == 3) {
                require(block.timestamp >= publicLockEndDate, "Wait");
                activeLockDate = publicLockEndDate;
            } else {
                revert("Not an investor!");
            }

            /* Time difference to calculate the interval between now and last vested time. */
            uint timeDifference;
            if(Investors[msg.sender].lastVestedTime == 0) {
                require(activeLockDate > 0, "Active lock-date was zero");
                timeDifference = block.timestamp - activeLockDate;//, "Sub error timedifference");
            } else {
                timeDifference = block.timestamp-Investors[msg.sender].lastVestedTime;//, "sub error lastvested time difference");
            }

            /* Number of units that can be vested between the time interval */
            uint numberOfUnitsCanBeVested = timeDifference/day;//, "Div error no.of units can be vested");

            /* Remining units to vest should be greater than 0 */
            require(Investors[msg.sender].reminingUnitsToVest > 0, "All units vested!");

            /* Number of units can be vested should be more than 0 */
            require(numberOfUnitsCanBeVested > 0, "Please wait till next vesting period!");

            if(numberOfUnitsCanBeVested >= Investors[msg.sender].reminingUnitsToVest) {
                numberOfUnitsCanBeVested = Investors[msg.sender].reminingUnitsToVest;
            }

            /*
                1. Calculate number of tokens to transfer
                2. Update the investor details
                3. Transfer the tokens to the wallet
            */

            uint tokenToTransfer = numberOfUnitsCanBeVested * Investors[msg.sender].tokensPerUnit;
            uint reminingUnits = Investors[msg.sender].reminingUnitsToVest;
            uint balance = Investors[msg.sender].vestingBalance;
            Investors[msg.sender].reminingUnitsToVest -= numberOfUnitsCanBeVested;
            Investors[msg.sender].vestingBalance -= numberOfUnitsCanBeVested * Investors[msg.sender].tokensPerUnit;
            Investors[msg.sender].lastVestedTime = block.timestamp;
            if(numberOfUnitsCanBeVested == reminingUnits) {
                token.transfer(msg.sender, balance);
                emit TokenWithdraw(msg.sender, balance);
            } else {
                token.transfer(msg.sender, tokenToTransfer);
                emit TokenWithdraw(msg.sender, tokenToTransfer);
            }
        }
        else {
            Investors[msg.sender].vestingBalance -= Investors[msg.sender].initialAmount;
            Investors[msg.sender].isInitialAmountClaimed = true;
            uint amount = Investors[msg.sender].initialAmount;
            Investors[msg.sender].initialAmount = 0;
            initialToIntermediate[_msgSender()] = block.timestamp;
            token.transfer(msg.sender, amount);
            emit TokenWithdraw(msg.sender, amount);
        }
    }

    function setDay(uint _value) public onlyOwner {
        day = _value;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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