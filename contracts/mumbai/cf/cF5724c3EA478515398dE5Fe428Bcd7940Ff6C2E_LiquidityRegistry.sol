// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./interfaces/IPolicyBook.sol";
import "./interfaces/IPolicyBookRegistry.sol";
import "./interfaces/IContractsRegistry.sol";
import "./interfaces/ILiquidityRegistry.sol";
import "./interfaces/IBMICoverStaking.sol";
import "./interfaces/ICapitalPool.sol";

import "./libraries/SafeMath.sol";

import "./abstract/AbstractDependant.sol";

import "./Globals.sol";

contract LiquidityRegistry is ILiquidityRegistry, AbstractDependant {
    using SafeMath for uint256;
    using Math for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    IPolicyBookRegistry public policyBookRegistry;
    IBMICoverStaking public bmiCoverStaking;

    // User address => policy books array
    mapping(address => EnumerableSet.AddressSet) private _policyBooks;

    // User address => policy books array - for withdrawl requests for all pools
    mapping(address => EnumerableSet.AddressSet) private _userWithdrawlRequestsPoolsList;
    // list of all users have withdrawl request
    EnumerableSet.AddressSet internal _withdrawlRequestUsersList;

    address public capitalPool;

    // policy books address => user array - for withdrawl requests for each pool
    mapping(address => EnumerableSet.AddressSet) private _poolWithdrawlRequestsUsersList;

    event PolicyBookAdded(address _userAddr, address _policyBookAddress);
    event PolicyBookRemoved(address _userAddr, address _policyBookAddress);

    modifier onlyEligibleContracts() {
        require(
            msg.sender == address(bmiCoverStaking) ||
                policyBookRegistry.isPolicyBookFacade(msg.sender) ||
                policyBookRegistry.isPolicyBook(msg.sender),
            "LR: Not an eligible contract"
        );
        _;
    }

    modifier onlyCapitalPool() {
        require(msg.sender == capitalPool, "LR: not Capital Pool");
        _;
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        policyBookRegistry = IPolicyBookRegistry(
            _contractsRegistry.getPolicyBookRegistryContract()
        );
        bmiCoverStaking = IBMICoverStaking(_contractsRegistry.getBMICoverStakingContract());
        capitalPool = _contractsRegistry.getCapitalPoolContract();
    }

    function tryToAddPolicyBook(address _userAddr, address _policyBookAddr)
        external
        override
        onlyEligibleContracts
    {
        if (
            IERC20(_policyBookAddr).balanceOf(_userAddr) > 0 ||
            bmiCoverStaking.balanceOf(_userAddr) > 0
        ) {
            _policyBooks[_userAddr].add(_policyBookAddr);

            emit PolicyBookAdded(_userAddr, _policyBookAddr);
        }
    }

    function tryToRemovePolicyBook(address _userAddr, address _policyBookAddr)
        external
        override
        onlyEligibleContracts
    {
        if (
            IERC20(_policyBookAddr).balanceOf(_userAddr) == 0 &&
            bmiCoverStaking.balanceOf(_userAddr) == 0 &&
            IPolicyBook(_policyBookAddr).getWithdrawalStatus(_userAddr) ==
            IPolicyBook.WithdrawalStatus.NONE
        ) {
            _policyBooks[_userAddr].remove(_policyBookAddr);

            // remove user withdraw request from the list
            _userWithdrawlRequestsPoolsList[_userAddr].remove(_policyBookAddr);
            _poolWithdrawlRequestsUsersList[_policyBookAddr].remove(_userAddr);
            if (_userWithdrawlRequestsPoolsList[_userAddr].length() == 0) {
                _withdrawlRequestUsersList.remove(_userAddr);
            }

            emit PolicyBookRemoved(_userAddr, _policyBookAddr);
        }
    }

    function removeExpiredWithdrawalRequest(address _userAddr, address _policyBookAddr)
        external
        override
        onlyEligibleContracts
    {
        // remove user withdraw request from the list
        _userWithdrawlRequestsPoolsList[_userAddr].remove(_policyBookAddr);
        _poolWithdrawlRequestsUsersList[_policyBookAddr].remove(_userAddr);
        if (_userWithdrawlRequestsPoolsList[_userAddr].length() == 0) {
            _withdrawlRequestUsersList.remove(_userAddr);
        }
    }

    function getPolicyBooksArrLength(address _userAddr) external view override returns (uint256) {
        return _policyBooks[_userAddr].length();
    }

    function getPolicyBooksArr(address _userAddr)
        external
        view
        override
        returns (address[] memory _resultArr)
    {
        uint256 _policyBooksArrLength = _policyBooks[_userAddr].length();

        _resultArr = new address[](_policyBooksArrLength);

        for (uint256 i = 0; i < _policyBooksArrLength; i = uncheckedInc(i)) {
            _resultArr[i] = _policyBooks[_userAddr].at(i);
        }
    }

    /// @notice _bmiXRatio comes with 10**18 precision
    function getLiquidityInfos(
        address _userAddr,
        uint256 _offset,
        uint256 _limit
    ) external view override returns (LiquidityInfo[] memory _resultArr) {
        uint256 _to = (_offset.add(_limit)).min(_policyBooks[_userAddr].length()).max(_offset);

        _resultArr = new LiquidityInfo[](_to.uncheckedSub(_offset));

        for (uint256 i = _offset; i < _to; i = uncheckedInc(i)) {
            address _currentPolicyBookAddr = _policyBooks[_userAddr].at(i);

            (uint256 _lockedAmount, , ) =
                IPolicyBook(_currentPolicyBookAddr).withdrawalsInfo(_userAddr);
            uint256 _availableAmount =
                IERC20(address(_currentPolicyBookAddr)).balanceOf(_userAddr);

            uint256 _bmiXRaito = IPolicyBook(_currentPolicyBookAddr).convertBMIXToSTBL(10**18);

            _resultArr[i - _offset] = LiquidityInfo(
                _currentPolicyBookAddr,
                _lockedAmount,
                _availableAmount,
                _bmiXRaito
            );
        }
    }

    function getWithdrawalRequests(
        address _userAddr,
        uint256 _offset,
        uint256 _limit
    )
        external
        view
        override
        returns (uint256 _arrLength, WithdrawalRequestInfo[] memory _resultArr)
    {
        uint256 _to = (_offset.add(_limit)).min(_policyBooks[_userAddr].length()).max(_offset);

        _resultArr = new WithdrawalRequestInfo[](_to.uncheckedSub(_offset));

        for (uint256 i = _offset; i < _to; i = uncheckedInc(i)) {
            IPolicyBook _currentPolicyBook = IPolicyBook(_policyBooks[_userAddr].at(i));

            (uint256 _requestAmount, uint256 _readyToWithdrawDate, ) =
                _currentPolicyBook.withdrawalsInfo(_userAddr);

            IPolicyBook.WithdrawalStatus _currentStatus =
                _currentPolicyBook.getWithdrawalStatus(_userAddr);

            if (_currentStatus == IPolicyBook.WithdrawalStatus.NONE) {
                continue;
            }

            uint256 _endWithdrawDate;

            if (block.timestamp > _readyToWithdrawDate) {
                _endWithdrawDate = _readyToWithdrawDate.tryAdd(
                    _currentPolicyBook.READY_TO_WITHDRAW_PERIOD()
                );
            }

            (uint256 coverTokens, uint256 liquidity) =
                _currentPolicyBook.getNewCoverAndLiquidity();

            _resultArr[_arrLength] = WithdrawalRequestInfo(
                address(_currentPolicyBook),
                _requestAmount,
                _currentPolicyBook.convertBMIXToSTBL(_requestAmount),
                liquidity.trySub(coverTokens),
                _readyToWithdrawDate,
                _endWithdrawDate
            );

            _arrLength = _arrLength.tryAdd(1);
        }
    }

    /// @notice Register's Withdrawals for all pools
    /// @dev Requires withdrawls to be serialized
    /// @param _policyBook address of the policybook with requested withdrawl
    /// @param _user address user addres requesting withdrawl
    function registerWithdrawl(address _policyBook, address _user)
        external
        override
        onlyEligibleContracts
    {
        _userWithdrawlRequestsPoolsList[_user].add(_policyBook);
        _poolWithdrawlRequestsUsersList[_policyBook].add(_user);
        _withdrawlRequestUsersList.add(_user);
    }

    /// @notice fetches the withdrawal data and amounts across all policybooks
    /// @dev use with getWithdrawlRequestUsersListCount()
    /// @param _limit max count of the list
    /// @return _totalWithdrawlAmount uint256 collected withdrawl amount
    function getAllPendingWithdrawalRequestsAmount(uint256 _limit)
        external
        view
        override
        returns (uint256 _totalWithdrawlAmount)
    {
        address _userAddr;

        for (uint256 i = 0; i < _limit; i = uncheckedInc(i)) {
            _userAddr = _withdrawlRequestUsersList.at(i);
            _totalWithdrawlAmount = _totalWithdrawlAmount.add(
                getAllPendingWithdrawalRequestsAmountByUser(
                    _userAddr,
                    _getUserWithdrawlRequestsPoolsListCount(_userAddr)
                )
            );
        }
    }

    /// @dev use with _getUserWithdrawlRequestsPoolsListCount()
    function getAllPendingWithdrawalRequestsAmountByUser(address _userAddr, uint256 _limit)
        internal
        view
        returns (uint256 _totalWithdrawlAmount)
    {
        IPolicyBook.WithdrawalStatus _currentStatus;
        address policyBookAddr;
        for (uint256 j = 0; j < _limit; j = uncheckedInc(j)) {
            policyBookAddr = _userWithdrawlRequestsPoolsList[_userAddr].at(j);
            IPolicyBook _currentPolicyBook = IPolicyBook(policyBookAddr);

            _currentStatus = _currentPolicyBook.getWithdrawalStatus(_userAddr);

            if (
                _currentStatus == IPolicyBook.WithdrawalStatus.NONE ||
                _currentStatus == IPolicyBook.WithdrawalStatus.EXPIRED
            ) {
                continue;
            }

            (uint256 _requestAmount, uint256 _readyToWithdrawDate, ) =
                _currentPolicyBook.withdrawalsInfo(_userAddr);

            ///@dev exclude all ready request until before ready to withdraw date by 24 hrs
            /// + 1 hr (spare time for transaction execution time)
            if (
                block.timestamp >=
                _readyToWithdrawDate.sub(
                    ICapitalPool(capitalPool).rebalanceDuration().tryAdd(60 * 60)
                )
            ) {
                _totalWithdrawlAmount = _totalWithdrawlAmount.add(
                    _currentPolicyBook.convertBMIXToSTBL(_requestAmount)
                );
            }
        }
    }

    /// @notice fetches the withdrawal data and amounts by policybook
    /// @dev use with getPoolWithdrawlRequestsUsersListCount()
    /// @param _policyBook address of the policybook with requested withdrawl
    /// @param _limit max count of the list
    /// @return _totalWithdrawlAmount uint256 collected withdrawl amount
    function getPendingWithdrawalAmountByPolicyBook(address _policyBook, uint256 _limit)
        external
        view
        override
        returns (uint256 _totalWithdrawlAmount)
    {
        IPolicyBook.WithdrawalStatus _currentStatus;

        address _userAddr;
        IPolicyBook _currentPolicyBook = IPolicyBook(_policyBook);

        for (uint256 i = 0; i < _limit; i = uncheckedInc(i)) {
            _userAddr = _poolWithdrawlRequestsUsersList[_policyBook].at(i);

            _currentStatus = _currentPolicyBook.getWithdrawalStatus(_userAddr);

            if (
                _currentStatus == IPolicyBook.WithdrawalStatus.NONE ||
                _currentStatus == IPolicyBook.WithdrawalStatus.EXPIRED
            ) {
                continue;
            }

            (uint256 _requestAmount, , ) = _currentPolicyBook.withdrawalsInfo(_userAddr);

            _totalWithdrawlAmount = _totalWithdrawlAmount.add(
                _currentPolicyBook.convertBMIXToSTBL(_requestAmount)
            );
        }
    }

    function getWithdrawlRequestUsersListCount() external view override returns (uint256) {
        return _withdrawlRequestUsersList.length();
    }

    function _getUserWithdrawlRequestsPoolsListCount(address _user)
        internal
        view
        returns (uint256)
    {
        return _userWithdrawlRequestsPoolsList[_user].length();
    }

    function getPoolWithdrawlRequestsUsersListCount(address _policyBook)
        external
        view
        override
        returns (uint256)
    {
        return _poolWithdrawlRequestsUsersList[_policyBook].length();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.7;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * COPIED FROM https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.5/contracts/utils/math/SafeMath.sol
 * customize try functions to return one value which is uint256 instead of return tupple
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return 0;
            return c;
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            if (b > a) return 0;
            return a - b;
        }
    }

    function uncheckedSub(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {return a - b;}
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return 0;
            uint256 c = a * b;
            if (c / a != b) return 0;
            return c;
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            if (b == 0) return 0;
            return a / b;
        }
    }

    function uncheckedDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {return a / b;}
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            if (b == 0) return 0;
            return a % b;
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IPolicyBookFabric.sol";

interface IPolicyBookRegistry {
    struct PolicyBookStats {
        string symbol;
        address insuredContract;
        IPolicyBookFabric.ContractType contractType;
        uint256 maxCapacity;
        uint256 totalSTBLLiquidity;
        uint256 totalLeveragedLiquidity;
        uint256 stakedSTBL;
        uint256 APY;
        uint256 annualInsuranceCost;
        uint256 bmiXRatio;
        bool whitelisted;
    }

    function policyBooksByInsuredAddress(address insuredContract) external view returns (address);

    function policyBookFacades(address facadeAddress) external view returns (address);

    /// @notice Adds PolicyBook to registry, access: PolicyFabric
    function add(
        address insuredContract,
        IPolicyBookFabric.ContractType contractType,
        address policyBook,
        address facadeAddress
    ) external;

    function whitelist(address policyBookAddress, bool whitelisted) external;

    /// @notice returns required allowances for the policybooks
    function getPoliciesPrices(
        address[] calldata policyBooks,
        uint256[] calldata epochsNumbers,
        uint256[] calldata coversTokens
    ) external view returns (uint256[] memory _durations, uint256[] memory _allowances);

    /// @notice Buys a batch of policies
    function buyPolicyBatch(
        address[] calldata policyBooks,
        uint256[] calldata epochsNumbers,
        uint256[] calldata coversTokens
    ) external;

    /// @notice Checks if provided address is a PolicyBook
    function isPolicyBook(address policyBook) external view returns (bool);

    /// @notice Checks if provided address is a policyBookFacade
    function isPolicyBookFacade(address _facadeAddress) external view returns (bool);

    /// @notice Checks if provided address is a user leverage pool
    function isUserLeveragePool(address policyBookAddress) external view returns (bool);

    /// @notice Returns number of registered PolicyBooks with certain contract type
    function countByType(IPolicyBookFabric.ContractType contractType)
        external
        view
        returns (uint256);

    /// @notice Returns number of registered PolicyBooks, access: ANY
    function count() external view returns (uint256);

    function countByTypeWhitelisted(IPolicyBookFabric.ContractType contractType)
        external
        view
        returns (uint256);

    function countWhitelisted() external view returns (uint256);

    /// @notice Listing registered PolicyBooks with certain contract type, access: ANY
    /// @return _policyBooksArr is array of registered PolicyBook addresses with certain contract type
    function listByType(
        IPolicyBookFabric.ContractType contractType,
        uint256 offset,
        uint256 limit
    ) external view returns (address[] memory _policyBooksArr);

    /// @notice Listing registered PolicyBooks, access: ANY
    /// @return _policyBooksArr is array of registered PolicyBook addresses
    function list(uint256 offset, uint256 limit)
        external
        view
        returns (address[] memory _policyBooksArr);

    function listByTypeWhitelisted(
        IPolicyBookFabric.ContractType contractType,
        uint256 offset,
        uint256 limit
    ) external view returns (address[] memory _policyBooksArr);

    function listWhitelisted(uint256 offset, uint256 limit)
        external
        view
        returns (address[] memory _policyBooksArr);

    /// @notice Listing registered PolicyBooks with stats and certain contract type, access: ANY
    function listWithStatsByType(
        IPolicyBookFabric.ContractType contractType,
        uint256 offset,
        uint256 limit
    ) external view returns (address[] memory _policyBooksArr, PolicyBookStats[] memory _stats);

    /// @notice Listing registered PolicyBooks with stats, access: ANY
    function listWithStats(uint256 offset, uint256 limit)
        external
        view
        returns (address[] memory _policyBooksArr, PolicyBookStats[] memory _stats);

    function listWithStatsByTypeWhitelisted(
        IPolicyBookFabric.ContractType contractType,
        uint256 offset,
        uint256 limit
    ) external view returns (address[] memory _policyBooksArr, PolicyBookStats[] memory _stats);

    function listWithStatsWhitelisted(uint256 offset, uint256 limit)
        external
        view
        returns (address[] memory _policyBooksArr, PolicyBookStats[] memory _stats);

    /// @notice Getting stats from policy books, access: ANY
    /// @param policyBooks is list of PolicyBooks addresses
    function stats(address[] calldata policyBooks)
        external
        view
        returns (PolicyBookStats[] memory _stats);

    /// @notice Return existing Policy Book contract, access: ANY
    /// @param insuredContract is contract address to lookup for created IPolicyBook
    function policyBookFor(address insuredContract) external view returns (address);

    /// @notice Getting stats from policy books, access: ANY
    /// @param insuredContracts is list of insuredContracts in registry
    function statsByInsuredContracts(address[] calldata insuredContracts)
        external
        view
        returns (PolicyBookStats[] memory _stats);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IPolicyBook.sol";
import "./IPolicyBookFabric.sol";
import "./ILeveragePortfolio.sol";

interface IPolicyBookFacade {
    /// @notice Let user to buy policy by supplying stable coin, access: ANY
    /// @param _epochsNumber period policy will cover
    /// @param _coverTokens amount paid for the coverage
    function buyPolicy(uint256 _epochsNumber, uint256 _coverTokens) external;

    /// @param _holder who owns coverage
    /// @param _epochsNumber period policy will cover
    /// @param _coverTokens amount paid for the coverage
    function buyPolicyFor(
        address _holder,
        uint256 _epochsNumber,
        uint256 _coverTokens
    ) external;

    function policyBook() external view returns (IPolicyBook);

    function userLiquidity(address account) external view returns (uint256);

    /// @notice forces an update of RewardsGenerator multiplier
    function forceUpdateBMICoverStakingRewardMultiplier() external;

    /// @notice view function to get precise policy price
    /// @param _epochsNumber is number of epochs to cover
    /// @param _coverTokens is number of tokens to cover
    /// @param _buyer address of the user who buy the policy
    /// @return totalSeconds is number of seconds to cover
    /// @return totalPrice is the policy price which will pay by the buyer
    function getPolicyPrice(
        uint256 _epochsNumber,
        uint256 _coverTokens,
        address _buyer
    )
        external
        view
        returns (
            uint256 totalSeconds,
            uint256 totalPrice,
            uint256 pricePercentage
        );

    function secondsToEndCurrentEpoch() external view returns (uint256);

    /// @notice virtual funds deployed by reinsurance pool
    function VUreinsurnacePool() external view returns (uint256);

    /// @notice leverage funds deployed by reinsurance pool
    function LUreinsurnacePool() external view returns (uint256);

    /// @notice leverage funds deployed by user leverage pool
    function LUuserLeveragePool(address userLeveragePool) external view returns (uint256);

    /// @notice total leverage funds deployed to the pool sum of (VUreinsurnacePool,LUreinsurnacePool,LUuserLeveragePool)
    function totalLeveragedLiquidity() external view returns (uint256);

    function userleveragedMPL() external view returns (uint256);

    function reinsurancePoolMPL() external view returns (uint256);

    function rebalancingThreshold() external view returns (uint256);

    function safePricingModel() external view returns (bool);

    /// @notice policyBookFacade initializer
    /// @param pbProxy polciybook address upgreadable cotnract.
    function __PolicyBookFacade_init(
        address pbProxy,
        address liquidityProvider,
        uint256 initialDeposit
    ) external;

    /// @param _epochsNumber period policy will cover
    /// @param _coverTokens amount paid for the coverage
    /// @param _distributor if it was sold buy a whitelisted distributor, it is distributor address to receive fee (commission)
    function buyPolicyFromDistributor(
        uint256 _epochsNumber,
        uint256 _coverTokens,
        address _distributor
    ) external;

    /// @param _buyer who is buying the coverage
    /// @param _epochsNumber period policy will cover
    /// @param _coverTokens amount paid for the coverage
    /// @param _distributor if it was sold buy a whitelisted distributor, it is distributor address to receive fee (commission)
    function buyPolicyFromDistributorFor(
        address _buyer,
        uint256 _epochsNumber,
        uint256 _coverTokens,
        address _distributor
    ) external;

    /// @notice Let user to add liquidity by supplying stable coin, access: ANY
    /// @param _liquidityAmount is amount of stable coin tokens to secure
    function addLiquidity(uint256 _liquidityAmount) external;

    /// @notice Let user to add liquidity by supplying stable coin, access: ANY
    /// @param _user the one taht add liquidity
    /// @param _liquidityAmount is amount of stable coin tokens to secure
    function addLiquidityFromDistributorFor(address _user, uint256 _liquidityAmount) external;

    function addLiquidityAndStakeFor(
        address _liquidityHolderAddr,
        uint256 _liquidityAmount,
        uint256 _stakeSTBLAmount
    ) external;

    /// @notice Let user to add liquidity by supplying stable coin and stake it,
    /// @dev access: ANY
    function addLiquidityAndStake(uint256 _liquidityAmount, uint256 _stakeSTBLAmount) external;

    /// @notice Let user to withdraw deposited liqiudity, access: ANY
    function withdrawLiquidity() external;

    /// @notice deploy leverage funds (RP lStable, ULP lStable)
    /// @param  deployedAmount uint256 the deployed amount to be added or substracted from the total liquidity
    /// @param leveragePool whether user leverage or reinsurance leverage
    function deployLeverageFundsAfterRebalance(
        uint256 deployedAmount,
        ILeveragePortfolio.LeveragePortfolio leveragePool
    ) external;

    /// @notice deploy virtual funds (RP vStable)
    /// @param  deployedAmount uint256 the deployed amount to be added to the liquidity
    function deployVirtualFundsAfterRebalance(uint256 deployedAmount) external;

    ///@dev in case ur changed of the pools by commit a claim or policy expired
    function reevaluateProvidedLeverageStable() external;

    /// @notice set the MPL for the user leverage and the reinsurance leverage
    /// @param _userLeverageMPL uint256 value of the user leverage MPL
    /// @param _reinsuranceLeverageMPL uint256  value of the reinsurance leverage MPL
    function setMPLs(uint256 _userLeverageMPL, uint256 _reinsuranceLeverageMPL) external;

    /// @notice sets the rebalancing threshold value
    /// @param _newRebalancingThreshold uint256 rebalancing threshhold value
    function setRebalancingThreshold(uint256 _newRebalancingThreshold) external;

    /// @notice sets the rebalancing threshold value
    /// @param _safePricingModel bool is pricing model safe (true) or not (false)
    function setSafePricingModel(bool _safePricingModel) external;

    /// @notice returns how many BMI tokens needs to approve in order to submit a claim
    function getClaimApprovalAmount(address user, uint256 bmiPriceInUSDT)
        external
        view
        returns (uint256);

    /// @notice upserts a withdraw request
    /// @dev prevents adding a request if an already pending or ready request is open.
    /// @param _tokensToWithdraw uint256 amount of tokens to withdraw
    function requestWithdrawal(uint256 _tokensToWithdraw) external;

    function listUserLeveragePools(uint256 offset, uint256 limit)
        external
        view
        returns (address[] memory _userLeveragePools);

    function countUserLeveragePools() external view returns (uint256);

    /// @notice Getting info, access: ANY
    /// @return _symbol is the symbol of PolicyBook (bmiXCover)
    /// @return _insuredContract is an addres of insured contract
    /// @return _contractType is a type of insured contract
    /// @return _whitelisted is a state of whitelisting
    function info()
        external
        view
        returns (
            string memory _symbol,
            address _insuredContract,
            IPolicyBookFabric.ContractType _contractType,
            bool _whitelisted
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IPolicyBookFabric {
    enum ContractType {CONTRACT, STABLECOIN, SERVICE, EXCHANGE, VARIOUS}

    /// @notice Create new Policy Book contract, access: ANY
    /// @param _contract is Contract to create policy book for
    /// @param _contractType is Contract to create policy book for
    /// @param _description is bmiXCover token desription for this policy book
    /// @param _projectSymbol replaces x in bmiXCover token symbol
    /// @param _initialDeposit is an amount user deposits on creation (addLiquidity())
    /// @return _policyBook is address of created contract
    function create(
        address _contract,
        ContractType _contractType,
        string calldata _description,
        string calldata _projectSymbol,
        uint256 _initialDeposit,
        address _shieldMiningToken
    ) external returns (address);

    function createLeveragePools(
        address _insuranceContract,
        ContractType _contractType,
        string calldata _description,
        string calldata _projectSymbol
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IPolicyBookFabric.sol";
import "./IClaimingRegistry.sol";
import "./IPolicyBookFacade.sol";

interface IPolicyBook {
    enum WithdrawalStatus {NONE, PENDING, READY, EXPIRED}

    struct PolicyHolder {
        uint256 coverTokens;
        uint256 startEpochNumber;
        uint256 endEpochNumber;
        uint256 paid;
        uint256 reinsurancePrice;
    }

    struct WithdrawalInfo {
        uint256 withdrawalAmount;
        uint256 readyToWithdrawDate;
        bool withdrawalAllowed;
    }

    struct BuyPolicyParameters {
        address buyer;
        address holder;
        uint256 epochsNumber;
        uint256 coverTokens;
        uint256 distributorFee;
        address distributor;
    }

    function policyHolders(address _holder)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function policyBookFacade() external view returns (IPolicyBookFacade);

    function setPolicyBookFacade(address _policyBookFacade) external;

    function EPOCH_DURATION() external view returns (uint256);

    function stblDecimals() external view returns (uint256);

    function READY_TO_WITHDRAW_PERIOD() external view returns (uint256);

    function whitelisted() external view returns (bool);

    function epochStartTime() external view returns (uint256);

    // @TODO: should we let DAO to change contract address?
    /// @notice Returns address of contract this PolicyBook covers, access: ANY
    /// @return _contract is address of covered contract
    function insuranceContractAddress() external view returns (address _contract);

    /// @notice Returns type of contract this PolicyBook covers, access: ANY
    /// @return _type is type of contract
    function contractType() external view returns (IPolicyBookFabric.ContractType _type);

    function totalLiquidity() external view returns (uint256);

    function totalCoverTokens() external view returns (uint256);

    // /// @notice return MPL for user leverage pool
    // function userleveragedMPL() external view returns (uint256);

    // /// @notice return MPL for reinsurance pool
    // function reinsurancePoolMPL() external view returns (uint256);

    // function bmiRewardMultiplier() external view returns (uint256);

    function withdrawalsInfo(address _userAddr)
        external
        view
        returns (
            uint256 _withdrawalAmount,
            uint256 _readyToWithdrawDate,
            bool _withdrawalAllowed
        );

    function __PolicyBook_init(
        address _insuranceContract,
        IPolicyBookFabric.ContractType _contractType,
        string calldata _description,
        string calldata _projectSymbol
    ) external;

    function whitelist(bool _whitelisted) external;

    function getEpoch(uint256 time) external view returns (uint256);

    /// @notice get STBL equivalent
    function convertBMIXToSTBL(uint256 _amount) external view returns (uint256);

    /// @notice get BMIX equivalent
    function convertSTBLToBMIX(uint256 _amount) external view returns (uint256);

    /// @notice submits new claim of the policy book
    function submitClaimAndInitializeVoting(string calldata evidenceURI, uint256 bmiPriceInUSDT)
        external;

    /// @notice submits new appeal claim of the policy book
    function submitAppealAndInitializeVoting(string calldata evidenceURI, uint256 bmiPriceInUSDT)
        external;

    /// @notice updates info on claim when not accepted
    function commitClaim(
        address claimer,
        uint256 claimEndTime,
        IClaimingRegistry.ClaimStatus status
    ) external;

    /// @notice withdraw the claim after requested
    function commitWithdrawnClaim(address claimer) external;

    /// @notice function to get precise current cover and liquidity
    function getNewCoverAndLiquidity()
        external
        view
        returns (uint256 newTotalCoverTokens, uint256 newTotalLiquidity);

    /// @notice Let user to buy policy by supplying stable coin, access: ANY
    /// @param _buyer who is transferring funds
    /// @param _holder who owns coverage
    /// @param _epochsNumber period policy will cover
    /// @param _coverTokens amount paid for the coverage
    /// @param _distributorFee distributor fee (commission). It can't be greater than PROTOCOL_PERCENTAGE
    /// @param _distributor if it was sold buy a whitelisted distributor, it is distributor address to receive fee (commission)
    function buyPolicy(
        address _buyer,
        address _holder,
        uint256 _epochsNumber,
        uint256 _coverTokens,
        uint256 _distributorFee,
        address _distributor
    ) external returns (uint256, uint256);

    /// @notice end active policy from ClaimingRegistry in case of a new bought policy
    function endActivePolicy(address _holder) external;

    function updateEpochsInfo(bool _rebalance) external;

    /// @notice Let eligible contracts add liqiudity for another user by supplying stable coin
    /// @param _liquidityHolderAddr is address of address to assign cover
    /// @param _liqudityAmount is amount of stable coin tokens to secure
    function addLiquidityFor(address _liquidityHolderAddr, uint256 _liqudityAmount) external;

    /// @notice Let user to add liquidity by supplying stable coin, access: ANY
    /// @param _liquidityBuyerAddr address the one that transfer funds
    /// @param _liquidityHolderAddr address the one that owns liquidity
    /// @param _liquidityAmount uint256 amount to be added on behalf the sender
    /// @param _stakeSTBLAmount uint256 the staked amount if add liq and stake
    function addLiquidity(
        address _liquidityBuyerAddr,
        address _liquidityHolderAddr,
        uint256 _liquidityAmount,
        uint256 _stakeSTBLAmount
    ) external returns (uint256);

    function getAvailableBMIXWithdrawableAmount(address _userAddr) external view returns (uint256);

    function getWithdrawalStatus(address _userAddr) external view returns (WithdrawalStatus);

    function requestWithdrawal(uint256 _tokensToWithdraw, address _user) external;

    // function requestWithdrawalWithPermit(
    //     uint256 _tokensToWithdraw,
    //     uint8 _v,
    //     bytes32 _r,
    //     bytes32 _s
    // ) external;

    function unlockTokens() external;

    /// @notice Let user to withdraw deposited liqiudity, access: ANY
    function withdrawLiquidity(address sender)
        external
        returns (uint256 _tokensToWithdraw, uint256 _stblTokensToWithdraw);

    ///@notice for doing defi hard rebalancing, access: policyBookFacade
    function updateLiquidity(uint256 _newLiquidity) external;

    function getAPY() external view returns (uint256);

    /// @notice Getting user stats, access: ANY
    function userStats(address _user) external view returns (PolicyHolder memory);

    /// @notice Getting number stats, access: ANY
    /// @return _maxCapacities is a max token amount that a user can buy
    /// @return _buyPolicyCapacity new capacity which is a max token amount that a user can buy including withdraw amount
    /// @return _totalSTBLLiquidity is PolicyBook's liquidity
    /// @return _totalLeveragedLiquidity is PolicyBook's leveraged liquidity
    /// @return _stakedSTBL is how much stable coin are staked on this PolicyBook
    /// @return _annualProfitYields is its APY
    /// @return _annualInsuranceCost is percentage of cover tokens that is required to be paid for 1 year of insurance
    function numberStats()
        external
        view
        returns (
            uint256 _maxCapacities,
            uint256 _buyPolicyCapacity,
            uint256 _totalSTBLLiquidity,
            uint256 _totalLeveragedLiquidity,
            uint256 _stakedSTBL,
            uint256 _annualProfitYields,
            uint256 _annualInsuranceCost,
            uint256 _bmiXRatio
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ILiquidityRegistry {
    struct LiquidityInfo {
        address policyBookAddr;
        uint256 lockedAmount;
        uint256 availableAmount;
        uint256 bmiXRatio; // multiply availableAmount by this num to get stable coin
    }

    struct WithdrawalRequestInfo {
        address policyBookAddr;
        uint256 requestAmount;
        uint256 requestSTBLAmount;
        uint256 availableLiquidity;
        uint256 readyToWithdrawDate;
        uint256 endWithdrawDate;
    }

    struct WithdrawalSetInfo {
        address policyBookAddr;
        uint256 requestAmount;
        uint256 requestSTBLAmount;
        uint256 availableSTBLAmount;
    }

    function tryToAddPolicyBook(address _userAddr, address _policyBookAddr) external;

    function tryToRemovePolicyBook(address _userAddr, address _policyBookAddr) external;

    function removeExpiredWithdrawalRequest(address _userAddr, address _policyBookAddr) external;

    function getPolicyBooksArrLength(address _userAddr) external view returns (uint256);

    function getPolicyBooksArr(address _userAddr)
        external
        view
        returns (address[] memory _resultArr);

    function getLiquidityInfos(
        address _userAddr,
        uint256 _offset,
        uint256 _limit
    ) external view returns (LiquidityInfo[] memory _resultArr);

    function getWithdrawalRequests(
        address _userAddr,
        uint256 _offset,
        uint256 _limit
    ) external view returns (uint256 _arrLength, WithdrawalRequestInfo[] memory _resultArr);

    function registerWithdrawl(address _policyBook, address _users) external;

    function getAllPendingWithdrawalRequestsAmount(uint256 _limit)
        external
        view
        returns (uint256 _totalWithdrawlAmount);

    function getPendingWithdrawalAmountByPolicyBook(address _policyBook, uint256 _limit)
        external
        view
        returns (uint256 _totalWithdrawlAmount);

    function getWithdrawlRequestUsersListCount() external view returns (uint256);

    function getPoolWithdrawlRequestsUsersListCount(address _policyBook)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ILeveragePortfolio {
    enum LeveragePortfolio {USERLEVERAGEPOOL, REINSURANCEPOOL}
    struct LevFundsFactors {
        uint256 netMPL;
        uint256 netMPLn;
        address policyBookAddr;
    }

    function targetUR() external view returns (uint256);

    function d_ProtocolConstant() external view returns (uint256);

    function a_ProtocolConstant() external view returns (uint256);

    function max_ProtocolConstant() external view returns (uint256);

    /// @notice deploy lStable from user leverage pool or reinsurance pool using 2 formulas: access by policybook.
    /// @param leveragePoolType LeveragePortfolio is determine the pool which call the function
    function deployLeverageStableToCoveragePools(LeveragePortfolio leveragePoolType)
        external
        returns (uint256);

    /// @notice deploy the vStable from RP in v2 and for next versions it will be from RP and LP : access by policybook.
    function deployVirtualStableToCoveragePools() external returns (uint256);

    /// @notice set the threshold % for re-evaluation of the lStable provided across all Coverage pools : access by owner
    /// @param threshold uint256 is the reevaluatation threshold
    function setRebalancingThreshold(uint256 threshold) external;

    /// @notice set the protocol constant : access by owner
    /// @param _targetUR uint256 target utitlization ration
    /// @param _d_ProtocolConstant uint256 D protocol constant
    /// @param  _a1_ProtocolConstant uint256 A1 protocol constant
    /// @param _max_ProtocolConstant uint256 the max % included
    function setProtocolConstant(
        uint256 _targetUR,
        uint256 _d_ProtocolConstant,
        uint256 _a1_ProtocolConstant,
        uint256 _max_ProtocolConstant
    ) external;

    /// @notice calc M factor by formual M = min( abs((1/ (Tur-UR))*d) /a, max)
    /// @param poolUR uint256 utitilization ratio for a coverage pool
    /// @return uint256 M facotr
    //function calcM(uint256 poolUR) external returns (uint256);

    /// @return uint256 the amount of vStable stored in the pool
    function totalLiquidity() external view returns (uint256);

    /// @notice add the portion of 80% of premium to user leverage pool where the leverage provide lstable : access policybook
    /// add the 20% of premium + portion of 80% of premium where reisnurance pool participate in coverage pools (vStable)  : access policybook
    /// @param epochsNumber uint256 the number of epochs which the policy holder will pay a premium for
    /// @param  premiumAmount uint256 the premium amount which is a portion of 80% of the premium
    function addPremium(uint256 epochsNumber, uint256 premiumAmount) external;

    /// @notice Used to get a list of coverage pools which get leveraged , use with count()
    /// @return _coveragePools a list containing policybook addresses
    function listleveragedCoveragePools(uint256 offset, uint256 limit)
        external
        view
        returns (address[] memory _coveragePools);

    /// @notice get count of coverage pools which get leveraged
    function countleveragedCoveragePools() external view returns (uint256);

    function updateLiquidity(uint256 _lostLiquidity) external;

    function forceUpdateBMICoverStakingRewardMultiplier() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IContractsRegistry {
    function getAMMBMIToETHPairContract() external view returns (address);

    function getAMMBMIToUSDTPairContract() external view returns (address);

    function getSushiSwapMasterChefV2Contract() external view returns (address);

    function getUSDTContract() external view returns (address);

    function getBMIContract() external view returns (address);

    function getPolicyBookRegistryContract() external view returns (address);

    function getPolicyBookFabricContract() external view returns (address);

    function getBMICoverStakingContract() external view returns (address);

    function getBMICoverStakingViewContract() external view returns (address);

    function getBMITreasury() external view returns (address);

    function getRewardsGeneratorContract() external view returns (address);

    function getLiquidityBridgeContract() external view returns (address);

    function getClaimingRegistryContract() external view returns (address);

    function getPolicyRegistryContract() external view returns (address);

    function getLiquidityRegistryContract() external view returns (address);

    function getClaimVotingContract() external view returns (address);

    function getReinsurancePoolContract() external view returns (address);

    function getLeveragePortfolioViewContract() external view returns (address);

    function getCapitalPoolContract() external view returns (address);

    function getPolicyBookAdminContract() external view returns (address);

    function getPolicyQuoteContract() external view returns (address);

    function getBMIStakingContract() external view returns (address);

    function getSTKBMIContract() external view returns (address);

    function getStkBMIStakingContract() external view returns (address);

    function getLiquidityMiningStakingETHContract() external view returns (address);

    function getLiquidityMiningStakingUSDTContract() external view returns (address);

    function getReputationSystemContract() external view returns (address);

    function getDefiProtocol1Contract() external view returns (address);

    function getAaveLendPoolAddressProvdierContract() external view returns (address);

    function getAaveATokenContract() external view returns (address);

    function getDefiProtocol2Contract() external view returns (address);

    function getCompoundCTokenContract() external view returns (address);

    function getCompoundComptrollerContract() external view returns (address);

    function getDefiProtocol3Contract() external view returns (address);

    function getYearnVaultContract() external view returns (address);

    function getYieldGeneratorContract() external view returns (address);

    function getShieldMiningContract() external view returns (address);

    function getDemandBookContract() external view returns (address);

    function getDemandBookLiquidityContract() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IPolicyBookFabric.sol";

interface IClaimingRegistry {
    enum ClaimStatus {
        CAN_CLAIM,
        UNCLAIMABLE,
        PENDING,
        AWAITING_CALCULATION,
        REJECTED_CAN_APPEAL,
        REJECTED,
        ACCEPTED,
        EXPIRED
    }

    struct ClaimInfo {
        address claimer;
        address policyBookAddress;
        string evidenceURI;
        uint256 dateSubmitted;
        uint256 dateEnded;
        bool appeal;
        ClaimStatus status;
        uint256 claimAmount;
        uint256 claimRefund;
    }

    struct ClaimWithdrawalInfo {
        uint256 readyToWithdrawDate;
        bool committed;
    }

    struct RewardWithdrawalInfo {
        uint256 rewardAmount;
        uint256 readyToWithdrawDate;
    }

    enum WithdrawalStatus {NONE, PENDING, READY, EXPIRED}

    function claimWithdrawalInfo(uint256 index)
        external
        view
        returns (uint256 readyToWithdrawDate, bool committed);

    function rewardWithdrawalInfo(address voter)
        external
        view
        returns (uint256 rewardAmount, uint256 readyToWithdrawDate);

    /// @notice returns anonymous voting duration
    function anonymousVotingDuration(uint256 index) external view returns (uint256);

    /// @notice returns the whole voting duration
    function votingDuration(uint256 index) external view returns (uint256);

    /// @notice returns the whole voting duration + view verdict duration
    function validityDuration(uint256 index) external view returns (uint256);

    /// @notice returns how many time should pass before anyone could calculate a claim result
    function anyoneCanCalculateClaimResultAfter(uint256 index) external view returns (uint256);

    function canCalculateClaim(uint256 index, address calculator) external view returns (bool);

    /// @notice check if a user can buy new policy of specified PolicyBook and end the active one if there is
    function canBuyNewPolicy(address buyer, address policyBookAddress) external;

    /// @notice returns withdrawal status of requested claim
    function getClaimWithdrawalStatus(uint256 index) external view returns (WithdrawalStatus);

    /// @notice returns withdrawal status of requested reward
    function getRewardWithdrawalStatus(address voter) external view returns (WithdrawalStatus);

    /// @notice returns true if there is ongoing claiming procedure
    function hasProcedureOngoing(address poolAddress) external view returns (bool);

    /// @notice submits new PolicyBook claim for the user
    function submitClaim(
        address user,
        address policyBookAddress,
        string calldata evidenceURI,
        uint256 cover,
        bool appeal
    ) external returns (uint256);

    /// @notice returns true if the claim with this index exists
    function claimExists(uint256 index) external view returns (bool);

    /// @notice returns claim submition time
    function claimSubmittedTime(uint256 index) external view returns (uint256);

    /// @notice returns claim end time or zero in case it is pending
    function claimEndTime(uint256 index) external view returns (uint256);

    /// @notice returns true if the claim is anonymously votable
    function isClaimAnonymouslyVotable(uint256 index) external view returns (bool);

    /// @notice returns true if the claim is exposably votable
    function isClaimExposablyVotable(uint256 index) external view returns (bool);

    /// @notice returns true if claim is anonymously votable or exposably votable
    function isClaimVotable(uint256 index) external view returns (bool);

    /// @notice returns true if a claim can be calculated by anyone
    function canClaimBeCalculatedByAnyone(uint256 index) external view returns (bool);

    /// @notice returns true if this claim is pending or awaiting
    function isClaimPending(uint256 index) external view returns (bool);

    /// @notice returns how many claims the holder has
    function countPolicyClaimerClaims(address user) external view returns (uint256);

    /// @notice returns how many pending claims are there
    function countPendingClaims() external view returns (uint256);

    /// @notice returns how many claims are there
    function countClaims() external view returns (uint256);

    /// @notice returns a claim index of it's claimer and an ordinal number
    function claimOfOwnerIndexAt(address claimer, uint256 orderIndex)
        external
        view
        returns (uint256);

    /// @notice returns pending claim index by its ordinal index
    function pendingClaimIndexAt(uint256 orderIndex) external view returns (uint256);

    /// @notice returns claim index by its ordinal index
    function claimIndexAt(uint256 orderIndex) external view returns (uint256);

    /// @notice returns current active claim index by policybook and claimer
    function claimIndex(address claimer, address policyBookAddress)
        external
        view
        returns (uint256);

    /// @notice returns true if the claim is appealed
    function isClaimAppeal(uint256 index) external view returns (bool);

    /// @notice returns current status of a claim
    function policyStatus(address claimer, address policyBookAddress)
        external
        view
        returns (ClaimStatus);

    /// @notice returns current status of a claim
    function claimStatus(uint256 index) external view returns (ClaimStatus);

    /// @notice returns the claim owner (claimer)
    function claimOwner(uint256 index) external view returns (address);

    /// @notice returns the claim PolicyBook
    function claimPolicyBook(uint256 index) external view returns (address);

    /// @notice returns claim info by its index
    function claimInfo(uint256 index) external view returns (ClaimInfo memory _claimInfo);

    function getAllPendingClaimsAmount(uint256 _limit)
        external
        view
        returns (uint256 _totalClaimsAmount);

    function getAllPendingRewardsAmount(uint256 _limit)
        external
        view
        returns (uint256 _totalRewardsAmount);

    function getClaimableAmounts(uint256[] memory _claimIndexes) external view returns (uint256);

    function getBMIRewardForCalculation(uint256 index) external view returns (uint256);

    /// @notice marks the user's claim as Accepted
    function acceptClaim(uint256 index, uint256 amount) external;

    /// @notice marks the user's claim as Rejected
    function rejectClaim(uint256 index) external;

    /// @notice marks the user's claim as Expired
    function expireClaim(uint256 index) external;

    /// @notice Update Image Uri in case it contains material that is ilegal
    ///         or offensive.
    /// @dev Only the owner of the PolicyBookAdmin can erase/update evidenceUri.
    /// @param claim_Index Claim Index that is going to be updated
    /// @param _newEvidenceURI New evidence uri. It can be blank.
    function updateImageUriOfClaim(uint256 claim_Index, string calldata _newEvidenceURI) external;

    function requestClaimWithdrawal(uint256 index) external;

    function requestRewardWithdrawal(address voter, uint256 rewardAmount) external;

    function getWithdrawClaimRequestIndexListCount() external view returns (uint256);

    function getWithdrawRewardRequestVoterListCount() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IPolicyBookFacade.sol";

interface ICapitalPool {
    struct PremiumFactors {
        uint256 epochsNumber;
        uint256 premiumPrice;
        uint256 vStblDeployedByRP;
        uint256 vStblOfCP;
        uint256 poolUtilizationRation;
        uint256 premiumPerDeployment;
        uint256 userLeveragePoolsCount;
        IPolicyBookFacade policyBookFacade;
    }

    enum PoolType {COVERAGE, LEVERAGE, REINSURANCE}

    function virtualUsdtAccumulatedBalance() external view returns (uint256);

    function liquidityCushionBalance() external view returns (uint256);

    /// @notice distributes the policybook premiums into pools (CP, ULP , RP)
    /// @dev distributes the balances acording to the established percentages
    /// @param _stblAmount amount hardSTBL ingressed into the system
    /// @param _epochsNumber uint256 the number of epochs which the policy holder will pay a premium for
    /// @param _protocolFee uint256 the amount of protocol fee earned by premium
    function addPolicyHoldersHardSTBL(
        uint256 _stblAmount,
        uint256 _epochsNumber,
        uint256 _protocolFee
    ) external returns (uint256);

    /// @notice distributes the demands premiums into pools (RP)
    /// @dev distributes the balances acording to the established percentages (20%)
    /// @param _stblReinsurancePoolAmount amount hardSTBL ingressed into the system
    function addDemandHoldersHardSTBL(uint256 _stblReinsurancePoolAmount) external;

    /// @notice distributes the hardSTBL from the coverage providers
    /// @dev emits PoolBalancedUpdated event
    /// @param _stblAmount amount hardSTBL ingressed into the system
    function addCoverageProvidersHardSTBL(uint256 _stblAmount) external;

    /// @notice distributes the hardSTBL from the leverage providers
    /// @dev emits PoolBalancedUpdated event
    /// @param _stblAmount amount hardSTBL ingressed into the system
    function addLeverageProvidersHardSTBL(uint256 _stblAmount) external;

    /// @notice distributes the hardSTBL from the demand liquidity providers
    /// @dev emits PoolBalancedUpdated event
    /// @param _stblAmount amount hardSTBL ingressed into the system
    function addDemandProvidersHardSTBL(uint256 demandIndex, uint256 _stblAmount) external;

    /// @notice distributes the hardSTBL from the reinsurance pool
    /// @dev emits PoolBalancedUpdated event
    /// @param _stblAmount amount hardSTBL ingressed into the system
    function addReinsurancePoolHardSTBL(uint256 _stblAmount) external;

    /// @notice rebalances pools acording to v2 specification and dao enforced policies
    /// @dev  emits PoolBalancesUpdated
    function rebalanceLiquidityCushion() external;

    /// @notice Fullfils policybook claims by transfering the balance to claimer
    /// @param _claimer, address of the claimer recieving the withdraw
    /// @param _claimAmount uint256 amount to be withdrawn
    /// @param _policyBookAddress address of the policybook
    function fundClaim(
        address _claimer,
        uint256 _claimAmount,
        address _policyBookAddress
    ) external returns (uint256);

    /// @notice Fullfils policybook claims by transfering the balance to claimer
    /// @param _voter, address of the voter recieving the withdraw
    /// @param _rewardAmount uint256 amount to of the reward
    function fundReward(address _voter, uint256 _rewardAmount) external returns (uint256);

    /// @notice Withdraws liquidity from a specific policbybook to the user
    /// @param _sender, address of the user beneficiary of the withdraw
    /// @param _stblAmount uint256 amount to be withdrawn
    /// @param _isLeveragePool bool wether the pool is ULP or CP(policybook)
    function withdrawLiquidity(
        address _sender,
        uint256 _stblAmount,
        bool _isLeveragePool
    ) external returns (uint256);

    /// @notice Withdraws liquidity from a specific policbybook to the user
    /// @param demandIndex, index of demand
    /// @param _sender, address of the user beneficiary of the withdraw
    /// @param _stblAmount uint256 amount to be withdrawn
    function withdrawDemandLiquidity(
        uint256 demandIndex,
        address _sender,
        uint256 _stblAmount
    ) external returns (uint256 _actualAmount);

    function rebalanceDuration() external view returns (uint256);

    function getWithdrawPeriod() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IBMICoverStaking {
    struct StakingInfo {
        address policyBookAddress;
        uint256 stakedBMIXAmount;
    }

    struct PolicyBookInfo {
        uint256 totalStakedSTBL;
        uint256 rewardPerBlock;
        uint256 stakingAPY;
        uint256 liquidityAPY;
    }

    struct UserInfo {
        uint256 totalStakedBMIX;
        uint256 totalStakedSTBL;
        uint256 totalBmiReward;
    }

    struct NFTsInfo {
        uint256 nftIndex;
        string uri;
        uint256 stakedBMIXAmount;
        uint256 stakedSTBLAmount;
        uint256 reward;
    }

    function aggregateNFTs(address policyBookAddress, uint256[] calldata tokenIds) external;

    function stakeBMIX(uint256 amount, address policyBookAddress) external;

    function stakeBMIXWithPermit(
        uint256 bmiXAmount,
        address policyBookAddress,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function stakeBMIXFrom(address user, uint256 amount) external;

    function stakeBMIXFromWithPermit(
        address user,
        uint256 bmiXAmount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    // mappings

    function _stakersPool(uint256 index)
        external
        view
        returns (address policyBookAddress, uint256 stakedBMIXAmount);

    // function getPolicyBookAPY(address policyBookAddress) external view returns (uint256);

    function restakeBMIProfit(uint256 tokenId) external;

    function restakeStakerBMIProfit(address policyBookAddress) external;

    function withdrawBMIProfit(uint256 tokenID) external;

    function withdrawStakerBMIProfit(address policyBookAddress) external;

    function withdrawFundsWithProfit(uint256 tokenID) external;

    function withdrawStakerFundsWithProfit(address policyBookAddress) external;

    function getSlashedBMIProfit(uint256 tokenId) external view returns (uint256);

    function getBMIProfit(uint256 tokenId) external view returns (uint256);

    function getSlashedStakerBMIProfit(
        address staker,
        address policyBookAddress,
        uint256 offset,
        uint256 limit
    ) external view returns (uint256 totalProfit);

    function getStakerBMIProfit(
        address staker,
        address policyBookAddress,
        uint256 offset,
        uint256 limit
    ) external view returns (uint256 totalProfit);

    function totalStaked(address user) external view returns (uint256);

    function totalStakedSTBL(address user) external view returns (uint256);

    function stakedByNFT(uint256 tokenId) external view returns (uint256);

    function stakedSTBLByNFT(uint256 tokenId) external view returns (uint256);

    function balanceOf(address user) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function uri(uint256 tokenId) external view returns (string memory);

    function tokenOfOwnerByIndex(address user, uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../interfaces/IContractsRegistry.sol";

abstract contract AbstractDependant {
    /// @dev keccak256(AbstractDependant.setInjector(address)) - 1
    bytes32 private constant _INJECTOR_SLOT =
        0xd6b8f2e074594ceb05d47c27386969754b6ad0c15e5eb8f691399cd0be980e76;

    modifier onlyInjectorOrZero() {
        address _injector = injector();

        require(_injector == address(0) || _injector == msg.sender, "Dependant: Not an injector");
        _;
    }

    function setInjector(address _injector) external onlyInjectorOrZero {
        bytes32 slot = _INJECTOR_SLOT;

        assembly {
            sstore(slot, _injector)
        }
    }

    /// @dev has to apply onlyInjectorOrZero() modifier
    function setDependencies(IContractsRegistry) external virtual;

    function injector() public view returns (address _injector) {
        bytes32 slot = _INJECTOR_SLOT;

        assembly {
            _injector := sload(slot)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

uint256 constant SECONDS_IN_THE_YEAR = 365 * 24 * 60 * 60; // 365 days * 24 hours * 60 minutes * 60 seconds
uint256 constant DAYS_IN_THE_YEAR = 365;
uint256 constant MAX_INT = type(uint256).max;

uint256 constant DECIMALS18 = 10**18;

uint256 constant PRECISION = 10**25;
uint256 constant PERCENTAGE_100 = 100 * PRECISION;

uint256 constant BLOCKS_PER_DAY = 6450;
uint256 constant BLOCKS_PER_YEAR = BLOCKS_PER_DAY * 365;

uint256 constant BLOCKS_PER_DAY_BSC = 28800;
uint256 constant BLOCKS_PER_DAY_POLYGON = 43200;

uint256 constant APY_TOKENS = DECIMALS18;

uint256 constant PROTOCOL_PERCENTAGE = 20 * PRECISION;
uint256 constant ACTIVE_REWARD_PERCENTAGE = 80 * PRECISION;
uint256 constant CLOSED_REWARD_PERCENTAGE = 1 * PRECISION;

uint256 constant DEFAULT_REBALANCING_THRESHOLD = 10**23;

uint256 constant EPOCH_DAYS_AMOUNT = 7;

// ClaimVoting ClaimingRegistry
uint256 constant APPROVAL_PERCENTAGE = 66 * PRECISION;
uint256 constant PENALTY_THRESHOLD = 11 * PRECISION;
uint256 constant QUORUM = 10 * PRECISION;
uint256 constant CALCULATION_REWARD_PER_DAY = PRECISION;
uint256 constant PERCENTAGE_50 = 50 * PRECISION;

// PolicyBook
uint256 constant MINUMUM_COVERAGE = 100 * DECIMALS18; // 100 STBL
uint256 constant ANNUAL_COVERAGE_TOKENS = MINUMUM_COVERAGE * 10; // 1000 STBL

uint256 constant PREMIUM_DISTRIBUTION_EPOCH = 1 days;
uint256 constant MAX_PREMIUM_DISTRIBUTION_EPOCHS = 90;
enum Networks {ETH, BSC, POL}

/// @dev unchecked increment
function uncheckedInc(uint256 i) pure returns (uint256) {
    unchecked {return i + 1;}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
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