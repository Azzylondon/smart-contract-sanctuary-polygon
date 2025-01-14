// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC721 {
    function mint(address to, uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokneId) external view returns (address owner);
}

contract pacificrimcontract is Ownable {
    address public contract_address;
    uint256 public amount;
    IERC721 contract_instance;

    uint256 public cappedSupply;
    uint256 public mintedSupply;
    uint256 public transactionCount; // in case of public sale
    uint256 public mintLimit; // in case of pre sale mint and whitelist mint

    // minting durations
    uint256 public presaleTime;
    uint256 public whitelistTime;
    uint256 public publicsaleTime;

    mapping(address => uint256) public mintBalance; // in case of presale mint and whitlist mint

    event withdrawETH(uint256 indexed amount, address indexed to);
    event airdrop(address[] indexed to, uint256[][] indexed tokenId);

    constructor() Ownable() {
        contract_address = 0xb68C2df9c7Cb1c505C61Eb70B523a2c253f1026F;
        contract_instance = IERC721(contract_instance);
        amount = 0 ether;
        cappedSupply = 5000;
        mintedSupply = 0;
        transactionCount = 5;
        mintLimit = 2;

        presaleTime = 1671753600; // presale 23-12-22 00:00:00
        whitelistTime = 1671754200; // whitelist mint 23-12-22 00:15:00
        publicsaleTime = 1671757200; // public sale 23-12-22 01:00:00
    }

    function mint(address to, uint256[] memory tokenId) public payable {
        require(msg.value == tokenId.length * amount, "invalid amount");
        if (
            block.timestamp >= presaleTime && block.timestamp <= whitelistTime
        ) {
            require(
                mintedSupply <= cappedSupply,
                "can't mint capped limit reached"
            );
            require(
                mintBalance[msg.sender] <= mintLimit,
                "minting limit already reached"
            );
            require(
                tokenId.length + mintBalance[msg.sender] <= mintLimit,
                "cannot mint more than the minting limit"
            );
            require(
                mintedSupply + tokenId.length <= cappedSupply,
                "cannot mint capped limit reached"
            );
            _mint(to, tokenId);
        } else if (
            block.timestamp >= whitelistTime &&
            block.timestamp <= publicsaleTime
        ) {
            require(
                mintedSupply <= cappedSupply,
                "can't mint capped limit reached"
            );
            require(
                mintBalance[msg.sender] <= mintLimit,
                "minting limit already reached"
            );
            require(
                tokenId.length + mintBalance[msg.sender] <= mintLimit,
                "cannot mint more than the minting limit"
            );
            require(
                mintedSupply + tokenId.length <= cappedSupply,
                "cannot mint capped limit reached"
            );
            _mint(to, tokenId);
        } else if (block.timestamp >= publicsaleTime) {
            require(
                tokenId.length <= transactionCount,
                "cannot mint more than 5 in each transaction"
            );
            require(
                mintedSupply <= cappedSupply,
                "can't mint capped limit reached"
            );
            require(
                mintedSupply + tokenId.length <= cappedSupply,
                "cannot mint capped limit reached"
            );
            _mint(to, tokenId);
        }
    }

    function airDrop(
        address[] memory to,
        uint256[][] memory tokenId
    ) public onlyOwner {
        require(
            to.length == tokenId.length,
            "length should be same for addresses and tokenIds"
        );

        for (uint256 i = 0; i < to.length; i++) {
            require(
                mintedSupply + tokenId[i].length <= cappedSupply,
                "capped value reached"
            );
            for (uint256 j = 0; j < tokenId[i].length; j++) {
                contract_instance.mint(to[i], tokenId[i][j]);
                mintedSupply++;
            }
        }
    }

    function setTimeDurations(uint256[] memory _time) public onlyOwner {
        require(_time.length == 3, "invalid time slots");
        require(
            _time[0] + 15 minutes == _time[1] && _time[1] + 1 hours == _time[2],
            "invlaid time for the slots"
        );
        presaleTime = _time[0];
        whitelistTime = _time[1];
        publicsaleTime = _time[2];
    }

    function updateCappedValue(uint256 value) public onlyOwner {
        require(value >= mintedSupply, "invlid capped value");
        require(value != 0, "capped value cannot be zero");
        cappedSupply = value;
    }

    function updateTransactionCount(uint256 count) public onlyOwner {
        require(count != 0, "cannot set to zero");
        transactionCount = count;
    }

    function updateMintLimit(uint256 limit) public onlyOwner {
        require(limit != 0, "cannot set to zero");
        mintLimit = limit;
    }

    function updateNFTAddress(address _address) public onlyOwner {
        require(
            _address != address(0),
            "address can't be set to address of zero"
        );
        contract_instance = IERC721(_address);
    }

    function updateAmount(uint256 _amount) public onlyOwner {
        require(_amount != 0, "invalid amount");
        amount = _amount;
    }

    function withdraw(uint256 _amount) public onlyOwner returns (bool) {
        require(address(this).balance >= _amount, "invalid amount");
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        emit withdrawETH(_amount, msg.sender);
        return success;
    }

    function _mint(address _to, uint256[] memory _tokenId) internal {
        for (uint256 i = 0; i < _tokenId.length; i++) {
            contract_instance.mint(_to, _tokenId[i]);
            mintedSupply++;
            mintBalance[msg.sender]++;
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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