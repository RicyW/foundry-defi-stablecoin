// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DecentralisedStableCoin} from "../../src/DecentralisedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import { MockV3Aggregator } from "../mocks/MockV3Aggregator.sol";


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
    uint256 amountDscToMint = 100 ether;

    modifier depositedCollateral() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);
        dsce.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

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

    function testRevertWithUnapprovedCollateral() public {
        ERC20Mock ranToken = new ERC20Mock("RAN", "RAN", USER, AMOUNT_COLLATERAL);
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngineError_NotAllowedToken.selector);
        dsce.depositCollateral(address(ranToken), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    function testCanDepositCollateralAndGetAccountInfo() public depositedCollateral {
        // 1. check user status and see how much of DSC and collateral the xuser has, in this case we are testing deposit 
        // collateral and get account info so the total DSC minted should be 0
        // 2. since the usr is going to deposit collateral, then we need getTokenAmountFromUsd to know
        // how much collateral in USD is going to be deposited
        (uint256 totalDscMinted, uint collateralValueInUsd) = dsce.getTotalAmountMintedDSCAndTotalCollateralValue(USER);
        // @note this line of code might need a bit more rethinking to fully understand it
        uint256 expectedDepositedAmount = dsce.getTokenAmountFromUsd(weth, collateralValueInUsd);
        assertEq(totalDscMinted, 0);
        // @note understand better why here AMOUNT_COLLATERAL is the benchmark. video 3:09:33
        assertEq(AMOUNT_COLLATERAL, expectedDepositedAmount);
    }

    /////////////////////////////////////////
    //////////// Mint DSC Test //////////////
    /////////////////////////////////////////

    function testRevertIfMintFailed() public depositedCollateral {

    }

    function testIfMintAmountIsZero() public depositedCollateral {
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngineError_MustBeGreaterThanZero.selector);
        dsce.mintDSC(0);
        vm.stopPrank();
    }

    function testCanMintDSC() public depositedCollateral {
        vm.startPrank(USER);
        uint256 totalDscMinted = dsc.balanceOf(USER);
        dsce.mintDSC(amountDscToMint); 
        uint256 newTotalDscMinted = dsc.balanceOf(USER);
        assertEq(newTotalDscMinted, (totalDscMinted+amountDscToMint));
        vm.stopPrank();
    }

    function testRevertIfHealthFactorBelowThreshold() public view {
        // this is applicable to both function mintDSC and depositCollateralandMintDSC
        // because only when mintDSC is called, the health factor can be broken

        // know the price of the eth/USD ✅
        // know the amount of collateral deposited - this is one of assumptions✅
        // first figure out the max to mint, it is supposed to be 200% overcollateralized
        // then mint a number which is greater than the max to mint
        (, int256 price,,,) = MockV3Aggregator(ethUsdPriceFeed).latestRoundData();
        correctedAmountCollateral = AMOUNT_COLLATERAL * int256(price) * dsce.getAdditionalFeedPrecision();


    // Calculate the value of the collateral in USD
        uint256 collateralValue =  / dsce.getPrecision();

    // Calculate the maximum amount to mint based on a 200% overcollateralization requirement
        uint256 maxAmountToMint = collateralValue / 2;




    }

    

    


}

    