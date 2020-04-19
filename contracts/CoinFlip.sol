pragma solidity ^0.5.0;


contract CoinFlip {

	// ERC-20 standard
	string public name = "CoinFlip";
	string public symbol = "CF";
	uint256 public totalSupply;
	mapping(address => uint256) public balanceOf;
	mapping(address => mapping(address => uint256)) public allowance;

	event Transfer (
		address indexed _from,
		address indexed _to,
		uint256 _value
	);

	event Approval (
		address indexed _owner,
		address indexed _spender,
		uint256 _value
	);

	// State variables for coin flip functions
	address payable public player1;
	address payable public player2;
	address payable public winner;

	bytes32 public player1Commitment;
	bool public player2Choice;

	uint256 public expiration;
	uint public pot;
	uint minBet;

	constructor() public {
	    minBet = 10 wei;
	    // Creator of contract will hold 1000000 tokens
	    balanceOf[msg.sender] = 1000000;
	    totalSupply = 1000000;
	}

	function transfer(address _to, uint256 _value) public returns (bool success) {
		require(balanceOf[msg.sender] >= _value);

		balanceOf[msg.sender] -= _value;
		balanceOf[msg.sender] += _value;

		emit Transfer(msg.sender, _to, _value);

		return true;
	}

	function approve(address _spender, uint256 _value) public returns (bool success) {
		allowance[msg.sender][_spender] = _value;

		emit Approval(msg.sender, _spender, _value);

		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		require(_value <= balanceOf[_from]);
		require(_value <= allowance[_from][msg.sender]);

		balanceOf[_from] -= _value;
		balanceOf[_to] += _value;

		allowance[_from][msg.sender] -= _value;

		emit Transfer(_from, _to, _value);

		return true;
	}
	
	function getPot() public view returns(uint) {
	    return pot;
	}
	
	function getWinner() public view returns(address payable) {
	    return winner;
	}
	
	function getPlayer1() public view returns(address payable) {
	    return player1;
	}
	
	function getPlayer2() public view returns(address payable) {
	    return player2;
	}
	
	function reset() public {
	    player1 = address(0);
		player2 = address(0);
		expiration = 0;
		pot = 0;
	}

	function flipCoin(bool _bet, uint256 _nonce) public payable {
	    // Player 1 must bet at least the minimum bet
	    if(msg.value < minBet) {
	        revert("Must bet minimally 10 Wei");
	    }
		player1 = msg.sender;
		player1Commitment = keccak256(abi.encodePacked(_bet, _nonce));
		pot += msg.value;
	}
	
	function takeBet(bool _bet) public payable {
		// Only two players can play
		if(player2 != address(0)) {
			revert("There is already a Player 2, wait for next betting round");
		}

		// player 2 must bet at least the minimum bet
	    if(msg.value < minBet) {
	        revert("Must bet minimally 10 Wei");
	    }

		// Player 2 is the caller of this function
		player2 = msg.sender;

		// Set player 2 choice to arg passed
		player2Choice = _bet;
		
		// Update the pot
		pot += msg.value;

		// Set expiration timer for player 1 to reveal commitment
		expiration = now + 30 minutes;
	}

	// Called by player 1 to reveal his earlier bet
	function reveal(bool _choice, uint256 _nonce) public payable {
		//require(player2 != address(0));
		if(now > expiration || player2 == address(0)) {
			revert("The expiration has been exceeded or there is no Player 2");			
		}

		// choice must be the same as his initial commitment
		if (keccak256(abi.encodePacked(_choice, _nonce)) != player1Commitment) {
			// if player 1 deviates from protocol, he loses his bet amount to player 2
			address(player2).transfer(address(this).balance);
		}

		if (player2Choice == _choice) {
		    winner = player2;
			address(player2).transfer(address(this).balance);
		}

		else {
		    winner = player1;
			address(player1).transfer(address(this).balance);
		}
		
		// Reset all state variables before new game
		player1 = address(0);
		player2 = address(0);
		expiration = 0;
		pot = 0;
		
	}

	// player 1 can cancel the bet before player 2 calls takeBet
	function cancel() public {
		if(msg.sender != player1 || player2 != address(0)) {
			revert("Only Player 1 can call cancel function or Player 2 has already entered bet");
		}
		
		// give player 1 his money back
		address(msg.sender).transfer(address(this).balance);
	}

	// player 2 can call timeout on player 1 if player 1 refuses to call reveal()
	function claimTimeout() public {
		if(now < expiration) {
			revert("Cannot claim until after expiration period");
		}

		address(player2).transfer(address(this).balance);
	}

}