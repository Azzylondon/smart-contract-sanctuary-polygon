/**
 *Submitted for verification at polygonscan.com on 2022-06-02
*/

pragma solidity 0.8.6;
pragma experimental ABIEncoderV2;


// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}


/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
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
}


interface ILottery {

    //-------------------------------------------------------------------------
    // VIEW FUNCTIONS
    //-------------------------------------------------------------------------

    function getMaxRange() external view returns(uint32);

    //-------------------------------------------------------------------------
    // STATE MODIFYING FUNCTIONS
    //-------------------------------------------------------------------------

    function numbersDrawn(
        uint256 _lotteryId,
        bytes32 _requestId,
        uint256 _randomNumber
    )
    external;
}


contract Ticket is Initializable {
    // governance
    address public operator;

    // State variables
    address public lotteryContract;

    uint256 internal totalSupply;

    // Storage for ticket information
    struct TicketInfo {
        address owner;
        uint256 number;
        bool claimed;
        uint256 lotteryId;
    }
    // Token ID => Token information
    mapping(uint256 => TicketInfo) internal ticketInfo;
    // lottery ID => tickets count
    mapping(uint256 => uint256) internal ticketsCount;
    // User address => Lottery ID => Ticket IDs
    mapping(address => mapping(uint256 => uint256[])) internal userTickets;

    //  if require 6 numbers match, use value of 2^6
    uint8 public constant sizeOfIndex = 64;
    // lotteryId => hash => count
    // the hash is combined from ticked numbers
    mapping(uint256 => mapping(uint256 => uint256)) internal ticketHashes;

    //-------------------------------------------------------------------------
    // EVENTS
    //-------------------------------------------------------------------------

    event InfoBatchMint(address indexed receiving, uint256 lotteryId, uint256 amountOfTokens, uint256[] tokenIds);

    //-------------------------------------------------------------------------
    // MODIFIERS
    //-------------------------------------------------------------------------

    modifier onlyOperator() {
        require(operator == msg.sender, "caller is not the operator");
        _;
    }

    /**
     * @notice  Restricts minting of new tokens to only the lotto contract.
     */
    modifier onlyLotto() {
        require(msg.sender == lotteryContract, "Only Lotto can mint");
        _;
    }

    function initialize(address _lotto, address _operator) external initializer {
        lotteryContract = _lotto;
        operator = _operator;
    }

    function transferOperator(address newOperator) external onlyOperator {
        require(newOperator != address(0), "Contracts cannot be 0 address");
        operator = newOperator;
    }

    //-------------------------------------------------------------------------
    // VIEW FUNCTIONS
    //-------------------------------------------------------------------------

    function getTotalSupply() external view returns (uint256) {
        return totalSupply;
    }

    /**
     * @param   _ticketID: The unique ID of the ticket
     * @return  uint32[]: The chosen numbers for that ticket
     */
    function getTicketNumbers(uint256 _ticketID) external view returns (uint256) {
        return ticketInfo[_ticketID].number;
    }

    /**
     * @param   _ticketID: The unique ID of the ticket
     * @return  address: Owner of ticket
     */
    function getOwnerOfTicket(uint256 _ticketID) external view returns (address) {
        return ticketInfo[_ticketID].owner;
    }

    function getTicketInfo(uint256 _ticketID) external view returns (TicketInfo memory) {
        return ticketInfo[_ticketID];
    }

    function getTicketClaimStatus(uint256 _ticketID) external view returns (bool) {
        return ticketInfo[_ticketID].claimed;
    }

    function getTicketClaimStatuses(uint256[] calldata ticketIds)
    external
    view
    returns (bool[] memory ticketStatuses)
    {
        ticketStatuses = new bool[](ticketIds.length);
        for (uint256 i = 0; i < ticketIds.length; i++) {
            ticketStatuses[i] = ticketInfo[ticketIds[i]].claimed;
        }
    }

    function getUserTickets(uint256 _lotteryId, address _user) external view returns (uint256[] memory) {
        return userTickets[_user][_lotteryId];
    }

    function getNumberOfTickets(uint256 _lotteryId) external view returns (uint256) {
        return ticketsCount[_lotteryId];
    }

    //-------------------------------------------------------------------------
    // STATE MODIFYING FUNCTIONS
    //-------------------------------------------------------------------------

    /**
     * @param   _to The address being minted to
     * @param   _numberOfTickets The number of NFT's to mint
     * @notice  Only the lotto contract is able to mint tokens.
        // uint8[][] calldata _lottoNumbers
     */
    function batchMint(
        address _to,
        uint256 _lotteryId,
        uint8 _numberOfTickets
    ) external onlyLotto() returns (uint256[] memory) {
        // Storage for the token IDs
        uint256[] memory tokenIds = new uint256[](_numberOfTickets);
        for (uint8 i = 0; i < _numberOfTickets; i++) {
            // Incrementing the tokenId counter
            totalSupply = totalSupply + 1;
            tokenIds[i] = ticketsCount[_lotteryId] + i + 1;
            // Storing the ticket information
            ticketInfo[totalSupply] = TicketInfo(_to, tokenIds[i], false, _lotteryId);
            userTickets[_to][_lotteryId].push(totalSupply);
        }
        ticketsCount[_lotteryId] = ticketsCount[_lotteryId] + _numberOfTickets;
        // Emitting relevant info
        emit InfoBatchMint(_to, _lotteryId, _numberOfTickets, tokenIds);
        // Returns the token IDs of minted tokens
        return tokenIds;
    }

    function claimTicket(uint256 _ticketID, uint256 _lotteryId) external onlyLotto() returns (bool) {
        require(ticketInfo[_ticketID].claimed == false, "Ticket already claimed");
        require(ticketInfo[_ticketID].lotteryId == _lotteryId, "Ticket not for this lottery");
        ticketInfo[_ticketID].claimed = true;
        return true;
    }

    function setLottery(address _lottery) external onlyOperator {
        require(_lottery != address(0), "Invalid address");
        lotteryContract = _lottery;
    }
}