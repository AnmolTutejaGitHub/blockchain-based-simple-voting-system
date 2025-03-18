## Blockchain-Based Voting System Smart Contract

Blockchain-based voting system smart contract where anyone can create a room and candidates can register to that room. The room has the following parameters:
```solidity
uint256 candidateRegisterationWindow;
uint256 votingStartTime;
uint256 votingEndTime;
```

The system also handles result declaration. 
</br>

uses chainlink automation for result declaration.

## deploying on anvil
```bash
     forge script script/DeployVoting.s.sol --rpc-url http://127.0.0.1:8545 --broadcast --private-key <PRIVATE_KEY>
```

## deployed on sepolia at : 
```
Contract Address: 0x85ADA3d330FEdD53d5F65B6f99cD8F89b04f5300
	•	Transaction Hash: 0x0158bf2734b57e59c2762b9a6486fd07a3a5848ed9b213f2195977ef86233e47
	•	Block Number: 7928395
	•	Gas Used: 1067485
	•	Gas Price: ~3.90 gwei
	•	Total Cost: 0.004158857755354065 ETH
```

## note : Not funded chainlink automation so need to call declareResult manually for now 

