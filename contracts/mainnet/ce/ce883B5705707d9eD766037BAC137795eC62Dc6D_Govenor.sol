/**
 *Submitted for verification at polygonscan.com on 2021-09-28
*/

// Sources flattened with hardhat v2.0.4 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]


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
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File contracts/Infected.sol

pragma solidity ^0.8.0;


contract Infected is Ownable {

	struct Bet {
		uint number;
		uint amount;
    bool claimed;
		bool betPlaced;
	}

	struct Result {
		uint number;
		bool committed;
	}

	// round ID => pot
	mapping(uint => uint) public pots;
	// round ID => address => number of covid cases
	mapping(uint => mapping(address => Bet)) public bets;
	// round ID => number of covid cases => bet total
	mapping(uint => mapping(uint => uint)) public betTotals;
	// round ID => result
	mapping(uint => Result) public results;
	// min bet
	uint public minBet;
	// fee address
	address public feeAddress;
	// betting asset
	IERC20 public bettingAsset;
	// range of your bet to win eg within 10, 100, 1000 etc.
	uint public range;

	address public govenor;

	event BetPlaced(uint number, uint amount, uint roundId, address sender);

	event RoundResult(uint roundId, uint number);

	event Claim(uint roundId, uint number, uint amount, address sender);

	constructor(address _feeAddress, IERC20 _bettingAsset, uint _minBet, uint _range, address _govenor) {
		minBet = _minBet;
		feeAddress = _feeAddress;
		bettingAsset = _bettingAsset;
		range = _range;
		govenor = _govenor;
	}

	modifier onlyGovenor() {
		require(msg.sender == govenor, "governor only");
		_;
	}

	function setFeeAddress(address _feeAddress) external {
    	require(msg.sender == feeAddress, "not fee address");
		feeAddress = _feeAddress;
	}

	function setMinBet(uint _minBet) external onlyOwner {
		minBet = _minBet;
	}

	function setRange(uint _range) external onlyOwner {
		range = _range;
	}

	function setGovenor(address _govenor) external onlyOwner {
		govenor = _govenor;
	}

	function placeBet(uint _number, uint _amount) external {
		require(_number % range == 0, "number is not in the range");
		require(_amount >= minBet, "amount not greater than min bet");
		uint currentRound = _getRoundId(block.timestamp);
		Bet storage bet = bets[currentRound][msg.sender];
		require(bet.betPlaced == false, "sender already placed bet");
		// transfer fee to fee address 
		uint fee = _amount * 1000 / 1e4;
		if(fee > 0) {
			bettingAsset.transferFrom(msg.sender, feeAddress, fee);
		}
		// transfer bet amount to contract
		uint amountMinFee = _amount - fee;
		bettingAsset.transferFrom(msg.sender, address(this), amountMinFee);
		// save bet
		bet.number = _number;
		bet.amount = amountMinFee;
		bet.betPlaced = true;
		// update states
		betTotals[currentRound][_number] += amountMinFee;
		pots[currentRound] += amountMinFee;
		emit BetPlaced(_number, _amount, currentRound, msg.sender);
	}

	function claim(uint _roundId) external {
		Bet storage bet = bets[_roundId][msg.sender];
		require(bet.betPlaced == true, "sender has not placed a bet for this round");
    require(bet.claimed == false, "sender has already claimed bet");
    bet.claimed = true;

		Result memory result = results[_roundId];
		require(result.committed == true, "round not committed");
		require(result.number == bet.number, "bet was not correct");
    
		uint pot = pots[_roundId];
		uint winnings = pot * bet.amount / betTotals[_roundId][result.number];
		_safeTransferBettingAsset(msg.sender, winnings);
		emit Claim(_roundId, result.number, winnings, msg.sender);
	}
  
	function commitResult(uint number, uint roundId) external onlyGovenor {
		Result storage result = results[roundId];	
		require(result.committed == false, "result already committed");
		result.number = number;
		result.committed = true;

    if(betTotals[roundId][number] == 0) {
      // nobody bet for this number so the pot rolls over
      uint nextRoundId = roundId + 1;
      while(results[roundId + 1].committed) {
        nextRoundId += 1;
      }
      pots[nextRoundId] += pots[roundId];
    }

		emit RoundResult(roundId, number);
	}

	function _safeTransferBettingAsset(address to, uint amount) private {
		uint balance = bettingAsset.balanceOf(address(this));
		if(balance < amount) {
			amount = balance;
		}
		bettingAsset.transfer(to, amount);	
	}

  function getRoundId() external view returns (uint) {
    return _getRoundId(block.timestamp);
  }

  function _getRoundId(uint256 timestamp) internal virtual pure returns (uint) {
    uint secondsInDay = 86400;
    return (timestamp - (timestamp % secondsInDay)) / secondsInDay;
  }
}


// File contracts/Govenor.sol

pragma solidity ^0.8.0;


contract Govenor is Ownable {

  struct Proposal {
    // timestamp for when the lock expires and the proposal
    // can be executed
    uint lockExpires;
    // number of cases to be committed
    uint number;
    // the infected round ID
    uint roundId;
    // number of votes against this commitment senders votes
    // are proportional to their stake in the pot
    uint votesAgainst;
    // total pot for this round ID
    uint pot;
  }

  Infected public infected;

  uint public MINIMUM_DELAY = 8 hours;

  uint public quorum = 40;

  uint public delay;
  
  // signature key mapped to proposal
  mapping(bytes32 => Proposal) public proposals;
  // votes against a committment
  mapping(bytes32 => uint) public votesAgainst;
  // address voted against
  mapping(bytes32 => mapping(address => bool)) public addressVotedAgainst;

  event Proposed(uint number, uint roundId);

  event Committed(uint number, uint roudId);

  event VotedAgainst(uint number, uint roundId);

  constructor(uint _delay) {
    require(_delay >= MINIMUM_DELAY, "delay less than minimum delay");
    delay = _delay;
  }

  function setInfected(Infected _infected) external onlyOwner {
    infected = _infected;
  }

  function setQuorum(uint _quorum) external onlyOwner {
    quorum = _quorum;
  }

  function setDelay(uint _delay) external virtual onlyOwner {
    require(_delay >= MINIMUM_DELAY, "delay less than minimum delay");
    delay = _delay;
  }

  function propose(uint number, uint roundId) external onlyOwner {
    require(infected.getRoundId() > roundId, "round ID greater than latest round ID");
    (,bool committed) = infected.results(roundId);
    require(committed == false, "round already committed");

    bytes32 txHash = keccak256(abi.encode(number, roundId));
    Proposal storage proposal = proposals[txHash];
    proposal.number = number;
    proposal.roundId = roundId;
    proposal.lockExpires = block.timestamp + delay; 
    proposal.pot = infected.pots(roundId);
    
    emit Proposed(number, roundId);
  }

  function commit(uint number, uint roundId) external {
    // require votes against not to be more than 40% of the round ID pot
    require(_isProposalDeclined(number, roundId) == false, "committement has been voted against");
    bytes32 txHash = keccak256(abi.encode(number, roundId));
    Proposal storage proposal = proposals[txHash];
    require(proposal.lockExpires != 0, "proposal not committed");
    require(block.timestamp >= proposal.lockExpires, "lock not expired");

    infected.commitResult(number, roundId);

    emit Committed(number, roundId);
  }

  function voteAgainst(uint number, uint roundId) external {
    bytes32 txHash = keccak256(abi.encode(number, roundId));
    require(addressVotedAgainst[txHash][msg.sender] == false, "sender already voted against");
    // require msg.sender to have participated in round ID
    (,uint amount,,bool betPlaced) = infected.bets(roundId, msg.sender);
    require(betPlaced == true, "sender has not bet for this round");
    // require roundId to not already have committed
    (,bool committed) = infected.results(roundId);
    require(committed == false, "round already comitted");

    votesAgainst[txHash] += amount;
    addressVotedAgainst[txHash][msg.sender] = true;

    emit VotedAgainst(number, roundId);
  }

  function summary(uint number, uint roundId) public view returns (uint, uint) {
    bytes32 txHash = keccak256(abi.encode(number, roundId));
    uint voteCount = votesAgainst[txHash];
    Proposal memory proposal = proposals[txHash];
    return (voteCount, proposal.pot);
  }

  function _isProposalDeclined(uint number, uint roundId) internal view returns (bool) {
    bytes32 txHash = keccak256(abi.encode(number, roundId));
    uint votesAgainstCount = votesAgainst[txHash]; 
    
    Proposal memory proposal = proposals[txHash];
    return votesAgainstCount / proposal.pot * 100 > quorum;
  }
}