# Basic Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, a sample script that deploys that contract, and an example of a task implementation, which simply lists the available accounts.


For installing dependencies
```shell
npm install
```
Try running some of the following tasks:
```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
node scripts/sample-script.js
npx hardhat help
```
For running script
```shell
npx hardhat run scripts/deploy-crowdToken.js --network sepolia
npx hardhat run scripts/createProject --network sepolia
```
Important Links:
sepolia faucet - https://www.alchemy.com/faucets/ethereum-sepolia

etherscan - https://etherscan.io/myapikey

solidity documentation - https://docs.soliditylang.org/en/v0.8.25/

Deployment Information - 0x95aAcb75Cc96CDCAe5A42edeA06452D79b61088a

Contract Address - 0x95aAcb75Cc96CDCAe5A42edeA06452D79b61088a

Live Explorer - https://sepolia.etherscan.io/address/0x95aAcb75Cc96CDCAe5A42edeA06452D79b61088a#code

##  Project Evidence & Testing

### 1. Smart Contract Deployment
We successfully deployed the `CrowdTank` contract to the Ethereum Sepolia Testnet using Remix IDE and MetaMask.
Deployment Screenshot https://github.com/Jemjem01/Real-Time-BlockChain-Crowd-Funding-Application/blob/main/Evidence/Deployment%20Success.png?raw=true

### 2. Etherscan Verification
The contract is fully verified, allowing users to interact with the code directly on the block explorer.
Etherscan Verification https://github.com/Jemjem01/Real-Time-BlockChain-Crowd-Funding-Application/blob/main/Evidence/Contract%20on%20EtherScan.png?raw=true

### 3. Function Execution Testing
Testing the `createProject` function to ensure decentralized crowdfunding logic works as intended.
Testing Screenshot https://github.com/Jemjem01/Real-Time-BlockChain-Crowd-Funding-Application/blob/main/Evidence/Execution%20Test.png?raw=true




