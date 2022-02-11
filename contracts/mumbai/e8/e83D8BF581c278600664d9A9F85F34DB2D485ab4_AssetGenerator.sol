/**
 *Submitted for verification at polygonscan.com on 2021-11-19
*/

// File @chainlink/contracts/src/v0.8/interfaces/[email protected]

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}


// File @chainlink/contracts/src/v0.8/[email protected]

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
  )
    internal
    pure
    returns (
      uint256
    )
  {
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
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}


// File @chainlink/contracts/src/v0.8/[email protected]

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
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

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
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}


// File contracts/access/Owned.sol


pragma solidity 0.8.7;

contract Owned {

    address public owner;
    address public nominatedOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnerNominated(address indexed newOwner);

    constructor(address _owner) {
        require(_owner != address(0),
            "Address cannot be 0");

        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    function nominateNewOwner(address _owner)
    external
    onlyOwner {
        nominatedOwner = _owner;

        emit OwnerNominated(_owner);
    }

    function acceptOwnership()
    external {
        require(msg.sender == nominatedOwner,
            "You must be nominated before you can accept ownership");

        emit OwnershipTransferred(owner, nominatedOwner);

        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        require(msg.sender == owner,
            "Only the contract owner may perform this action");
        _;
    }

}


// File contracts/access/AccessController.sol


pragma solidity 0.8.7;

contract AccessController is Owned {

  mapping(bytes32 => mapping(address => bool)) public roles;

  constructor(
    bytes32[] memory _roles,
    address[] memory _authAddresses,
    bool[] memory _authorizations,
    address _owner
  ) Owned(_owner) {
    require(_roles.length == _authAddresses.length && _roles.length == _authorizations.length,
      "Input lenghts not matched");

    for(uint i = 0; i < _roles.length; i++) {
      _setAuthorizations(_roles[i], _authAddresses[i], _authorizations[i]);
    }
  }

  function setAuthorizations(
    bytes32[] memory _roles,
    address[] memory _authAddresses,
    bool[] memory _authorizations
  ) external
  onlyOwner {
    require(_roles.length == _authAddresses.length && _roles.length == _authorizations.length,
      "Input lenghts not matched");

    for(uint i = 0; i < _roles.length; i++) {
      _setAuthorizations(_roles[i], _authAddresses[i], _authorizations[i]);
    }
  }

  function _setAuthorizations(
    bytes32 _role,
    address _address,
    bool _authorization
  ) internal {
    roles[_role][_address] = _authorization;
  }

  modifier onlyRole(bytes32 _role, address _address) {
    require(roles[_role][_address],
      string(abi.encodePacked("Caller is not ", _role)));
    _;
  }

}


// File contracts/AssetManager.sol


pragma solidity ^0.8.7;

contract AssetManager is AccessController {

  mapping(uint => address) public versionToStorage; // version => storage_address

  mapping(address => uint) public storageToVersion; // storage_address => version

  bytes32 constant public GENERATOR_ROLE = "GENERATOR_ROLE";

  bytes32[] public assets;

  constructor(
    bytes32[] memory _roles,
    address[] memory _authAddresses,
    bool[] memory _authorizations,
    address _owner
  ) AccessController(
    _roles,
    _authAddresses,
    _authorizations,
    _owner
  ) {}

  function addStorage(uint _version, address _storage)
  external
  onlyOwner {
    require(versionToStorage[_version] == address(0),
      string(abi.encodePacked("storage is already assigned in the version ", _version)));

    versionToStorage[_version] = _storage;
    storageToVersion[_storage] = _version;
  }

  function addAsset(bytes32 _assetKey)
  external
  onlyRole(GENERATOR_ROLE, msg.sender) {
    assets.push(_assetKey);
  }

  function assetsLength()
  external view
  returns(uint) {
    return assets.length;
  }

}


// File contracts/interfaces/IPartsStorage.sol


pragma solidity 0.8.7;

interface IPartsStorage {

  function generateAsset(uint seed)
  external returns (
    uint[] memory generated,
    uint16 score,
    uint8 property,
    bool flagged
  );

}


// File contracts/interfaces/IAssetManager.sol


pragma solidity ^0.8.7;

interface IAssetManager {

  function versionToStorage(uint version)
  external view
  returns(address);

  function storageToVersion(address _storage)
  external view
  returns(uint);


}


// File contracts/AssetGenerator.sol


pragma solidity 0.8.7;




contract AssetGenerator is VRFConsumerBase, AccessController {

  struct RequestIdAssigned {
    uint tokenId;
    uint storageVersion;
  }

  IAssetManager public assetManager;

  mapping(bytes32 => RequestIdAssigned) public requestIdAssigned;  // requestId to tokenId

  mapping(uint => bytes32) public requestIdByTokenId;

  mapping(uint => bytes32) public assetAssigned;  // tokenId to asset

  mapping(uint => uint) public generationRetries;

  bytes32 constant public REQUESTOR_ROLE = "REQUESTOR_ROLE";

  bytes32 immutable keyHash;
  uint internal fee;

  event AssetGenerationRequested(uint tokenId, bytes32 requestId);
  event AssetAssigned(uint tokenId, bytes32 assetId);

  constructor(
    address _vrfCoordinator,
    address _link,
    bytes32 _keyHash,
    uint _fee,
    address _assetStorage,
    bytes32[] memory _roles,
    address[] memory _authAddresses,
    bool[] memory _authorizations,
    address _owner
  ) VRFConsumerBase(_vrfCoordinator, _link)
  AccessController(
    _roles,
    _authAddresses,
    _authorizations,
    _owner
  ) {
    keyHash = _keyHash;
    fee = _fee;
    assetManager = IAssetManager(_assetStorage);
  }

  function setVRFFee(uint _newFee)
  external {
    fee = _newFee;
  }

  function requestAssetGeneration(uint _tokenId, uint _storageVersion)
  external
  onlyRole(REQUESTOR_ROLE, msg.sender) {
    require(LINK.balanceOf(address(this)) >= fee,
      "Not enough LINK");

    bytes32 requestId = requestRandomness(keyHash, fee);

    requestIdAssigned[requestId].tokenId = _tokenId;
    requestIdAssigned[requestId].storageVersion = _storageVersion;
    requestIdByTokenId[_tokenId] = requestId;

    emit AssetGenerationRequested(_tokenId, requestId);
  }

  function fulfillRandomness(bytes32 _requestId, uint _randomness)
  internal override {
    RequestIdAssigned memory _mem_RequestIdAssigned = requestIdAssigned[_requestId];
    (
      uint[] memory parts,
      uint16 score,
      uint8 property,
      bool flagged
    ) = partsStorage(assetManager.versionToStorage(_mem_RequestIdAssigned.storageVersion)).generateAsset(_randomness);

    if(flagged) {
      require(++generationRetries[_mem_RequestIdAssigned.tokenId] < 5,
        "Too many generation retries");

      this.requestAssetGeneration(_mem_RequestIdAssigned.tokenId, _mem_RequestIdAssigned.storageVersion);
    }

    bytes memory _assetKey = _initAssetKey();
    // Version
    _assetKey[_assetKey.length - 1] = bytes1(uint8(_mem_RequestIdAssigned.storageVersion));
    // Parts
    for(uint i = 0; i < parts.length; i++) {
      _assetKey[i] = bytes1(uint8(parts[i]));
    }
    // Score
    _assetKey[_assetKey.length - 3] = bytes2(score)[0];
    _assetKey[_assetKey.length - 2] = bytes2(score)[1];
    // Property
    _assetKey[_assetKey.length - 4] = bytes1(property);

    assetAssigned[_mem_RequestIdAssigned.tokenId] = bytes32(_assetKey);

    emit AssetAssigned(_mem_RequestIdAssigned.tokenId, bytes32(_assetKey));
  }

  function withdrawLink(address _to)
  external
  onlyOwner {
    LINK.transfer(_to, LINK.balanceOf(address(this)));
  }

  function _initAssetKey()
  internal pure
  returns(bytes memory) {
    bytes memory _assetKey = new bytes(32);

    return _assetKey;
  }

  function partsStorage(address _storage)
  internal pure
  returns(IPartsStorage) {
    return IPartsStorage(_storage);
  }

}