// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./Interfaces/ICyber9Token.sol";
import "./Interfaces/ICyber9Items.sol";
import "./Interfaces/ICyber9Badge.sol";
import "./Libraries/RNG.sol";
import "./Libraries/EnemyLib.sol";
import "./Libraries/CharacterLib.sol";
import "./Libraries/ClanLib.sol";

contract Cyber9 is ERC721Enumerable, Ownable, RNG, VRFConsumerBase {
    using Strings for uint256;
    using CharacterLib for CharacterLib.Character;
    using EnemyLib for EnemyLib.Enemy;
    using ClanLib for uint256[];
    ICyber9Badge private immutable cyber9badge;
    ICyber9Items private immutable cyber9items;
    ICyber9Token private immutable cyber9token;
    address private enhancementContract;
    string private baseURI;
    bytes32 internal keyHash;
    uint256 private VRFfee;    
    uint256 public amountMinted;
    uint256 public maxSupply = 12; //change back to 9000
    uint256 public maxMintPerTx = 10;
    uint256 public cost = 0.01 ether; //CHANGE BACK TO 50
    uint256 private attackCD = 1 days;
    uint256 private defeatedCD = 3 days; 
    uint256 private startFrom = 9; //Start the random mint from
    uint256 constant public MAX_LEVEL = 50;
    bool public usable = false;
    bool public paused = true;
    mapping(address => bool) public isSpawned;
    mapping(address => EnemyLib.Enemy) enemy;
    mapping(address => uint256) public randomResult;
    mapping(address => uint256) public storedBei; 
    mapping(uint256 => bool) public isStaked;
    mapping(uint256 => uint256) public storedExp;
    mapping(uint256 => uint256) public stakeStart;
    mapping(uint256 => uint256) public yieldPerToken;
    mapping(uint256 => uint256) private expPerToken;
    mapping(uint256 => int256) public characterMaxHp;
    mapping(uint256 => uint256) private breakthrough;
    mapping(uint256 => uint256) private cooldown;
    mapping(uint256 => CharacterLib.Character) private characters;
    mapping(bytes32 => address) public requestIdToAddress;

    //Events
    event Attack(address indexed _from, uint256 _tokenId, uint256 _dmg, bool _isCrit, uint256 _enemyDmg, uint256 _experience);
    event CharacterDefeated(address indexed _from, uint256 _tokenId);
    event EnemyDefeated(address indexed _from, uint256 _tokenId, uint256 _beiReward);
    event Staked(address indexed _from, uint256[] _tokenIds);
    event Unstaked(address indexed _from, uint256[] _tokenIds);
    event Withdraw(address indexed _from, uint256[] _tokenIds, uint256[] _tokensExp, uint256 _beiAmount);

    //VRFConsumerBase (VRF Coordinator, LINK TOKEN)
    //MUMBAI (0x8C7382F9D8f56b33781fE506E897a4F1e2d17255, 0x326C977E6efc84E512bB9C30f76E30c160eD06FB)
    //MUMBAI KEYHASH 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4

    //POLYGON (0x3d2341ADb2D31f1c5530cDC622016af293177AE0, 0xb0897686c545045aFc77CF20eC7A532E3120E0F1)
    //POLYGON KEYHASH 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da
    constructor(
        ICyber9Badge _badge,
        ICyber9Token _token,
        ICyber9Items _items
        ) 
        ERC721("Cyber9", "C9")
        VRFConsumerBase(
            0x8C7382F9D8f56b33781fE506E897a4F1e2d17255, 
            0x326C977E6efc84E512bB9C30f76E30c160eD06FB
        )
        RNG(maxSupply-startFrom, startFrom+1)
    {        
        cyber9badge = _badge;
        cyber9token = _token;
        cyber9items = _items;
        reserveMint();
        keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
        VRFfee = 0.0001 ether; 
    }

    modifier status(uint256 _tokenId) {
        require(isStaked[_tokenId] == false, "S");
        require(characters[_tokenId].hp > 0, "D");
        _;
    }

    //@notice First 9 are reserved 
    function reserveMint() internal {
        for(uint256 i = 1; i<startFrom+1; i++) { 
            if(i == 1) {
                characters[i].setStats(1, 200, 30, 15, 15, 20, 20, 0);  
                characterMaxHp[i] = 200;
            }else if(i == 2) {
                characters[i].setStats(1, 150, 20, 30, 15, 20, 20, 0);
                characterMaxHp[i] = 150;
            }else if(i == 3) {
                characters[i].setStats(1, 200, 15, 20, 20, 30, 15, 0);
                characterMaxHp[i] = 200;
            }else if(i == 4) {
                characters[i].setStats(1, 150, 20, 15, 20, 20, 30, 0);
                characterMaxHp[i] = 150;
            }else if(i == 5) {
                characters[i].setStats(1, 200, 15, 20, 30, 15, 20, 0);
                characterMaxHp[i] = 200;
            }else if(i == 6) {
                characters[i].setStats(1, 300, 20, 15, 15, 20, 20, 0);
                characterMaxHp[i] = 300;
            }else if(i == 7) {
                characters[i].setStats(1, 200, 20, 15, 25, 15, 25, 0);
                characterMaxHp[i] = 200;
            }else if(i == 8) {
                characters[i].setStats(1, 200, 25, 25, 15, 20, 15, 0);
                characterMaxHp[i] = 200;
            }else {
                characters[i].setStats(1, 150, 25, 20, 15, 20, 25, 0);
                characterMaxHp[i] = 150;
            }
            _safeMint(msg.sender, i);
            amountMinted++;
        }  
    }

    function mint(uint256 _amount) external payable {
        require(paused==false);
        require(_amount > 0);
        require(_amount < maxMintPerTx + 1, "M");
        require(amountMinted + _amount < maxSupply + 1, "O");
        require(msg.value >= cost * _amount, "C");
        mintLogic(_amount);
    }
    
    //@notice only available to badge holders
    function freeMint(uint256 _badgeId) external {
        require(amountMinted < maxSupply , "O");
        cyber9badge.useFreeMint(_badgeId, msg.sender);
        mintLogic(1);
    }

     function mintLogic(uint256 _amount) private {
        int256 _hp;
        uint256 _strength;
        uint256 _agility;
        uint256 _intelligence;
        uint256 _dexterity;
        uint256 _luck;
        getRandomNumber();

        for(uint256 i=0; i<_amount;i++) {
            uint256 _newId = nextToken();
            _safeMint(msg.sender, _newId);
            
            //@dev assign stats, generateStats takes in a ID and a random number
            (_hp, _strength,_agility,_intelligence,_dexterity,_luck) = generateStats(_newId, randomResult[msg.sender]);
            characters[_newId].setStats(1,_hp, _strength,_agility,_intelligence,_dexterity,_luck,0);
            characterMaxHp[_newId] = _hp;
            //@dev issues token to minter whenever they mint one
            cyber9token.mintBei(msg.sender, 200);
            amountMinted++;
        }
        //Checks if collection is sold out, if it is wipe all badges free mints
        if(amountMinted == maxSupply) {
            cyber9badge.wipeFreeMints();
        }
    }

    function burnCyber9(uint256 _tokenId, address _from) external { 
        require(msg.sender == enhancementContract, "A");
        require(_exists(_tokenId),"N");        
        require(ownerOf(_tokenId) == _from,"B");
        delete characters[_tokenId];
        _burn(_tokenId);
    }

    function CharacterIdByIndex(uint256 _index) external view returns(uint256) {
        return tokenByIndex(_index);
    }
    
    function walletOfOwner(address _owner) public view returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
          tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }
    
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) 
    {
        require(_exists(_tokenId),"N");
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, _tokenId.toString(), '.json'))
            : "";
    }

    // ------------------------------------ VRF Chainlink ------------------------------------
    function getRandomNumber() private {
        require(LINK.balanceOf(address(this)) >= VRFfee, "L");
        bytes32 requestId = requestRandomness(keyHash, VRFfee);
        requestIdToAddress[requestId] = msg.sender;
    }
    
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        address requestAddress = requestIdToAddress[requestId];
        randomResult[requestAddress] = randomness;
    }

    //check LINK balance of current contract
    function getLinkBalance() external view returns(uint256) {
        return LINK.balanceOf(address(this));
    }

    //withdraw LINK
    function withdrawLink() external onlyOwner {
        require(LINK.transfer(owner(), LINK.balanceOf(address(this))));
    }

    // ------------------------------------- Character functions -------------------------------------
    function getCharacterStats(uint256 _tokenId) external view 
        returns(uint256 level,
        int256 hp,
        uint256 strength,
        uint256 agility,
        uint256 intelligence,
        uint256 dexterity,
        uint256 luck,
        uint256 experience)
    {
        return characters[_tokenId].getStats();
    }
    
    function levelUp(uint256 _tokenId) external status(_tokenId) {
        require(characters[_tokenId].level < MAX_LEVEL);
        require(msg.sender == ownerOf(_tokenId));
        uint256 _expRequired = expRequired(_tokenId);
        require(characters[_tokenId].experience >= _expRequired, "E");
        //Every 10 levels requires orbs to breakthrough
        if(characters[_tokenId].level % 10 == 9){
            breakthrough[_tokenId]++;
            //1 additional orb every 10 levels
            cyber9items.useOrbs(msg.sender, breakthrough[_tokenId]);
        }
        characterMaxHp[_tokenId] += 10;
        characters[_tokenId].levelUp(_expRequired); 
    }
    
    function expRequired(uint256 _tokenId) public view returns (uint256 experience) {
        return characters[_tokenId].lvlUpExp();
    }

    // ------------------------------------- Enemy functions -------------------------------------
    function spawnEnemy() external {
        require(usable == true);
        require(walletOfOwner(msg.sender).length > 0, "F");
        require(isSpawned[msg.sender] == false);

        uint256 total;
        uint256[] memory _character = walletOfOwner(msg.sender);
        for(uint256 i; i<_character.length;i++) {
            total += characters[_character[i]].level;
        }
        uint256 avg = total/walletOfOwner(msg.sender).length;
        int256 hp = int(avg * 400) - walletOfOwner(msg.sender).c7Bonus();
        uint256 enemyAttack = avg + 15;

        enemy[msg.sender].assignEnemyStats(hp, enemyAttack);
        isSpawned[msg.sender] = true;
    }

    function getEnemyStats(address _from) external view returns (int256 hp, uint256 atk) {
        return enemy[_from].getEnemyStats();
    }

    function attackEnemy(uint256[] memory _tokensId) external {
        require(isSpawned[msg.sender] == true);

        for(uint256 i = 0; i<_tokensId.length;i++) {
            require(characters[_tokensId[i]].hp > 0, "D");
            require(msg.sender == ownerOf(_tokensId[i]));
            require(isStaked[_tokensId[i]] == false, "S");
            require(block.timestamp > cooldown[_tokensId[i]], "H");

            //Cooldown for attack
            setCooldown(attackCD - (characters[_tokensId[i]].agility + walletOfOwner(msg.sender).c2Bonus()) * 300, _tokensId[i]);
            uint256 _dmg = roll(characters[_tokensId[i]].strength, 1) + walletOfOwner(msg.sender).c1Bonus();
            bool isCrit = false;

            if(crit(characters[_tokensId[i]].luck + walletOfOwner(msg.sender).c4Bonus(), characters[_tokensId[i]].dexterity + walletOfOwner(msg.sender).c3Bonus())) {
                _dmg = _dmg *2;
                isCrit = true;
            }
            enemy[msg.sender].attacked(_dmg);   

            uint256 _enemyAtk = enemy[msg.sender].attack;
            uint256 _enemyDmg = uint256(roll(_enemyAtk, 2));
            characters[_tokensId[i]].hp -= int256(_enemyDmg) - walletOfOwner(msg.sender).c6Bonus();
            uint256 _exp = ((characters[_tokensId[i]].level * 400) - expRequired(_tokensId[i])) + walletOfOwner(msg.sender).c9Bonus();
            characters[_tokensId[i]].experience += _exp;
            emit Attack(msg.sender, _tokensId[i], _dmg, isCrit, _enemyDmg, _exp);

            //Character defeated
            if(characters[_tokensId[i]].hp < 1) {
                characters[_tokensId[i]].hp = 0;
                setCooldown(defeatedCD, _tokensId[i]);
                emit CharacterDefeated(msg.sender, _tokensId[i]);
            }           
            //Enemy defeated
            if(enemy[msg.sender].health < 1 ) {    
                cyber9token.mintBei(msg.sender, _enemyAtk * 20);
                emit EnemyDefeated(msg.sender, _tokensId[i], _enemyAtk * 20);
                delete enemy[msg.sender];
                isSpawned[msg.sender] = false;                
                return;
            }
        }                     
    }

    function revive(uint256 _tokenId) external {
        require(characters[_tokenId].hp == 0, "J");
        require(timeLeft(_tokenId) == 0, "H");
        characters[_tokenId].hp = characterMaxHp[_tokenId];    
    }

    // ------------------------------------- ITEMS -------------------------------------
    function healCharacter(uint256 _tokenId) external {
        require(characters[_tokenId].hp > 0, "K");
        characters[_tokenId].hp = characterMaxHp[_tokenId];
        cyber9items.useHpKit(msg.sender);
    }

    function resetCD(uint256 _tokenId) external {
        require(characters[_tokenId].hp > 0, "K");
        cooldown[_tokenId] = 0;
        cyber9items.useCdKit(msg.sender);
    }

    function resetStats(uint256 _tokenId) external {
        require(_tokenId > 9);
        require(characters[_tokenId].hp > 0, "D");
        newStats(_tokenId);
        characters[_tokenId].setLevels(characters[_tokenId].level, characters[_tokenId].experience);
        cyber9items.useStatReset(msg.sender);
    }

    //Stack too deep need to split the function 
    function newStats(uint256 _tokenId) private {
        int256 _hp;
        uint256 _strength;
        uint256 _agility;
        uint256 _intelligence;
        uint256 _dexterity;
        uint256 _luck;
        getRandomNumber();
        (_hp, _strength, _agility, _intelligence, _dexterity, _luck) = rerollStats(characters[_tokenId].level, randomResult[msg.sender]);
        characters[_tokenId].setNewStats(_hp, _strength, _agility, _intelligence, _dexterity, _luck);
        characterMaxHp[_tokenId] = _hp;
    }

    // ------------------------------------- TIMER -------------------------------------
    function setCooldown(uint256 _time, uint256 tokenId) private {
        uint256 startTime = block.timestamp;
        cooldown[tokenId] = startTime+_time;
    }

    function timeLeft(uint256 tokenId) public view returns(uint256) {
        if(cooldown[tokenId] == 0 || cooldown[tokenId] < block.timestamp){
            return 0;
        }else{
            return cooldown[tokenId]-block.timestamp;
        }
    }

    // ------------------------------------- Staking functions START -------------------------------------
    function stake(uint256[] memory _tokenIds) external {
        require(usable == true);
        uint256[] memory _stakeArray = new uint256[](_tokenIds.length);

        for(uint256 i = 0; i<_tokenIds.length; i++) {
            require(characters[_tokenIds[i]].hp > 0, "D");
            require(block.timestamp> cooldown[_tokenIds[i]], "H");
            require(msg.sender == ownerOf(_tokenIds[i]));
            require(isStaked[_tokenIds[i]] == false, "S");
        
            uint256 _beiGain = characters[_tokenIds[i]].level + characters[_tokenIds[i]].intelligence + walletOfOwner(msg.sender).c5Bonus() + characters[_tokenIds[i]].luck + walletOfOwner(msg.sender).c4Bonus();
            isStaked[_tokenIds[i]] = true;
            yieldPerToken[_tokenIds[i]] = _beiGain + walletOfOwner(msg.sender).c8Bonus();
            expPerToken[_tokenIds[i]] = 150 * characters[_tokenIds[i]].level;
            stakeStart[_tokenIds[i]] = block.timestamp;
            _stakeArray[i] = _tokenIds[i];
        }
        emit Staked(msg.sender, _stakeArray);
    }

    function unstake(uint256[] memory _tokenIds) external {
        uint256 yieldTransfer;
        uint256[] memory _unstakeArray = new uint256[](_tokenIds.length);

        for(uint256 i =0; i<_tokenIds.length;i++) {
            require(msg.sender == ownerOf(_tokenIds[i]));
            require(isStaked[_tokenIds[i]] == true, "R");
            
            (uint256 totalYield, uint256 expYield) = calculateYieldTotal(_tokenIds[i]);
            yieldTransfer = yieldTransfer + totalYield;
            yieldPerToken[_tokenIds[i]] = 0 ;
            isStaked[_tokenIds[i]] = false;
            storedExp[_tokenIds[i]] = expYield;
            expPerToken[_tokenIds[i]] = 0;
            _unstakeArray[i] = _tokenIds[i];
        }
        storedBei[msg.sender] += yieldTransfer;
        emit Unstaked(msg.sender, _unstakeArray);
    }

    function withdrawYield() external {
        uint256 toTransfer;
        uint256[] memory _tokens = walletOfOwner(msg.sender);

        uint256[] memory _tokensArray = new uint256[](_tokens.length);
        uint256[] memory _expArray = new uint256[](_tokens.length);

        for(uint256 i = 0; i<_tokens.length; i++) {
            (uint256 totalYield,uint256 expYield) = calculateYieldTotal(_tokens[i]);
            toTransfer = toTransfer + totalYield;
            stakeStart[_tokens[i]] = block.timestamp;
            expYield += storedExp[_tokens[i]];

            if(expYield > 0) {
                characters[_tokens[i]].experience += expYield;
                storedExp[_tokens[i]] = 0;
                _tokensArray[i] = _tokens[i];
                _expArray[i] = expYield;
            }
        }
        require(toTransfer > 0 || storedBei[msg.sender] > 0 , "Q");
        toTransfer += storedBei[msg.sender];
        storedBei[msg.sender] = 0;
        cyber9token.mintBei(msg.sender, toTransfer);
        emit Withdraw(msg.sender, _tokensArray, _expArray, toTransfer);
    }

    function calculateYieldTime(uint256 _tokenId) internal view returns(uint256) {
        uint256 end = block.timestamp;
        uint256 totalTime = end - stakeStart[_tokenId];
        return totalTime;
    }

    function calculateYieldTotal(uint256 _tokenId) public view returns(uint256 balance, uint256 experience) {
        uint256 _time = calculateYieldTime(_tokenId) * 10**18;
        uint256 _rate = 86400;
        uint256 _timeRate = _time / _rate;
        uint256 _rawYield = (yieldPerToken[_tokenId] * _timeRate) / 10**18;
        uint256 _expYield = (expPerToken[_tokenId] * _timeRate) / 10**18;
        return (_rawYield, _expYield);
    }

    // ------------------------------------- Staking functions END -------------------------------------

    // Cyber9 token functions
    function getBeiBalance(address _from) external view returns (uint256 balance) {
        return cyber9token.balanceOf(_from);
    }

    //for enhancement
    function setEnhancementContract(address _enhancementContract) external onlyOwner {
        enhancementContract = _enhancementContract;
    }

    //@dev added modifier to safeTransferFrom functions - Cannot transfer if tokens are staked, defeated or on cooldown
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override status(tokenId) {
        require(block.timestamp > cooldown[tokenId], "H");
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from,address to,uint256 tokenId,bytes memory _data) public virtual override status(tokenId) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "T");
        require(block.timestamp > cooldown[tokenId], "H");
        _safeTransfer(from, to, tokenId, _data);
    }
    
    function transferFrom(address from,address to,uint256 tokenId) public virtual override status(tokenId) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "T");
        require(block.timestamp > cooldown[tokenId], "H");
        _transfer(from, to, tokenId);
    }
        
    //onlyOwner
    function setUsable(bool _state) external onlyOwner {
        usable = _state;
    }
    
    function setCost(uint256 _newCost) external onlyOwner {
        cost = _newCost;
    }
    
    function pause(bool _state) external onlyOwner {
        paused = _state;
    }
  
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    
    function withdraw() external payable onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success);
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICyber9Token{
    function balanceOf(address _owner) external view returns (uint256);
    function mintBei(address _to, uint256 _amount) external;
    function burnBei(address _from, uint256 _amount) external; 
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICyber9Items{
    function useOrbs(address _from,uint256 _amount) external;
    function useHpKit(address _from) external;
    function useCdKit(address _from) external;
    function useStatReset(address _from) external ;
    function mintOrbs(address _to, uint256 _amount) external;
    function mintHpKit(address _to, uint256 _amount) external;
    function mintCdKit(address _to, uint256 _amount) external;
    function mintStatReset(address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICyber9Badge {
    function ownerOf(uint256 _tokenId) external view returns (address);
    function useFreeMint(uint256 _tokenId, address _from) external;
    function wipeFreeMints() external;
    function burnBadge(uint256 _tokenId, address _from) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";

abstract contract RNG{
    
    using Counters for Counters.Counter;
    Counters.Counter private _tokenCount;
    uint256 private _maxSupply;
    uint256 private _startFrom;
    mapping(uint256 => uint256) private tokenMatrix;

    constructor (uint256 maxSupply_, uint256 startFrom_) 
    {
        _maxSupply = maxSupply_;
        _startFrom = startFrom_;
    }
    
    //pseudo random mint
    function nextToken() public returns (uint256) {
        uint256 maxIndex = _maxSupply - tokenCount();

        uint256 random = uint256(keccak256(
            abi.encodePacked(
                msg.sender,
                block.coinbase,
                block.difficulty,
                block.gaslimit,
                block.timestamp
            )
        )) % maxIndex;

        uint256 value = 0;

        if(tokenMatrix[random] == 0) {
            value = random;
        } else {
            value = tokenMatrix[random];
        }

        if(tokenMatrix[maxIndex - 1] == 0) {
            tokenMatrix[random] = maxIndex - 1;
        }else{
            tokenMatrix[random] = tokenMatrix[maxIndex - 1];
        }

         _tokenCount.increment();
        return value + _startFrom;
    }

    function tokenCount() public view returns (uint256) {
        return _tokenCount.current();
    }

    function availableTokens() public view returns (uint256) {
        return _maxSupply - tokenCount();
    }

    //@dev generate random attributes, also takes in a second argument so every value is unique if minting more than one
    function generateStats(uint256 _id, uint256 _randomResult) public view returns (int256,uint256,uint256,uint256,uint256,uint256) {
        uint256[] memory stats = new uint256[](6);
        for(uint256 i =0; i<6;i++){
            uint256 random = uint256(keccak256(abi.encodePacked(i, block.timestamp, _id, _randomResult)));
            //random stat from 1~21
            stats[i] = (random % 21) + 1 ;
        }
        return (int256(stats[0]*10),stats[1],stats[2],stats[3],stats[4],stats[5]);
    }

    //@dev allows to reroll attributes, keeps current level and experience. Only the base changes
    function rerollStats(uint256 _currentLevel, uint256 _randomResult) public view returns(int256,uint256,uint256,uint256,uint256,uint256) {
        uint256[] memory stats = new uint256[](6);
        for(uint256 i =0; i<6;i++){
            uint256 random = uint256(keccak256(abi.encodePacked(i, block.timestamp, _currentLevel, _randomResult)));
            //random stat from 1~21
            stats[i] = (random % 21) + 1 ;
        }
        return (int256(stats[0]*10+(_currentLevel*10)),stats[1]+_currentLevel,stats[2]+_currentLevel,stats[3]+_currentLevel,stats[4]+_currentLevel,stats[5]+_currentLevel);
    }

    //1 = character, 2 = enemy
    function roll(uint256 _base, uint256 _type) public view returns (uint256) {
        uint256 range;
        if(_type == 1) {
            range = _base * 5;
            uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.gaslimit,block.timestamp, _base)));
            range = range + (random % _base);
        }else{
            uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.gaslimit,block.timestamp, _base)));
            range = _base + (random % _base);
        }
        return range;
    }

    function crit(uint256 _luck, uint256 _dex) public view returns (bool) {
        bool critHit;
        uint256 random = uint256(keccak256(abi.encodePacked(block.gaslimit,block.timestamp, _luck, _dex))) % 10000 + 1;
        uint256 _multiplier = ((_luck + _dex) * 30) + 1000;
        if(_multiplier > random ){
            critHit = true;
        }
        return critHit;
    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library EnemyLib {

    struct Enemy {
        int256 health;
        uint256 attack;
    }

    function assignEnemyStats(Enemy storage enemy, int256 _hp, uint256 _attack) public {
        enemy.health = _hp;
        enemy.attack  = _attack;
    }

    function getEnemyStats(Enemy storage enemy) view public returns (int256 hp, uint256 atk) {
        return (enemy.health, enemy.attack);
    }

    function attacked(Enemy storage enemy, uint256 _dmg) public {
        enemy.health -= int256(_dmg);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library CharacterLib {

    struct Character {
        uint256 level;
        int256 hp;
        uint256 strength;
        uint256 agility;
        uint256 intelligence;
        uint256 dexterity;
        uint256 luck;
        uint256 experience;
    }

    function setStats(Character storage character, 
        uint256 _lvl,
        int256 _hp, 
        uint256 _str,
        uint256 _agi,
        uint256 _int,
        uint256 _dex,
        uint256 _luk,
        uint256 _exp
        ) public {
            character.level = _lvl;
            character.hp = _hp;
            character.strength = _str;
            character.agility = _agi;
            character.intelligence = _int;
            character.dexterity = _dex;
            character.luck = _luk;
            character.experience = _exp;
    }

    function getStats(Character storage character) public view
        returns (
            uint256 level,
            int256 hp,
            uint256 strength,
            uint256 agility,
            uint256 intelligence,
            uint256 dexterity,
            uint256 luck,
            uint256 experience
        ) {
            return (
                character.level,
                character.hp,
                character.strength,
                character.agility,
                character.intelligence,
                character.dexterity,
                character.luck,
                character.experience
                );
        }

    function levelUp(Character storage character, uint256 _expRequired) public {
        character.level += 1;
        character.hp += 10;
        character.strength += 1;
        character.agility += 1;
        character.intelligence += 1;
        character.dexterity += 1;
        character.luck += 1;
        character.experience -= _expRequired;
    }

    function lvlUpExp(Character storage character) public view returns (uint256 experience) {
        uint256 _lvlUpExp = ((character.level-1) + character.level) * 150;
        return _lvlUpExp;
    }

    //Stack too deep when rerolling, splitting up the set stat function
    function setLevels(Character storage character, uint256 _lvl, uint256 _exp) public {
        character.level = _lvl;
        character.experience = _exp;
    }

    function setNewStats(Character storage character, 
            int256 _hp, 
            uint256 _str,
            uint256 _agi,
            uint256 _int,
            uint256 _dex,
            uint256 _luk
        ) public {
            character.hp = _hp;
            character.strength = _str;
            character.agility = _agi;
            character.intelligence = _int;
            character.dexterity = _dex;
            character.luck = _luk;
    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library ClanLib {

    function c1Bonus(uint256[] memory _ownerTokens) public pure returns(uint256 bonusDmg) {
        uint256 _c1Count;
        for(uint256 i; i<_ownerTokens.length;i++) {
            if((_ownerTokens[i] > 9 && _ownerTokens[i] < 1009) || _ownerTokens[i] == 1) {
                _c1Count += 1;
            }
        }
        //Every 3 owned of the same clan gives 5 bonus dmg
        uint256 _bonus = _c1Count / 3;
        if(_bonus > 20) _bonus = 20; //bonus limit
        return _bonus *5;
    }

    function c2Bonus(uint256[] memory _ownerTokens) public pure returns(uint256 bonusAgi) {
        uint256 _c2Count; 
        for(uint256 i; i<_ownerTokens.length;i++) {
            if((_ownerTokens[i] > 1008 && _ownerTokens[i] < 2007) || _ownerTokens[i] == 2) {
               _c2Count++; 
           }
        }
        //Every 3 owned of the same clan gives 10 bonus agi to cooldown
        uint256 _bonus = _c2Count / 3;
        if(_bonus > 40) _bonus = 40; //bonus limit
        return _bonus * 10;
    }

    
    function c3Bonus(uint256[] memory _ownerTokens) public pure returns(uint256 bonusDex) {
        uint256 _c3Count; 
        for(uint256 i; i<_ownerTokens.length;i++) {
            if((_ownerTokens[i] > 2006 && _ownerTokens[i] < 3006) || _ownerTokens[i] == 3) {
               _c3Count++; 
           }
        }
        //Every 3 owned of the same clan gives 5 bonus dex
        uint256 _bonus = _c3Count / 3;
        if(_bonus > 20) _bonus = 20; //bonus limit
        return _bonus * 5;
    }

    function c4Bonus(uint256[] memory _ownerTokens) public pure returns(uint256 bonusLuck) {
        uint256 _c4Count; 
        for(uint256 i; i<_ownerTokens.length;i++) {
            if((_ownerTokens[i] > 3005 && _ownerTokens[i] < 4005) || _ownerTokens[i] == 4) {
               _c4Count++; 
           }
        }
        //Every 3 owned of the same clan gives 5 bonus luck
        uint256 _bonus = _c4Count / 3;
        if(_bonus > 20) _bonus = 20; //bonus limit
        return _bonus * 5;
    }
    
    function c5Bonus(uint256[] memory _ownerTokens) public pure returns(uint256 bonusInt) {
        uint256 _c5Count; 
        for(uint256 i; i<_ownerTokens.length;i++) {
            if((_ownerTokens[i] > 4004 && _ownerTokens[i] < 5004) || _ownerTokens[i] == 5) {
               _c5Count++; 
           }
        }
        //Every 3 owned of the same clan gives 5 bonus intelligence
        uint256 _bonus = _c5Count / 3;
        if(_bonus > 20) _bonus = 20; //bonus limit
        return _bonus * 5;
    }

    function c6Bonus(uint256[] memory _ownerTokens) public pure returns(int256 bonusDef) {
        int256 _c6Count; 
        for(uint256 i; i<_ownerTokens.length;i++) {
            if((_ownerTokens[i] > 5003 && _ownerTokens[i] < 6003) || _ownerTokens[i] == 6) {
               _c6Count++; 
           }
        }
        //Every 3 owned of the same clan reduces dmg by 5
        int256 _bonus = _c6Count / 3;
        if(_bonus > 20) _bonus = 20; //bonus limit
        return _bonus * 5;
    }
    
    function c7Bonus(uint256[] memory _ownerTokens) public pure returns(int256 reduceHp) {
        int256 _c7Count; 
        for(uint256 i; i<_ownerTokens.length;i++) {
            if((_ownerTokens[i] > 6002 && _ownerTokens[i] < 7002) || _ownerTokens[i] == 7) {
               _c7Count++; 
           }
        }
        //Every 3 owned of the same clan reduces the amount of hp of the enemy
        int256 _bonus = _c7Count / 3;
        if(_bonus > 60) _bonus = 60; //bonus limit
        return _bonus * 15;
    }

    function c8Bonus(uint256[] memory _ownerTokens) public pure returns(uint256 bonusBei) {
        uint256 _c8Count; 
        for(uint256 i; i<_ownerTokens.length;i++) {
            if((_ownerTokens[i] > 7001 && _ownerTokens[i] < 8001) || _ownerTokens[i] == 8) {
               _c8Count++; 
           }
        }
        //Every 3 owned of the same clan grants 10 more Token per day when staking
        uint256 _bonus = _c8Count / 3;
        if(_bonus > 40) _bonus = 40; //bonus limit
        return _bonus * 10;
    }

    function c9Bonus(uint256[] memory _ownerTokens) public pure returns(uint256 bonusExp) {
        uint256 _c9Count; 
        for(uint256 i; i<_ownerTokens.length;i++) {
            if((_ownerTokens[i] > 8000 && _ownerTokens[i] < 9001) || _ownerTokens[i] == 9) {
               _c9Count++; 
           }
        }
        //Every 3 owned of the same clan increases exp per Attack
        uint256 _bonus = _c9Count / 3;
        if(_bonus > 400) _bonus = 400; //bonus limit
        return _bonus * 100;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}