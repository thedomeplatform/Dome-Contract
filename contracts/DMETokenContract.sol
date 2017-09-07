pragma solidity ^0.4.11;

import './StandardToken.sol';
import './Ownable.sol';


contract TheDomePlatformToken is StandardToken, Ownable {
    string public constant name = "DomePlatform token";
    string public constant symbol = "DME";
    uint public constant decimals = 18;

    using SafeMath for uint256;

    // timestamps for first and second Steps
    uint public startDate;
    uint public endDate;

    // address where funds are collected
    address public wallet;

    // how many token units a buyer gets per wei
    uint256 public rate;

    uint256 public minTransactionAmount;

    uint256 public raisedForEther = 0;

    modifier inActivePeriod() {
	require((startDate < now && now <= endDate));
        _;
    }

    function TheDomePlatformToken(address _wallet, uint _start, uint _end) {
        require(_wallet != 0x0);
        require(_start < _end);

        // accumulation wallet
        wallet = _wallet;

        //90,000,000 DME tokens
        totalSupply = 90000000;
	crowdsaleSupply = 60000000;
	bonusesSupply = 2800000;

	bonusesSold = 0;
	tokensSold = 0;

        // 1 ETH = 1,750 DME
        rate = 1750;

        // minimal invest
        minTransactionAmount = 0.1 ether;

	startDate = _start;
	endDate = _end;
    }

    function setupPeriod(uint _start, uint _end) onlyOwner {
        require(_start < _end);
        startDate = _start;
        endDate = _end;
    }

    // fallback function can be used to buy tokens
    function () inActivePeriod payable {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address _sender) inActivePeriod payable {
        require(_sender != 0x0);
        require(msg.value >= minTransactionAmount);

        uint256 weiAmount = msg.value;

        raisedForEther = raisedForEther.add(weiAmount);

        // calculate token amount to be created
        uint256 tokens = weiAmount.mul(rate);
        tokens += getBonus(tokens);
	require(tokensSold + tokens <= crowdsaleSupply + bonusesSupply);

        tokenReserve(_sender, tokens);
	tokensSold += tokens;

        forwardFunds();
    }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    /*
    *        Day 1: +20% bonus
    *        Day 2: +15% bonus
    *        Day 3: +10% bonus
    *        Day 4: no bonuses
    */
    function getBonus(uint256 _tokens) constant returns (uint256 bonus) {
        require(_tokens != 0);
	uint256 bonuses = 0;
        if (startDate <= now && now < startDate + 1 days) {
            bonuses = _tokens.mul(20).div(100);
        } else if (startDate + 1 days <= now && now < startDate + 2 days ) {
            bonuses = _tokens.mul(15).div(100);
        } else if (startDate + 2 days <= now && now < startDate + 3 days ) {
            bonuses = _tokens.mul(10).div(100);
        }
	if (bonusesSold + bonuses > bonusesSupply) {
	    bonuses = 0;
	} else {
	    bonusesSold += bonuses;
	}
	return bonuses;
    }

    function tokenReserve(address _to, uint256 _value) internal returns (bool) {
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
}
