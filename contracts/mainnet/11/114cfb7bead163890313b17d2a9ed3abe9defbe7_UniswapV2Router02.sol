/**
 *Submitted for verification at polygonscan.com on 2022-02-28
*/

/**
 *Submitted for verification at polygonscan.com on 2021-05-18
*/

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// File: @uniswap/lib/contracts/libraries/TransferHelper.sol

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// File: contracts/interfaces/IUniswapV2Router01.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: contracts/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;


// interface IUniswapV2Router02 is IUniswapV2Router01 {
interface IUniswapV2Router02  {
    function crossSwapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address[] calldata routerPath,
        address[] calldata factoryPath,
        address to,
        uint deadline
    ) external;
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// File: contracts/libraries/SafeMath.sol

pragma solidity =0.6.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// File: contracts/libraries/UniswapV2Library.sol

pragma solidity >=0.5.0;



library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = IUniswapV2Factory(factory).getPair(token0,token1);
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function getReserveList(address factory, address[] memory path) internal view returns (uint[] memory reserveIns,uint[] memory reserveOuts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        reserveIns = new uint[](path.length);
        reserveOuts = new uint[](path.length);
        for (uint i; i < path.length - 1; i++) {
            (reserveIns[i] ,reserveOuts[i]) = getReserves(factory, path[i], path[i + 1]);
        }
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(address router,uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        amountOut = IUniswapV2Router01(router).getAmountOut(amountIn, reserveIn, reserveOut);
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(address router,uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        amountIn = IUniswapV2Router01(router).getAmountIn(amountOut, reserveIn, reserveOut);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address[] memory router,address[] memory factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory[i], path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(router[i],amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address[] memory router,address[] memory factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory[i], path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(router[i],amounts[i], reserveIn, reserveOut);
        }
    }
}

// File: contracts/interfaces/IERC20.sol

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// File: contracts/interfaces/IWETH.sol

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// File: contracts/UniswapV2Router02.sol

pragma solidity =0.6.6;



contract UniswapV2Router02 is IUniswapV2Router02 {
    using SafeMath for uint;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('getPair(address,address)')));

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }
    

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _crossSwapSupportingFeeOnTransferTokens(address[] memory path,address[] memory routerPath,address[] memory factoryPath,address[] memory  pairPath, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(factoryPath[i], input, output));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
                (uint reserve0, uint reserve1,) = pair.getReserves();
                (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
                amountOutput = UniswapV2Library.getAmountOut(routerPath[i], amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? pairPath[i] : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
    function crossSwapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address[] calldata routerPath,
        address[] calldata factoryPath,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factoryPath[0], path[0], path[1]), amountIn
        );
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        address[] memory pairPath = new address[](path.length-2);
        for (uint i; i < path.length - 2; i++) {
            pairPath[i] = pairFor(factoryPath[i+1], path[i+1], path[i + 2]);
        }
        _crossSwapSupportingFeeOnTransferTokens(path, routerPath, factoryPath, pairPath, to);
        uint balanceAfter = IERC20(path[path.length - 1]).balanceOf(to);
        require(
            balanceAfter.sub(balanceBefore) >= amountOutMin,
            'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    function pairFor(address factory, address tokenA, address tokenB)
        public
        virtual
        view
        returns (address pair)
    {
        (address token0, address token1) = UniswapV2Library.sortTokens(tokenA, tokenB);
        (bool success, bytes memory data) = factory.staticcall(abi.encodeWithSignature("getPair(address,address)", token0, token1));
        if(success){
            return abi.decode(data, (address));
        }
    }

    function getReserveList(address factory,address[] memory path)
        public
        view
        virtual
        returns (uint[] memory reserveIns,uint[] memory reserveOuts)
    {
        return UniswapV2Library.getReserveList(factory,path);
    }
    function getAmountOut(address router,uint amountIn, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        returns (uint amountOut)
    {
        return UniswapV2Library.getAmountOut(router,amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(address router,uint amountOut, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        returns (uint amountIn)
    {
        return UniswapV2Library.getAmountIn(router,amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(address[] memory router,address[] memory factory, uint amountIn, address[] memory path)
        public
        view
        virtual
        returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsOut(router,factory, amountIn, path);
    }

    function getAmountsIn(address[] memory router,address[] memory factory, uint amountOut, address[] memory path)
        public
        view
        virtual
        returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsIn(router,factory, amountOut, path);
    }
}