/**
 *Submitted for verification at polygonscan.com on 2022-02-10
*/

// File: interfaces/ICloutStaking.sol


pragma solidity 0.7.5;

interface ICloutStaking {
    function stake(uint256 _amount, address _recipient) external returns (bool);

    function claim(address _recipient) external;
}

// File: interfaces/IERC20.sol


pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface IERC20Mintable {
    function mint(uint256 amount_) external;

    function mint(address account_, uint256 ammount_) external;
}

// File: CloutStakingHelper.sol


pragma solidity 0.7.5;



contract CloutStakingHelper {
    address public immutable staking;
    address public immutable CLOUT;

    constructor(address _staking, address _CLOUT) {
        require(_staking != address(0));
        staking = _staking;
        require(_CLOUT != address(0));
        CLOUT = _CLOUT;
    }

    function stake(uint256 _amount, address _recipient) external {
        IERC20(CLOUT).transferFrom(msg.sender, address(this), _amount);
        IERC20(CLOUT).approve(staking, _amount);
        ICloutStaking(staking).stake(_amount, _recipient);
        ICloutStaking(staking).claim(_recipient);
    }
}