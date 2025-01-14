/**
 *Submitted for verification at polygonscan.com on 2022-08-18
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

contract RightsPayer {
    uint256 public payPerPlay;
    uint256 public usdtPerPlay; // 6 decimals
    address payable public owner;
    address payable public receiver;
    IERC20 public usdt;

    mapping(address => bool) public isAdmin;

    event RightsPayed(
        string token,
        uint256 paid,
        uint256 payPerPlay,
        uint256 plays,
        address receiver,
        address triggeredBy
    );

    error WithdrawalFailed();
    error UnsufficientUSDT();
    error PayRightsFailed();
    error NotAnAdmin();

    constructor(
        uint256 _payPerPlay,
        uint256 _usdtPerPlay,
        address usdtContract,
        address payable _receiver,
        address _admin
    ) {
        payPerPlay = _payPerPlay;
        usdtPerPlay = _usdtPerPlay;
        usdt = IERC20(usdtContract);
        receiver = _receiver;
        isAdmin[_admin] = true;
        owner = payable(msg.sender);
        isAdmin[owner] = true;
    }

    modifier onlyAdmin() {
        if (msg.sender != owner && !isAdmin[msg.sender]) revert NotAnAdmin();
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setUsdtContract(address usdtContract) external onlyAdmin {
        usdt = IERC20(usdtContract);
    }

    function setMaticPerPlay(uint256 tokens) external onlyAdmin {
        payPerPlay = tokens;
    }

    /*
     * 1 USDT = 1,000,000 units. USDT to units: / 10**6
     */
    function setUsdtPerPlay(uint256 tokens) external onlyAdmin {
        usdtPerPlay = tokens;
    }

    function setReceiver(address payable _receiver) external onlyAdmin {
        receiver = _receiver;
    }

    // admin, owner management

    function addAdmin(address _admin) external onlyAdmin {
        isAdmin[_admin] = true;
    }

    function deleteAdmin(address _admin) external onlyAdmin {
        delete isAdmin[_admin];
    }

    function setOwner(address payable _owner) external onlyOwner {
        owner = _owner;
    }

    // pay Rights

    function payRightsInMatic(uint256 plays) external onlyAdmin {
        uint256 total = plays * payPerPlay;

        (bool success, ) = receiver.call{value: total}("");
        if (!success) revert PayRightsFailed();
        emit RightsPayed(
            "MATIC",
            total,
            payPerPlay,
            plays,
            receiver,
            msg.sender
        );
    }

    function payRightsInUSDT(uint256 plays) external onlyAdmin {
        uint256 toPay = usdtPerPlay * plays;
        if (toPay > usdtBalance()) revert UnsufficientUSDT();
        // transfers USDT that belong to your contract to the specified address

        bool success = usdt.transfer(receiver, toPay);
        if (!success) revert PayRightsFailed();
        emit RightsPayed(
            "USDT",
            toPay,
            payPerPlay,
            plays,
            receiver,
            msg.sender
        );
    }

    // balance functions

    function usdtBalance() public view returns (uint256) {
        return usdt.balanceOf(address(this));
    }

    function ERC20Balance(address erc_contract) public view returns (uint256) {
        return IERC20(erc_contract).balanceOf(address(this));
    }

    // withdrawal to owner

    function withdrawMatic() external onlyAdmin {
        (bool success, ) = owner.call{value: address(this).balance}("");
        if (!success) revert WithdrawalFailed();
    }

    function withdrawUsdt() external onlyAdmin {
        usdt.transfer(owner, usdtBalance());
    }

    function withdrawErc(address erc_contract) external onlyAdmin {
        IERC20 erc20 = IERC20(erc_contract);
        erc20.transfer(owner, erc20.balanceOf(address(this)));
    }

    function fundContract() external payable {}

    receive() external payable {}
}