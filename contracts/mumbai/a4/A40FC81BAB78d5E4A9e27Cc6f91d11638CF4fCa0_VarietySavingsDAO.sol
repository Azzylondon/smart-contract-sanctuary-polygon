/**
 *Submitted for verification at polygonscan.com on 2021-11-27
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

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

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract VarietySavingsDAO is VRFConsumerBase {
    // --------------- General Round Info ----------------
    uint32 public roundNumber;

    // -------------------- User Info --------------------
    address[] private usersWhoVoted;
    mapping(address => bool) private hasUserVoted;
    mapping(address => bool) addressVotingEligibity;

    // ------------------- Token Info --------------------
    address[] public availableTokens = [
        0x4997910AC59004383561Ac7D6d8a65721Fa2A663,
        0xd5936853145A0212AA86BeDc434F8365f84069D5,
        0x98C50fa9f048E8F452d32B8dE8E96c0b14642B9F
    ];
    mapping(address => uint32) private tokenVoteTotal;
    mapping(address => bool) tokenAvailableForVoting;
    address public lastRoundWinningToken;

    uint8 TRANSFER_TOKEN_AMOUNT = 10;

    // ----------------- Contract Info -------------------
    address public owner;

    address public mainSavingsContract;

    // -------------------- VRF Info ---------------------
    bytes32 internal keyHash;
    uint256 internal fee;
    // ~~~ randomness
    uint8 public chanceOfWinning = 10;
    uint256 public randomResult;
    uint256 MAX_INT = 2**256 - 1;
    uint256 public cutoffInt;

    // -------------------- Constructor ---------------------
    /**
     * Constructor inherits VRFConsumerBase
     *
     * Network: Polygon (Matic) Mumbai Testnet
     * Chainlink VRF Coordinator address: 0x8C7382F9D8f56b33781fE506E897a4F1e2d17255
     * LINK token address:                0x326C977E6efc84E512bB9C30f76E30c160eD06FB
     * Key Hash: 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4
     */

    constructor()
        VRFConsumerBase(
            0x8C7382F9D8f56b33781fE506E897a4F1e2d17255, // VRF Coordinator
            0x326C977E6efc84E512bB9C30f76E30c160eD06FB // LINK Token
        )
    {
        owner = msg.sender;
        uint8 numberOfAvailableTokens = uint8(availableTokens.length);
        // to begin with, add some choice tokens to votable pool
        for (uint8 i = 0; i < numberOfAvailableTokens; i++) {
            tokenAvailableForVoting[availableTokens[i]] = true;
        }
        keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
        fee = 0.0001 * 10**18; // 0.0001 LINK (Varies by network)
        owner = msg.sender;
        cutoffInt = (MAX_INT / 100) * chanceOfWinning;
    }

    // -------------------- Randomness Functions ---------------------
    /**
     * Requests randomness
     */
    function getRandomNumber() public returns (bytes32 requestId) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        randomResult = randomness;
    }

    /**
     * Turns single random number into array of random numbers
     */
    function expand(uint256 randomValue, uint256 n)
        public
        pure
        returns (uint256[] memory expandedValues)
    {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
        }
        return expandedValues;
    }

    function changeChanceOfWinning(uint8 _newChance) public {
        chanceOfWinning = _newChance;
        cutoffInt = (MAX_INT / 100) * _newChance;
    }

    // -------------------- Set State Functions ---------------------
    function setMainSavingsContract(address contractAddress)
        public
        onlyOwner(msg.sender)
    {
        mainSavingsContract = contractAddress;
    }

    function setWalletVotingEligibility(address user, bool eligibility) public {
        addressVotingEligibity[user] = eligibility;
    }

    // -------------------- Modifiers ---------------------
    modifier onlyMain(address caller) {
        require(caller == mainSavingsContract, "Unauthorized");
        _;
    }

    modifier onlyOwner(address caller) {
        require(caller == owner, "Unauthorized");
        _;
    }

    modifier walletEligibleToVote() {
        require(
            addressVotingEligibity[msg.sender],
            "You are not eligible to vote"
        );
        _;
    }

    modifier walletNotVotedYet() {
        require(!hasUserVoted[msg.sender], "You can only vote once");
        _;
    }

    // -------------------- Contract State Visibility ---------------------
    function isTokenAvailableForVoting(address _token)
        public
        view
        returns (bool)
    {
        return tokenAvailableForVoting[_token];
    }

    function tokenVotes(address _token) public view returns (uint32) {
        return tokenVoteTotal[_token];
    }

    function getUserVotedStatus(address _user) public view returns (bool) {
        return hasUserVoted[_user];
    }

    function isUserEligibleToVote(address _user) public view returns (bool) {
        return addressVotingEligibity[_user];
    }

    // -------------------- Voting Functions ---------------------
    function voteForTokens(address[] memory _chosenTokens)
        public
        walletEligibleToVote
        walletNotVotedYet
    {
        uint8 numberOfVotedTokens = uint8(_chosenTokens.length);
        for (uint8 i = 0; i < numberOfVotedTokens; i++) {
            address currentToken = _chosenTokens[i];
            // only vote for allowed tokens
            if (tokenAvailableForVoting[currentToken]) {
                tokenVoteTotal[currentToken] += 1;
            }
        }
        // register that the user has voted
        hasUserVoted[msg.sender] = true;
    }

    // -------------------- End Round Functions ---------------------
    // ~~~ Delete Round Data
    function deleteUsersVotingRoundInfo(address _user) private {
        hasUserVoted[_user] = false;
    }

    function deleteTokenVotesForRound() private {
        uint8 numberOfTokens = uint8(availableTokens.length);
        for (uint8 i = 0; i < numberOfTokens; i++) {
            tokenVoteTotal[availableTokens[i]] = 0;
        }
    }
    // ~~~ win selections
    function selectWinningToken() public {
        uint8 numberOfTokens = uint8(availableTokens.length);
        address _tempToken = availableTokens[0];
        uint32 _tempTokenVote = tokenVoteTotal[_tempToken];
        for (uint8 i = 1; i < numberOfTokens; i++) {
            if (tokenVoteTotal[availableTokens[i]] > _tempTokenVote) {
                _tempToken = availableTokens[i];
                _tempTokenVote = tokenVoteTotal[_tempToken];
            }
        }
        lastRoundWinningToken = _tempToken;
        require(tokenVoteTotal[lastRoundWinningToken] != 0, "No votes registered");
    }

    function distributeTokens(address _user, uint256 _winningChance) private {
        if (_winningChance < cutoffInt) {
            IERC20 token = IERC20(lastRoundWinningToken);
            token.transfer(_user, TRANSFER_TOKEN_AMOUNT);
        }
    }
    // ~~~ control end round execution
    function newVotingRound() public {
        uint64 numberPriorRoundVoters = uint64(usersWhoVoted.length);
        // get chances of winning from vrf
        getRandomNumber();
        uint256[] memory userWinningChances = new uint256[](
            numberPriorRoundVoters
        );
        userWinningChances = expand(randomResult, numberPriorRoundVoters);
        for (uint64 i = 0; i < numberPriorRoundVoters; i++) {
            address user = usersWhoVoted[i];
            uint256 userWinningChance = userWinningChances[i];
            // distribute rewards according to vrf
            distributeTokens(user, userWinningChance);
            deleteUsersVotingRoundInfo(user);
        }
        deleteTokenVotesForRound();
        delete usersWhoVoted;
        roundNumber += 1;
    }

    // -------------------- Auxiliary Functions ---------------------
    // Implement a withdraw function to avoid locking your LINK in the contract
    function withdrawLink() external {
        LINK.transfer(owner, LINK.balanceOf(address(this)));
        uint8 numberOfTokens = uint8(availableTokens.length);
        // send all ERC20 tokens back
        for (uint8 i = 1; i < numberOfTokens; i++) {
            IERC20 token = IERC20(availableTokens[i]);
            token.transfer(owner, token.balanceOf(address(this)));
        }
    }
}