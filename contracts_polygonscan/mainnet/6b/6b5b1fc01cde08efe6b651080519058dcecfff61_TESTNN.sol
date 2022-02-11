/**
 *Submitted for verification at polygonscan.com on 2022-02-08
*/

/**
 Nerd Head Club 2022-01-30
*/

pragma solidity ^0.8.0;
/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract ERC721Holder is IERC721Receiver {

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

abstract contract ERC165 is IERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {

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

interface IAccessControl {

    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// contract-TESTNN

pragma solidity ^0.8.2;


contract TESTNN is ERC20, AccessControl, ERC721Holder {
    bytes32 public constant CONTRACT_ADMIN_ROLE = keccak256("CONTRACT_ADMIN_ROLE");
    address public owner;
    address public collectionAddressC1;
    address public collectionAddressC2;
    address public collectionAddressC3;

    uint256 public numberOfBlocksPerRewardUnitC1;
    uint256 public numberOfBlocksPerRewardUnitC2;
    uint256 public numberOfBlocksPerRewardUnitC3;

    uint256 public coinAmountPerRewardUnitC1;
    uint256 public coinAmountPerRewardUnitC2;
    uint256 public coinAmountPerRewardUnitC3;

    uint256 public amountOfStakersC1;
    uint256 public amountOfStakersC2;
    uint256 public amountOfStakersC3;

    uint256 public tokensStakedC1;
    uint256 public tokensStakedC2;
    uint256 public tokensStakedC3;
    uint256 immutable public contractCreationBlock;

    struct StakeInfoC1 {
        uint256 stakedAtBlock;
        uint256 lastHarvestBlock;
        bool currentlyStaked;
    }
    struct StakeInfoC2 {
        uint256 stakedAtBlock;
        uint256 lastHarvestBlock;
        bool currentlyStaked;
    }
    struct StakeInfoC3 {
        uint256 stakedAtBlock;
        uint256 lastHarvestBlock;
        bool currentlyStaked;
    }
    // / owner => tokenId => StakeInfo
    mapping (address => mapping(uint256 => StakeInfoC1)) public stakeLogC1;
    mapping (address => mapping(uint256 => StakeInfoC2)) public stakeLogC2;
    mapping (address => mapping(uint256 => StakeInfoC3)) public stakeLogC3;
    /// owner => #NFTsStaked
    mapping (address => uint256) public tokensStakedByUserC1;
    mapping (address => uint256) public tokensStakedByUserC2;
    mapping (address => uint256) public tokensStakedByUserC3;
    /// owner => list of all tokenIds that the user has staked
    mapping (address => uint256[]) public stakePortfolioByUserC1;
    mapping (address => uint256[]) public stakePortfolioByUserC2;
    mapping (address => uint256[]) public stakePortfolioByUserC3;
    /// tokenId => indexInStakePortfolio
    mapping(uint256 => uint256) public indexOfTokenIdInStakePortfolioC1;
    mapping(uint256 => uint256) public indexOfTokenIdInStakePortfolioC2;
    mapping(uint256 => uint256) public indexOfTokenIdInStakePortfolioC3;

    event RewardsHarvestedC1 (address owner, uint256 amount);
    event RewardsHarvestedC2 (address owner, uint256 amount);
    event RewardsHarvestedC3 (address owner, uint256 amount);

    event NFTStakedC1 (address owner, uint256 tokenId);
    event NFTStakedC2 (address owner, uint256 tokenId);
    event NFTStakedC3 (address owner, uint256 tokenId);

    event NFTUnstakedC1 (address owner, uint256 tokenId);
    event NFTUnstakedC2 (address owner, uint256 tokenId);
    event NFTUnstakedC3 (address owner, uint256 tokenId);

    constructor() ERC20("TESTNN", "TESTNN")AccessControl(){
        owner = _msgSender();
        collectionAddressC1 = 0x0000000000000000000000000000000000000000;
        collectionAddressC2 = 0x0000000000000000000000000000000000000000;
        collectionAddressC3 = 0x0000000000000000000000000000000000000000;
        _mint(owner, 200000 * 10 ** 18);
        _setupRole(DEFAULT_ADMIN_ROLE, owner);
        _setupRole(CONTRACT_ADMIN_ROLE, owner);
        contractCreationBlock = block.number;
        coinAmountPerRewardUnitC1 = 1 * 10 ** 17;
        coinAmountPerRewardUnitC2 = 1 * 10 ** 17;
        coinAmountPerRewardUnitC3 = 1 * 10 ** 17;
        numberOfBlocksPerRewardUnitC1 = 3600;
        numberOfBlocksPerRewardUnitC2 = 3600;
        numberOfBlocksPerRewardUnitC3 = 3600;
    }

    function stakedNFTSByUserC1(address owner) external view returns (uint256[] memory){
        return stakePortfolioByUserC1[owner];
    }

    function stakedNFTSByUserC2(address owner) external view returns (uint256[] memory){
        return stakePortfolioByUserC2[owner];
    }

    function stakedNFTSByUserC3(address owner) external view returns (uint256[] memory){
        return stakePortfolioByUserC3[owner];
    }

    function burn(uint256 amount) public returns (bool success) {
        super._burn(_msgSender(), amount);
        return true;
    }

    function pendingRewardsC1(address owner, uint256 tokenId) public view returns (uint256){
        StakeInfoC1 memory infoC1 = stakeLogC1[owner][tokenId];

        if(infoC1.lastHarvestBlock < contractCreationBlock || infoC1.currentlyStaked == false) {
            return 0;
        }
        uint256 blocksPassedSinceLastHarvest = block.number - infoC1.lastHarvestBlock;
        if (blocksPassedSinceLastHarvest < numberOfBlocksPerRewardUnitC1 * 2) {
            return 0;
        }
        uint256 rewardAmount = blocksPassedSinceLastHarvest / numberOfBlocksPerRewardUnitC1 - 1;
        return rewardAmount * coinAmountPerRewardUnitC1;
    }
    function pendingRewardsC2(address owner, uint256 tokenId) public view returns (uint256){
        StakeInfoC2 memory infoC2 = stakeLogC2[owner][tokenId];

        if(infoC2.lastHarvestBlock < contractCreationBlock || infoC2.currentlyStaked == false) {
            return 0;
        }
        uint256 blocksPassedSinceLastHarvest = block.number - infoC2.lastHarvestBlock;
        if (blocksPassedSinceLastHarvest < numberOfBlocksPerRewardUnitC2 * 2) {
            return 0;
        }
        uint256 rewardAmount = blocksPassedSinceLastHarvest / numberOfBlocksPerRewardUnitC2 - 1;
        return rewardAmount * coinAmountPerRewardUnitC2;
    }
    function pendingRewardsC3(address owner, uint256 tokenId) public view returns (uint256){
        StakeInfoC3 memory infoC3 = stakeLogC3[owner][tokenId];

        if(infoC3.lastHarvestBlock < contractCreationBlock || infoC3.currentlyStaked == false) {
            return 0;
        }
        uint256 blocksPassedSinceLastHarvest = block.number - infoC3.lastHarvestBlock;
        if (blocksPassedSinceLastHarvest < numberOfBlocksPerRewardUnitC3 * 2) {
            return 0;
        }
        uint256 rewardAmount = blocksPassedSinceLastHarvest / numberOfBlocksPerRewardUnitC1 - 1;
        return rewardAmount * coinAmountPerRewardUnitC1;
    }

    function stakeC1(uint256 tokenId) public {
        IERC721(collectionAddressC1).safeTransferFrom(_msgSender(), address(this), tokenId);
        require(IERC721(collectionAddressC1).ownerOf(tokenId) == address(this),
            "TESTNN: Error while transferring token");
        StakeInfoC1 storage infoC1 = stakeLogC1[_msgSender()][tokenId];
        infoC1.stakedAtBlock = block.number;
        infoC1.lastHarvestBlock = block.number;
        infoC1.currentlyStaked = true;
        if(tokensStakedByUserC1[_msgSender()] == 0){
            amountOfStakersC1 += 1;
        }
        tokensStakedByUserC1[_msgSender()] += 1;
        tokensStakedC1 += 1;
        stakePortfolioByUserC1[_msgSender()].push(tokenId);
        uint256 indexOfNewElementC1 = stakePortfolioByUserC1[_msgSender()].length - 1;
        indexOfTokenIdInStakePortfolioC1[tokenId] = indexOfNewElementC1;
        emit NFTStakedC1(_msgSender(), tokenId);
    }

    function stakeC2(uint256 tokenId) public {
        IERC721(collectionAddressC2).safeTransferFrom(_msgSender(), address(this), tokenId);
        require(IERC721(collectionAddressC2).ownerOf(tokenId) == address(this),
            "TESTNN: Error while transferring token");
        StakeInfoC2 storage infoC2 = stakeLogC2[_msgSender()][tokenId];
        infoC2.stakedAtBlock = block.number;
        infoC2.lastHarvestBlock = block.number;
        infoC2.currentlyStaked = true;
        if(tokensStakedByUserC2[_msgSender()] == 0){
            amountOfStakersC2 += 1;
        }
        tokensStakedByUserC2[_msgSender()] += 1;
        tokensStakedC2 += 1;
        stakePortfolioByUserC2[_msgSender()].push(tokenId);
        uint256 indexOfNewElementC2 = stakePortfolioByUserC2[_msgSender()].length - 1;
        indexOfTokenIdInStakePortfolioC2[tokenId] = indexOfNewElementC2;
        emit NFTStakedC2(_msgSender(), tokenId);
    }

    function stakeC3(uint256 tokenId) public {
        IERC721(collectionAddressC3).safeTransferFrom(_msgSender(), address(this), tokenId);
        require(IERC721(collectionAddressC3).ownerOf(tokenId) == address(this),
            "TESTNN: Error while transferring token");
        StakeInfoC3 storage infoC3 = stakeLogC3[_msgSender()][tokenId];
        infoC3.stakedAtBlock = block.number;
        infoC3.lastHarvestBlock = block.number;
        infoC3.currentlyStaked = true;
        if(tokensStakedByUserC3[_msgSender()] == 0){
            amountOfStakersC3 += 1;
        }
        tokensStakedByUserC3[_msgSender()] += 1;
        tokensStakedC3 += 1;
        stakePortfolioByUserC3[_msgSender()].push(tokenId);
        uint256 indexOfNewElementC3 = stakePortfolioByUserC3[_msgSender()].length - 1;
        indexOfTokenIdInStakePortfolioC3[tokenId] = indexOfNewElementC3;
        emit NFTStakedC3(_msgSender(), tokenId);
    }

    function stakeBatchC1(uint256[] memory tokenIds) external {
        for(uint currentId = 0; currentId < tokenIds.length; currentId++) {
            if(tokenIds[currentId] == 0) {
                continue;
            }
            stakeC1(tokenIds[currentId]);
        }
    }

    function stakeBatchC2(uint256[] memory tokenIds) external {
        for(uint currentId = 0; currentId < tokenIds.length; currentId++) {
            if(tokenIds[currentId] == 0) {
                continue;
            }
            stakeC2(tokenIds[currentId]);
        }
    }

    function stakeBatchC3(uint256[] memory tokenIds) external {
        for(uint currentId = 0; currentId < tokenIds.length; currentId++) {
            if(tokenIds[currentId] == 0) {
                continue;
            }
            stakeC3(tokenIds[currentId]);
        }
    }

    function harvestC1(uint256 tokenId) public {
        StakeInfoC1 storage infoC1 = stakeLogC1[_msgSender()][tokenId];
        uint256 rewardAmountInTESTNN = pendingRewardsC1(_msgSender(), tokenId);
        if(rewardAmountInTESTNN > 0) {
            infoC1.lastHarvestBlock = block.number;
            _mint(_msgSender(), rewardAmountInTESTNN);
            emit RewardsHarvestedC1(_msgSender(), rewardAmountInTESTNN);
        }
    }
    function harvestC2(uint256 tokenId) public {
        StakeInfoC2 storage infoC2 = stakeLogC2[_msgSender()][tokenId];
        uint256 rewardAmountInTESTNN = pendingRewardsC2(_msgSender(), tokenId);
        if(rewardAmountInTESTNN > 0) {
            infoC2.lastHarvestBlock = block.number;
            _mint(_msgSender(), rewardAmountInTESTNN);
            emit RewardsHarvestedC2(_msgSender(), rewardAmountInTESTNN);
        }
    }
    function harvestC3(uint256 tokenId) public {
        StakeInfoC3 storage infoC3 = stakeLogC3[_msgSender()][tokenId];
        uint256 rewardAmountInTESTNN = pendingRewardsC3(_msgSender(), tokenId);
        if(rewardAmountInTESTNN > 0) {
            infoC3.lastHarvestBlock = block.number;
            _mint(_msgSender(), rewardAmountInTESTNN);
            emit RewardsHarvestedC3(_msgSender(), rewardAmountInTESTNN);
        }
    }

    function harvestBatchC1(address user) external payable{
        uint256[] memory tokenIds = stakePortfolioByUserC1[user];

        for(uint currentId = 0; currentId < tokenIds.length; currentId++) {
            if(tokenIds[currentId] == 0) {
                continue;
            }
            harvestC1(tokenIds[currentId]);
        }
    }
    function harvestBatchC2(address user) external payable{
        uint256[] memory tokenIds = stakePortfolioByUserC2[user];

        for(uint currentId = 0; currentId < tokenIds.length; currentId++) {
            if(tokenIds[currentId] == 0) {
                continue;
            }
            harvestC2(tokenIds[currentId]);
        }
    }
    function harvestBatchC3(address user) external payable{
        uint256[] memory tokenIds = stakePortfolioByUserC3[user];

        for(uint currentId = 0; currentId < tokenIds.length; currentId++) {
            if(tokenIds[currentId] == 0) {
                continue;
            }
            harvestC3(tokenIds[currentId]);
        }
    }

    function unstakeC1(uint256 tokenId) public {
        if(pendingRewardsC1(_msgSender(), tokenId) > 0){
            harvestC1(tokenId);
        }
        StakeInfoC1 storage infoC1 = stakeLogC1[_msgSender()][tokenId];
        infoC1.currentlyStaked = false;
        IERC721(collectionAddressC1).safeTransferFrom(address(this), _msgSender(), tokenId);
        require(IERC721(collectionAddressC1).ownerOf(tokenId) == _msgSender(),
            "TESTNN: Error while transferring token");
        if(tokensStakedByUserC1[_msgSender()] == 1){
            amountOfStakersC1 -= 1;
        }
        tokensStakedByUserC1[_msgSender()] -= 1;
        tokensStakedC1 -= 1;
        stakePortfolioByUserC1[_msgSender()][indexOfTokenIdInStakePortfolioC1[tokenId]] = 0;
        emit NFTUnstakedC1(_msgSender(), tokenId);
    }

    function unstakeC2(uint256 tokenId) public {
        if(pendingRewardsC2(_msgSender(), tokenId) > 0){
            harvestC2(tokenId);
        }
        StakeInfoC2 storage infoC2 = stakeLogC2[_msgSender()][tokenId];
        infoC2.currentlyStaked = false;
        IERC721(collectionAddressC2).safeTransferFrom(address(this), _msgSender(), tokenId);
        require(IERC721(collectionAddressC2).ownerOf(tokenId) == _msgSender(),
            "TESTNN: Error while transferring token");
        if(tokensStakedByUserC2[_msgSender()] == 1){
            amountOfStakersC2 -= 1;
        }
        tokensStakedByUserC2[_msgSender()] -= 1;
        tokensStakedC2 -= 1;
        stakePortfolioByUserC2[_msgSender()][indexOfTokenIdInStakePortfolioC2[tokenId]] = 0;
        emit NFTUnstakedC2(_msgSender(), tokenId);
    }

    function unstakeC3(uint256 tokenId) public {
        if(pendingRewardsC3(_msgSender(), tokenId) > 0){
            harvestC3(tokenId);
        }
        StakeInfoC3 storage infoC3 = stakeLogC3[_msgSender()][tokenId];
        infoC3.currentlyStaked = false ;
        IERC721(collectionAddressC3).safeTransferFrom(address(this), _msgSender(), tokenId);
        require(IERC721(collectionAddressC3).ownerOf(tokenId) == _msgSender(),
            "TESTNN: Error while transferring token");
        if(tokensStakedByUserC3[_msgSender()] == 1){
            amountOfStakersC3 -= 1;
        }
        tokensStakedByUserC3[_msgSender()] -= 1;
        tokensStakedC3 -= 1;
        stakePortfolioByUserC3[_msgSender()][indexOfTokenIdInStakePortfolioC3[tokenId]] = 0;
        emit NFTUnstakedC3(_msgSender(), tokenId);
    }

    function unstakeBatchC1(uint256[] memory tokenIds) external {
        for(uint currentId = 0; currentId < tokenIds.length; currentId++) {
            if(tokenIds[currentId] == 0) {
                continue;
            }
            unstakeC1(tokenIds[currentId]);
        }
    }
    function unstakeBatchC2(uint256[] memory tokenIds) external {
        for(uint currentId = 0; currentId < tokenIds.length; currentId++) {
            if(tokenIds[currentId] == 0) {
                continue;
            }
            unstakeC2(tokenIds[currentId]);
        }
    }
    function unstakeBatchC3(uint256[] memory tokenIds) external {
        for(uint currentId = 0; currentId < tokenIds.length; currentId++) {
            if(tokenIds[currentId] == 0) {
                continue;
            }
            unstakeC3(tokenIds[currentId]);
        }
    }

    function setNumberOfBlocksPerRewardUnitC1(uint256 numberOfBlocksC1) external onlyRole(CONTRACT_ADMIN_ROLE){
        numberOfBlocksPerRewardUnitC1 = numberOfBlocksC1;
    }
    function setNumberOfBlocksPerRewardUnitC2(uint256 numberOfBlocksC2) external onlyRole(CONTRACT_ADMIN_ROLE){
        numberOfBlocksPerRewardUnitC2 = numberOfBlocksC2;
    }
    function setNumberOfBlocksPerRewardUnitC3(uint256 numberOfBlocksC3) external onlyRole(CONTRACT_ADMIN_ROLE){
        numberOfBlocksPerRewardUnitC3 = numberOfBlocksC3;
    }

    function setCoinAmountPerRewardUnitC1(uint256 coinAmountC1) external onlyRole(CONTRACT_ADMIN_ROLE){
        coinAmountPerRewardUnitC1 = coinAmountC1;
    }
    function setCoinAmountPerRewardUnitC2(uint256 coinAmountC2) external onlyRole(CONTRACT_ADMIN_ROLE){
        coinAmountPerRewardUnitC2 = coinAmountC2;
    }
    function setCoinAmountPerRewardUnitC3(uint256 coinAmountC3) external onlyRole(CONTRACT_ADMIN_ROLE){
        coinAmountPerRewardUnitC3 = coinAmountC3;
    }

    function setCollectionAddressC1(address newAddressC1) external onlyRole(CONTRACT_ADMIN_ROLE){
        require (newAddressC1 != address(0), "TESTNN: update to zero address not possible");
        collectionAddressC1 = newAddressC1;
    }

    function setCollectionAddressC2(address newAddressC2) external onlyRole(CONTRACT_ADMIN_ROLE){
        require (newAddressC2 != address(0), "TESTNN: update to zero address not possible");
        collectionAddressC2 = newAddressC2;
    }

    function setCollectionAddressC3(address newAddressC3) external onlyRole(CONTRACT_ADMIN_ROLE){
        require (newAddressC3 != address(0), "TESTNN: update to zero address not possible");
        collectionAddressC3 = newAddressC3;
    }
}