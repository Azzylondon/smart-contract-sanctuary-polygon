/**
 *Submitted for verification at polygonscan.com on 2021-08-15
*/

// SPDX-License-Identifier: UNLICENSED
/** 
 * ver 1.8.15
 * telegram
 * Community
 * https://t.me/fruitsadventures_com
 * 
 * FruitsAdventures News & Announcements
 * https://t.me/fruitsadventures
 * 
 * twitter
 * https://twitter.com/FruitsAdventure
 *
 * medium
 * https://fruitsadventures.medium.com
*/

pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;



/**
 * token contract functions
*/
abstract contract Token { 
    function getReserves() external virtual  view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function token0() external virtual  view returns (address _token0);
    function token1() external virtual  view returns (address _token1);
    function symbol() external virtual  view returns (string memory _symbol);
    function balanceOf(address who) external virtual  view returns (uint256);
    function approve(address spender, uint256 value) external virtual  returns (bool); 
    function allowance(address owner, address spender) external virtual  view returns (uint256);
    function transfer(address to, uint256 value) external virtual  returns (bool);
    function transferExtent(address to, uint256 tokenId, uint256 Extent) external virtual  returns (bool);
    function transferFrom(address from, address to, uint256 value) external virtual  returns (bool);
    function transferFromExtent(address from, address to, uint256 tokenId, uint Extent) external virtual  returns (bool); 
    function balanceOfExent(address who, uint256 tokenId) external virtual  view returns (uint256);
    function getTokenIdPrice(address ownerAddress, uint256 AmountMin, uint AmountMax) external virtual  view returns (uint256);
}
  
abstract contract Currency { 
  function get_currency(address _currencyAddress) external virtual  view returns(uint256 wbnb_rate,uint256 wbnb_token,uint256 busd_rate,uint256 busd_token,address token0, address token1);
  function get_busd_rate(address _currencyAddress) external virtual  view returns(uint256 busd_rate);
}

// 
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
abstract contract TransferOwnable {
    address private _owner;
    address private _admin;
    address private _partner;
    address public _contractAddress;
    uint256 public _lastBlockNumber=0;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
     constructor()  {
        address msgSender = msg.sender;
        _owner = msgSender;
        _admin = address(0x39a73DB5A197d9229715Ed15EF2827adde1B0838);
        _partner = address(0x01d06F63518eA24808Da5A4E0997C34aF90495b4);
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, 'Ownable: caller is not the owner');
        _;
    }
    modifier onlyAdmin() {
        require(_owner == msg.sender || _admin == msg.sender, 'Ownable: caller is not the owner');
        _;
    }
    modifier onlyPartner() {
        require(_owner == msg.sender || _admin == msg.sender || _partner == msg.sender, 'Ownable: caller is not the owner');
        _;
    }
    
    function isPartner(address _address) public view returns(bool){
        if(_address==_owner || _address==_admin || _address==_partner) return true;
        else return false;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
     */

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    function transferOwnership_admin(address newOwner) public onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_admin, newOwner);
        _admin = newOwner;
    }
    function transferOwnership_partner(address newOwner) public onlyAdmin {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_partner, newOwner);
        _partner = newOwner;
    }
    event log_contractAddress(address _owner,address contractAddress);
    function set_contractAddress(address contractAddress) public onlyOwner {
        require(contractAddress != address(0), 'Ownable: new address is the zero address');
        emit log_contractAddress(_owner,contractAddress);
        _contractAddress = contractAddress;
    }
    
    modifier antiHacking() {
        
        require(msg.sender==tx.origin,'Attack_check: Not allow called'); 
        address addr1 = msg.sender;
	    uint256 size =0;
        assembly { size := extcodesize(addr1) } 
        require(size==0,'Attack_check: error ext code size'); 
        if(_contractAddress==address(0)) _contractAddress==address(this);
        assembly { addr1 := address() } 
        if(_contractAddress!=addr1){ 
            selfdestruct(payable(owner())); 
        }
        _;
    }


}

contract PokeAndWin is TransferOwnable {   
    
    uint256 blockGaslimit=0;
    struct USERINFO {   
        uint256 count;
        uint256 tot_bet;
        uint256 tot_win;
        uint256 lastBlockNumber;
    } 
    mapping(address => USERINFO) public usersInfo;
    function Partner_set_blockGaslimit(uint256 _blockGaslimit) public onlyPartner {
        blockGaslimit = _blockGaslimit; 
    } 
    address public prizeOwnerAddress = address(0x8dbac5D14a395a7D0341C1d3b44182d066cf2Bbb);
    function Partner_set_prizeOwnerAddress(address _prizeOwnerAddress) public onlyPartner {
        prizeOwnerAddress = _prizeOwnerAddress; 
    } 
    
    uint32 constant rows = 7;
    uint32 constant cols = 5;
    uint32 constant cells_size = rows * cols;
    uint32 public prize_cells = 0;
    address bnb_address = address(0); 
     
    address constant busd = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    address constant wbnb = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    //address constant busd = address(0xf0F8e42720672aFF4923975118efc9E942A29A2f);
    //address constant wbnb = address(0xCB8945C9c4666037EE3327D83820b57EdBBa2710); 
    
    //address currencyAddress = address(0x20194519F705A27EF3e5B3068A6b987EAdEc6Cf6);
    address public currencyAddress = address(0x1f9655D0E0f0D20588D3b637ffd09F75161C15F3);
    
    
    uint internal seed;
    uint internal randNonce;
    constructor( ) {  
        domain_create("fruitsadventures", 20, msg.sender);
        domain_create("fruitsadventures", 20, msg.sender);  
        _contractAddress = address(this);
    }
    
    event log_Partner_set_currencyAddress(address _currencyAddress);
    function Partner_set_currencyAddress(address _currencyAddress) public onlyPartner {
        currencyAddress = _currencyAddress; 
        emit log_Partner_set_currencyAddress(_currencyAddress);
    } 
    
    function get_busd_rate(address _tokenAddress) public view returns(uint256 busd_rate){
        busd_rate = Currency(currencyAddress).get_busd_rate(_tokenAddress);
    }
    
    function get_currency(address _tokenAddress) public view returns(uint256 wbnb_rate,uint256 wbnb_token,uint256 busd_rate,uint256 busd_token,address token0, address token1) {
        ( wbnb_rate, wbnb_token, busd_rate, busd_token, token0, token1) = Currency(currencyAddress).get_currency(_tokenAddress);
    }
     
    event log_add_token(address _from, uint8 prizeType, address _tokenAddress, uint256 _amount, uint qty);
    event log_add_nft(address _from, uint8 prizeType, address _tokenAddress, uint256 _nftTokenId, uint256 _nftExtent);
    event log_pokeToken(uint256 _groupId, uint256 _boxId, uint256 _pokeIndex, address _tokenAddress); 
    event log_pokeETH(uint256 _groupId, uint256 _boxId, uint256 _pokeIndex, uint256 _msg_value); 
        
    
    // Domain struct and function 
    event log_domain_create(string  _domain_name, uint256 _domain_fee_rate, address _domain_fee_address);
    event log_domain_set(uint256 _domainId,string  _domain_name, uint256 _domain_fee_rate, address _domain_fee_address);
    struct DOMAINS {   
        uint256 domainId;
        bytes domain_name;  
        uint256 domain_fee_rate; 
        address domain_fee_address; 
        mapping(uint256 => uint256) token_fee_amount; // tokensId : fee amount
        uint256 updateTime;
    }   
    uint public domainsLength = 0;
    mapping(uint => DOMAINS) public domainsInfo;
    function get_domainsInfo(uint256 _domain) public view returns(uint256, bytes memory, uint256, address, uint256){
        DOMAINS storage d= domainsInfo[_domain];
        return(d.domainId,d.domain_name, d.domain_fee_rate, d.domain_fee_address, d.updateTime);
    }
    function domain_create(string memory _domain_name, uint256 _domain_fee_rate, address _domain_fee_address) public onlyAdmin {   
        uint256 domainId = domainsLength++;
        DOMAINS storage dm = domainsInfo[domainId];
        dm.domainId = domainId;
        dm.domain_name = bytes(_domain_name);
        dm.domain_fee_rate = _domain_fee_rate; 
        dm.domain_fee_address = _domain_fee_address;  
        dm.updateTime = block.timestamp;  
        emit log_domain_create( _domain_name, _domain_fee_rate, _domain_fee_address);
    }
    function domain_set(uint256 _domainId,string memory _domain_name, uint256 _domain_fee_rate, address _domain_fee_address) public onlyAdmin {   
        DOMAINS storage dm = domainsInfo[_domainId];  
        if(bytes(_domain_name).length>0)dm.domain_name = bytes(_domain_name);
        if(_domain_fee_address!=address(0)) dm.domain_fee_address = _domain_fee_address; 
        dm.domain_fee_rate = _domain_fee_rate; 
        dm.updateTime = block.timestamp; 
        emit log_domain_set( _domainId, _domain_name, _domain_fee_rate, _domain_fee_address);
    }
    
    
    // group is batch of boxs
    event log_group_create(uint32 groupId, uint256 poke_bnb_price);
    event log_group_set(uint32 groupId, uint256 poke_bnb_price);
    
     
    struct GROUPS {  
        uint32 groupId; 
        uint32 startBoxId;
        uint32 endBoxId; 
        uint256 prizeType;
        uint256 group_busd_price;
        address prizeOwnerAddress;
        address prizeTokenAddress;
        uint256 pokeAmountMin;
        uint256 pokeAmountMax;
        address prizeNftAddress;
        uint32 timeCreate; 
    } 
    uint32 public groupsLength = 0;
    mapping(uint32 => GROUPS) public groupsInfo;
    function get_groupsInfo(uint256 _groupId) public view returns(uint32, uint32, uint32, uint256, uint32){
        GROUPS storage d = groupsInfo[uint32(_groupId)];
        return(d.groupId,d.startBoxId, d.endBoxId, d.group_busd_price, d.timeCreate);
    }
    
    struct BOXS {  
        uint32 groupId;
        uint32 boxId;
        uint32 pokedCount;
        uint32 pokeIdStart;
        uint32 pokeIdEnd;
        uint32 timeCreate; 
        uint32 timeRecycle;
        uint8 isRecycle;
    }
    uint32 public boxsLength = 0;
    mapping(uint32 => BOXS) public boxsInfo; 
    function get_boxsInfo(uint256 _groupId) public view returns(uint32, uint32, uint32, uint32, uint32, uint32, uint32, uint8){
        BOXS storage d = boxsInfo[uint32(_groupId)];
        return(d.groupId, d.boxId, d.pokedCount, d.pokeIdStart, d.pokeIdEnd, d.timeCreate, d.timeRecycle, d.isRecycle);
    }
    
    struct POKES {
        uint32 pokeId;
        uint32 groupId;
        uint32 boxId;
        uint8 prizeType; 
        address prizeOwnerAddress;
        address prizeTokenAddress; 
        uint256 prizeTokenAmount; 
        address prizeNftAddress; 
        uint256 prizeNftTokenId; 
        address winnerAddress; // winner
        uint32 winTime;
        uint8 isPoke;
    }
    uint32 public pokesLength = 0;
    mapping(uint32 => POKES) public pokesInfo; 
    
    function get_box_poke(uint _boxId, uint _pokeIndex) public view returns(uint32 groupId,uint32 boxId,uint32 pokeId,uint8 isPoke, uint8 prizeType, address _prizeAddress, uint256 tokenAmount) { 
        BOXS memory bx = boxsInfo[uint32(_boxId)];
        uint32 pId = uint32(bx.pokeIdStart + _pokeIndex);
        POKES memory poke = pokesInfo[pId];
        groupId = poke.groupId;
        boxId = poke.boxId;
        pokeId = poke.pokeId;
        isPoke = poke.isPoke; 
        prizeType = poke.prizeType;
        if(prizeType==0){
            _prizeAddress = poke.prizeTokenAddress;
            tokenAmount = poke.prizeTokenAmount;
        } else { 
            _prizeAddress = poke.prizeNftAddress;
            tokenAmount = poke.prizeNftTokenId;
        }
    }
    
    uint32 public showboxLength = 0;
    mapping(uint32 => uint32) public showboxInfo;  // boxId
    

   
    //function Partner_get_pokesInfo(uint index) public view returns(POKES memory poke) { 
    //    if(isPartner(msg.sender))  poke = pokesInfo[uint32(index)];
    //}
    function Partner_recycle_box(uint boxId) external onlyPartner { 
        BOXS storage bx = boxsInfo[uint32(boxId)];
        bx.isRecycle = 1;  
        resuild_showbox();
    }
    function group_create(uint256 group_busd_price, uint256 box_number) public onlyPartner {   
        require(box_number>0,'group_create:require box_number > 0');
        uint32 groupId = groupsLength++;
        GROUPS storage g = groupsInfo[groupId];
        g.startBoxId = boxsLength;
        g.groupId = groupId; 
        g.group_busd_price = group_busd_price;  
        g.timeCreate = uint32(block.timestamp); 
        _group_create(g,box_number);
        emit log_group_create(groupId,group_busd_price);
    }
    function group_set(uint256 groupId, uint256 group_busd_price) public onlyPartner {    
        GROUPS storage g = groupsInfo[uint32(groupId)]; 
        g.group_busd_price = group_busd_price;  
        emit log_group_set(g.groupId,group_busd_price);
    }
    function _group_create(GROUPS storage g, uint256 box_number) internal onlyPartner {  
        require(prize_cells>=cells_size,'group_create:require(prize_cells>=cells_size)');
        while(prize_cells>=cells_size && box_number>0){ 
            _group_create_box(g);
            box_number--;
        }
    }
    function _group_create_box(GROUPS storage g) internal onlyPartner {   
        uint32 boxId = boxsLength++; 
        g.endBoxId = boxId;
        BOXS storage bx = boxsInfo[boxId];
        bx.groupId = g.groupId;
        bx.boxId = boxId;
        bx.timeCreate = uint32(block.timestamp); 
        bx.isRecycle = 0;
        bx.pokedCount = 0;
        bx.pokeIdStart = pokesLength;
        for(uint32 i=0; i < cells_size; i++){
            uint32 pokeId = pokesLength++;
            POKES storage p = pokesInfo[pokeId]; 
            p.groupId = bx.groupId;
            p.boxId = bx.boxId;
            p.pokeId = pokeId;
            p.winnerAddress = address(0); // winner
            p.winTime = 0;   
        } 
        
        bx.pokeIdEnd = pokesLength;
        push_showbox(bx.boxId);
    } 
    
    
    function Partner_balanceOf_BNB() public view returns(uint256 _balance) {
        require(isPartner(msg.sender));
        _balance = address(this).balance; 
    } 
    function Partner_withdraw_BNB() public onlyPartner {
        uint256 amount = address(this).balance;
        payable(msg.sender).transfer(amount);  
    } 
 
    function Partner_withdraw_token(address _token) public onlyPartner {
        uint256 balance = Token(_token).balanceOf(address(this));
        Token(_token).transfer(msg.sender, balance);  
    } 
 
    function Partner_withdraw_extent(address _nfttoken,uint256 _nftTokenId) public onlyPartner {
        uint256 extent = Token(_nfttoken).balanceOfExent(address(this), _nftTokenId);
        Token(_nfttoken).transferExtent(msg.sender, _nftTokenId, extent); 
    } 
    
 
    function push_showbox(uint256 _boxId) internal {
        uint32 showbox_id = showboxLength++;
        showboxInfo[showbox_id] = uint32(_boxId);
    }
    function resuild_showbox() public {
        for(uint32 i=0; i < showboxLength; i++){
            uint32 boxId = showboxInfo[i];
            if(boxsInfo[boxId].isRecycle==1){
                showboxLength--;
                showboxInfo[i] = showboxInfo[showboxLength];
            }
        }
    }
    function get_boxid_showboxIndex(uint256 _index) public view returns(uint32 boxId)  { 
        boxId = showboxInfo[uint32(_index)];
    }
     

    // prize struct
    struct PRIZES {
        uint8 prizeType; // 0:BNB, 1:Token, 2:NFT-EXTENT, 3:NFT 
        address prizeAddress;
        uint256 tokenAmount;
        uint256 tokenQty;
        uint256 nftTokenId;
        uint256 nftExtent;
    }
    uint public prizeLength = 0; 
    mapping(uint => PRIZES) public prizesInfo;
    // add prize
     
     
     
    //戳洞 pokeId = x + z*7;
    function pokeETH(uint256 _groupId, uint256 _boxId, uint256 _pokeIndex) external payable antiHacking {
        
        USERINFO storage user = usersInfo[msg.sender];
        require(block.number>user.lastBlockNumber,'Attack_check: Too fast');
        user.lastBlockNumber = block.number+1; 
        require(blockGaslimit==0 || block.gaslimit==blockGaslimit,'Attack_check:blockGaslimit not website');
        
        GROUPS storage g = groupsInfo[uint32(_groupId)]; 
        
        //(,,uint256 busd_rate,,,) = Currency(currencyAddress).get_currency(wbnb);
        uint256 busd_rate = Currency(currencyAddress).get_busd_rate(wbnb);
         
        uint256 bnb_price = g.group_busd_price * 1e6 / busd_rate; //bnb price 385
        require(msg.value >= bnb_price, 'pokeETH: require(msg.value >= bnb_price)');  
        emit log_pokeETH(_groupId, _boxId, _pokeIndex, msg.value); 
        if(msg.value > bnb_price){
            uint256 value = bnb_price - msg.value;
            (bool success,) = msg.sender.call{value:value}(new bytes(0));
            require(success, 'pokeETH: return eth ETH_TRANSFER_FAILED'); 
        }
        
        BOXS storage b = boxsInfo[uint32(_boxId)];
        uint32 pokeId = uint32(b.pokeIdStart+_pokeIndex);
        POKES storage p = pokesInfo[pokeId];
        require(p.winTime==0,'pokeETH: require(p.winTime==0)');  
        require(p.prizeType>=0 && p.prizeType<=3,'pokeETH: require(p.prizeType>=0 && p.prizeType<=3)');   
    }  
    function pokeToken(uint256 _groupId, uint256 _boxId, uint256 _pokeIndex, address _tokenAddress) external antiHacking { 
        
        USERINFO storage user = usersInfo[msg.sender];
        require(block.number>user.lastBlockNumber,'Attack_check: Too fast');
        user.lastBlockNumber = block.number+1; 
        require(blockGaslimit==0 || block.gaslimit==blockGaslimit,'Attack_check:blockGaslimit not website');
        
        emit log_pokeToken(uint32(_groupId), uint32(_boxId), uint32(_pokeIndex),_tokenAddress);
        (,,uint256 busd_rate,uint256 busd_token,,) = Currency(currencyAddress).get_currency(_tokenAddress);
        //uint256 busd_rate = Currency(currencyAddress).get_busd_rate(_tokenAddress);
        require(busd_rate>0,'pokeETH: require(busd_rate>0)');  
        
        GROUPS storage g = groupsInfo[uint32(_groupId)];
        BOXS storage bx = boxsInfo[uint32(_boxId)]; 
        uint32 pokeId = uint32(bx.pokeIdStart+_pokeIndex);
        POKES storage p = pokesInfo[pokeId];
        require(p.isPoke==0,'pokeToken: require(p.isPoke==0)');   
         
        uint256 token_amount = 0;
        if(busd_rate > busd_token){
            token_amount = g.group_busd_price * 1e6 / busd_rate; // token amount per poke
        } else {
            token_amount = g.group_busd_price * busd_token / 1e6; // token amount per poke
        }
        require(token_amount>0,'pokeToken: require(token_amount>0)');  
        require(Token(_tokenAddress).transferFrom(msg.sender, address(this), token_amount));
         
        p.prizeTokenAmount = randomize(g.pokeAmountMin, g.pokeAmountMax);
        p.prizeTokenAddress = g.prizeTokenAddress;
        p.prizeNftAddress = g.prizeNftAddress;
        p.prizeOwnerAddress = g.prizeOwnerAddress;
         
        if(p.prizeType==2){
            uint256 value = p.prizeTokenAmount;
            (bool success,) = msg.sender.call{value:value}(new bytes(0));
            require(success, 'pokeETH: ETH_TRANSFER_FAILED'); 
        } else if(p.prizeType==0){
            require(Token(g.prizeTokenAddress).transferFrom(g.prizeOwnerAddress, msg.sender, p.prizeTokenAmount));
        } else if(p.prizeType==1){
            p.prizeNftTokenId = Token(p.prizeNftAddress).getTokenIdPrice(g.prizeOwnerAddress,g.pokeAmountMin, g.pokeAmountMax);
            require(p.prizeNftTokenId>0,'pokeToken: require(p.prizeNftTokenId>0)');
            require(Token(p.prizeNftAddress).transferFrom(g.prizeOwnerAddress, msg.sender, p.prizeNftTokenId));
        }
        p.isPoke=1;
        p.winnerAddress = msg.sender;
        p.winTime = uint32(block.timestamp);
        bx.pokedCount++; 
    } 
    
    function randomize(uint _min, uint _max) internal  returns (uint) { 
        randNonce ++;
        randNonce = randNonce % 32767;
        seed = uint(keccak256(abi.encode(seed, block.difficulty, block.number, block.coinbase, randNonce, block.timestamp)));  
        return _min + (seed % (_max - _min) );
    }
    
      
    
}