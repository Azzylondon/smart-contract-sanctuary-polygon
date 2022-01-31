/**
 *Submitted for verification at polygonscan.com on 2021-12-15
*/

pragma solidity =0.8.6;

interface IHexFactory {
  
    function getPair(string memory name)
        external
        view
        returns (address token);                  

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPool(string memory CID,string memory Name,address token)
        external
        returns (address pool);
    

}

interface IHexPool {
  function initialize(address ,string memory ,string memory  ,address ) external;
  function Deposit(uint _amount,address _user)external;
  function EndStake() external;
  function StartStaking()external;
  function Withdraw(uint _amount) external;
  function ChangePoolEndTimeandMaxLimit(uint ,uint)external;
  function setFounderOfPool(address )external;
  function setPercent(uint ,uint ,uint ,uint ,uint )external;

  //function TransferFunds()external;
}

interface IHEXToken{

    function stakeStart(uint256 newStakedHearts, uint256 newStakedDays)external;
    function stakeGoodAccounting(address stakerAddr, uint256 stakeIndex, uint40 stakeIdParam) external;
    function stakeEnd(uint256 stakeIndex, uint40 stakeIdParam)external;
    function stakeLists(address,uint)external returns(uint40,uint72 ,uint72 stakeShares,uint16 lockedDay,uint16 stakedDays,uint16 unlockedDay,bool isAutoStake) ;
    function stakeCount(address stakerAddr)external returns (uint256);
}


// a library for performing various math operations
library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}


interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}


contract HexPool {
    //using SafeMath for uint256;
    //state variables
    address public Token;
    string public Name;
    uint256 private unlocked = 1;
    address public factory;
    uint public StakeStartedTime;//will be in days
    bool public IsStaking;
    //uint public ReleaseTime =;
    uint public PoolEndingTime = 1;//will be in days
    uint public MaximumAmountToStaked =15000000000000000;//150Million in hearts
    uint public DepositedAmount;
    uint public PoolCreatedTime ;//will be in timestamp
    uint public Sharerate;
    uint8 public constant decimals = 8;
    uint public TotalShares;
    uint256 private constant HEARTS_PER_HEX = 10 ** uint256(decimals); // 1e8
    string public ImageCID;
    uint public payout;
    uint public penality;
    uint public UserAssignedPayout;
    uint public UserAssignedPenality;
    //important addresses
    address public CreatorofPool;
    address public StakeEnder;
    address public FounderAddress;
    //Percent Dividors
    uint public UserPercent;
    uint public CreatorofPoolPercent;
    uint public StakeEnderPercent;
    uint public FounderPercent;
    uint public PercentDivisor;

    /* Stake shares Bigger Pays Better bonus constants used by _stakeStartBonusHearts() */
    uint256 private constant BPB_BONUS_PERCENT = 10;
    uint256 private constant BPB_MAX_HEX = 75 * 1e6;
    uint256 internal constant BPB_MAX_HEARTS = BPB_MAX_HEX * HEARTS_PER_HEX;
    uint256 internal constant BPB = BPB_MAX_HEARTS * 100 / BPB_BONUS_PERCENT;

     /* Share rate is scaled to increase precision */
    uint256 internal constant SHARE_RATE_SCALE=1e5;
    
    //mappings
    mapping(address => uint)public UserAmount;
    mapping(address => uint)public UserBonusAmount;
    mapping(address=>uint)public UserShares;
    
    //events
    event StakeStart(uint _amount,uint _timelength,uint _sharesforStake);
    event StakeEnd(uint _shares,uint _payouts,uint _amount,uint _penalty);


    //modifiers
    modifier lock() {
        require(unlocked == 1, "PulseChain: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }
    modifier CheckStake(){
        require(IsStaking,"Not Staking");
        _;
    }
    modifier CheckUnStake(){
        require(!IsStaking,"Staking");
        _;
    }
    modifier CheckZero(uint _amount){
        require(_amount > 0,"The entered amount can't be zero");
        _;
    }
    modifier CheckBalance(uint _amount){
       require((DepositedAmount + _amount) <= MaximumAmountToStaked,"The entered amount cross the limit");
       _;
    }
    modifier CheckStakeTime()
    {
        uint curentDay=_currentDay();
        require((curentDay - StakeStartedTime) >= PoolEndingTime,"The Staking period is not still completed");
        _;
    }
  
    modifier CheckTwoWeeks()
    {
        require(block.timestamp > (PoolCreatedTime+2 minutes),"The 2 weeks time period is still not completed");
        _;
    }
    modifier CheckFactory()
    {
        require(msg.sender == factory," The msg.sender is equals to factory");
        _;
    }
    //constructure
    constructor() {
        factory = msg.sender;
        Sharerate=uint40(1 * SHARE_RATE_SCALE);
    }

    //setFunctions
    function initialize(address _token,string memory _name,string memory _cid,address _creatorpool) external {
        require(msg.sender == factory, "PulseChain: FORBIDDEN"); // sufficient check
        Token=_token;
        Name=_name;
        ImageCID = _cid;
        PoolCreatedTime=block.timestamp;
        CreatorofPool=_creatorpool;
    }
    function ChangePoolEndTimeandMaxLimit(uint _endingtimeindays,uint _Maxpoollimitinhearts)public CheckFactory{
        PoolEndingTime =_endingtimeindays;
        MaximumAmountToStaked=_Maxpoollimitinhearts;
    }
    function Deposit(uint _amount)public CheckUnStake CheckBalance(_amount) CheckZero(_amount){
       IERC20(Token).transferFrom(msg.sender,address(this),_amount);
       DepositedAmount +=_amount;
       uint256 bonusHearts = _stakeStartBonusHearts(_amount, PoolEndingTime);//-->bonus done
        uint256 newStakeShares = (_amount + bonusHearts) * SHARE_RATE_SCALE /Sharerate ;//shares done-->(amountTheUserStakes+BonusHearts the User Gets)*Sharerate scale/share-rate
        //just conceptual
     //    uint cuurentday=_currentDay();
     //    uint bonusfordays=(block.timestamp-PoolCreatedTime)*(1*HEARTS_PER_HEX);
        //until here
        Sharerate = (_amount + bonusHearts) * SHARE_RATE_SCALE / newStakeShares;//needs to be discussed(Not cleared)
       UserAmount[msg.sender] +=_amount;
       UserBonusAmount[msg.sender] +=bonusHearts;
       UserShares[msg.sender] += newStakeShares;
       TotalShares +=newStakeShares;
       if(DepositedAmount == MaximumAmountToStaked){
           StartStaking();
       } 
       //get the percentage from the contract itself    
    }
    
    function EndStake()public CheckStake CheckStakeTime 
    {
     //will allocate the funds to all the users
     //     //we need to make sure the endstake is called by the authorized party only and thats to at the right time
         
        IsStaking=false;
        uint stakelength=IHEXToken(Token).stakeCount(address(this));
        StakeEnder=msg.sender;
        (uint40 stakeId,uint72 stakedHearts,uint72 stakeShares,uint16 lockedDay,uint16 stakedDays,uint16 unlockedDay,bool isAutoStake)= IHEXToken(Token).stakeLists(address(this),stakelength-1);
        uint _BalanceBefore= IERC20(Token).balanceOf(address(this));
        IHEXToken(Token).stakeEnd(stakelength-1, stakeId);
        uint _BalanceAfter=IERC20(Token).balanceOf(address(this));
          
        if((_BalanceAfter - _BalanceBefore) >= 0)
        {
            payout=_BalanceAfter-_BalanceBefore;
            //send to creator of pool
            uint creatorBalance=payout*(CreatorofPoolPercent/PercentDivisor);
            //send to founder
            uint FounderBalance=payout*(FounderPercent/PercentDivisor);
            //close bounty
            uint CloserBalance=payout*(StakeEnderPercent/PercentDivisor);

            UserAssignedPayout=payout*(UserPercent/PercentDivisor);
            IERC20(Token).transfer(CreatorofPool,creatorBalance);
            IERC20(Token).transfer(FounderAddress, FounderBalance);
            IERC20(Token).transfer(StakeEnder, CloserBalance);
        }
        else if((_BalanceBefore-_BalanceAfter) >=0)
        {
            penality =_BalanceBefore-_BalanceAfter;
        }

        emit StakeEnd(stakeShares,payout,stakedHearts,penality);//Need to change later
        
        //     //write the distribution logic
        //     //Get the hex tokens
        //     //distribute then to the users
        //        //-->loop through evry users and distribute
        //        //-->Not give yet 
        //        //
    }

    function StartStaking() public
    {
        IsStaking=true;
        StakeStartedTime=_currentDay();
        uint ContractBalance=IERC20(Token).balanceOf(address(this));
        IHEXToken(Token).stakeStart(ContractBalance, PoolEndingTime);
        uint stakelength=IHEXToken(Token).stakeCount(address(this));
        (uint40 stakeId,uint72 stakedHearts,uint72 stakeShares,uint16 lockedDay,uint16 stakedDays,uint16 unlockedDay,bool isAutoStake)= IHEXToken(Token).stakeLists(address(this),stakelength-1);
        emit StakeStart(ContractBalance,StakeStartedTime+PoolEndingTime,stakeShares);

    }
    
    function Withdraw() public CheckUnStake CheckTwoWeeks lock
    {
        uint ContractBalance=IERC20(Token).balanceOf(address(this));
        uint payoutforUser=CalcUserPayout(msg.sender);
        uint userBalance=UserAmount[msg.sender]+(payoutforUser);

        if(userBalance <= ContractBalance)
        {
            IERC20(Token).transfer(msg.sender, userBalance);
        }
        else
        {
            IERC20(Token).transfer(msg.sender,ContractBalance);
        }
        
        DepositedAmount -= userBalance;
        UserAmount[msg.sender] = 0;
        TotalShares -=UserShares[msg.sender];
        UserShares[msg.sender] =0;
        UserBonusAmount[msg.sender] =0;	
    }
    function CalcUserPayout(address _user)internal returns(uint){
       uint shares=UserShares[msg.sender];
       uint balance=UserAssignedPayout*(shares/TotalShares);
       return(balance);
    }
    function TransferFunds(uint _amount)public CheckFactory(){
        // uint ContractBalance =IERC20()
        require(_amount <= IERC20(Token).balanceOf(address(this)));
        IERC20(Token).transfer(factory,_amount);
    }
    function setFounderOfPool(address _founder)public CheckFactory(){
        require(_founder != address(0));
        FounderAddress = _founder;
    }
    function setPercent(uint _founderpercent,uint _endstakerpercent,uint _creatorPercent,uint _userPercent,uint _percentdivior)public CheckFactory()
    {
        require((_founderpercent+_endstakerpercent+_creatorPercent+_userPercent) == _percentdivior);
        FounderPercent=_founderpercent;
        CreatorofPoolPercent=_creatorPercent;
        UserPercent = _userPercent;
        PercentDivisor=_percentdivior;
    }

    //getFunctions
    function currentDay()
        external
        view
        returns (uint256)
    {
        return _currentDay();
    }

    function _currentDay()
        internal
        view
        returns (uint256)
    {
        return (block.timestamp - PoolCreatedTime) / 1 days;//gives us the current day according to the lauch day 
    }
    function AmountRemainingtoStake()public view returns(uint _amount){
        return (MaximumAmountToStaked -  DepositedAmount);
    }
    function GetRemainingTimeForPool()public view returns(uint _time){
         uint currentday=_currentDay();
        uint endingTime=PoolEndingTime-(currentday-StakeStartedTime);
        return (endingTime);
    }
    function CheckStakingCompleted() CheckStake public  view returns(bool _completed,uint Time)
    {
        uint curentDay=_currentDay();
        if((curentDay - StakeStartedTime) < PoolEndingTime)
        {
            return (false,(PoolEndingTime-(curentDay - StakeStartedTime)));
        }
        return (true,0);
    }

     function _stakeStartBonusHearts(uint256 newStakedHearts, uint256 newStakedDays)
        private
        pure
        returns (uint256 bonusHearts)
    {

        uint256 cappedStakedHearts = newStakedHearts <= BPB_MAX_HEARTS
            ? newStakedHearts
            : BPB_MAX_HEARTS;
        bonusHearts=newStakedHearts*(cappedStakedHearts /  BPB_MAX_HEARTS) /(10);
        return bonusHearts;
    } 

}

contract HexFactory is IHexFactory 
{
    //state variables
    address[] public override allPairs;
    address public Owner;
    //events
    event PairCreated(
        address indexed token,
        string indexed name,
        string indexed cid,
        address pool,
        uint256 length
    );
    
    //mappings
    mapping(string => address) public override getPair;
    //modifiers
    modifier OnlyOwner()
    {
        require(msg.sender == Owner,"Sender is not Owner");
        _;
    }
    //constructor
    constructor() {
        Owner = msg.sender;
    }

   
    //Set Functions
    function createPool(string memory CID,string memory Name,address token)
        external
        override
        returns (address pool)
    {
        require(token != address(0), "PulseChain: IDENTICAL_ADDRESSES");
        bytes memory bytecode = type(HexPool).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token,Name,CID,allPairs.length));
        assembly {
            pool := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IHexPool(pool).initialize(token,Name,CID,msg.sender);
        getPair[Name] = pool;
        allPairs.push(pool);
        emit PairCreated(token, Name,CID, pool, allPairs.length);
    }
    //Change PoolEndTimeAndMaxLimit
    function ChangePoolEndTimeandMaxLimit(address pool,uint _endtimeindays,uint _poolLimitinHearts)public OnlyOwner{
        require(_endtimeindays > 0 && _poolLimitinHearts>0);
        IHexPool(pool).ChangePoolEndTimeandMaxLimit(_endtimeindays, _poolLimitinHearts); 
    }
    //Change SetFounder
    function setFounder(address _founder,address Pool)public OnlyOwner{
        require(_founder != address(0));
        IHexPool(Pool).setFounderOfPool(_founder);
    }
    //SetPercentof the contract
    function setPercent(uint _founderpercent,uint _endstakerpercent,uint _creatorPercent,uint _userPercent,uint _percentdivior,address Pool)public OnlyOwner
    {
        IHexPool(Pool).setPercent(_founderpercent, _endstakerpercent, _creatorPercent, _userPercent, _percentdivior);
    }

    //Get functions
     function allPairsLength() external view override returns (uint256) {
        return allPairs.length;
    }

    // function MergePools(address _pool1,address _pool2)public OnlyOwner{
    //     //transfer the funds from _pool1 to this 
    //     //transfer the funds from _pool2 to this
    //     //create a new pool 
    //     //send the funds to the pool
    // }
    //


   
}