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

    uint256 private crowdsaleSupply = 60000000000000000000000000;
    uint256 private reserveSupply = 25130000000000000000000000;
    uint256 private bountySupply = 270000000000000000000000;
    uint256 private bonusesSupply = 2800000000000000000000000;
    uint256 private developersSupply = 1800000000000000000000000;
    
    uint256 public bonusesSold = 0;
    uint256 public tokensSold = 0;

    function TheDomePlatformToken(address _wallet, uint _start, uint _end) {
        require(_wallet != 0x0);
        require(_start < _end);

        // accumulation wallet
        wallet = _wallet;

        //90,000,000 DME tokens
        totalSupply = 90000000000000000000000000;

	bonusesSold = 0;
	tokensSold = 0;

        // 1 ETH = 1,750 DME
        rate = 1750;

        // minimal invest
        minTransactionAmount = 0.1 ether;

	startDate = _start;
	endDate = _end;

	// Send the bounty and developers funds to the creator wallet
        balances[_wallet] = balances[_wallet].add(developersSupply + bountySupply);
	// Store the reserve funds in the contract
	balances[this] = balances[this].add(reserveSupply);
    }

    // In case any tokens are not sold they will be added to the reserve
    function addToReserve() onlyOwner {
        if (bonusesSold < bonusesSupply) {
            uint256 remainingBonuses = bonusesSupply.sub(bonusesSold);
            reserveSupply += remainingBonuses;
	    balances[this] = balances[this].add(remainingBonuses);
	    // No more bonuses
	    bonusesSold = bonusesSupply;
        }
        if (tokensSold < crowdsaleSupply) {
            uint256 remainingTokens = crowdsaleSupply.sub(tokensSold);
            reserveSupply += remainingTokens;
	    balances[this] = balances[this].add(remainingTokens);
	    // No more tokens to sel, everything goes to reserve.
	    tokensSold = crowdsaleSupply;
        }
    }

    // This function will allow us to withdraw the reserve in order to distribute it
    // to Wi-Fi contributors
    function transferReserve(address _to) onlyOwner {
	require(balances[this] == reserveSupply);
        balances[_to] = balances[_to].add(reserveSupply);
	balances[this] = balances[this].sub(reserveSupply);
        Transfer(msg.sender, _to, reserveSupply);
    }

    function setupPeriod(uint _start, uint _end) onlyOwner {
        require(_start < _end);
        startDate = _start;
        endDate = _end;
    }

    function transferReserve(_to) onlyOwner {
	require(balances[this] == reserveSupply);
        balances[_to] = balances[_to].add(reserveSupply);
	balances[this] = balances[this].sub(reserveSupply);
        Transfer(msg.sender, _to, reserveSupply);
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
