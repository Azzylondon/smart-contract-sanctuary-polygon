/**
 *Submitted for verification at polygonscan.com on 2022-12-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

// Creating a Contract
contract point
{

// Table to map addresses
// to their balance
mapping(address => uint256) balances;

// Mapping owner address to
// those who are allowed to
// use the contract
mapping(address => mapping (
		address => uint256)) allowed;


//Stuff
uint256 frac_ptr=0;
uint256 int_ptr=0;
uint256 symbol_ptr=0;

int precision = 0;
// totalSupply
uint256 _totalSupply = 500;



// owner address
address public owner;

// Triggered whenever
// approve(address _spender, uint256 _value)
// is called.
event Approval(address indexed _owner,
				address indexed _spender,
				uint256 _value);

// Event triggered when
// tokens are transferred.
event Transfer(address indexed _from,
			address indexed _to,
			uint256 _value);

// totalSupply function
function totalSupply()
		public view returns (
		uint256 theTotalSupply)
{
theTotalSupply = _totalSupply;
return theTotalSupply;
}




//Require stuff
function check_conditions(uint _x) public{
    frac_ptr=frac_ptr+5;
    if(_x<2){
        revert("value of x is less than 2");
    }
    else if(_x<3){
        revert("Fuck off");
    }
    else if(frac_ptr!=int_ptr){
        revert("wrong string format ");
    }
    else if(int_ptr>=0 && int_ptr<=9){
        revert("wrong string format");
    }
    else if(symbol_ptr>=0 && symbol_ptr<=9){
        revert("wrong string format");
    }


    //ADD FORMULAES 
    
}

// balanceOf function
function balanceOf(address _owner)
		public view returns (
		uint256 balance)
{
return balances[_owner];
}

// function approve
function approve(address _spender,
				uint256 _amount)
				public returns (bool success)
{
	// If the address is allowed
	// to spend from this contract
allowed[msg.sender][_spender] = _amount;
	
// Fire the event "Approval"
// to execute any logic that
// was listening to it
emit Approval(msg.sender,
				_spender, _amount);
return true;
}

// transfer function
function transfer(address _to,
				uint256 _amount)
				public returns (bool success)
{
	// transfers the value if
	// balance of sender is
	// greater than the amount
	if (balances[msg.sender] >= _amount)
	{
		balances[msg.sender] -= _amount;
		balances[_to] += _amount;
		
		// Fire a transfer event for
		// any logic that is listening
		emit Transfer(msg.sender,
					_to, _amount);
			return true;
	}
	else
	{
		return false;
	}
}


/* The transferFrom method is used for
a withdraw workflow, allowing
contracts to send tokens on
your behalf, for example to
"deposit" to a contract address
and/or to charge fees in sub-currencies;*/
function transferFrom(address _from,
					address _to,
					uint256 _amount)
					public returns (bool success)
{
if (balances[_from] >= _amount &&
	allowed[_from][msg.sender] >=
	_amount && _amount > 0 &&
	balances[_to] + _amount > balances[_to])
{
		balances[_from] -= _amount;
		balances[_to] += _amount;
		
		// Fire a Transfer event for
		// any logic that is listening
		emit Transfer(_from, _to, _amount);
	return true;

}
else
{
	return false;
}
}

// Check if address is allowed
// to spend on the owner's behalf
function allowance(address _owner,
				address _spender)
				public view returns (uint256 remaining)
{
return allowed[_owner][_spender];
}
}