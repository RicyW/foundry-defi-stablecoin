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
