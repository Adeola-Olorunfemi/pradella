// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "interface.sol";
contract is IERC20{
    uint pulic override totalsupply;
    mapping(address=>uint) public override balanceof;
    mapping (address=>mapping)(address=>uint) public override allowance;
    string public name="ADDY TOKEN";
    string public symbol="ATk"
    uint public decimal=18;

    /* to send money from one account to another,
    line 17 is withdrawing money from the sender, line 18 is receiving money into the recepient account*/
    
    function transfer(address recepient, uint amount)
    external override returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recepient] += amount;

        emit Transfer(msg.sender,recepient,amount);
        true;
        // emit will show front end transaction is succesful=
    }
}