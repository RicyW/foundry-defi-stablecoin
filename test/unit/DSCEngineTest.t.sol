// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeplyDSC} from "../../script/DeployDSC.s.sol";
import {DecentralisedStableCoin} from "../../src/DecentralisedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DecentralisedStableCoin dsc;
    DSCEngine engine;
    HelperConfig config;
    address ethUsdPriceFeed;
    address weth;

    function Setup() public {
        deployer = new DeployDSC();
        (dsc. engine, config) = deployer.run();
        (ethUsdPriceFeed, weth, , , ) = config.activeNetworkConfig();
    }

    /////////////////////////////////////////
    /////////////// Price Test //////////////
    /////////////////////////////////////////
    function testGetWethAddress() public {
        uint256 ethAmount = 15e18;
        //15e8 * 2000 ETH = 30000e8
        uint256 expectedUsd = 30000e8;
        uint256 actualUsd = engine.getUsdAmount(weth, ethAmount);
        assertEq(expectedUsd, actualUsd);
    }
}