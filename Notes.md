This document records how test is implemented and the coverage. The key functions are in DSCEngine. There are 17 functions:

depositCollateralAndMintDSC
depositCollateral[tested]
redeemCollateralForDSC[tested]
redeemCollateral[tested]
mintDSC[tested]
burnDSC[tested]
liquidate[tested]
getHealthFactor[tested]
\_burnDSC[tested]
\_redeemCollateral[tested]
\_getTotalAmountMintedDSCAndTotalCollateralValue[tested]
\_healthFactor[tested]
\_revertIfHealthFactorBelowThreshold[tested]
getTotalCollateralValueInUsd
getUsdValuep[tested]
getTokenAmountFromUsd[tested]
getTotalAmountMintedDSCAndTotalCollateralValue[tested]
error DSCEngineError_MustBeGreaterThanZero();[tested]
error DSCEngineError_TokenAddressAndPriceFeedAddressMustMatch();[tested]
error DSCEngineError_NotAllowedToken();[tested]
error DSCEngineError_TokenTransferFailed();
error DSCEngineError_BreaksHealthFactor(uint256 healthFactor);[tested]
error DSCEngineError_MintFailed();
error DSCEngineError_CollateralRedeemFailed();
error DSCEngineError_DSCBurnFailed();
error DSCEngineError_HealthFactorOk();[tested]
error DSCEngineError_HealthFactorNotImproved();

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
