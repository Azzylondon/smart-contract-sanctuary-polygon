// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";

contract TestNFT is ERC721Enumerable, Ownable {
	using SafeMath for uint256;
    
	uint256 public constant MAX_TOKENS = 9999;
	
    uint256 private _reserved; // Saved for the team and for promotional purposes
	uint256 private _price; // This is currently
	uint256 private _startingIndex; // Started or Stopped sale
	
	bool public _saleStarted; // Allow for starting/pausing sale
	string public _baseTokenURI;

    event TransferSent(address _from, address _destAddr, uint _amount);

	constructor() ERC721("Test NFT", "TN2") {
		_reserved = 99;
		_price = 25 * 10 ** 18;
		_saleStarted = false;
		setBaseURI("https://api.coolcatsnft.com/cat/");
	}
    
	modifier whenSaleStarted() {
		require(_saleStarted, "Sale Stopped");
		_;
	}
	
	// Sale Started
	function startSale() public onlyOwner {
		_saleStarted = true;
	}
	
	//Sale Stopped
	function pauseSale() public onlyOwner {
		_saleStarted = false;
	}
	
	function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return _baseTokenURI;
    }
	
	// Make it possible to change the price
    function setPrice(uint256 _newPrice) external onlyOwner {
        _price = _newPrice;
    }

    function getPrice() public view returns (uint256) {
        return _price;
    }
	
	function getReserved() public view returns (uint256) {
        return _reserved;
    }
	
    // Allows for the early reservation of 99 NFT from the creators for promotional use
    function takeReserves(uint256 _count) public onlyOwner {
        uint256 totalSupply = totalSupply();
		
        require(_count <= _reserved, "That would exceed the max reserved.");
		
        for (uint256 i; i < _count; i++) {
            _safeMint(owner(), totalSupply + i);
        }
		
		_reserved -= _count;
    }
	
	function mint(uint256 _count) external payable whenSaleStarted {
		uint256 totalSupply = totalSupply();
		
		require(_count < 11, "Exceeds the max NFT per transaction limit.");
		require(_count + totalSupply <= MAX_TOKENS - _reserved, "A transaction of this size would surpass the NFT limit.");
        require(totalSupply < MAX_TOKENS, "All tokens have already been minted.");
		require(_count * _price <= msg.value, "The value submitted with this transaction is too low.");
		
		for (uint256 i; i < _count; i++) {
            _safeMint(msg.sender, totalSupply + i);
        }
	}
	
	function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
		
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
		
        return tokensId;
    }
	
    function transferERC20(IERC20 token, address to, uint256 amount) public onlyOwner {
        uint256 erc20balance = token.balanceOf(address(this));
        require(amount <= erc20balance, "Balance is low");
        token.transfer(to, amount);
        emit TransferSent(msg.sender, to, amount);
    }
	
	function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}