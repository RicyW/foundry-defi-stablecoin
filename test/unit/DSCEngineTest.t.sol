// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DecentralisedStableCoin} from "../../src/DecentralisedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
// import { ERC20Mock } from "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import { ERC20Mock } from "../mocks/ERC20Mock.sol";
import { MockV3Aggregator } from "../mocks/MockV3Aggregator.sol";
import { MockMoreDebtDSC } from "../mocks/MockMoreDebtDSC.sol";
import { StdCheats } from "forge-std/StdCheats.sol";


contract DSCEngineTest is StdCheats, Test {
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
    uint256 amountDscToBurn = 99 ether;

    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    // Liquidation
    address public liquidator = makeAddr("liquidator");
    uint256 public collateralToCover = 20 ether;

    modifier depositedCollateral() {
        //The collateral is held by the contract, not the user: When collateral
        // is deposited, it's typically transferred from the user's account to the contract. 
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);
        dsce.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    modifier depositedCollateralAndMintedDsc() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);
        dsce.depositCollateralAndMintDSC(weth, AMOUNT_COLLATERAL, amountDscToMint);
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
    // @note this is not done yet
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

    function testRevertIfHealthFactorBelowThreshold() public {
        // this is applicable to both function mintDSC and depositCollateralandMintDSC
        // because only when mintDSC is called, the health factor can be broken

        // know the price of the eth/USD ✅
        // know the amount of collateral deposited - this is one of assumptions✅
        // first figure out the max to mint, it is supposed to be 200% overcollateralized
        // then mint a number which is greater than the max to mint
        // (, int256 price,,,) = MockV3Aggregator(ethUsdPriceFeed).latestRoundData();
        // correctedAmountCollateral = AMOUNT_COLLATERAL * int256(price) * dsce.getAdditionalFeedPrecision();
         (, int256 price,,,) = MockV3Aggregator(ethUsdPriceFeed).latestRoundData();
        amountDscToMint = (AMOUNT_COLLATERAL * (uint256(price) * dsce.getAdditionalFeedPrecision())) / dsce.getPrecision();
        vm.startPrank(USER);

        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);

        uint256 expectedHealthFactor =
            dsce.calculateHealthFactor(amountDscToMint, dsce.getUsdValue(weth, AMOUNT_COLLATERAL));
        console.log("expectedHealthFactor", expectedHealthFactor);
        console.log("amountDscToMint", amountDscToMint);
        console.log("AMOUNT_COLLATERAL", AMOUNT_COLLATERAL);
        
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngineError_BreaksHealthFactor.selector, expectedHealthFactor));
        dsce.depositCollateralAndMintDSC(weth, AMOUNT_COLLATERAL, amountDscToMint);
        vm.stopPrank();
    }   
    /////////////////////////////////////////
    //////////// Burn DSC Test //////////////
    /////////////////////////////////////////

    function testRevertIfBurnAmountIsZero() public {
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngineError_MustBeGreaterThanZero.selector);
        dsce.burnDSC(0);
        vm.stopPrank();
    }

    function testCantBurnMoreThanUserHas() public {
        vm.prank(USER);
        vm.expectRevert();
        dsce.burnDSC(1);
    }

    function testCanBurnDSC() public depositedCollateralAndMintedDsc {
        vm.startPrank(USER);
        dsc.approve(address(dsce), amountDscToMint);
        uint256 totalDscMinted = dsc.balanceOf(USER);
        dsce.burnDSC(amountDscToBurn);
        uint256 newTotalDscMinted = dsc.balanceOf(USER);
        assertEq(newTotalDscMinted, (totalDscMinted-amountDscToBurn));
        vm.stopPrank();
    }

    /////////////////////////////////////////
    ////// Redeem Collateral Test ///////////
    /////////////////////////////////////////

    function testIfRedeemZeroCollateral() public {
        ERC20Mock ETHToken = new ERC20Mock("ETH", "ETH", USER, AMOUNT_COLLATERAL);
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngineError_MustBeGreaterThanZero.selector);
        dsce.redeemCollateral(address(ETHToken), 0);
        vm.stopPrank();
    }

    function testIfRedeemDisallowedToken() public {
        ERC20Mock ranToken = new ERC20Mock("Ran", "Ran", USER, AMOUNT_COLLATERAL);
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngineError_NotAllowedToken.selector);
        dsce.redeemCollateral(address(ranToken), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    function testCanRedeemCollateral() public depositedCollateral {
        // depostiedCollateral will deposit the collateral to the contract
        // userBalance will be 0. The contract address held the collateral to mint DSC
        vm.startPrank(USER);
        dsce.redeemCollateral(weth, AMOUNT_COLLATERAL);
        uint256 newUserBalance = ERC20Mock(weth).balanceOf(USER);
        assertEq(newUserBalance, AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    // @note this is not done yet
    function testRevertIfRedeemFailed() public {}


    ///////////////////////////////////
    // redeemCollateralForDsc Tests //
    //////////////////////////////////

    function testMustRedeemMoreThanZero() public depositedCollateralAndMintedDsc{
        vm.startPrank(USER);
        dsc.approve(address(dsce), amountDscToMint);
        vm.expectRevert(DSCEngine.DSCEngineError_MustBeGreaterThanZero.selector);
        dsce.redeemCollateralForDSC(weth, 0, (amountDscToMint));
        vm.stopPrank();
    }

    function testCanRedeemDepositedCollateral() public depositedCollateralAndMintedDsc{
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);
        dsc.approve(address(dsce), amountDscToMint);
        dsce.redeemCollateralForDSC(weth, AMOUNT_COLLATERAL, (amountDscToMint));
        vm.stopPrank();
        uint256 userBalance = dsc.balanceOf(USER);
        assertEq(userBalance, 0);
    }

    ///////////////////////////////////////
    //////////// liquidate Tests //////////
    ///////////////////////////////////////

    modifier liquidated() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);
        dsce.depositCollateralAndMintDSC(weth, AMOUNT_COLLATERAL, amountDscToMint);
        vm.stopPrank();
        int256 ethUsdUpdatedPrice = 18e8; // 1 ETH = $18

        MockV3Aggregator(ethUsdPriceFeed).updateAnswer(ethUsdUpdatedPrice);
        uint256 userHealthFactor = dsce.getHealthFactor(USER);

        ERC20Mock(weth).mint(liquidator, collateralToCover);

        vm.startPrank(liquidator);
        ERC20Mock(weth).approve(address(dsce), collateralToCover);
        dsce.depositCollateralAndMintDSC(weth, collateralToCover, amountDscToMint);
        dsc.approve(address(dsce), amountDscToMint);
        dsce.liquidate(weth, USER, amountDscToMint); // We are covering their whole debt
        vm.stopPrank();
        _;
    }

    function testMustImproveHealthFactorOnLiquidation() public {
        // Arrange - Setup
        MockMoreDebtDSC mockDsc = new MockMoreDebtDSC(ethUsdPriceFeed);
        tokenAddresses = [weth];
        priceFeedAddresses = [ethUsdPriceFeed];
        address owner = msg.sender;
        vm.prank(owner);
        DSCEngine mockDsce = new DSCEngine(tokenAddresses, priceFeedAddresses, address(mockDsc));
        mockDsc.transferOwnership(address(mockDsce));
        // Arrange - User
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(mockDsce), AMOUNT_COLLATERAL);
        mockDsce.depositCollateralAndMintDSC(weth, AMOUNT_COLLATERAL, amountDscToMint);
        vm.stopPrank();

        // Arrange - Liquidator
        collateralToCover = 1 ether;
        ERC20Mock(weth).mint(liquidator, collateralToCover);

        vm.startPrank(liquidator);
        ERC20Mock(weth).approve(address(mockDsce), collateralToCover);
        uint256 debtToCover = 10 ether;
        mockDsce.depositCollateralAndMintDSC(weth, collateralToCover, amountDscToMint);
        mockDsc.approve(address(mockDsce), debtToCover);
        // Act
        int256 ethUsdUpdatedPrice = 18e8; // 1 ETH = $18
        MockV3Aggregator(ethUsdPriceFeed).updateAnswer(ethUsdUpdatedPrice);
        // Act/Assert
        vm.expectRevert(DSCEngine.DSCEngineError_HealthFactorNotImproved.selector);
        mockDsce.liquidate(weth, USER, debtToCover);
        vm.stopPrank();
    }


    function testDebtMustBeGreaterThanZero() public depositedCollateral {
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngineError_MustBeGreaterThanZero.selector);
        dsce.liquidate(USER, weth, 0);
        vm.stopPrank();
    }


    function testLiquidationTakesAllDebt() public liquidated {
        (uint256 userDscBalance,) = dsce.getTotalAmountMintedDSCAndTotalCollateralValue(USER);
        assertEq(userDscBalance, 0);
    }

    function testLiquidatorTakesOnUsersDebt() public liquidated {
        (uint256 liquidatorDscMinted,) = dsce.getTotalAmountMintedDSCAndTotalCollateralValue(liquidator);
        assertEq(liquidatorDscMinted, amountDscToMint);
    }







    

    


}

    