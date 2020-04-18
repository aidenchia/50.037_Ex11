pragma solidity ^0.5.0;


contract CoinFlip {
	address payable public player1;
	address payable public player2;
	address payable public winner;

	bytes32 public player1Commitment;
	bool public player2Choice;

	uint256 public expiration;

	// Withdrawal pattern
	mapping(address => uint) pot;

	function flipCoin(bool _bet, uint256 _nonce) public payable {
		player1 = msg.sender;
		player1Commitment = keccak256(abi.encodePacked(_bet, _nonce));
		pot[msg.sender] = msg.value;
	}

	function takeBet(bool _bet) public payable {
		// Only two players can play
		if(player2 != address(0)) {
			revert("There is already a Player 2, wait for next betting round");
		}

		// player 2 must bet at least some amount
		if(msg.value == 0) {
			revert("Must bet more than 0 Wei");
		}

		// Player 2 is the caller of this function
		player2 = msg.sender;

		// Set player 2 choice to arg passed
		player2Choice = _bet;

		// Set expiration timer for player 1 to reveal commitment
		//expiration = now + 5 minutes;

		// Update the pot
		pot[msg.sender] = msg.value;
	}

	// Called by player 1 to reveal his earlier bet
	function reveal(bool _choice, uint256 _nonce) public {
		
		//if(now > expiration || player2 == address(0)) {
		//	revert("The expiration has been exceeded or there is no Player 2");			
		//}

		// Player 1 choice must be the same as his initial commitment
		if (keccak256(abi.encodePacked(_choice, _nonce)) != player1Commitment) {
			
			// if player 1 deviates from protocol, player 2 wins;
			winner = player2;
			return;
		}

		// if player 2 has chosen the same value as player 1, player 2 wins
		if (player2Choice == _choice) {
			winner = player2;
		}

		// if player 2 has chosen a different value from player 1, player 1 wins
		else {
			winner = player1;
		}

		// reset the timer
		//expiration = 0;
	}

	function withdraw() public payable {
		//if(msg.sender != winner) {
		//	revert("Only winner can withdraw winnings");
		//}

		uint winnings = pot[player1] + pot[player2];
		require(msg.value == winnings);
		
		msg.sender.transfer(msg.value);

	}


	// player 1 can cancel the bet before player 2 calls takeBet
	function cancel() public payable {
		if(msg.sender != player1 || player2 != address(0)) {
			revert("Only Player 1 can call cancel function or Player 2 has already entered bet");
		}

		// give player 1 his money back
		address(msg.sender).transfer(pot[player1]);

		// reset the timer
		//expiration = 0;
	}

	function reset() public {
		delete pot[player1];
		delete pot[player2];
		player1 = address(0);
		player2 = address(0);
		winner = address(0);
		expiration = 0;

	}

	// player 2 can call timeout on player 1 if player 1 refuses to call reveal()
	function claimTimeout() public {
		//if(now < expiration) {
		//	revert("Cannot claim until after expiration period");
		//}

		// make player 2 winner
		winner = player2;
	}

}