/**
 *Submitted for verification at polygonscan.com on 2021-08-25
*/

// File: contracts/SafeMath.sol

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity >=0.5.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    int256 constant private INT256_MIN = -2**255;

    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Multiplies two signed integers, reverts on overflow.
    */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN)); // This is the only case of overflow not detected by the check below

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
    */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0); // Solidity only automatically asserts when dividing by 0
        require(!(b == -1 && a == INT256_MIN)); // This is the only case of overflow

        int256 c = a / b;

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Subtracts two signed integers, reverts on overflow.
    */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Adds two signed integers, reverts on overflow.
    */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// File: contracts/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address to, uint256 value) external returns (bool);
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

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function blindBox(address seller, string calldata tokenURI, bool flag, address to, string calldata ownerId) external returns (uint256);
    function mintAliaForNonCrypto(uint256 price, address from) external returns (bool);
    // function transferOwnershipPack(address seller, address to, uint256 tokenId, string calldata ownerId) external returns (bool);
    function getRandomNumber() external returns (bytes32);
    function getRandomVal() external returns (uint256);
}

// File: contracts/BlindBox.sol

pragma solidity 0.5.0;



contract BlindBox {

using SafeMath for uint256;
  IERC20 ALIA;
  uint256 randomValue;
  address xanaliaDex;

  struct category{
    mapping(uint256=>string) tokenUris;
    uint256 count;
    string title;
    string description;
    string image;
    uint256 price;
    uint256 usdPrice;
    uint256 countNFT;
  }
  mapping(string=>category) private Category;
   bool private isInitialized1;
  IERC20 LPAlia;
  //IERC20 LPBNB;
using SafeMath for uint112;
  struct categoryDetail{  
    string hash;  
  } 
  mapping(string=>categoryDetail) private CategoryDetail;

  event CreateCategory(string name, string title,string description,string image, uint256 price, uint256 usdPrice, uint256 countNFT, string detailHash);
  event URIAdded(string name, string uri, uint256 count);
  event BuyBox(address buyer, string ownerId, string name, uint256 tokenIds );
  event UpdateAllValueOfPack(string name, string title, string description, string image, uint256 price, uint256 usdPrice, uint256 count, string detailHash);
  constructor() public{
    // ALIA = IERC20(0x8D8108A9cFA5a669300074A602f36AF3252B7533);
    // xanaliaDex = 0xc2F19E2be5c5a1AA7A998f44B759eb3360587ad1;
    // LPAlia=IERC20(0x52826ee949d3e1C3908F288B74b98742b262f3f1);
    // LPBNB=IERC20(0xe230E414f3AC65854772cF24C061776A58893aC2);
    // isInitialized1=true;
  }

 function init1() public {
    require(!isInitialized1);
    ALIA = IERC20(0xe1a4af407A124777A4dB6bB461b6F256c1f8E341);
    xanaliaDex = 0xfE1a571eb3458d3aCf7d71bF0A78aC62DA537124;
    LPAlia=IERC20(0x8c77B810EaC25502EE7de2e447ffb80b316c4E6E);
    //LPBNB=IERC20(0xe230E414f3AC65854772cF24C061776A58893aC2);
    isInitialized1=true;
  }
  IERC20 chainRan;
  bool private isInitialized2;
  uint256 randomValueMain;
  function init2() public {
    require(!isInitialized2);
    isInitialized2=true;
    chainRan = IERC20(0xF3af3ae700dedeee1Ed84aAA5b1849bb2cB36f01);
  }

  modifier adminAdd() {
      require(msg.sender == 0x7712a69600587E48d73060Def272D3a37e078921);
      _;
  }

  function createCategory(string memory name, string memory title, string memory description, string memory image, uint256 price, uint256 usdPrice, uint256 countNFT, string memory detailHash) public adminAdd {
    require(price > 0 || usdPrice > 0, "Price or Price in usd should be greater than 0");
    require(countNFT > 0, "Count of NFTs should be greater then 0");
    require(Category[name].count == 0, "NFT name alreay present with token URIs");
    Category[name].title = title;
    Category[name].description = description;
    Category[name].image = image;
    Category[name].price = price;
    Category[name].usdPrice = usdPrice;
    Category[name].countNFT = countNFT;
    CategoryDetail[name].hash = detailHash; 
    emit CreateCategory(name, title, description, image, price, usdPrice,countNFT, detailHash);
  }

  function addUriToCategory(string memory name,string memory uris) adminAdd public {
    require(Category[name].price > 0 || Category[name].usdPrice > 0, "Category not created");
    Category[name].tokenUris[Category[name].count] = uris;
    emit URIAdded(name, uris,Category[name].count);
    Category[name].count++;
  }
  function updateAllValueOfPack(string memory name, string memory title,string memory description, string memory image, uint256 price, uint256 usdPrice, uint256 count, string memory detailHash)  public adminAdd {
    require(price > 0 || usdPrice > 0, "Price or Price in usd should be greater than 0");
    Category[name].title = title;
    Category[name].description = description;
    Category[name].image = image;
    Category[name].price = price;
    Category[name].usdPrice = usdPrice;
    Category[name].countNFT = count;
    CategoryDetail[name].hash = detailHash; 
    emit UpdateAllValueOfPack(name, title, description, image, price, usdPrice, count, detailHash);
  }
  

  function buyBox(address seller, string memory ownerId, string memory name) public {
    uint256 price = Category[name].price;
    if(price == 0){
      //(uint112 _reserve0, uint112 _reserve1,) =LPBNB.getReserves();
           (uint112 reserve0, uint112 reserve1,) =LPAlia.getReserves();
           price = (Category[name].usdPrice * reserve1) /(reserve0 * 1000000000000);
           //SafeMath.div(SafeMath.mul(Category[name].usdPrice,reserve1),SafeMath.mul(reserve0,1000000000000));
           //(Category[name].usdPrice * reserve0) /(reserve1);
    }
    IERC20(xanaliaDex).mintAliaForNonCrypto(price,msg.sender);
    uint256 tokenId;
    chainRan.getRandomNumber();
    for(uint256 i =0; i<Category[name].countNFT; i++)
    {
    // uint256 num = SafeMath.div(SafeMath.div(now,block.number),i+1);
    // randomValue = uint256(keccak256(abi.encodePacked(now, block.difficulty, msg.sender, num))) % SafeMath.sub(Category[name].count, 1);
    
    randomValueMain = chainRan.getRandomVal();
    tokenId = IERC20(xanaliaDex).blindBox(seller, Category[name].tokenUris[(uint256(keccak256(abi.encode(randomValueMain, i))) % Category[name].count)], true, msg.sender, ownerId);
    emit BuyBox(msg.sender, ownerId, name,tokenId);
    }
    ALIA.transferFrom(msg.sender, 0x17e42ABa1Aa9aA2D50Ada0e4b3E03837e8e57Cec, price);
  }

  function getBoxDetail(string memory name) public view returns(string memory, string memory, uint256,uint256, uint256){
    return (Category[name].title, Category[name].description, Category[name].price,Category[name].usdPrice,Category[name].countNFT);
  }

 
}