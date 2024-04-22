This document records how test is implemented and the coverage. The key functions are in DSCEngine. There are 17 functions:

depositCollateralAndMintDSC
depositCollateral[tested]
redeemCollateralForDSC
redeemCollateral
mintDSC
burnDSC
liquidate
getHealthFactor - empty

\_burnDSC
\_redeemCollateral
\_getTotalAmountMintedDSCAndTotalCollateralValue[tested]
\_healthFactor
\_revertIfHealthFactorBelowThreshold

getTotalCollateralValueInUsd
getUsdValuep[tested]
getTokenAmountFromUsd[tested]
getTotalAmountMintedDSCAndTotalCollateralValue[tested]

error DSCEngineError_MustBeGreaterThanZero();[tested]
error DSCEngineError_TokenAddressAndPriceFeedAddressMustMatch();[tested]
error DSCEngineError_NotAllowedToken();[tested]
error DSCEngineError_TokenTransferFailed();
error DSCEngineError_BreaksHealthFactor(uint256 healthFactor);
error DSCEngineError_MintFailed();
error DSCEngineError_CollateralRedeemFailed();
error DSCEngineError_DSCBurnFailed();
error DSCEngineError_HealthFactorOk();
error DSCEngineError_HealthFactorNotImproved();

Analysing contracts...[2024.04.19]
Running tests...
| File | % Lines | % Statements | % Branches | % Funcs |
|---------------------------------|-----------------|-----------------|---------------|---------------|
| script/DeployDSC.s.sol | 100.00% (10/10) | 100.00% (14/14) | 100.00% (0/0) | 100.00% (1/1) |
| script/HelperConfig.s.sol | 0.00% (0/10) | 0.00% (0/17) | 0.00% (0/2) | 0.00% (0/2) |
| src/DSCEngine.sol | 28.81% (17/59) | 31.65% (25/79) | 7.14% (1/14) | 29.41% (5/17) |
| src/DecentralisedStableCoin.sol | 0.00% (0/12) | 0.00% (0/14) | 0.00% (0/8) | 0.00% (0/2) |
| test/mocks/MockV3Aggregator.sol | 6.67% (1/15) | 6.67% (1/15) | 100.00% (0/0) | 20.00% (1/5) |
| Total | 26.42% (28/106) | 28.78% (40/139) | 4.17% (1/24) | 25.93% (7/27) |

---

depositCollateralAndMintDSC
depositCollateral[tested]
redeemCollateralForDSC
redeemCollateral
mintDSC[tested]
burnDSC[tested]
liquidate
getHealthFactor - empty
\_burnDSC[tested]
\_redeemCollateral
\_getTotalAmountMintedDSCAndTotalCollateralValue[tested]
\_healthFactor
\_revertIfHealthFactorBelowThreshold
getTotalCollateralValueInUsd
getUsdValuep[tested]
getTokenAmountFromUsd[tested]
getTotalAmountMintedDSCAndTotalCollateralValue[tested]
error DSCEngineError_MustBeGreaterThanZero();[tested]
error DSCEngineError_TokenAddressAndPriceFeedAddressMustMatch();[tested]
error DSCEngineError_NotAllowedToken();[tested]
error DSCEngineError_TokenTransferFailed();
error DSCEngineError_BreaksHealthFactor(uint256 healthFactor);
error DSCEngineError_MintFailed();
error DSCEngineError_CollateralRedeemFailed();
error DSCEngineError_DSCBurnFailed();
error DSCEngineError_HealthFactorOk();
error DSCEngineError_HealthFactorNotImproved();

| File                            | % Lines         | % Statements    | % Branches    | % Funcs        |
| ------------------------------- | --------------- | --------------- | ------------- | -------------- |
| script/DeployDSC.s.sol          | 100.00% (10/10) | 100.00% (14/14) | 100.00% (0/0) | 100.00% (1/1)  |
| script/HelperConfig.s.sol       | 0.00% (0/10)    | 0.00% (0/17)    | 0.00% (0/2)   | 0.00% (0/2)    |
| src/DSCEngine.sol               | 57.63% (34/59)  | 60.76% (48/79)  | 28.57% (4/14) | 64.71% (11/17) |
| src/DecentralisedStableCoin.sol | 66.67% (8/12)   | 71.43% (10/14)  | 50.00% (4/8)  | 100.00% (2/2)  |
| test/mocks/MockV3Aggregator.sol | 6.67% (1/15)    | 6.67% (1/15)    | 100.00% (0/0) | 20.00% (1/5)   |
| Total                           | 50.00% (53/106) | 52.52% (73/139) | 33.33% (8/24) | 55.56% (15/27) |
