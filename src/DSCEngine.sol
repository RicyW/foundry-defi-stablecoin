// SPDX-License-Identifier: MIT

// This is considered an Exogenous, Decentralized, Anchored (pegged), Crypto Collateralized low volitility coin

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions


/*
* @title DSC Engine
* @author ZinaW
* This system is designed to be as minimal as possible, and have the token maintained by 1 token == 1 USD peg.
* The stablecoin has the properties of 
* exogenous collateral
* dollar pegged
* algorithmic stable
* It is similar to DAI stablecoin if DAI has no governance no fees and backed by WBTC/WETH.
* @notice The is the core of the DSC system. It handles all the logic of mining, redeeming DSC, as well as deposting and withdrawing collateral.
* This constract is very loosely based on MAKER DAO's DAI stablecoin.
*/

pragma solidity ^0.8.18;

import {DecentralisedStableCoin} from "./DecentralisedStableCoin.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


contract DSCEngine is ReentrancyGuard {
    //////////////////////////////////////////////////////////////
    ///////////////////    Error      ////////////////////////////
    //////////////////////////////////////////////////////////////
    error DSCEngineError_MustBeGreaterThanZero();
    error DSCEngineError_TokenAddressAndPriceFeedAddressMustMatch();
    error DSCEngineError_NotAllowedToken();
    error DSCEngineError_TokenTransferFailed();
    error DSCEngineError_BreaksHealthFactor(uint256 healthFactor);
    error DSCEngineError_MintFailed();
    error DSCEngineError_CollateralRedeemFailed();
    error DSCEngineError_DSCBurnFailed();
    error DSCEngineError_HealthFactorOk();
    error DSCEngineError_HealthFactorNotImproved();

    //////////////////////////////////////////////////////////////
    ///////////////////State Variables////////////////////////////
    //////////////////////////////////////////////////////////////
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; //200% overcollateralized
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;
    uint256 private constant LIQUIDATION_BONUS = 10; // this means10% bonus for liquidating a user

    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDesposited;
    mapping(address user => uint256 amountMintedDSC) private s_mintedDSC;
    DecentralisedStableCoin private immutable i_dsc;
    address[] private s_collateralTokens; 

    //////////////////////////////////////////////////////////////
    ///////////////////       Event      /////////////////////////
    //////////////////////////////////////////////////////////////
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);
    event CollateralRedeemed(address indexed redeemedFrom, address indexed redeemedTo, address indexed token, uint256 amount);
    //////////////////////////////////////////////////////////////
    ///////////////////    Modifier      /////////////////////////
    //////////////////////////////////////////////////////////////

    modifier moreThanZero(uint256 amount) {
        if (amount <= 0) {
            revert DSCEngineError_MustBeGreaterThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert DSCEngineError_NotAllowedToken();
        }
        _;
    }

    //////////////////////////////////////////////////////////////
    ///////////////////    Functions      ////////////////////////
    //////////////////////////////////////////////////////////////
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address dscAddress) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngineError_TokenAddressAndPriceFeedAddressMustMatch();}
        for (uint i = 0; i < tokenAddresses.length; i++) {
            // for example ETH/USD, BTC/USD, MKR/USD price feed
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(tokenAddresses[i]);
        }
        i_dsc = DecentralisedStableCoin(dscAddress);
    }


    //////////////////////////////////////////////////////////////
    ///////////////////External Functions ////////////////////////
    //////////////////////////////////////////////////////////////
    /*
    * @param tokenCollateralAddress The address of the token to be deposited as collateral
    * @param amountCollatral The amount of the token to be deposited as collateral
    * @param amountDscToMint The amount of DSC to mint
    * @notice This function is a convenience function that allows the user to deposit collateral and mint DSC in one transaction.
    */
    function depositCollateralAndMintDSC(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        uint256 amountDscToMint
    ) external {
        depositCollateral(tokenCollateralAddress, amountCollateral);
        mintDSC(amountDscToMint);
    }

    /*
    * @param tokenCollateralAddress The address of the token to be deposited as collateral
    * @param amountCollatral The amount of the token to be deposited as collateral
    */

    function depositCollateral(
        address tokenCollateralAddress,
        uint amountCollateral
    ) public 
      moreThanZero(amountCollateral) 
      isAllowedToken(tokenCollateralAddress) 
      nonReentrant 
    {
    //increasing the amount of the specified token that the sender has deposited as collateral
        s_collateralDesposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if (!success) {
            revert DSCEngineError_TokenTransferFailed();
        }
    }
    // CEI: check, effects and interactions

    /*
    * @param tokenCollateralAddress The address of the token to be redeemed
    * @param amountCollateral The amount of the token to be redeemed
    * @param amountDscToBurn The amount of DSC to burn
    * @notice This function is a convenience function that allows the user to redeem collateral and burn DSC in one transaction.
    */
    function redeemCollateralForDSC(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountDscToBurn) public {
        burnDSC(amountDscToBurn);
        redeemCollateral(tokenCollateralAddress, amountCollateral);
        // redeem collateral already checks the health factor
    }
        

    function redeemCollateral(
        address tokenCollateralAddress, 
        uint256 amountCollateral) 
        public 
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant 
        {
            _redeemCollateral(msg.sender, msg.sender, tokenCollateralAddress, amountCollateral);
            // _revertIfHealthFactorBelowThreshold(msg.sender);
    }

    /*
    * @param amountDscToMint The amount of DSC to mint
    * @notice The collateral must be deposited before calling this function and the collateral must be greater than minimal threshold. 
    */
    function mintDSC(uint256 amountDscToMint) public moreThanZero(amountDscToMint) nonReentrant {
        s_mintedDSC[msg.sender] += amountDscToMint;
        // if they minted too much: $150 DSC and $100 ETH
        _revertIfHealthFactorBelowThreshold(msg.sender);
        bool minted = i_dsc.mint(msg.sender, amountDscToMint);
        if (minted != true) {
            revert DSCEngineError_MintFailed();
        }
    }

    function burnDSC(uint256 amountDscToBurn) public moreThanZero(amountDscToBurn) {
        _burnDSC(amountDscToBurn, msg.sender, msg.sender);
        _revertIfHealthFactorBelowThreshold(msg.sender); //@note you probably won't need it before burning DSC probably will not break the health factor

    }
    /*
    * @param tokenCollateralAddress The address of the token to be liquidated
    * @param user The address of the user to be liquidated, who breaks the liquidation threshold and the health factor is below threshold
    * @param debtToCover The amount of DSC to be burned to improve the user health factor
    * @notice you can partially liquidate a user
    * @notice you can get a liquidation bonus (10%) for liquidating a user
    * @notice this functions working assumes that the user is 200% overcollateralized
    */
    function liquidate(address tokenCollateralAddress, address user, uint256 debtToCover) external moreThanZero(debtToCover) nonReentrant {
        uint256 startingUserHealthFactor = _healthFactor(user);
        if (startingUserHealthFactor >= MIN_HEALTH_FACTOR) {
            revert DSCEngineError_HealthFactorOk();
        }
        // we want to burn the DSC 
        // then take their collateral
        uint256 tokenAmountDebtCovered = getTokenAmountFromUsd(tokenCollateralAddress, debtToCover);
        uint256 bonusCollateral = (tokenAmountDebtCovered * LIQUIDATION_BONUS) / PRECISION;
        uint256 totalCollateralToRedeem = tokenAmountDebtCovered + bonusCollateral;

        _redeemCollateral(user, msg.sender, tokenCollateralAddress, totalCollateralToRedeem);
        _burnDSC(debtToCover, user, msg.sender);
        uint256 endingUserHealthFactor = _healthFactor(user);
        if (endingUserHealthFactor <= startingUserHealthFactor) {
            revert DSCEngineError_HealthFactorNotImproved();
        }
        _revertIfHealthFactorBelowThreshold(msg.sender);
    }

    function getHealthFactor() external {}


    //////////////////////////////////////////////////////////////
    ////////////Private/Internal View Functions///////////////////
    //////////////////////////////////////////////////////////////
    function _burnDSC(uint256 amountDscToBurn, address onBehalfOf, address dscFrom) private {
        s_mintedDSC[onBehalfOf] -= amountDscToBurn;
        //If the contract tried to burn the tokens directly from the user's account without transferring them first, the burn operation would fail because the contract doesn't own the tokens.
        bool success = i_dsc.transferFrom(dscFrom, address(this),amountDscToBurn);
        if (!success) {
            revert DSCEngineError_DSCBurnFailed();
        }
        i_dsc.burn(amountDscToBurn);
    }

    function _redeemCollateral (address from, address to, address tokenCollateralAddress, uint256 amountCollateral) private {
        s_collateralDesposited[from][tokenCollateralAddress] += amountCollateral;
        emit CollateralRedeemed(from, to, tokenCollateralAddress, amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transfer(to, amountCollateral);
        if (!success) {
            revert DSCEngineError_TokenTransferFailed();
    }
    }


    function _getTotalAmountMintedDSCAndTotalCollateralValue(address user) private view returns(uint256 totalAmountMintedDSC, uint256 totalCollateralValueInUsd) {
        totalAmountMintedDSC = s_mintedDSC[user];
        totalCollateralValueInUsd = getTotalCollateralValueInUsd(user);
    }
    
    /*
    * Return how close the user is to being liquidated. If it is below 1, the user will be liquidated.
    */
    
    function _healthFactor(address user) private view returns(uint256) {
        (uint256 totalAmountMintedDSC, uint256 totalCollateralValueInUsd) = _getTotalAmountMintedDSCAndTotalCollateralValue(user);
        uint256 collateralAdjustedForThreshold = (totalCollateralValueInUsd * LIQUIDATION_PRECISION) / LIQUIDATION_THRESHOLD;
        return (collateralAdjustedForThreshold * PRECISION) / totalAmountMintedDSC;
    }
    
    function _revertIfHealthFactorBelowThreshold(address user) internal view {
        uint256 userHealthFactor = _healthFactor(user);
        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngineError_BreaksHealthFactor(userHealthFactor);
        }
    }

    //////////////////////////////////////////////////////////////
    ///////////////////Public & External View Functions///////////
    //////////////////////////////////////////////////////////////
    // this function is to see how much collateral the user has deposited and the value of the collateral in USD. This is used as part of _getTotalAmountMintedDSCAndTotalCollateralValue to know user account status
    function getTotalCollateralValueInUsd(address user) public view returns(uint256 totalCollateralValueInUsd){
        //loop through the collateral tokens, get the amount they have deposit. map it to the price and get the value of each token in USD
        for(uint256 i = 0; i<s_collateralTokens.length; i++){
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDesposited[user][token];
            totalCollateralValueInUsd += getUsdValue(token, amount);
        } 
        return totalCollateralValueInUsd;
    }

    // this function is to get the value of the token in USD. So it is a subset of the above function: getTotalCollateralValueInUsd
    function getUsdValue(address token, uint256 amount) public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (,int256 price,,,) = priceFeed.latestRoundData();    
        // 1ETH = 1000 USD
        // The returned value from chainlink will be 1000 * 1e8
        // 1e8 = 10^8 = 100000000
        // @note I don't fully understand how the precision is tunned 
        return ((uint256(price) * ADDITIONAL_FEED_PRECISION) * amount)/ PRECISION;
    }

    // this function is to get the amount of token from USD. The difference between this function and getTotalCollateralValueInUsd is that this function is used before depositing collateral. This function can be used to know how much of a specific token you can buy based on the market price. 
    function getTokenAmountFromUsd(address tokenColleralAddress, uint256 usdAmountInWei) public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[tokenColleralAddress]);
        (,int256 price,,,) = priceFeed.latestRoundData();
        // first you figure out conversion between usd and wei
        // then you know based on this usd you have and this price of the
        // token, how much of the token you can buy
        // so let usd in wei to be divided by the price of the token
        return ((usdAmountInWei * PRECISION) / (uint256(price) * ADDITIONAL_FEED_PRECISION));
    }

    // this function is more like an overview of all assets in the user account. It is used to know the user account status. 
    function getTotalAmountMintedDSCAndTotalCollateralValue(address user) external view returns(
        uint256 totalAmountMintedDSC, 
        uint256 totalCollateralValueInUsd) {
        (totalAmountMintedDSC, totalCollateralValueInUsd) = _getTotalAmountMintedDSCAndTotalCollateralValue(user);
    }

    function getPrecision() external pure returns (uint256) {
        return PRECISION;
    }

    function getAdditionalFeedPrecision() external pure returns (uint256) {
        return ADDITIONAL_FEED_PRECISION;
    }

    function getLiquidationThreshold() external pure returns (uint256) {
        return LIQUIDATION_THRESHOLD;
    }

    function getLiquidationBonus() external pure returns (uint256) {
        return LIQUIDATION_BONUS;
    }

    function getLiquidationPrecision() external pure returns (uint256) {
        return LIQUIDATION_PRECISION;
    }

    function getMinHealthFactor() external pure returns (uint256) {
        return MIN_HEALTH_FACTOR;
    }
}
