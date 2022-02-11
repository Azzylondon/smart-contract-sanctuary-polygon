// SPDX-License-Identifier: AGPL-3.0-or-later\
pragma solidity 0.7.5;

import '../interfaces/IERC20.sol';

import '../libraries/SafeMath.sol';

contract Dex1CirculatingSupply {
    using SafeMath for uint256;

    bool public isInitialized;

    address public DEX1;
    address public owner;
    address[] public nonCirculatingDEX1Addresses;

    constructor(address _owner) {
        owner = _owner;
    }

    function initialize(address _DEX1) external returns (bool) {
        require(msg.sender == owner, 'caller is not owner');
        require(isInitialized == false);

        DEX1 = _DEX1;

        isInitialized = true;

        return true;
    }

    function DEX1CirculatingSupply() external view returns (uint256) {
        uint256 _totalSupply = IERC20(DEX1).totalSupply();

        uint256 _circulatingSupply = _totalSupply.sub(getNonCirculatingDEX1());

        return _circulatingSupply;
    }

    function getNonCirculatingDEX1() public view returns (uint256) {
        uint256 _nonCirculatingDEX1;

        for (
            uint256 i = 0;
            i < nonCirculatingDEX1Addresses.length;
            i = i.add(1)
        ) {
            _nonCirculatingDEX1 = _nonCirculatingDEX1.add(
                IERC20(DEX1).balanceOf(nonCirculatingDEX1Addresses[i])
            );
        }

        return _nonCirculatingDEX1;
    }

    function setNonCirculatingDEX1Addresses(
        address[] calldata _nonCirculatingAddresses
    ) external returns (bool) {
        require(msg.sender == owner, 'Sender is not owner');
        nonCirculatingDEX1Addresses = _nonCirculatingAddresses;

        return true;
    }

    function transferOwnership(address _owner) external returns (bool) {
        require(msg.sender == owner, 'Sender is not owner');

        owner = _owner;

        return true;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
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
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
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

    function sqrrt(uint256 a) internal pure returns (uint256 c) {
        if (a > 3) {
            c = a;
            uint256 b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}