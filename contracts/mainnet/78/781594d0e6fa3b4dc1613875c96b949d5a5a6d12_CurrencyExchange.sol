/**
 *Submitted for verification at polygonscan.com on 2022-08-16
*/

/**
 *Submitted for verification at polygonscan.com on 2021-08-31
*/

// SPDX-License-Identifier: UNLICENSED
/** 
 * V2 1.8.31
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
    
}

abstract contract Currency { 
  function get_currency(address _currencyAddress) external virtual view returns(uint256 wmatic_rate,uint256 wmatic_token,uint256 usdc_rate,uint256 usdc_token,
  address token0,address token1);
}

contract CurrencyExchange is TransferOwnable {

    address public currencyAddress = address(0x8fbbF04B5E0a7326B9aEd908015Db07DbAA92A38);
    address public tokenAddress = address(0x7415566ADf553e1303858499C90b8bC6b5E70eE8);

    constructor( ) {



    }

    function setCurrencyAddress(address _address) public{

        require(isPartner(msg.sender), 'setAddress: require isPartner(msg.sender)');
        currencyAddress = _address;

    }

    function setTokenAddress(address _address) public{

        require(isPartner(msg.sender), 'setAddress: require isPartner(msg.sender)');
        tokenAddress = _address;

    }

    function USD_exchange(uint256 USD) public view returns (uint256){

        uint256 rate = USD_rate();
        return rate * USD;

    }

    function USD_rate() public view returns (uint256){

        (,,uint256 usdc_rate,,,) 
            = Currency(currencyAddress).get_currency(tokenAddress);       

        uint256 rate = 1e6 / usdc_rate;
        return rate;

    }

}