/**
 *Submitted for verification at polygonscan.com on 2022-02-15
*/

pragma solidity 0.8.10;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier:MIT

// BEP20 token standard interface
interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address _account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one _account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// Dex Factory contract interface
interface IDexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

// Dex Router02 contract interface
interface IDexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any _account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new _account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    /**
     * @dev set the owner for the first time.
     * Can only be called by the contract or deployer.
     */
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Utils {
    using SafeMath for uint256;

    function swapTokensForEth(address routerAddress, uint256 tokenAmount)
        internal
    {
        IDexRouter dexRouter = IDexRouter(routerAddress);

        // generate the Dex pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        // make the swap
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp + 300
        );
    }

    function addLiquidity(
        address routerAddress,
        address owner,
        uint256 tokenAmount,
        uint256 ethAmount
    ) internal {
        IDexRouter dexRouter = IDexRouter(routerAddress);

        // add the liquidity
        dexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner,
            block.timestamp + 300
        );
    }
}

contract LuluToken is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    mapping(address => bool) private _isExcludedFromMaxSellLimit;
    mapping(address => bool) public _isBlackListed;

    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1 * 1e12 * 1e18; // 1 trillion supply
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "LULU Token";
    string private _symbol = "LULU";
    uint8 private _decimals = 18;

    IDexRouter public dexRouter;
    address public dexPair;
    address payable public marketWallet;
    address payable public farmingPoolWallet;

    uint256 public _maxSellAmount = 20000 * 1e18; // should be 20k per transaction
    uint256 minTokenNumberToSell = 100000 * 1e18; // 100k max tx amount will trigger swap and add liquidity

    bool public swapAndLiquifyEnabled = false; // should be true to turn on to liquidate the pool
    bool public reflectionFeesdiabled = false; // should be false to charge fee
    bool inSwapAndLiquify = false;

    uint256 public _taxFee = 10; // 1% will be distributed among holder as token divideneds
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _liquidityFee = 10; // 1% will be added to the liquidity pool
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 public _marketFee = 10; // 1% will go to the market address
    uint256 private _previousMarketFee = _marketFee;

    uint256 public _farmingPoolFee = 20; // 2% will go to the dev address
    uint256 private _previousFarmingPoolFee = _farmingPoolFee;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event ClaimBNBSuccessfully(
        address recipient,
        uint256 ethReceived,
        uint256 nextAvailableClaimDate
    );
    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(
        address payable _marketWallet,
        address payable _farmingPoolWallet
    ) {
        _rOwned[owner()] = _rTotal;
        marketWallet = _marketWallet;
        farmingPoolWallet = _farmingPoolWallet;

        IDexRouter _dexRouter = IDexRouter(
            0x8954AfA98594b838bda56FE4C12a09D7739D179b
        );
        // Create a pancake pair for this new token
        dexPair = IDexFactory(_dexRouter.factory()).createPair(
            address(this),
            _dexRouter.WETH()
        );

        // set the rest of the contract variables
        dexRouter = _dexRouter;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        // exclude from max tx
        _isExcludedFromMaxSellLimit[owner()] = true;
        _isExcludedFromMaxSellLimit[address(this)] = true;

        emit Transfer(address(0), owner(), _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "LULU: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "LULU: decreased allowance below zero"
            )
        );
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(
            !_isExcluded[sender],
            "Excluded addresses cannot call this function"
        );
        uint256 rAmount = tAmount.mul(_getRate());
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            uint256 rAmount = tAmount.mul(_getRate());
            return rAmount;
        } else {
            uint256 rAmount = tAmount.mul(_getRate());
            uint256 rTransferAmount = rAmount.sub(
                totalFeePerTx(tAmount).mul(_getRate())
            );
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _rOwned[account] = _tOwned[account].mul(_getRate());
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    // to add any address to BlackList
    function addInBlackList(address _account) external onlyOwner {
        require(
            _account != address(dexRouter),
            "LULU: We can not blacklist dexRouter"
        );
        require(!_isBlackListed[_account], "LULU: sniper already exist");
        _isBlackListed[_account] = true;
    }

    // to remove any address to BlackList
    function removeFromBlackList(address _account) external onlyOwner {
        require(_isBlackListed[_account], "LULU: Not a sniper");
        _isBlackListed[_account] = false;
    }

    // for 1% input 100
    function setMaxTxPercent(uint256 maxellAmount) public onlyOwner {
        _maxSellAmount = maxellAmount;
    }

    function setMinTokenNumberToSell(uint256 _amount) public onlyOwner {
        minTokenNumberToSell = _amount;
    }

    function setExcludeFromMaxTx(address _address, bool value)
        public
        onlyOwner
    {
        _isExcludedFromMaxSellLimit[_address] = value;
    }

    function updateTaxFees(
        uint256 reflectionFee,
        uint256 liquidityFee,
        uint256 marketFee,
        uint256 devFee
    ) external onlyOwner {
        _taxFee = reflectionFee;
        _liquidityFee = liquidityFee;
        _marketFee = marketFee;
        _farmingPoolFee = devFee;
    }

    function setSwapAndLiquifyEnabled(bool _state) public onlyOwner {
        swapAndLiquifyEnabled = _state;
        emit SwapAndLiquifyEnabledUpdated(_state);
    }

    function setReflectionFees(bool _state) external onlyOwner {
        reflectionFeesdiabled = _state;
    }

    function setMarketAddress(address payable _marketAddress)
        external
        onlyOwner
    {
        marketWallet = _marketAddress;
    }

    function setFarmingPoolWallet(address payable _devAddress)
        external
        onlyOwner
    {
        farmingPoolWallet = _devAddress;
    }

    // owner can change router and pair address
    function setRoute(IDexRouter _router, address _pair) external onlyOwner {
        dexRouter = _router;
        dexPair = _pair;
    }

    //to receive BNB from dexRouter when swapping
    receive() external payable {}

    function totalFeePerTx(uint256 tAmount) internal view returns (uint256) {
        uint256 percentage = tAmount
            .mul(
                _taxFee.add(_liquidityFee).add(_marketFee).add(_farmingPoolFee)
            )
            .div(1e3);
        return percentage;
    }

    function _reflectFee(uint256 tAmount) private {
        uint256 tFee = tAmount.mul(_taxFee).div(1e3);
        uint256 rFee = tFee.mul(_getRate());
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeBothPoolFee(
        address sender,
        uint256 tAmount,
        uint256 currentRate
    ) internal {
        uint256 tPoolFee = tAmount.mul(_liquidityFee).div(1e3);
        uint256 rPoolFee = tPoolFee.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rPoolFee);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tPoolFee);
        emit Transfer(sender, address(this), tPoolFee);
    }

    function _takeMarketFee(
        address sender,
        uint256 tAmount,
        uint256 currentRate
    ) internal {
        uint256 tMarketFee = tAmount.mul(_marketFee).div(1e3);
        uint256 rMarketFee = tMarketFee.mul(currentRate);
        _rOwned[marketWallet] = _rOwned[marketWallet].add(rMarketFee);
        if (_isExcluded[marketWallet])
            _tOwned[marketWallet] = _tOwned[marketWallet].add(tMarketFee);
        emit Transfer(sender, marketWallet, tMarketFee);
    }

    function _takeFarmingPoolFee(
        address sender,
        uint256 tAmount,
        uint256 currentRate
    ) internal {
        uint256 tDevFee = tAmount.mul(_farmingPoolFee).div(1e3);
        uint256 rDevFee = tDevFee.mul(currentRate);
        _rOwned[farmingPoolWallet] = _rOwned[farmingPoolWallet].add(rDevFee);
        if (_isExcluded[farmingPoolWallet])
            _tOwned[farmingPoolWallet] = _tOwned[farmingPoolWallet].add(
                tDevFee
            );
        emit Transfer(sender, farmingPoolWallet, tDevFee);
    }

    function removeAllFee() private {
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousMarketFee = _marketFee;
        _previousFarmingPoolFee = _farmingPoolFee;

        _taxFee = 0;
        _liquidityFee = 0;
        _marketFee = 0;
        _farmingPoolFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _marketFee = _previousMarketFee;
        _farmingPoolFee = _previousFarmingPoolFee;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "LULU: approve from the zero address");
        require(spender != address(0), "LULU: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "LULU: transfer from the zero address");
        require(to != address(0), "LULU: transfer to the zero address");
        require(amount > 0, "LULU: Transfer amount must be greater than zero");
        require(!_isBlackListed[to], "LULU: Sniper detected");
        require(!_isBlackListed[from], "LULU: Sniper detected");

        if (
            to == dexPair && _isExcludedFromMaxSellLimit[from] == false // by default false
        ) {
            require(amount <= _maxSellAmount, "LULU:amount exceed max limit");
        }

        // swap and liquify
        swapAndLiquify(from, to);

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (
            _isExcludedFromFee[from] ||
            _isExcludedFromFee[to] ||
            reflectionFeesdiabled
        ) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();
        else if (recipient != dexPair && sender != dexPair) {
            removeAllFee();
        }

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 currentRate = _getRate();
        uint256 tTransferAmount = tAmount.sub(totalFeePerTx(tAmount));
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(
            totalFeePerTx(tAmount).mul(currentRate)
        );
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeBothPoolFee(sender, tAmount, currentRate);
        _takeMarketFee(sender, tAmount, currentRate);
        _takeFarmingPoolFee(sender, tAmount, currentRate);
        _reflectFee(tAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 currentRate = _getRate();
        uint256 tTransferAmount = tAmount.sub(totalFeePerTx(tAmount));
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(
            totalFeePerTx(tAmount).mul(currentRate)
        );
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeBothPoolFee(sender, tAmount, currentRate);
        _takeMarketFee(sender, tAmount, currentRate);
        _takeFarmingPoolFee(sender, tAmount, currentRate);
        _reflectFee(tAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 currentRate = _getRate();
        uint256 tTransferAmount = tAmount.sub(totalFeePerTx(tAmount));
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(
            totalFeePerTx(tAmount).mul(currentRate)
        );
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeBothPoolFee(sender, tAmount, currentRate);
        _takeMarketFee(sender, tAmount, currentRate);
        _takeFarmingPoolFee(sender, tAmount, currentRate);
        _reflectFee(tAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 currentRate = _getRate();
        uint256 tTransferAmount = tAmount.sub(totalFeePerTx(tAmount));
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(
            totalFeePerTx(tAmount).mul(currentRate)
        );
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeBothPoolFee(sender, tAmount, currentRate);
        _takeMarketFee(sender, tAmount, currentRate);
        _takeFarmingPoolFee(sender, tAmount, currentRate);
        _reflectFee(tAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function swapAndLiquify(address from, address to) private {
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is pancake pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= _maxSellAmount) {
            contractTokenBalance = _maxSellAmount;
        }

        bool shouldSell = contractTokenBalance >= minTokenNumberToSell;

        if (
            !inSwapAndLiquify &&
            shouldSell &&
            from != dexPair &&
            swapAndLiquifyEnabled &&
            !(from == address(this) && to == address(dexPair)) // swap 1 time
        ) {
            // only sell for minTokenNumberToSell, decouple from _maxSellAmount
            // split the contract balance into 4 pieces

            contractTokenBalance = minTokenNumberToSell;
            // approve contract
            _approve(address(this), address(dexRouter), contractTokenBalance);

            // add liquidity
            // split the contract balance into 2 pieces

            uint256 otherPiece = contractTokenBalance.div(2);
            uint256 tokenAmountToBeSwapped = contractTokenBalance.sub(
                otherPiece
            );

            uint256 initialBalance = address(this).balance;

            // now is to lock into staking pool
            Utils.swapTokensForEth(address(dexRouter), tokenAmountToBeSwapped);

            // how much BNB did we just swap into?

            // capture the contract's current BNB balance.
            // this is so that we can capture exactly the amount of BNB that the
            // swap creates, and not make the liquidity event include any BNB that
            // has been manually sent to the contract

            uint256 bnbToBeAddedToLiquidity = address(this).balance.sub(
                initialBalance
            );

            // add liquidity to pancake
            Utils.addLiquidity(
                address(dexRouter),
                owner(),
                otherPiece,
                bnbToBeAddedToLiquidity
            );

            emit SwapAndLiquify(
                tokenAmountToBeSwapped,
                bnbToBeAddedToLiquidity,
                otherPiece
            );
        }
    }
}