pragma solidity ^0.5.0;


contract CoinFlip {
	address payable public player1;
	address payable public player2;

	bytes32 public player1Commitment;
	bool public player2Choice;

	uint256 public betAmount;
	uint256 public expiration;

	function flipCoin(bool _bet, uint256 _nonce) public payable {
		player1 = msg.sender;
		player1Commitment = keccak256(abi.encodePacked(_bet, _nonce));
		betAmount = msg.value;
	}

	function takeBet(bool _bet) public payable {
		// Only two players can play
		require(player2 == address(0));

		// player 2 must bet amount == player 1 bet
		require(msg.value == betAmount);

		// Player 2 is the caller of this function
		player2 = msg.sender;

		// Set player 2 choice to arg passed
		player2Choice = _bet;

		// Set expiration timer for player 1 to reveal commitment
		expiration = now + 1 minutes;
	}

	// Called by player 1 to reveal his earlier bet
	function reveal(bool _choice, uint256 _nonce) public payable {
		require(player2 != address(0));
		require(now < expiration);

		// choice must be the same as his initial commitment
		if (keccak256(abi.encodePacked(_choice, _nonce)) != player1Commitment) {
			// if player 1 deviates from protocol, he loses his bet amount to player 2
			address(player2).transfer(address(this).balance);
		}

		if (player2Choice == _choice) {
			address(player2).transfer(address(this).balance);
		}

		else {
			address(player1).transfer(address(this).balance);
		}

		// reset the bet amount and expiration
		betAmount = 0;
		expiration = 0;
	}

	// player 1 can cancel the bet before player 2 calls takeBet
	function cancel() public {
		require(msg.sender == player1);
		require(player2 == address(0));

		// reset the bet amount and expiration
		betAmount = 0;
		expiration = 0;

		// give player 1 his money back
		address(msg.sender).transfer(address(this).balance);
	}

	// player 2 can call timeout on player 1 if player 1 refuses to call reveal()
	function claimTimeout() public {
		require(now >= expiration);

		address(player2).transfer(address(this).balance);

		// reset the bet amount and expiration
		betAmount = 0;
		expiration = 0;
	}



}