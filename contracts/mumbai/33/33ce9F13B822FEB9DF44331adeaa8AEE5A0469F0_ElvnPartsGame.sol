pragma solidity ^0.8.4;

// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICHAR{
    function chestPayment(uint _amount) external;
}

contract ElvnPartsGame is ERC1155, Ownable, Pausable, ERC1155Burnable, ERC1155Supply {
    /*
    ClassList 
    1: Hoody 
    2: Mask
    3: Short
    4: Shoes
    5: Gloves
    6: StakingBoost
    7: EXPBoost
    */
    modifier onlyMinter {   

        require(minter[msg.sender] == true || owner() == msg.sender);
        _;
    }

    modifier onlySetter {

        require(setterAddress[msg.sender] || owner() == msg.sender);
        _;
    }

    mapping(address => mapping(uint256 => uint256)) private ownedTokens;
    mapping(uint256 => uint256) private ownedTokensIndex;
    mapping(address => uint256) private ownerDifferentIdCount;
    mapping(uint => uint) public class;
    mapping(uint => uint) public expBoostPower;
    mapping(uint => uint) public stakeBoostPower;
    mapping(uint => uint) public stakeBoostDuration;
    mapping(address => bool) public minter;
    mapping(uint => uint) public partStakingPower;
    mapping(uint => bool) public partList;
    mapping(uint => uint) public partSet;
    mapping(uint => uint) public classSupply;
    mapping(uint => uint[2]) public randomBase;
    uint public classSupplyLimit = 1000;
    uint public totalSupplyLimit = 1100;
    bool internal charactersCreated = false;
    uint chestBaseCost = 5;
    address public gelvnAddress;
    address public characterAddress;
    uint keyId;

    mapping(address => bool) public setterAddress;

    uint internal randomizer;

    constructor(address _setterAddress, address _gelvnAddress, address _characterAddress) ERC1155("ELVN Game Parts") {
        addKey(89);
        gelvnAddress = _gelvnAddress;
        setterAddress[_setterAddress] = true;
        characterAddress = _characterAddress;
        minter[_characterAddress] = true;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function burn(address account, uint256 id, uint256 amount) public override onlyMinter{
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, amount);
        if(balanceOf(account, id) == 0){
            removeTokenFromOwner(account, id);
        }
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyMinter
    {
        require(partList[id],"ELVN Part: Part ID is not available for minting");
        _mint(account, id, amount, data);
        if(balanceOf(account, id) == 1){
            addTokenToOwner(account, id);
        }
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlySetter
    {
        for(uint i=0;i< ids.length;i++){
            require(partList[ids[i]],"ELVN Part: Part ID is not available for minting");
        }
        _mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
        if(balanceOf(from, id) == 0){
            removeTokenFromOwner(from, id);
        }
        if(balanceOf(to, id) == 1){
            addTokenToOwner(to, id);
        }
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyMinter{
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    //CUSTOM FUNCTIONS---------------------------------------------------------
    function setSetter(address _address) public onlyOwner{
        setterAddress[_address] = true;
    }

    function deleteSetter(address _address) public onlyOwner{
        setterAddress[_address] = false;
    }

    function random(uint _modulo) internal view returns (uint256) {
        uint256 randomHash = uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    block.difficulty,
                    block.timestamp,
                    msg.sender,
                    randomizer
                )
            )
        );
        return (randomHash % _modulo) + 1;
    }

   function setMinter(address _address) public onlyOwner{
        minter[_address] = true;
    }

    function deleteMinter(address _address) public onlyOwner{
        minter[_address] = false;
    }

    function setTokenAddress(address _address) public onlyOwner{
        gelvnAddress = _address;
    }

    function setCharacterAddress(address _address) public onlyOwner{
        characterAddress = _address;
    }

    function transferFrom(address _from, address _to, uint _id, uint _amount, bytes memory _data) public{
        _safeTransferFrom(_from, _to, _id, _amount, _data);
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = ownerDifferentIdCount[_owner];
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function walletOfOwnerWithBalance(address _owner) public view returns (uint256[] memory, uint256[] memory){
        uint256[] memory _tokenIds = walletOfOwner(_owner);
        uint256[] memory _balances;
        for(uint i = 0;i<_tokenIds.length;i++){
            _balances[i] = balanceOf(_owner,_tokenIds[i]);
        }
        return(_tokenIds,_balances);
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        public
        view
        returns (uint256)
    {
        require(
            _index < ownerDifferentIdCount[_owner],
            "ERC721Enumerable: owner index out of bounds"
        );
        return ownedTokens[_owner][_index];
    }

    function addTokenToOwner(address _to, uint256 _tokenId) private {
        uint256 length = ownerDifferentIdCount[_to];
        ownedTokens[_to][length] = _tokenId;
        ownedTokensIndex[_tokenId] = length;
        ownerDifferentIdCount[_to] += 1;
    }

    function removeTokenFromOwner(address _from, uint256 _tokenId)
        private
    {
        uint256 lastTokenIndex = ownerDifferentIdCount[_from] - 1;
        uint256 tokenIndex = ownedTokensIndex[_tokenId];
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = ownedTokens[_from][lastTokenIndex];

            ownedTokens[_from][tokenIndex] = lastTokenId; 
            ownedTokensIndex[lastTokenId] = tokenIndex; 
        }
        ownerDifferentIdCount[_from] -= 1;
        delete ownedTokensIndex[_tokenId];
        delete ownedTokens[_from][lastTokenIndex];
    }

    function virtualTransfer(address _from, address _to, uint256 _tokenId) external onlySetter{
            
            removeTokenFromOwner(_from,_tokenId);
            addTokenToOwner(_to, _tokenId);
    }

    //PART FUNCTIONS---------------------------------------------------------

    function addPart(uint _partId, uint _class, uint _stakingPower, uint _setId) public onlySetter{
        require(!partList[_partId],"ELVN Part: Part ID already in use");
        require(0 < _class && _class <= 5,"ELVN Part: Class is not a Part Class");
        partList[_partId] = true;
        class[_partId] = _class;
        partStakingPower[_partId] = _stakingPower;
        partSet[_partId] = _setId;
    }

    function addPartBatch(uint[] calldata _partId, uint[] calldata _class, uint[] calldata _stakingPower, uint[] calldata _setId) external onlySetter{
        require(_partId.length == _class.length && _partId.length == _stakingPower.length,"ELVN Char: Length of Lists are not the same");
        for(uint i = 0; i< _partId.length; i++){
            partList[_partId[i]] = true;
            class[_partId[i]] = _class[i];
            partStakingPower[_partId[i]] = _stakingPower[i];
            partSet[_partId[i]] = _setId[i];
        }
    }

    function editPart(uint _partId, uint _class, uint _stakingPower, uint _setId) public onlySetter{
        require(0 < _class && _class <= 5,"ELVN Part: Class is not a Part Class");
        require(partList[_partId]);
        class[_partId] = _class;
        partStakingPower[_partId] = _stakingPower;
        partSet[_partId] = _setId;
    }

    function setPartStakingPower(uint _partId, uint _stakingPower) public onlySetter{
        require(partList[_partId],"ELVN Part: Part ID is not available");
        require(0 < class[_partId] && class[_partId] <= 5,"ELVN Part: Class is not a Part Class");
        partStakingPower[_partId] = _stakingPower;
    }

    function setPartStakingPowerBatch(uint[] memory _partId, uint[] memory _stakingPower) public onlySetter{
        require(_partId.length == _stakingPower.length, "ELVN Part: Length for the lists are not the same");
        for(uint i = 0; i <= _partId.length;i++){
            partStakingPower[_partId[i]] = _stakingPower[i];
        }
    }

    function totalStakingPower(uint[5] memory _parts) public view returns(uint){
        uint _totalStakingPower;
        for(uint i=0; i < _parts.length;i++){
            _totalStakingPower += partStakingPower[_parts[i]];
        }
        return _totalStakingPower;
    }

    function setClassSupplyLimit(uint _classSupplyLimit) public onlyOwner{
        require(_classSupplyLimit > classSupplyLimit, "ELVN Part: The new total supply limit can't be lower than the previous one");
        classSupplyLimit = _classSupplyLimit;
    }

    function setTotalSupplyLimit(uint _totalSupplyLimit) public onlyOwner{
        require(_totalSupplyLimit > totalSupplyLimit, "ELVN Part: The new total supply limit can't be lower than the previous one");
        totalSupplyLimit = _totalSupplyLimit;
    }

    function createBaseCharacter(uint _start, uint _stop) public onlySetter{
        require(!charactersCreated, "ELVN Char: Characters already created");
        uint[2] memory _baseParts;
        for(uint i=_start; i <= _stop;i++)
        {
            _baseParts[0] = getRandomNft();
            classSupply[class[_baseParts[0]]] += 1;
            for(bool j=false; j==false;){
                _baseParts[1] = getRandomNft();
                j = (class[_baseParts[0]] != class[_baseParts[1]]);
            }
            classSupply[class[_baseParts[1]]] += 1;
            randomBase[i] = _baseParts;
        }
    }

    function getRandomBase(uint _tokenId) public view returns(uint[2] memory){
        return randomBase[_tokenId];
    }

    function addClassSupply(uint _class, uint _amount) public onlySetter{
        require(classSupply[_class] + _amount <= classSupplyLimit,"ELVN Character: The amount added is too much");
        classSupply[_class] += _amount;
    }

    function setCharactersCreatedState() public onlyOwner{
        require(!charactersCreated,"ELVN Parts: Characters were already created");
        charactersCreated = true;
    }

    function getTotalPartSupply() public view returns (uint) {
        uint _totalPartSupply;
        for(uint i=1;i <=5; i++){
            _totalPartSupply += classSupply[i];
        }
        return _totalPartSupply;
    }
    //EXP BOOST FUNCTIONS---------------------------------------------------------


    function addEXPBoost(uint _boostId, uint _expBoostPower) public onlySetter{
        require(!partList[_boostId],"ELVN Part: Boost ID already in use");
        partList[_boostId] = true;
        class[_boostId] = 6;
        expBoostPower[_boostId] = _expBoostPower;
    }

    function addEXPBoostBatch(uint[] memory _boostId, uint[] memory _expBoostPower) external onlySetter{
        require(_boostId.length == _expBoostPower.length,"ELVN Char: Length of Lists are not the same");
        for(uint i = 0; i< _boostId.length; i++){
            partList[_boostId[i]] = true;
            class[_boostId[i]] = 6;
            expBoostPower[_boostId[i]] = _expBoostPower[i];
        }
    }

    function editEXPBoost(uint _boostId, uint _expBoostPower) public onlySetter{
        require(class[_boostId] == 7,"ELVN Part: Id is not an exp boost");
        require(partList[_boostId]);
        expBoostPower[_boostId] = _expBoostPower;
    }

    //STAKING BOOST FUNCTIONS---------------------------------------------------------


    function addStakingBoost(uint _boostId, uint _stakingBoostPower, uint _stakingBoostDuration) public onlySetter{
        require(!partList[_boostId],"ELVN Part: Boost ID already in use");
        partList[_boostId] = true;
        class[_boostId] = 7;
        stakeBoostPower[_boostId] = _stakingBoostPower;
        stakeBoostDuration[_boostId] = _stakingBoostDuration;
    }

    function addStakingBoostBatch(uint[] memory _boostId, uint[] memory _stakingBoostPower, uint[] memory _stakingBoostDuration) external onlySetter{
        require(_boostId.length == _stakingBoostPower.length && _boostId.length == _stakingBoostDuration.length,"ELVN Char: Length of Lists are not the same");
        for(uint i = 0; i< _boostId.length; i++){
            partList[_boostId[i]] = true;
            class[_boostId[i]] = 7;
            stakeBoostPower[_boostId[i]] = _stakingBoostPower[i];
            stakeBoostDuration[_boostId[i]] = _stakingBoostDuration[i];
        }
    }

    function editStakingBoost(uint _boostId, uint _stakingBoostPower, uint _stakingBoostDuration) public onlySetter{
        require(class[_boostId] == 6,"ELVN Part: Id is not a staking boost");
        require(partList[_boostId]);
        stakeBoostPower[_boostId] = _stakingBoostPower;
        stakeBoostDuration[_boostId] = _stakingBoostDuration;
    }

    
    //CHEST FUNCTIONS---------------------------------------------------------
    function batchMintChest(address[] calldata _to, uint[] calldata _chest) public onlySetter{
        require(_to.length == _chest.length,"ELVN Part: Length of lists are not the same");
        for(uint i=0;i<_to.length;i++){
            mint(_to[i],_chest[i],1,"");
            if(balanceOf(_to[i], _chest[i]) == 1){
                addTokenToOwner(_to[i], _chest[i]);
            }
        }
    }

    function addKey(uint _keyId) public onlySetter{
        require(!partList[_keyId],"ELVN Part: Key ID was already set");
        partList[_keyId] = true;
        keyId = _keyId;
    }

    function changeKeyId(uint _keyId) public onlySetter{
        keyId = _keyId;
    }

    function addChest(uint _chestId) public onlySetter {
        require(!partList[_chestId],"ELVN Part: Boost ID already in use");
        partList[_chestId] = true;
        class[_chestId] = 9;
    }

    function addChestBatch(uint[] memory _chestId) external onlySetter{
        for(uint i = 0; i< _chestId.length; i++){
            partList[_chestId[i]] = true;
            class[_chestId[i]] = 9;
        }
    }

    function openWoodChest(bool _useKey) public {
        require(balanceOf(msg.sender, 90) > 0,"ELVN Parts: You don't own a chest");
        if(_useKey){
            require(balanceOf(msg.sender,keyId)>= 1,"ELVN Parts: You don't own any Keys");
            burn(msg.sender,keyId,1);
        }
        else{
            require(IERC20(gelvnAddress).balanceOf(msg.sender) >= chestBaseCost * 1e18);
        }
        uint _randomBase;
        if(getTotalPartSupply() >= totalSupplyLimit && _randomBase <= 5){
                _randomBase = random(95)+5;
                randomizer = _randomBase;
        }
        else{
            _randomBase = random(100);
            randomizer = _randomBase;
        }   
        if(_randomBase <= 5){
            uint _partId = getRandomNft();
            mint(msg.sender,_partId,1,"");
            classSupply[class[_partId]] += 1;
        }
        else if(_randomBase >5 && _randomBase <= 20)
        {
            getRandomStakingBoost(1);
        }
            else if(_randomBase >20 && _randomBase <= 75)
            {
                getRandomExpBoost(1);
            }
            else
            {
                mint(msg.sender,keyId,1,"");
            }

        burn(msg.sender,90,1);
        takeChestPayment(chestBaseCost * 2);
    }

    function openBronzeChest(bool _useKey) public {
        require(balanceOf(msg.sender, 91) > 0,"ELVN Parts: You don't own a chest");
        if(_useKey){
            require(balanceOf(msg.sender,keyId)>= 1,"ELVN Parts: You don't own any Keys");
            burn(msg.sender,keyId,1);
        }
        else{
            require(IERC20(gelvnAddress).balanceOf(msg.sender) >= chestBaseCost * 2 * 1e18);
        }
        uint _randomBase;
        if(getTotalPartSupply() >= totalSupplyLimit && _randomBase <= 5){
                _randomBase = random(90)+10;
                randomizer = _randomBase;
        }
        else{
            _randomBase = random(100);
            randomizer = _randomBase;
        }  
        if(_randomBase <= 10){
            uint _partId = getRandomNft();
            mint(msg.sender,_partId,1,"");
            classSupply[class[_partId]] += 1;
        }
        else if(_randomBase >10 && _randomBase <= 35){
            getRandomStakingBoost(2);
        }
            else if(_randomBase >35 && _randomBase <= 85){
                getRandomExpBoost(2);
            }
            else
            {
                    mint(msg.sender,keyId,1,"");
            }
        burn(msg.sender,91,1);
        takeChestPayment(chestBaseCost * 2);
    }

    function openSilverChest(bool _useKey) public {
        require(balanceOf(msg.sender, 92) > 0,"ELVN Parts: You don't own a chest");
        if(_useKey){
            require(balanceOf(msg.sender,keyId)>= 1,"ELVN Parts: You don't own any Keys");
            burn(msg.sender,keyId,1);
        }
        else{
            require(IERC20(gelvnAddress).balanceOf(msg.sender) >= chestBaseCost * 2 * 1e18);
        }
        uint _randomBase;
        if(getTotalPartSupply() >= totalSupplyLimit && _randomBase <= 5){
                _randomBase = random(80)+20;
                randomizer = _randomBase;
        }
        else{
            _randomBase = random(100);
            randomizer = _randomBase;
        }  
        if(_randomBase <= 20){
            uint _partId = getRandomNft();
            mint(msg.sender,_partId,1,"");
            classSupply[class[_partId]] += 1;
        }
        else if(_randomBase >20 && _randomBase <= 50){
            getRandomStakingBoost(3);
        }
            else if(_randomBase >50 && _randomBase <= 95){
                getRandomExpBoost(3);
            }
            else
            {
                mint(msg.sender,keyId,1,"");
            }
        burn(msg.sender,92,1);
        takeChestPayment(chestBaseCost * 3);
    }

    function openGoldChest(bool _useKey) public {
        require(balanceOf(msg.sender, 93) > 0,"ELVN Parts: You don't own a chest");
        if(_useKey){
            require(balanceOf(msg.sender,keyId)>= 1,"ELVN Parts: You don't own any Keys");
            burn(msg.sender,keyId,1);
        }
        else{
            require(IERC20(gelvnAddress).balanceOf(msg.sender) >= chestBaseCost * 2 * 1e18);
        }
        uint _randomBase;
        if(getTotalPartSupply() >= totalSupplyLimit && _randomBase <= 5){
                _randomBase = random(70)+30;
                randomizer = _randomBase;
        }
        else{
            _randomBase = random(100);
            randomizer = _randomBase;
        }  
        if(_randomBase <= 30){
            uint _partId = getRandomNft();
            mint(msg.sender,_partId,1,"");
            classSupply[class[_partId]] += 1;
        }
        else if(_randomBase >30 && _randomBase <= 70){
            getRandomStakingBoost(4);
        }
        else
        {
            getRandomExpBoost(4);
        }
        burn(msg.sender,93,1);
        takeChestPayment(chestBaseCost * 4);
    }

    function openLegendaryChest(bool _useKey) public {
       require(balanceOf(msg.sender, 94) > 0,"ELVN Parts: You don't own a chest");
       if(_useKey){
            require(balanceOf(msg.sender,keyId)>= 1,"ELVN Parts: You don't own any Keys");
            burn(msg.sender,keyId,1);
        }
        else{
            require(IERC20(gelvnAddress).balanceOf(msg.sender) >= chestBaseCost * 2 * 1e18);
        }
        uint _randomBase;
        if(getTotalPartSupply() >= totalSupplyLimit && _randomBase <= 5){
                _randomBase = random(60)+40;
                randomizer = _randomBase;
        }
        else{
            _randomBase = random(100);
            randomizer = _randomBase;
        }  
        if(_randomBase <= 40){
            uint _partId = getRandomNft();
            mint(msg.sender,_partId,1,"");
            classSupply[class[_partId]] += 1;
        }
        else if(_randomBase >40 && _randomBase <= 90)
        {
            getRandomStakingBoost(5);
        }
        else
        {
            getRandomExpBoost(5);
        }
        burn(msg.sender,94,1);
        takeChestPayment(chestBaseCost * 5);
    }

    function setChestBaseCost(uint _cost) public onlySetter{
        chestBaseCost = _cost;
    }

    function takeChestPayment(uint _amount) internal{
        IERC20(gelvnAddress).transferFrom(msg.sender,characterAddress,_amount * 1e18);
        ICHAR(characterAddress).chestPayment(_amount);
    }

    function getRandomNft() internal returns (uint){
        uint _randomClass;
        for(bool i=false; i == false;){
            _randomClass = random(5); 
            i = ( classSupply[_randomClass] <= classSupplyLimit);
        }
        randomizer = random(9999);
        uint _randomPartResult = random(10000);
        randomizer = random(9999);
        uint _partId;
        if(_randomPartResult <= 2500){
            _partId = 1;
        }
        else if(_randomPartResult > 2500 && _randomPartResult <= 4000){
            _partId = 2;
        } 
            else if(_randomPartResult > 4000 && _randomPartResult <= 4750){
                _partId = 3;
            } 
                else if(_randomPartResult > 4750 && _randomPartResult <= 5000){
                    _partId = 4;
                } 
                    else if(_randomPartResult > 5000 && _randomPartResult <= 6500){
                        _partId = 5;
                    }
                        else if(_randomPartResult > 6500 && _randomPartResult <= 7400){
                            _partId = 6;
                        } 
                            else if(_randomPartResult > 7400 && _randomPartResult <= 7850){
                                _partId = 7;
                            }
                                else if(_randomPartResult > 7850 && _randomPartResult <= 8000){
                                    _partId = 8;
                                } 
                                    else if(_randomPartResult > 8000 && _randomPartResult <= 8750){
                                        _partId = 9;
                                    } 
                                        else if(_randomPartResult > 8750 && _randomPartResult <= 9200){
                                            _partId = 10;
                                        } 
                                            else if(_randomPartResult > 9200 && _randomPartResult <= 9425){
                                                _partId = 11;
                                            }
                                                else if(_randomPartResult > 9425 && _randomPartResult <= 9500){
                                                    _partId = 12;
                                                } 
                                                    else if(_randomPartResult > 9500 && _randomPartResult <= 9750){
                                                        _partId = 13;
                                                    }
                                                        else if(_randomPartResult > 9750 && _randomPartResult <= 9900){
                                                            _partId = 14;
                                                        }
                                                            else if(_randomPartResult > 9900 && _randomPartResult <= 9975){
                                                                _partId = 15;
                                                            }
                                                                else
                                                                {
                                                                    _partId = 16;
                                                                } 
        _partId = (_randomClass - 1) * 16 + _partId;
        return _partId;
    }

    function getRandomStakingBoost(uint _chestId) internal {
        uint _randomBoostResult = getRandomBoostNumber(_chestId);
        uint _boostId = _randomBoostResult + 80;
        mint(msg.sender,_boostId,1,"");
    }

    function getRandomExpBoost(uint _chestId) internal {
        uint _randomBoostResult = getRandomBoostNumber(_chestId);
        uint _boostId = _randomBoostResult + 84;
        mint(msg.sender,_boostId,1,"");
    }

    function getRandomBoostNumber(uint _chestId) internal returns(uint){
        uint _randomBoostResult = random(100);
        randomizer = _randomBoostResult;
        uint _boostLevel;
        if(_chestId == 1){
            if(_randomBoostResult <= 5){
                _boostLevel = 4;
            }
            else if(_randomBoostResult > 5 && _randomBoostResult <= 20){
                _boostLevel = 3;
                }
                else if(_randomBoostResult > 20 && _randomBoostResult <= 50){
                    _boostLevel = 2;
                    }
                    else
                    {
                         _boostLevel = 1;
                    }
        }
        else
        {
            if(_chestId == 2)
            {
                if(_randomBoostResult <= 10){
                    _boostLevel = 4;
                }
                else if(_randomBoostResult > 10 && _randomBoostResult <= 40){
                    _boostLevel = 3;
                    }
                    else if(_randomBoostResult > 40 && _randomBoostResult <= 70){
                        _boostLevel = 2;
                        }
                        else
                        {
                            _boostLevel = 1;
                        }
            }
            else
            {
                if(_chestId == 3){
                    if(_randomBoostResult <= 20){
                        _boostLevel = 4;
                    }
                    else if(_randomBoostResult > 20 && _randomBoostResult <= 60){
                        _boostLevel = 3;
                        }
                        else
                        {
                            _boostLevel = 2;
                        }
                }
                else
                {
                    if(_chestId == 4){
                        if(_randomBoostResult <= 40){
                            _boostLevel = 4;
                        }
                        else if(_randomBoostResult > 40 && _randomBoostResult <= 80){
                            _boostLevel = 3;
                            }
                            else
                            {
                                _boostLevel = 2;
                            }
                    }
                    else if(_randomBoostResult <= 60){
                        _boostLevel = 4;
                        }
                        else{
                            _boostLevel = 3;
                        }
                }
            }
        }
        return _boostLevel;
    }
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] -= amounts[i];
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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