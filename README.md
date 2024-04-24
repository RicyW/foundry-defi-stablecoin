This repo aims to develop a stablecoin and understand the key concepts of DeFi during implementation. The ultimate goal is the lay foundations for future smart contract auditing projects.

Key charateristics of the stablecoin in this project:

1. Relative Stability: Anchored or Pegged -> $1.00
   1. Chainlink price feed
   2. Set a function to exchange ETC/BTC
2. Stability Mechanism: Algorithmic (decentralised)
   1. Ppl only mint the stablecoin with enough collateral
3. Collateral: exogenous (crypto)
   1.ETH
   2.BTC

The new knowledge learned in this project [total time spent:2w]:

- **Programming**: Solidity(fun!)
- **Foundry Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: For interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Theory**: How stablecoin works, how the price is calculated, how to get the updated price feed, how to liquidate a user and how could users get bonus in a stablecoin system.
- **Testing**: How to write unit test and fuzzing test in solidity. And briefly touched base mock test.
- **Comment**: Develop a mature code style with clear comments

Because the purpose of this project is not to deep dive into how to develop in solidity and make a mature product, but to understand key product in DeFi and familiarise myself with DeFi technologies and theories for future smart contract audit. The project reached the goal when `forge coverage` showed more than 80% of DSCEngine.sol, which is the core of the project, has been tested.

| File                            | % Lines          | % Statements     | % Branches     | % Funcs        |
| ------------------------------- | ---------------- | ---------------- | -------------- | -------------- |
| script/DeployDSC.s.sol          | 100.00% (10/10)  | 100.00% (14/14)  | 100.00% (0/0)  | 100.00% (1/1)  |
| script/HelperConfig.s.sol       | 0.00% (0/10)     | 0.00% (0/17)     | 0.00% (0/2)    | 0.00% (0/2)    |
| src/DSCEngine.sol               | 84.21% (64/76)   | 87.13% (88/101)  | 68.75% (11/16) | 75.86% (22/29) |
| src/DecentralisedStableCoin.sol | 66.67% (8/12)    | 71.43% (10/14)   | 50.00% (4/8)   | 100.00% (2/2)  |
| test/fuzz/Handler.t.sol         | 93.75% (15/16)   | 95.00% (19/20)   | 75.00% (3/4)   | 100.00% (3/3)  |
| test/fuzz/InvariantsTest.t.sol  | 35.71% (5/14)    | 26.32% (5/19)    | 0.00% (0/2)    | 50.00% (1/2)   |
| test/mocks/ERC20Mock.sol        | 0.00% (0/4)      | 0.00% (0/4)      | 100.00% (0/0)  | 0.00% (0/4)    |
| test/mocks/MockMoreDebtDSC.sol  | 69.23% (9/13)    | 73.33% (11/15)   | 50.00% (4/8)   | 100.00% (2/2)  |
| test/mocks/MockV3Aggregator.sol | 46.67% (7/15)    | 46.67% (7/15)    | 100.00% (0/0)  | 40.00% (2/5)   |
| Total                           | 69.41% (118/170) | 70.32% (154/219) | 55.00% (22/40) | 66.00% (33/50) |

The original tutorial (5h) is here: https://www.youtube.com/watch?v=8dRAd-Bzc_E, from Patrick Collins (Cyfrin).
