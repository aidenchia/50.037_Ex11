# 50.037_Ex11
Exercise 11 for Blockchain Technology

## Question 1
As usual, I was having issue with solc as it doesn't support MacOS Catalina, which I'm currently running. So for the compilation step I grab the ABI and Bytecode from Remix and pass them as args when creating the smart contract object as follows:
 ```
# Compiled by Remix
abi = json.loads(open('abi.json', 'r').read())
bytecode = json.loads(open('bytecode.json', 'r').read())['object']

# Create smart contract object
CF = web3.eth.contract(abi=abi, bytecode=bytecode)
 ```
 
 For the deployment of the smart contract:
 ```
 # Deploy smart contract
tx_hash = CF.constructor().transact()
tx_receipt = web3.eth.waitForTransactionReceipt(tx_hash)

# Instantiate the smart contract at specified address
contract = web3.eth.contract(address=tx_receipt.contractAddress, abi=abi)
 ```

To interact with the smart contract on the frontend, I pass the contract address and ABI as arguments into Flask `render_template` function:
```
@app.route('/', methods=['POST', 'GET'])
def hello():
    return render_template('template.html', contractAddress = contract.address.lower(), contractABI = json.dumps(abi))
```

I then modified the `template.html` file from the `11_src` folder given. In order to get the winner status, I simply do:
```
contractInstance.getWinner(
  function(error, result) {
    if(!error) {
      var winner = JSON.stringify(result);
      $("span#winner").text(winner);
    }
    else {
    alert("Can't get winner value");
    }
});
```
There is a corresponding `<span>` tag with ID winner in the HTML which gets updated with the value of winner. I had to write a getWinner() function specially for this purpose instead of relying on Solidity's automatic getter functions. 

You may view the screenshots of the frontend here:   
![alt text](https://github.com/aidenchia/50.037_Ex11/blob/master/src/images/fe1.png)
![alt text](https://github.com/aidenchia/50.037_Ex11/blob/master/src/images/fe2.png)
![alt text](https://github.com/aidenchia/50.037_Ex11/blob/master/src/images/fe3.png)

As you can see, the winner's address gets updated as well as the pot amount which is the sum total of the bets wagered by both players. We can also view the player 1 and player 2 address in real-time on the frontend.  

Player 1 and player 2 each have their own respective actions. For example, Player 1 can start the coin flip by pressing the button, which will trigger a Metamask popup to confirm his transaction, with the bet, bet amount, and nonce determined by his inputs in the respective fields. This was done with:
```
$("a#call_flipCoin").click(function() {
  // 0 is heads, else is tails 
  var bet = $("input#bet").val() == 0;
  var betAmount = $("input#betAmount").val();
  var nonce = $("input#nonce").val();
  contractInstance.flipCoin(bet, nonce, 
  {from:web3.eth.accounts[0], value: betAmount, gas:100000}, 
    function(error, result) {
      if(error) {
        alert("Error flipCoin()");
      }
  });
});
```

## Question 2  
I implemented the ERC20 token standard by adding in the standard state variables and events into `CoinFlip.sol`:  
```
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
```

I set the total supply to 1,000,000 tokens and all of it is given to the contract deployer as follows:
```
constructor() public {
  minBet = 10 wei;
  // Creator of contract will hold 1000000 tokens
  balanceOf[msg.sender] = 1000000;
  totalSupply = 1000000;
}
```

I then added the standard functions such as `transfer`, `approve` and `transferFrom` as follows:
```
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
```

I then created `ICO.sol` for the CoinFlip contract to launch the crowd sale. It imports `CoinFlip.sol` and sets the admin as the deployer:
```
	constructor(CoinFlip _tokenContract, uint256 _tokenPrice) public {
		admin = msg.sender;
		tokenContract = _tokenContract;
		tokenPrice = _tokenPrice;
	}
```

I then allow investors to buy tokens as follows:
```
 function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
 }


  function buyTokens(uint256 _numberOfTokens) public payable {
        require(msg.value == multiply(_numberOfTokens, tokenPrice));
        require(tokenContract.balanceOf(this) >= _numberOfTokens);
        require(tokenContract.transfer(msg.sender, _numberOfTokens));

        tokensSold += _numberOfTokens;

        Sell(msg.sender, _numberOfTokens);
}
```

And the admin can end the sale of the ICO:
```
function endSale() public {
        require(msg.sender == admin);
        require(tokenContract.transfer(admin, tokenContract.balanceOf(this)));

        // Just transfer the balance to the admin
        admin.transfer(address(this).balance);
}
```





