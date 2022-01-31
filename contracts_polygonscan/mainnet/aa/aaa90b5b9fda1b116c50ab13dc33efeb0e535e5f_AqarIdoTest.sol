/**
 *Submitted for verification at polygonscan.com on 2021-10-20
*/

// SPDX-License-Identifier: none
pragma solidity ^0.8.4;

interface AggregatorV3Interface {

  function decimals() external view returns (uint);
  function description() external view returns (string memory);
  function version() external view returns (uint);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint roundId,
      uint answer,
      uint startedAt,
      uint updatedAt,
      uint answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint roundId,
      uint answer,
      uint startedAt,
      uint updatedAt,
      uint answeredInRound
    );

}

contract PriceConsumerV3 {

    AggregatorV3Interface internal priceFeed;

    constructor() {
        priceFeed = AggregatorV3Interface(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0); // Mainnet MATIC/USD
    }


    function getThePrice() public view returns (uint) {
        (
            uint roundID, 
            uint price,
            uint startedAt,
            uint timeStamp,
            uint answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
}

interface BEP20 {
             function totalSupply() external view returns (uint theTotalSupply);
             function balanceOf(address _owner) external view returns (uint balance);
             function transfer(address _to, uint _value) external returns (bool success);
             function transferFrom(address _from, address _to, uint _value) external returns (bool success);
             function approve(address _spender, uint _value) external returns (bool success);
             function allowance(address _owner, address _spender) external view returns (uint remaining);
             event Transfer(address indexed _from, address indexed _to, uint _value);
             event Approval(address indexed _owner, address indexed _spender, uint _value);
}

interface STAKE {
    function tierCount1() external view returns (uint);
    function tierCount2() external view returns (uint);
    function tierCount3() external view returns (uint);
    function tierCount4() external view returns (uint);
    function ongoingStakingStatus() external view returns (bool);
    function userStakeStastus(address) external view returns (bool);
    function details(address) external view returns(uint topTier, uint[] calldata amounts, uint[] calldata times, bool[] calldata withdrawStatus);
}

contract StakingDetails {
    
    STAKE internal stakeGetter;
    
    constructor() {
        stakeGetter = STAKE(0x1843EC59C04ffbf349e21aBd317F6EC874DCAc9F); //stake contract address
    }
    
    function oneCount() public view returns (uint) {
       return stakeGetter.tierCount1();
    }
    function twoCount() public view returns (uint) {
       return stakeGetter.tierCount2();
    }
    function threeCount() public view returns (uint) {
       return stakeGetter.tierCount3();
    }
    function fourCount() public view returns (uint) {
       return stakeGetter.tierCount4();
    }
    
    function stakeStatus(address addr) public view returns(bool){
        return stakeGetter.userStakeStastus(addr);
    }
    
    function getTopTier(address addr) public view returns (uint) {
        (
            uint topTier,
            uint[] memory amounts,
            uint[] memory times,
            bool[] memory withdrawStatus
        ) = stakeGetter.details(addr);
            
        return topTier;
    }
}

contract AqarIdoTest {
    
    PriceConsumerV3 priceConsumerV3 = new PriceConsumerV3();
    uint priceOfBNB = priceConsumerV3.getThePrice();
    
    struct Buyer{
        bool buyStatus;
        uint totalTokensBought;
        Bought[] bought;
    }
    
    struct Bought {
        uint tokenBought;
        uint at;
    }
    
    struct Claim {
        uint[] claimAmounts;
        uint[] claimTimes;
    }
    
    StakingDetails stakeDetails = new StakingDetails();
    
    
    uint tier1Number = stakeDetails.oneCount();
    uint tier2Number = stakeDetails.twoCount();
    uint tier3Number = stakeDetails.threeCount();
    uint tier4Number = stakeDetails.fourCount();
    
    uint totalAllocation = 142857142 * 10**15;
    uint tier1Alloc = 214285713 * 10**14;
    uint tier2Alloc = 357142855 * 10**14;
    uint tier3Alloc = 357142855 * 10**14;
    uint tier4Alloc = 357142855 * 10**14;
    
    mapping(address => uint) public userAlloc;
    address private owner = msg.sender;
    address claimTokenAddr = 0x7467afa7C48132e8f8C90A919fC2ebA041207195; // clainTokenAddress
    address public contractAddr = address(this);
    uint public buyPrice;
    mapping(address => Buyer) public buyer;
    mapping(address => Claim) claim;
    mapping(address => bool) public updaterArr;
    bool public saleStatus;
    uint public saleEndTime;
    uint public time;
    address[] public updaterList;
    
    event Received(address, uint);
    event TokensBought(address, uint);
    event OwnershipTransferred(address);
    
    constructor() {
        buyPrice = 4;
        saleStatus = false;
        time = block.timestamp;
    }
    
    /// Fetch user top tier
    function getUserTier(address addr) public view returns(uint){
        return stakeDetails.getTopTier(addr);
    }
    
    /**
     * @dev Buy token 
     * 
     * Requirements:
     * USD amount should be between 50 and 500
     * totalAllocation cannot be overflown
     * saleStatus has to be true
     * cannot send zero value transaction
     */
    function buyToken() public payable returns(bool) {
        
        bool userStakeStatus = stakeDetails.stakeStatus(msg.sender);
        address sender = msg.sender;
        // uint amount = msg.value * priceOfBNB / 10*10**18;
        uint userTier = getUserTier(sender);
        // uint time = block.timestamp;
        
        uint tokens = (msg.value * priceOfBNB / 100000) / buyPrice;
        uint claimAmount = tokens * 50 / 100;
        uint remainingClaimAmount = tokens * 83333 / 1000000;
        
        require(saleStatus == true, "Sale not started or has finished");
        require(msg.value > 0, "Zero value");
        require(userStakeStatus == true,"Not staked");
        
        if(userTier == 0){
            if(userAlloc[sender] == 0){
                userAlloc[sender] = tier1Alloc / tier1Number;
                require(tokens <= userAlloc[sender], "User allocation error1");
                userAlloc[sender] -= tokens;
            }
            else{
                require(tokens <= userAlloc[sender], "User Allocation Error2");
                userAlloc[sender] -= tokens;
            }
            
        }
        else if(userTier == 1){
            if(userAlloc[sender] == 0){
                userAlloc[sender] = tier2Alloc / tier2Number;
                require(tokens <= userAlloc[sender], "User allocation error3");
                userAlloc[sender] -= tokens;
            }
            else{
                require(tokens <= userAlloc[sender], "User Allocation Error4");
                userAlloc[sender] -= tokens;
            }
        }
        else if(userTier == 2){
            if(userAlloc[sender] == 0){
                userAlloc[sender] = tier3Alloc / tier3Number;
                require(tokens <= userAlloc[sender], "User allocation error5");
                userAlloc[sender] -= tokens;
            }
            else{
                require(tokens <= userAlloc[sender], "User Allocation Error6");
                userAlloc[sender] -= tokens;
            }
        }
        else if(userTier == 3){
            if(userAlloc[sender] == 0){
                userAlloc[sender] = tier4Alloc / tier4Number;
                require(tokens <= userAlloc[sender], "User allocation error7");
                userAlloc[sender] -= tokens;
            }
            else{
                require(tokens <= userAlloc[sender], "User Allocation Error8");
                userAlloc[sender] -= tokens;            }
        }
        
        claim[sender].claimAmounts.push(claimAmount);
        claim[sender].claimAmounts.push(remainingClaimAmount);
        claim[sender].claimAmounts.push(remainingClaimAmount);
        claim[sender].claimAmounts.push(remainingClaimAmount);
        claim[sender].claimAmounts.push(remainingClaimAmount);
        claim[sender].claimAmounts.push(remainingClaimAmount);
        claim[sender].claimAmounts.push(remainingClaimAmount);
        
        claim[sender].claimTimes.push(time);
        claim[sender].claimTimes.push(time + 30 days);
        claim[sender].claimTimes.push(time + 60 days);
        claim[sender].claimTimes.push(time + 90 days);
        claim[sender].claimTimes.push(time + 120 days);
        claim[sender].claimTimes.push(time + 150 days);
        claim[sender].claimTimes.push(time + 180 days);
        
        buyer[sender].bought.push(Bought(tokens, block.timestamp));
        buyer[sender].totalTokensBought += tokens;
        buyer[sender].buyStatus = true;
        
        emit TokensBought(sender, tokens);
        return true;
    }
    
    // Set buy price 
    // Upto 3 decimals
    function setBuyPrice(uint _price) public {
        require(msg.sender == owner, "Only owner");
        buyPrice = _price;
    }
    
    // View tokens for bnb
    function getTokens(uint bnbAmt) public view returns(uint tokens) {
        
        tokens = (bnbAmt * priceOfBNB / 100000) / buyPrice;
        return tokens;
    }
    
    // View tokens for busd
    function getTokensForBusd(uint busdAmount) public view returns(uint tokens) {
        
        tokens = busdAmount / buyPrice * 10000;
        return tokens;
    }
    
    // Buy tokens with BUSD
    function buyTokenWithBUSD(uint busdAmount) public returns (bool) {
        
        bool userStakeStatus = stakeDetails.stakeStatus(msg.sender);

        BEP20 token = BEP20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F); // Terher address mainnet
        
        address sender = msg.sender;
        uint userTier = getUserTier(sender);
        uint tokens = busdAmount / buyPrice * 1000;
        uint claimAmount = tokens * 50 / 100;
        uint remainingClaimAmount = tokens * 83333 / 1000000;
        // uint time = block.timestamp;
                
        require(userStakeStatus == true,"Not staked");
        require(saleStatus == true, "Sale not started or has finished");
        
        if(userTier == 0){
            if(userAlloc[sender] == 0){
                userAlloc[sender] = tier1Alloc / tier1Number;
                require(tokens <= userAlloc[sender], "User allocation error1");
                userAlloc[sender] -= tokens;
            }
            else{
                require(tokens <= userAlloc[sender], "User Allocation Error2");
                userAlloc[sender] -= tokens;
            }
            
        }
        else if(userTier == 1){
            if(userAlloc[sender] == 0){
                userAlloc[sender] = tier2Alloc / tier2Number;
                require(tokens <= userAlloc[sender], "User allocation error3");
                userAlloc[sender] -= tokens;
            }
            else{
                require(tokens <= userAlloc[sender], "User Allocation Error4");
                userAlloc[sender] -= tokens;
            }
        }
        else if(userTier == 2){
            if(userAlloc[sender] == 0){
                userAlloc[sender] = tier3Alloc / tier3Number;
                require(tokens <= userAlloc[sender], "User allocation error5");
                userAlloc[sender] -= tokens;
            }
            else{
                require(tokens <= userAlloc[sender], "User Allocation Error6");
                userAlloc[sender] -= tokens;
            }
        }
        else if(userTier == 3){
            if(userAlloc[sender] == 0){
                userAlloc[sender] = tier4Alloc / tier4Number;
                require(tokens <= userAlloc[sender], "User allocation error7");
                userAlloc[sender] -= tokens;
            }
            else{
                require(tokens <= userAlloc[sender], "User Allocation Error8");
                userAlloc[sender] -= tokens;
            }
        }
        
        token.transferFrom(sender, contractAddr, busdAmount);
        
        
        
        claim[sender].claimAmounts.push(claimAmount);
        claim[sender].claimAmounts.push(remainingClaimAmount);
        claim[sender].claimAmounts.push(remainingClaimAmount);
        claim[sender].claimAmounts.push(remainingClaimAmount);
        claim[sender].claimAmounts.push(remainingClaimAmount);
        claim[sender].claimAmounts.push(remainingClaimAmount);
        claim[sender].claimAmounts.push(remainingClaimAmount);
        
        claim[sender].claimTimes.push(time);
        claim[sender].claimTimes.push(time + 30 days);
        claim[sender].claimTimes.push(time + 60 days);
        claim[sender].claimTimes.push(time + 90 days);
        claim[sender].claimTimes.push(time + 120 days);
        claim[sender].claimTimes.push(time + 150 days);
        claim[sender].claimTimes.push(time + 180 days);
        
        
        buyer[sender].bought.push(Bought(tokens, block.timestamp));
        buyer[sender].totalTokensBought += tokens;
        buyer[sender].buyStatus = true;
        
        emit TokensBought(sender, tokens);
        return true;
    }
    
    /** 
     * @dev Set sale status
     * 
     * Only to temporarily pause sale if necessary
     * Otherwise use 'endSale' function to end sale
     */
    function setSaleStatus(bool status) public returns (bool) {
        require(msg.sender == owner, "Only owner");
        saleStatus = status;
        return true;
    }
    
    // user stake status
    function stakeStat(address addr) public view returns(bool){
        bool status = stakeDetails.stakeStatus(addr);
        return status;
    }
    
    /** 
     * @dev End presale 
     * 
     * Requirements:
     * 
     * Only owner can call this function
     */
    function endSale() public returns (bool) {
        require(msg.sender == owner, "Only owner");
        saleStatus = false;
        saleEndTime = block.timestamp;
        return true;
    }
    
    /// Set claim token address
    function setClaimTokenAddress(address addr) public returns(bool) {
        require(msg.sender == owner, "Only owner");
        claimTokenAddr = addr;
        return true;
    }
    
    /// Set first claim time 
    function setFirstClaimTime(uint _time) public {
        require(msg.sender == owner, "Only owner");
        time = _time;
    }
    
    /** 
     * @dev Claim tokens
     * 
     */
    function claimTokens(uint index) public returns (bool) {
        require(claimTokenAddr != address(0), "Claim token address not set");
        BEP20 token = BEP20(claimTokenAddr);
        Claim storage _claim = claim[msg.sender];
        uint amount = _claim.claimAmounts[index];
        require(buyer[msg.sender].buyStatus == true, "Not bought any tokens");
        require(block.timestamp > _claim.claimTimes[index], "Claim time not reached");
        require(_claim.claimAmounts[index] != 0, "Already claimed");
        token.transfer(msg.sender, amount);
        delete _claim.claimAmounts[index];
        return true;
    }
    
    
    // Update claims for addresses with multiple entries
    function updateClaims(address addr, uint[] memory _amounts, uint[] memory _times) public {
        Claim storage clm = claim[addr];
        require(msg.sender == owner || updaterArr[msg.sender] == true, "Permission error");
        require(_amounts.length == _times.length, "Array length error");
        uint len = _amounts.length;
        for(uint i = 0; i < len; i++){
            clm.claimAmounts.push(_amounts[i]);
            clm.claimTimes.push(_times[i]);
        }
        buyer[addr].buyStatus = true;
    }
    
    // Update claims for address with single entries
    function updateClaimWithSingleEntry(address[] memory addr, uint[] memory amt, uint[] memory at) public {
        require(msg.sender == owner || updaterArr[msg.sender] == true, "Permission error");
        require(addr.length == amt.length && addr.length == at.length, "Array length error");
        uint len = addr.length;
        for(uint i = 0; i < len; i++){
            claim[addr[i]].claimAmounts.push(amt[i]);
            claim[addr[i]].claimTimes.push(at[i]);
        }
    }
    
    // Update entry for user at particular index 
    function indexValueUpdate(address addr, uint index, uint amount, uint _time) public {
        require(msg.sender == owner || updaterArr[msg.sender] == true , "Permission error");
        claim[addr].claimAmounts[index] = amount;
        claim[addr].claimTimes[index] = _time;
    }
    
    // Set updater address 
    function setUpdaterAddress(address to) public {
        require(msg.sender == owner, "Only owner");
        updaterArr[to] = true;
        updaterList.push(to);
    }
    
     // Set updater address 
    function removeUpdaterAddress(address to) public {
        require(msg.sender == owner, "Only owner");
        updaterArr[to] = false;
    }
    
    /// Tier allocation left 
    function getTier1Allocation() public view returns(uint) {
        return tier1Alloc;
    }
    
    function getTier2Allocation() public view returns(uint) {
        return tier2Alloc;
    }
    
    function getTier3Allocation() public view returns(uint) {
        return tier3Alloc;
    }
    
    function getTier4Allocation() public view returns(uint) {
        return tier4Alloc;
    }
    
    /// Get user allocation left
    function userAllocationLeft(address user) public view returns(uint amount) {
        uint tier = getUserTier(user);
        bool staked = stakeStat(user);
        
        if(staked == false){
            amount = 0;
        }
        else{
            if(userBuyStatus(user) == false){
                if(tier == 0){
                    amount = tier1Alloc / tier1Number;
                }
                else if(tier ==1){
                    amount = tier2Alloc / tier2Number;
                }
                else if(tier == 2){
                    amount = tier3Alloc / tier3Number;
                }
                else if(tier == 3){
                    amount = tier4Alloc / tier4Number;
                }
            }
            else{
                amount = userAlloc[user];
            }
        }
        return amount;
    }
    
    /// Return tier number values
    function tier1Count() public view returns (uint){
        return tier1Number;
    }
    
    function tier2Count() public view returns (uint){
        return tier2Number;
    }
    
    function tier3Count() public view returns (uint){
        return tier3Number;
    }
    
    function tier4Count() public view returns (uint){
        return tier4Number;
    }
    
    /// View owner address
    function getOwner() public view returns(address){
        return owner;
    }
    
    /// View sale end time
    function viewSaleEndTime() public view returns(uint) {
        return saleEndTime;
    }
    
    /// View Buy Price
    function viewPrice() public view returns(uint){
        return buyPrice;
    }
    
    /// Return bought status of user
    function userBuyStatus(address user) public view returns (bool) {
        return buyer[user].buyStatus;
    }
    
    /// Return sale status
    function showSaleStatus() public view returns (bool) {
        return saleStatus;
    }
    
    /// Return updater address
    function viewUpdater() public view returns (address[] memory updaterArrList) {
        
        updaterArrList = updaterList; 
       
    }
    
     /// Return updater SINGLE address
    function viewUpdaterSingle(address updateAddr) public view returns (bool) {
        
        return updaterArr[updateAddr];
       
    }
    
    /// Show Buyer Details
    function claimDetails(address addr) public view returns(uint[] memory amounts, uint[] memory times){
        uint len = claim[addr].claimAmounts.length;
        amounts = new uint[](len);
        times = new uint[](len);
        for(uint i = 0; i < len; i++){
            amounts[i] = claim[addr].claimAmounts[i];
            times[i] = claim[addr].claimTimes[i];
        }
        return (amounts, times);
    }
     
    /// Show USD Price of 1 BNB
    function usdPrice(uint amount) external view returns(uint) {
        uint bnbAmt = amount * priceOfBNB;
        return bnbAmt/100000000;
    }
    
    // Owner Token Withdraw    
    // Only owner can withdraw token 
    function withdrawToken(address tokenAddress, address to, uint amount) public returns(bool) {
        require(msg.sender == owner, "Only owner");
        require(to != address(0), "Cannot send to zero address");
        BEP20 token = BEP20(tokenAddress);
        token.transfer(to, amount);
        return true;
    }
    
    // Owner BNB Withdraw
    // Only owner can withdraw BNB from contract
    function withdrawBNB(address payable to, uint amount) public returns(bool) {
        require(msg.sender == owner, "Only owner");
        require(to != address(0), "Cannot send to zero address");
        to.transfer(amount);
        return true;
    }
    
    // Ownership Transfer
    // Only owner can call this function
    function transferOwnership(address to) public returns(bool) {
        require(msg.sender == owner, "Only owner");
        require(to != address(0), "Cannot transfer ownership to zero address");
        owner = to;
        emit OwnershipTransferred(to);
        return true;
    }
    
    // Fallback
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}