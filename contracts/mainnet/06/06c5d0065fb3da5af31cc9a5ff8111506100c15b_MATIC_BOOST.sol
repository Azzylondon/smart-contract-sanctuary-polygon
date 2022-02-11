/**
 *Submitted for verification at polygonscan.com on 2022-01-02
*/

// File: @chainlink/contracts/src/v0.8/VRFRequestIDBase.sol

pragma solidity ^0.8.0;

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// File: @chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol


pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// File: @chainlink/contracts/src/v0.8/VRFConsumerBase.sol


pragma solidity ^0.8.0;



/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// File: contracts/MATIC_BOOST.sol


pragma solidity ^0.8.0;


contract MATIC_BOOST is VRFConsumerBase {
  using SafeMath for uint256;

    uint256 public random;
    bytes32 internal linkKeyHash;
    uint256 internal linkFee;
    bytes32 internal linkRequestId;

    uint256 public constant MIN_INVESTMENT = 10 ether;
    uint256 public constant REFERRAL_BONUS = 5;
    uint256 public constant COMPOUND_BONUS = 10;
    uint256 public constant DEV_FEE = 8;
    uint256 public constant PERCENTS_DIVIDER = 100;
    uint256 public constant TIME_STEP = 1 days;
    uint256 public constant BOOST_DELAY = 1 days;

    uint256 public constant PLAN_LENGTH = 9999999999;
    uint256 public constant PLAN_ROI_DAILY = 3;
    uint256[10] internal BOOSTS;

    uint256 public totalDeposits;
    uint256 public totalInvested;
    uint256 public totalReferrals;
    uint256 public totalBoosts;

    struct Plan {
      uint256 time;
      uint256 percent;
    }

    struct Deposit {
      uint256 amount;
      uint256 start;
      uint256 compoundExtension;
    }

    struct User {
      Deposit[] deposits;
      uint256 checkpoint;
      address referrer;
      uint256 referrals;
      uint256 referral;
      uint256 totalReferral;
      uint256 withdrawn;
      uint256 compounded;
      uint256 boost;
      uint256 totalBoost;
      uint256 lastBoosted;
      uint256 boostPercent;
    }

    mapping(address => User) internal users;

    address payable public ceo1;
    address payable public ceo2;

    event NewUser(address user);
    event NewDeposit(address indexed user, uint256 amount);
    event Referral(address indexed referrer, address indexed referral, uint256 amount);
    event Compound(address indexed user, uint256 amount);
    event Boost(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor() VRFConsumerBase(0x3d2341ADb2D31f1c5530cDC622016af293177AE0, 0xb0897686c545045aFc77CF20eC7A532E3120E0F1) {
      ceo1 = payable(msg.sender);
      ceo2 = payable(0xc2d5B2EeD93475F4E2782A2eAC2463c568e03327);

      linkKeyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
      linkFee = 0.0001 ether;
      linkRequestId = 0;

      // 4 boost options:
      //  * 10% boost: 4/10 chance
      //  * 50% boost: 3/10 chance
      //  * 100% boost: 2/10 chance
      //  * 300% boost: 1/10 chance
      BOOSTS[0] = 10;
      BOOSTS[1] = 50;
      BOOSTS[2] = 10;
      BOOSTS[3] = 10;
      BOOSTS[4] = 50;
      BOOSTS[5] = 100;
      BOOSTS[6] = 100;
      BOOSTS[7] = 300;
      BOOSTS[8] = 50;
      BOOSTS[9] = 10;
    }

    function invest(address referrer) public payable {
      uint256 amount = msg.value;
      require(amount >= MIN_INVESTMENT, "Less than min amount");

      uint256 devFee = amount.mul(DEV_FEE).div(PERCENTS_DIVIDER);
      uint256 devFee2 = devFee.div(2);

      ceo1.transfer(devFee2);
      ceo2.transfer(devFee.sub(devFee2));

      User storage user = users[msg.sender];

      if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
        user.referrer = referrer;
        users[referrer].referrals = users[referrer].referrals.add(1);
      }

      if (user.referrer != address(0)) {
        uint256 referralBonus = amount.mul(REFERRAL_BONUS).div(PERCENTS_DIVIDER); // 5% deposit ref bonus
        users[user.referrer].referral = users[user.referrer].referral.add(referralBonus);
        users[user.referrer].totalReferral = users[user.referrer].totalReferral.add(referralBonus);
        totalReferrals = totalReferrals.add(referralBonus);
        emit Referral(user.referrer, msg.sender, amount);
      }

      if (user.deposits.length == 0) {
        user.checkpoint = block.timestamp;
        user.lastBoosted = block.timestamp;
        emit NewUser(msg.sender);
      }

      user.deposits.push(Deposit(amount, block.timestamp, 0));

      totalDeposits = totalDeposits.add(1);
      totalInvested = totalInvested.add(amount);
      emit NewDeposit(msg.sender, amount);
    }

    function compound() public {
      uint256 compounded = 0;
      uint256 referralBonus = 0;
      User storage user = users[msg.sender];

      for (uint256 i = 0; i < user.deposits.length; i++) {
	      uint256 finish = (user.deposits[i].start.add(PLAN_LENGTH.mul(1 days))).add(user.deposits[i].compoundExtension);

		    if (user.checkpoint < finish) {
	        uint256 share = user.deposits[i].amount.mul(PLAN_ROI_DAILY).div(PERCENTS_DIVIDER);
		      uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
		      uint256 to = finish < block.timestamp ? finish : block.timestamp;

          if (from < to) {
		        uint256 compoundPeriod = to.sub(from);
		        uint256 compoundAmount = share.mul(compoundPeriod).div(TIME_STEP);
            referralBonus = referralBonus.add(compoundAmount.mul(COMPOUND_BONUS).div(PERCENTS_DIVIDER)); // 10% compound ref bonus
		        user.deposits[i].compoundExtension = user.deposits[i].compoundExtension.add(compoundPeriod);
		        user.deposits[i].amount = user.deposits[i].amount.add(compoundAmount);
		        user.compounded = user.compounded.add(compoundAmount);
            compounded = compounded.add(compoundAmount);
		      }
	      }
      }

      require(compounded > 0, "Nothing to compound");

      if(user.referrer != address(0)) {
        users[user.referrer].referral = users[user.referrer].referral.add(referralBonus);
        users[user.referrer].totalReferral = users[user.referrer].totalReferral.add(referralBonus);
        totalReferrals = totalReferrals.add(referralBonus);
        //emit Referral(user.referrer, msg.sender, amount);
      }

      user.checkpoint = block.timestamp;
      emit Compound(msg.sender, compounded);
    }

    function boost() public {
      require(getUserCanBoost(msg.sender), "Can only boost once every 24 hours");

      randomBoost();
      uint256 boostPercent = BOOSTS[random % 10];

      User storage user = users[msg.sender];
      uint256 boosted = 0;

      for (uint256 i = 0; i < user.deposits.length; i++) {
	      uint256 finish = (user.deposits[i].start.add(PLAN_LENGTH.mul(1 days))).add(user.deposits[i].compoundExtension);

		    if (user.checkpoint < finish) {
	        uint256 share = user.deposits[i].amount.mul(PLAN_ROI_DAILY).div(PERCENTS_DIVIDER);
          boosted = boosted.add(share.mul(boostPercent).div(PERCENTS_DIVIDER));
		    }
	    }

      user.boostPercent = boostPercent;
      user.boost = user.boost.add(boosted);
      user.totalBoost = user.totalBoost.add(boosted);
      user.lastBoosted = block.timestamp;
      totalBoosts = totalBoosts.add(boosted);
      emit Boost(msg.sender, boosted);
    }

    function withdraw() public {
      User storage user = users[msg.sender];
      uint256 divAmount = getUserDividends(msg.sender);
      uint256 referralBonus = getUserReferralBonus(msg.sender);
      uint256 boostBonus = getUserBoostBonus(msg.sender);

      uint256 totalAmount = divAmount;

      user.referral = 0;
      totalAmount = totalAmount.add(referralBonus);
    
      user.boost = 0;
      totalAmount = totalAmount.add(boostBonus);

      require(totalAmount > 0, "User has no dividends");

      uint256 available = getContractBalance();
      if (available < totalAmount) {
	    user.referral = totalAmount.sub(available);
		user.totalReferral = user.totalReferral.add(user.referral);
		totalAmount = available;
      }

      user.checkpoint = block.timestamp;
      user.withdrawn = user.withdrawn.add(totalAmount);

      payable(msg.sender).transfer(totalAmount);
      emit Withdraw(msg.sender, totalAmount);
    }

    function getUserDividends(address userAddress) public view returns (uint256) {
      User storage user = users[userAddress];
      uint256 totalAmount = 0;

      for (uint256 i = 0; i < user.deposits.length; i++) {
	      uint256 finish = (user.deposits[i].start.add(PLAN_LENGTH.mul(1 days))).add(user.deposits[i].compoundExtension);
		    if (user.checkpoint < finish) {
		      uint256 share = user.deposits[i].amount.mul(PLAN_ROI_DAILY).div(PERCENTS_DIVIDER);
		      uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
		      uint256 to = finish < block.timestamp ? finish : block.timestamp;
		      if (from < to) {
		        totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
		      }
		    }
      }

      return totalAmount;
    }

    function getUserTotalWithdrawn(address userAddress) public view returns (uint256) {
      return users[userAddress].withdrawn;
    }

    function getUserCheckpoint(address userAddress) public view returns (uint256) {
      return users[userAddress].checkpoint;
    }

    function getUserLastBoosted(address userAddress) public view returns (uint256) {
      return users[userAddress].lastBoosted;
    }

    function getUserBoostPercent(address userAddress) public view returns (uint256) {
      return users[userAddress].boostPercent;
    }

    function getUserCanBoost(address userAddress) public view returns (bool) {
      return (block.timestamp.sub(getUserLastBoosted(userAddress)) >= BOOST_DELAY);
    }

    function getUserReferrer(address userAddress) public view returns (address) {
      return users[userAddress].referrer;
    }

    function getUserReferralBonus(address userAddress) public view returns (uint256) {
      return users[userAddress].referral;
    }

    function getUserTotalReferralBonus(address userAddress) public view returns (uint256) {
      return users[userAddress].totalReferral;
    }

    function getUserReferralWithdrawn(address userAddress) public view returns (uint256) {
      return users[userAddress].totalReferral.sub(users[userAddress].referral);
    }

    function getUserBoostBonus(address userAddress) public view returns (uint256) {
      return users[userAddress].boost;
    }

    function getUserTotalBoostBonus(address userAddress) public view returns (uint256) {
      return users[userAddress].totalBoost;
    }

    function getUserAmountOfDeposits(address userAddress) public view returns (uint256) {
     return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress) public view returns (uint256 amount) {
      for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
        amount = amount.add(users[userAddress].deposits[i].amount);
      }
    }

    function getUserDepositInfo(address userAddress, uint256 index) public view returns (uint256 percent, uint256 amount, uint256 start, uint256 finish) {
      User storage user = users[userAddress];

      percent = PLAN_ROI_DAILY;
      amount = user.deposits[index].amount;
      start = user.deposits[index].start;
      finish = user.deposits[index].start.add(PLAN_LENGTH.mul(1 days));
    }

    function getUserInfo(address userAddress) public view returns (uint256 userTotalDeposits, uint256 userTotalWithdrawn, uint256 userTotalReferrals, uint256 userTotalBoosts) {
      return (getUserTotalDeposits(userAddress), getUserTotalWithdrawn(userAddress), getUserTotalReferralBonus(userAddress), getUserTotalBoostBonus(userAddress));
    }

    function getUserCompounded(address userAddress) public view returns (uint256) {
      return users[userAddress].compounded;
    }

    function getContractBalance() public view returns (uint256) {
      return address(this).balance;
    }

    function isContract(address addr) internal view returns (bool) {
      uint256 size;
      assembly { size := extcodesize(addr) }
      return size > 0;
    }

    function randomBoost() internal {
      require(LINK.balanceOf(address(this)) >= linkFee, "NOT ENOUGH LINK");
      requestRandomness(linkKeyHash, linkFee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 result) internal override {
      random = result;
      linkRequestId = requestId;
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