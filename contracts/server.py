import json

from flask import Flask, render_template

from web3 import Web3

app = Flask(__name__)

ganache_url = "http://127.0.0.1:7545"
web3 = Web3(Web3.HTTPProvider(ganache_url))

# Compiled by Remix
abi = json.loads(open('abi.json', 'r').read())
bytecode = json.loads(open('bytecode.json', 'r').read())['object']

# Set default account
web3.eth.defaultAccount = web3.eth.accounts[0]

# Create smart contract object
CF = web3.eth.contract(abi=abi, bytecode=bytecode)

# Deploy smart contract
tx_hash = CF.constructor().transact()
tx_receipt = web3.eth.waitForTransactionReceipt(tx_hash)

#print(tx_receipt)

# Instantiate the smart contract at specified address
contract = web3.eth.contract(address=tx_receipt.contractAddress, abi=abi)

@app.route('/', methods=['POST', 'GET'])
def hello():
    return render_template('template.html', contractAddress = contract.address.lower(), contractABI = json.dumps(abi))

if __name__ == '__main__':
    app.run(debug=True)


