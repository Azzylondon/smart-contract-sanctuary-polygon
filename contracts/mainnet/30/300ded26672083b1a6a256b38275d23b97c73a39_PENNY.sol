/**
 *Submitted for verification at polygonscan.com on 2021-09-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

struct GeneralDetails {
    string _name;
    string _symbol;
    uint8 _decimals;
    uint256 _totalSupply;
    uint256 _totalStake;   
    uint256 _activeStakers;
    uint256 _totalRewardPaid;
    bool _isPaused;
    uint256 _swapOut;
    uint256 _swapIn;
    uint256 _burned; //10
    
    uint256 _charityPool;
    uint256 _stakePool;
    uint256 _burnPool;
    uint256 _protocolPool;
    uint256 _lastProtocolPool;
    uint256 _lastCharityPool; //16
    
    //protocol update
    address _validatorAdd;
    string _validatorApi;
    uint256 _maxSupply;
    uint256 _maxTxLimit;        
    uint256 _voteApproveRate;    
    uint256 _propDuration;
    uint256 _stakeTax;
    uint256 _charityTax;
    uint256 _burnTax;
    uint256 _protocolTax;
    uint256 _propStakeAmount;  
    uint256 _stakeLocktime;
    uint256 _changeDate; //29
}

struct UserDetails {
    uint256 _balances;
    uint256 voteStatus;
    uint256 propStatus;
    uint256 nonce;
    uint256 stakeDate;
    uint256 collateral;
    uint256 tempReward;
    uint256 stakePool;
    uint256 rewardPaid;
} 

struct VoteData {
    address account;
    uint256 cycle;
    uint256 startDate;
    uint256 endDate;
    uint256 value;
    uint256 voteCount;
    string info;
    uint256 status;
}

abstract contract Context {
    
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    
}

interface AFTS {
    
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);      

    function isPaused() external view returns (bool);
    
    function generalDetails() external view returns(GeneralDetails memory);

    function userDetails(address account) external view returns(UserDetails memory);  
    
    function voteCycleDetails(uint256 cycle, string memory config) external view returns (VoteData memory);
    
    function voteAllDetails() external view returns (VoteData[11] memory);
    
    function swapInfo(uint256 nonceOut, bytes32 txid, uint256 method, address account) external view returns (uint256);
    
    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    function burn(uint256 amount, uint256 swapNonce, uint256 chainId) external returns (bool);
    
    function transferMulti(address[] memory to, uint256[] memory amount) external returns (bool);  
    
    function transferMultiFrom(address sender, address[] memory to, uint256[] memory amount) external returns (bool);    

	function byToken(
	    bytes[] memory sig, 
	    uint256[] memory details, //0-type,1-fees,2-method/swapNonce,3-chainID,4-swapFees
	    address[] memory accounts, //0-sender, 1-spender
	    address[] memory recipient, 
	    uint256[] memory amount, //0-amount/collateral,1-method,2-otherSupply,3-otherStake,4-otherPool,5-otherStakers,6-otherPaid
	    string[] memory info, //0-config,1-url
	    bytes32 txid
    ) external returns (bool);
    
    function stake(uint256[] memory info, bytes memory sig) external returns (bool);
    
    function propose(string memory config, string memory info, uint256 value, address account) external returns (bool);
    
    function vote(string memory config) external returns (bool);
    
    function mint(bytes32 txid, uint256 swapNonce, uint256 amount, uint256 fees, uint256 fromId, bytes memory sig) external returns (bool);   
    
    function protocolUpdate(uint256[] memory newConfig, address account, string memory info, uint256 status) external returns (bool);
    
    event Transfer(address indexed sender, address indexed recipient, uint256 value);

    event Approval(address indexed approver, address indexed spender, uint256 value);
    
    event Tax(address indexed payer, uint256 stake, uint256 burn, uint256 charity, uint256 protocol, uint256 total);
    
    event EventMethod(address indexed requester, string method);
     
    event Proposer(address indexed proposer, string indexed config, uint256 value, address account);
    
    event Voter(address indexed voter, string indexed config); 
    
    event Protocol(address indexed validator, uint256[] newConfig, address account, string info, uint256 status);
    
}

contract PENNY is Context, AFTS {
    
    GeneralDetails _general;
    
    mapping(string =>  uint256) private _genConfig;
    
    mapping(address =>  UserDetails) private _user;
    
    mapping(address => mapping(address => uint256)) private _allowances;
    
    mapping(address =>  mapping(bytes32 => uint256)) private _swapIn;
    
    mapping(address =>  mapping(uint256 => uint256)) private _swapOut;
    
    mapping(address =>  mapping(uint256 =>  mapping(string =>  uint256))) private _userVote;
    
    mapping(uint256 =>  mapping(string =>  VoteData)) private _vote;
    
    mapping(string =>  uint256) private _voteCycle;
    
    constructor () {
        _general._name = "PENNY";
        _general._symbol = "PENNY";
        _general._decimals = 18;
        _general._validatorAdd = _msgSender();
        _general._validatorApi = "https://validator.pennytoken.org/";
        _general._totalSupply = (block.chainid == 56) ? 50000000000000*1e18 : 0;
        _general._maxSupply = 50000000000000*1e18;
        _genConfig["maxTxLimit"] = 200;
        _genConfig["voteApproveRate"] = 51; 
        _genConfig["propDuration"] = 2592000;
        _genConfig["stakeTax"] = 2*1e18;
        _genConfig["charityTax"] = 0.5*1e18;
        _genConfig["burnTax"] = 2*1e18;
        _genConfig["protocolTax"] = 0.5*1e18;
        _genConfig["propStakeAmount"] = 100000000000*1e18;
        _genConfig["stakeLocktime"] = 604800;
        _general._isPaused = false;
        _transfer(address(0), 0xB713b0cFAEE5dFE7Bd81839d97F454bf86DaF58a, _general._totalSupply, 0, address(0));
    }

    function name() public view virtual override returns (string memory) {
        return _general._name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _general._symbol;
    }

    function decimals() public view virtual override returns (uint256) {
        return _general._decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _general._totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _user[account]._balances;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function isPaused() public view virtual override returns (bool) {
        return _general._isPaused;
    }   

    function generalDetails() public view virtual override returns(GeneralDetails memory){
        GeneralDetails memory gendet = _general;
        gendet._maxTxLimit = _genConfig["maxTxLimit"];
        gendet._voteApproveRate = _genConfig["voteApproveRate"];
        gendet._propDuration = _genConfig["propDuration"];
        gendet._stakeTax = _genConfig["stakeTax"];
        gendet._charityTax = _genConfig["charityTax"];
        gendet._burnTax = _genConfig["burnTax"];
        gendet._protocolTax = _genConfig["protocolTax"];
        gendet._propStakeAmount = _genConfig["propStakeAmount"];  
        gendet._stakeLocktime = _genConfig["stakeLocktime"];
        return gendet;        
    }
    
    function userDetails(address account) public view virtual override returns(UserDetails memory){
        return _user[account];
    }  
  
    function voteCycleDetails(uint256 cycle, string memory config) public view virtual override returns (VoteData memory) {
        if(cycle == 0){
            cycle = _voteCycle[config];
        }
        
        return _vote[cycle][config];
    }

    function voteAllDetails() public view virtual override returns (VoteData[11] memory) {
        VoteData[11] memory allVote;  
        allVote[0] = _vote[_voteCycle["charity"]]["charity"];
        allVote[1] = _vote[_voteCycle["maxTxLimit"]]["maxTxLimit"];
        allVote[2] = _vote[_voteCycle["voteApproveRate"]]["voteApproveRate"];
        allVote[3] = _vote[_voteCycle["propDuration"]]["propDuration"];
        allVote[4] = _vote[_voteCycle["stakeTax"]]["stakeTax"];
        allVote[5] = _vote[_voteCycle["charityTax"]]["charityTax"];
        allVote[6] = _vote[_voteCycle["burnTax"]]["burnTax"];
        allVote[7] = _vote[_voteCycle["protocolTax"]]["protocolTax"];
        allVote[8] = _vote[_voteCycle["propStakeAmount"]]["propStakeAmount"];
        allVote[9] = _vote[_voteCycle["stakeLocktime"]]["stakeLocktime"];
        allVote[10] = _vote[_voteCycle["validatorAdd"]]["validatorAdd"];
        return allVote;
    }     
    
    function swapInfo(uint256 nonceOut, bytes32 txid, uint256 method, address account) public view virtual override returns (uint256) {
        if(method == 0){
            return _swapOut[account][nonceOut];
        } else {
            return _swapIn[account][txid];
        }
    }    

    function _transfer(address sender, address recipient, uint256 amount, uint8 method, address spender) internal virtual {
        require(!_general._isPaused, "Contract is Paused");
        
        if(method > 0){
            require(sender != address(0), "from zero address");
            require(recipient != address(0), "to zero address");
        }

        if(method == 2){
            require(_allowances[sender][spender] >= amount, "amount exceeds allowance");
        } 
            
        if(sender != address(0)){
            require(_user[sender]._balances >= amount, "amount exceeds balance");
            _user[sender]._balances -= amount;
            if(method == 2){
                _approve(sender, _msgSender(), _allowances[sender][spender] - amount);
            }
        }
        
        if(recipient != address(0)){
            _user[recipient]._balances += amount;
        }
        
        emit Transfer(sender, recipient, amount);
    }
    
    function _tax(address account, uint256 amount) internal {
        uint256 totalTax = (amount * (_genConfig["stakeTax"] + _genConfig["charityTax"] + _genConfig["burnTax"] + _genConfig["protocolTax"])) / (100*1e18);
        uint256 stakeTax = (totalTax * ((_genConfig["stakeTax"] * 100) / (_genConfig["stakeTax"] + _genConfig["charityTax"] + _genConfig["burnTax"] + _genConfig["protocolTax"]))) / 100;
        uint256 charityTax = (totalTax * ((_genConfig["charityTax"] * 100) / (_genConfig["stakeTax"] + _genConfig["charityTax"] + _genConfig["burnTax"] + _genConfig["protocolTax"]))) / 100;
        uint256 burnTax = (totalTax * ((_genConfig["burnTax"] * 100) / (_genConfig["stakeTax"] + _genConfig["charityTax"] + _genConfig["burnTax"] + _genConfig["protocolTax"]))) / 100;
        uint256 protocolTax = (totalTax * ((_genConfig["protocolTax"] * 100) / (_genConfig["stakeTax"] + _genConfig["charityTax"] + _genConfig["burnTax"] + _genConfig["protocolTax"]))) / 100;
        require((totalTax + amount) <= _user[account]._balances, "Transfer + Tax amount exceeds balance");
        _transfer(account, address(0), totalTax, 0, address(0));
        _general._stakePool += stakeTax;
        _general._charityPool += charityTax;
        _general._burnPool += burnTax;
        _general._protocolPool += protocolTax;
        _general._totalSupply -= totalTax;
        emit Tax(account, stakeTax, burnTax, charityTax, protocolTax, totalTax);
    }    
    
    function _transferMulti(address sender, address[] memory to, uint256[] memory amount, uint8 method, address spender) internal virtual {
		require(_genConfig["maxTxLimit"] >= to.length, "greater than _maxTxLimit");        
		require(to.length == amount.length, "array length not equal");
		uint256 sum_;
		
        for (uint8 g; g < to.length; g++) {
            require(to[g] != address(0), "to zero address");
            sum_ += amount[g];            
        }
        
        require(_user[sender]._balances >= sum_, "amount exceeds balance");
        _tax(sender, sum_); 
        
        if(method == 2){
            require(_allowances[sender][spender] >= sum_, "amount exceeds allowance");           
        }
        
		for (uint8 i; i < to.length; i++) {
		    _transfer(sender, to[i], amount[i], method, address(0));
		}        
    }   
    
    function _approve(address sender, address spender, uint256 amount) internal virtual {
        require(!_general._isPaused, "Contract is Paused");
        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }
    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {     
        _tax(_msgSender(), amount);  
        _transfer(_msgSender(), recipient, amount, 1, address(0));
        return true;
    }
    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _tax(_msgSender(), amount); 
        _transfer(sender, recipient, amount, 2, _msgSender());
        return true;
    }

	function transferMulti(address[] memory to, uint256[] memory amount) public virtual override returns (bool) {
		_transferMulti(_msgSender(), to, amount, 1, address(0));
        return true;
	}
	
	function transferMultiFrom(address sender, address[] memory to, uint256[] memory amount) public virtual override returns (bool) {
		_transferMulti(sender, to, amount, 2, _msgSender());
        return true;
	} 
	
	function byToken(
	    bytes[] memory sig, 
	    uint256[] memory details, //0-type,1-fees,2-method/swapNonce,3-chainID,4-swapFees
	    address[] memory accounts, //0-sender, 1-spender
	    address[] memory recipient, 
	    uint256[] memory amount, //0-amount/collateral,1-method,2-otherSupply,3-otherStake,4-otherPool,5-otherStakers,6-otherPaid
	    string[] memory info, //0-config,1-url
	    bytes32 txid
    ) public virtual override returns (bool) {
	    require(_msgSender() == _general._validatorAdd, "Only Validator Allowed");
        _sigValidate(sig[0], keccak256(abi.encodePacked(accounts[0], details[0], details[1], _user[accounts[0]].nonce + 1)), accounts[0]);
	    require(details[0] >= 0 && details[0] < 8, "Invalid Type");
	    _transfer(accounts[0], _general._validatorAdd, details[1], 0, address(0));
	    if(details[0] == 0){
    	    if(details[2] == 1){ 
    	        _transfer(accounts[0], recipient[0], amount[0], 1, address(0));
    	    } else if(details[2] == 2){ 
                _transfer(accounts[0], recipient[0], amount[0], 2, accounts[1]); 
    	    } else if(details[2] == 3){ 
    	        _approve(accounts[0], accounts[1], amount[0]); 
    	    } else if(details[2] == 4){ 
    	        _transferMulti(accounts[0], recipient, amount, 1, address(0));
    	    } else if(details[2] == 5){ 
    	        _transferMulti(accounts[0], recipient, amount, 2, accounts[1]);
    	    }
	    } else if(details[0] > 0 && details[0] < 4){ 
	        _stakeProcess(accounts[0], amount, sig[1]);
	    } else if(details[0] == 4){
	        _propose(accounts[0], info[0], info[1], amount[0], recipient[0]);
	    } else if(details[0] == 5){
	        _voteProcess(accounts[0], info[0]);
	    } else if(details[0] == 6){
	        _burn(accounts[0], amount[0], details[2], details[3]);
	    } else if(details[0] == 7){
	        _mint(accounts[0], txid, details[2], amount[0], details[4], details[3], sig[1]);
	    }
	    _user[accounts[0]].nonce += 1;
	    return true;
	}
        
    function stake(uint256[] memory info, bytes memory sig) public virtual override returns (bool) { //info[] 0-collateral,1-method,2-otherSupply,3-otherStake,4-otherPool,5-otherStakers,6-otherPaid
        _stakeProcess(_msgSender(), info, sig);
        return true;
    }  
    
    function _stakeProcess(address staker, uint256[] memory info, bytes memory sig) internal virtual {
        uint256 tempReward;
        require(!_general._isPaused, "Contract is Paused");
        _sigValidate(sig, keccak256(abi.encodePacked(staker, info[0], info[2], info[3], info[4], info[5], info[6], block.chainid, _user[staker].nonce + 1, true)), _general._validatorAdd);
        _user[staker].nonce += 1;         
        require(staker != address(0), "from zero address");
        require(info[1] >= 0 && info[1] < 4, "Invalid Method");
        require((info[1] < 2)?info[0] > 0:info[0] == 0, "Invalid Amount");
        if(_user[staker].collateral > 0){
            if((_general._activeStakers + info[5]) > 1){
                tempReward = (((_user[staker].collateral * 1e18) / (_general._totalStake + info[3])) * ((_general._stakePool + info[4]) - _user[staker].stakePool)) / 1e18;
            } else {
                if(((_general._stakePool + info[4]) - (_general._totalRewardPaid + info[6])) > 0){
                    tempReward = (_general._stakePool + info[4]) - (_general._totalRewardPaid + info[6]);
                }
            }
        }
        
        if(info[1] < 2){
            
            if(info[1] == 0){
                require(!(_user[staker].collateral > 0), "Already Staking");
            } else {
                require(_user[staker].collateral > 0, "Staking Inactive");
            }
            
            _transfer(staker, address(0), info[0], 0, address(0));
            
            _user[staker].stakeDate = block.timestamp;
            _user[staker].stakePool = _general._stakePool + info[4];
            _general._totalStake += info[0];
            _user[staker].collateral += info[0];
            _user[staker].voteStatus = 1;
            if(_user[staker].collateral >= _genConfig["propStakeAmount"]){
                _user[staker].propStatus = 1;
            }            
            if(info[1] == 1){
                _user[staker].tempReward += tempReward;
            } else {
               _general._activeStakers += 1;
            }
            
        } else {
            require(_user[staker].collateral > 0, "Staking Inactive");

            if(info[1] == 2){
                require(block.timestamp >= (_user[staker].stakeDate + _genConfig["stakeLocktime"]), "Stake collateral claim date not reached");
                _transfer(address(0), staker, _user[staker].collateral, 0, address(0));
                _general._totalStake -= _user[staker].collateral;
                _user[staker].propStatus = 0;
                _user[staker].voteStatus = 0;
                _user[staker].collateral = 0;
                _general._activeStakers -= 1;
            }
            
            _transfer(address(0), staker, tempReward + _user[staker].tempReward, 0, address(0));
            _user[staker].stakePool = _general._stakePool + info[4];  
            _user[staker].rewardPaid += tempReward + _user[staker].tempReward; 
            _general._totalSupply += tempReward + _user[staker].tempReward;  
            _general._totalRewardPaid += tempReward + _user[staker].tempReward;  
            _user[staker].tempReward = 0;
        }
        
        emit EventMethod(staker, "Stake");
    }        

    function propose(string memory config, string memory info, uint256 value, address account) public virtual override returns (bool) {
        _propose(_msgSender(), config, info, value, account);
        return true;
    }
    
    function _propose(address sender, string memory config, string memory info, uint256 value, address account) internal {
        require(_user[sender].propStatus == 1, "Can't Propose");
        uint256 date = block.timestamp;
        uint256 cycle = _voteCycle[config];
        require((date - _vote[cycle][config].startDate) > _genConfig["propDuration"], "Old Active");
        _vote[cycle][config].status = 3;
        _voteCycle[config] += 1;
        cycle = _voteCycle[config];
        _vote[cycle][config].cycle = _voteCycle[config];
        _vote[cycle][config].startDate = date; 
        
        if(keccak256(bytes(config)) == keccak256(bytes("validatorAdd")) || keccak256(bytes(config)) == keccak256(bytes("charity"))){
            _vote[cycle][config].account = account;
        } else {
            _vote[cycle][config].value = value; 
        }  
        
        _vote[cycle][config].status = 1;
        _vote[cycle][config].info = info;
        emit Proposer(sender, config, value, account);        
    }

    function vote(string memory config) public virtual override returns (bool) {
        _voteProcess(_msgSender(), config);
        return true;
    } 
    
    function _voteProcess(address sender, string memory config) internal {
        require(_user[sender].voteStatus == 1, "Can't Vote");
        uint256 date = block.timestamp;
        uint256 cycle = _voteCycle[config];
        require(_vote[cycle][config].status == 1, "Voting Finished");
        require(_userVote[sender][cycle][config] == 0, "Already Voted");
        _userVote[sender][cycle][config] = 1;
        _vote[cycle][config].voteCount += 1;
        
        if(_vote[cycle][config].voteCount >= ((_general._activeStakers * _genConfig["voteApproveRate"]) / 100)){
  
            _vote[cycle][config].status = 2;
            _vote[cycle][config].endDate = date;
            _general._changeDate = date;
            
            if(keccak256(bytes(config)) == keccak256(bytes("charity"))){
                _transfer(address(0), _vote[cycle][config].account, _general._charityPool - _general._lastCharityPool, 0, address(0));
                emit EventMethod(_vote[cycle][config].account, "Charity");
                _general._lastCharityPool = _general._charityPool;
            } else if(keccak256(bytes(config)) == keccak256(bytes("validatorAdd"))){
                _general._validatorAdd = _vote[cycle][config].account;
                _general._validatorApi = _vote[cycle][config].info;
            } else {
                _genConfig[config] = _vote[_voteCycle[config]][config].value;
            }           
        }        
        emit Voter(sender, config);        
    }

    function _splitSignature(bytes memory sig) internal pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65);
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
       return (v, r, s);
    }       
   
    function _sigValidate(bytes memory sig, bytes32 hash, address account) internal pure {
        (uint8 v, bytes32 r, bytes32 s) = _splitSignature(sig);
        require(ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), v, r, s) == account, "Not Authorized");
    }

    function burn(uint256 amount, uint256 swapNonce, uint256 chainId) public virtual override returns (bool) {
        _burn(_msgSender(), amount, swapNonce, chainId);
        return true;
    }

    function _burn(address sender, uint256 amount, uint256 swapNonce, uint256 chainId) internal {
        _transfer(sender, address(0), amount, 0, address(0));
        
        if(swapNonce > 0){
            _swapOut[sender][swapNonce] = chainId;
            _general._swapOut += amount;
        } else {
            _general._burned += amount;
        }
        
        _general._totalSupply -= amount;
        emit EventMethod(sender, "Burn");
    }    
    
    function mint(bytes32 txid, uint256 swapNonce, uint256 amount, uint256 fees, uint256 fromId, bytes memory sig) public virtual override returns (bool) {
        _mint(_msgSender(), txid, swapNonce, amount, fees, fromId, sig);
        return true;
    }  
    
    function _mint(address sender, bytes32 txid, uint256 swapNonce, uint256 amount, uint256 fees, uint256 fromId, bytes memory sig) internal {
        require(!_general._isPaused, "Contract is Paused");
        require(_swapIn[sender][txid] == 0, "Already Swapped");
        _sigValidate(sig, keccak256(abi.encodePacked(sender, txid, swapNonce, amount, fees, fromId, block.chainid, true)), _general._validatorAdd);
        _transfer(address(0), sender, amount - fees, 0, address(0));
        _transfer(address(0), _general._validatorAdd, fees, 0, address(0));
        _general._totalSupply += amount;
        _swapIn[sender][txid] = swapNonce;
        _general._swapIn += amount;
        emit EventMethod(sender, "Mint");
        emit EventMethod(_general._validatorAdd, "Swap Fee");
    }    
    
    function protocolUpdate(uint256[] memory newConfig, address account, string memory info, uint256 status) public virtual override returns (bool) {
        require(_msgSender() == _general._validatorAdd, "Only Validator Allowed");
        if(newConfig.length == 10){
            _genConfig["maxTxLimit"] = newConfig[0];
            _genConfig["voteApproveRate"] = newConfig[1]; 
            _genConfig["propDuration"] = newConfig[2];
            _genConfig["stakeTax"] = newConfig[3];
            _genConfig["charityTax"] = newConfig[4]; 
            _genConfig["burnTax"] = newConfig[5];
            _genConfig["protocolTax"] = newConfig[6];
            _genConfig["propStakeAmount"] = newConfig[7]; 
            _genConfig["stakeLocktime"] = newConfig[8];
            _general._changeDate = newConfig[9];
        }
        
        if(account != address(0)){
           _general._validatorAdd = account;
           _general._validatorApi = info;
        }
        
        if(status > 0){
            _general._isPaused = (status == 1)?true:false;
        }
        _transfer(address(0), _msgSender(), _general._protocolPool - _general._lastProtocolPool, 0, address(0));
        _general._lastProtocolPool = _general._protocolPool; 
        emit EventMethod(_msgSender(), "Validator");       
        emit Protocol(_msgSender(), newConfig, account, info, status);
        return true;
    } 

}