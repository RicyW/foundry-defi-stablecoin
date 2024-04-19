// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DecentralisedStableCoin} from "../../src/DecentralisedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/ERC20Mock.sol";


contract DSCEngineTest is Test {
    DeployDSC deployer;
    DecentralisedStableCoin dsc;
    DSCEngine dsce;
    HelperConfig config;
    ERC20Mock wethToken;
    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address weth;
    address public USER = makeAddr("user");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether; 
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether; 

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, dsce, config) = deployer.run();
        (ethUsdPriceFeed,, weth,,) = config.activeNetworkConfig();
        ERC20Mock(weth).mint(address(USER), STARTING_ERC20_BALANCE);
    }
    /////////////////////////////////////////
    //////////Constrcutor Test //////////////
    /////////////////////////////////////////
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;
    
    function testRevertIfTokenLengthDoesntMatchPriceFeeds() public {
        tokenAddresses.push(weth);
        priceFeedAddresses.push(ethUsdPriceFeed);
        priceFeedAddresses.push(btcUsdPriceFeed);
        vm.expectRevert(DSCEngine.DSCEngineError_TokenAddressAndPriceFeedAddressMustMatch.selector);
        new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
    }

    /////////////////////////////////////////
    /////////////// Price Test //////////////
    /////////////////////////////////////////
    function testGetUsdValue() public view {
        uint256 ethAmount = 15e18;
        //15e8 * 2000 ETH = 30000e8
        uint256 expectedUsd = 30000e18;
        uint256 actualUsd = dsce.getUsdValue(weth, ethAmount);
        assertEq(expectedUsd, actualUsd);
    }

    function testGetTokenAmountFromUsd() public view {
        uint256 usdAmount = 100 ether;
        // $2000, ETH/ $100 = 0.05 ETH
        uint256 expectedWth = 0.05 ether;
        uint256 actualWth = dsce.getTokenAmountFromUsd(weth, usdAmount);
        assertEq(expectedWth,actualWth);
    }

    /////////////////////////////////////////
    ////// Deposite Collateral Test /////////
    /////////////////////////////////////////
    function testRevertIfCollateralAmountIsZero() public {
        // setting up the testing environment to simulate actions from the USER account. After calling this function, subsequent actions might be executed as if they were initiated by USER.
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);
        vm.expectRevert(DSCEngine.DSCEngineError_MustBeGreaterThanZero.selector);
        dsce.depositCollateral(weth, 0);
        vm.stopPrank();

    }
}