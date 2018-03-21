pragma solidity ^0.4.0;

import 'zeppelin-solidity/contracts/token/ERC20/CappedToken.sol';
import 'zeppelin-solidity/contracts/lifecycle/Pausable.sol';

contract SuperOneToken is CappedToken, Pausable {

    string public name;
    string public symbol;
    uint8 public decimals;

    function SuperOneToken(string _name, string _symbol,
        uint256 _cap, uint8 _decimals) public CappedToken(_cap * (10 ** uint256(_decimals))) {

        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        pause();
    }

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}
