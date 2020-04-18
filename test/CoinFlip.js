const CoinFlip = artifacts.require("./CoinFlip.sol");

contract("CoinFlip", function(accounts) {
	var contract;

	before(async() => {
		contract = await CoinFlip.deployed();
	})
	
	describe("deployment", async() => {
		it("should deploy contract at a valid address", async() => {
			const address = await contract.address;
			assert.notEqual(address, 0);
		})
	})

	describe("coin flip", async() => {
		it("coin flip should set bet amount and player 1", async() => {
			await contract.flipCoin(true, 1, {from: accounts[0], value: web3.utils.toWei("10", "Wei")});
			let player1 = await contract.player1();
			assert.equal(player1, accounts[0]);
		})
	})

})

