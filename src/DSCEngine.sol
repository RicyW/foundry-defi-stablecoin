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
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
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

    //////////////////////////////////////////////////////////////
    ///////////////////State Variables////////////////////////////
    //////////////////////////////////////////////////////////////
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; //200% overcollateralized
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1;

    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDesposited;
    mapping(address user => uint256 amountMintedDSC) private s_mintedDSC;
    DecentralisedStableCoin private immutable i_dsc;
    address[] private s_collateralTokens; 

    //////////////////////////////////////////////////////////////
    ///////////////////       Event      /////////////////////////
    //////////////////////////////////////////////////////////////
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);

    //////////////////////////////////////////////////////////////
    ///////////////////    Modifier      /////////////////////////
    //////////////////////////////////////////////////////////////

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
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
    function depositCollateralAndMintDSC() external {}

    /*
    * @param tokenCollateralAddress The address of the token to be deposited as collateral
    * @param amountCollatral The amount of the token to be deposited as collateral
    */

    function depositCollateral(
        address tokenCollateralAddress,
        uint amountCollatral
    ) external 
      moreThanZero(amountCollatral) 
      isAllowedToken(tokenCollateralAddress) 
      nonReentrant 
    {
    //increasing the amount of the specified token that the sender has deposited as collateral
        s_collateralDesposited[msg.sender][tokenCollateralAddress] += amountCollatral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollatral);
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollatral);
        if (!success) {
            revert DSCEngineError_TokenTransferFailed();
        }
    }

    function redeemCollateralForDSC() external {}

    function redeemCollateral() external {}

    /*
    * @param amountDscToMint The amount of DSC to mint
    * @notice The collateral must be deposited before calling this function and the collateral must be greater than minimal threshold. 
    */
    function mintDSC(uint256 amountDscToMint) external moreThanZero(amountDscToMint) nonReentrant {
        s_mintedDSC[msg.sender] += amountDscToMint;
        _revertIfHealthFactorBelowThreshold(msg.sender);
    }

    function burnDSC() external {}

    function liquidate() external {}

    function getHealthFactor() external {}


    //////////////////////////////////////////////////////////////
    ///////////////////Internal View Functions////////////////////
    //////////////////////////////////////////////////////////////
    function _getTotalAmountMintedDSCAndTotalCollateralValue(address user) private view returns (uint256 totalAmountMintedDSC, uint256 totalCollateralValueInUsd) {
        totalAmountMintedDSC = s_mintedDSC[user];
        totalCollateralValueInUsd = getTotalCollateralValueInUsd(user);
    }
    
    /*
    * Return how close the user is to being liquidated. If it is below 1, the user will be liquidated.
    */
    
    function _healthFactor(address user) internal view returns (uint256) {
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
    function getTotalCollateralValueInUsd(address user) public view returns(uint256 totalCollateralValueInUsd){
        //loop through the collateral tokens, get the amount they have deposit. map it to the price and get the value of each token in USD
        for(uint256 i = 0; i<s_collateralTokens.length; i++){
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDesposited[user][token];
            totalCollateralValueInUsd += getUsdValue(token, amount);
        } 
        return totalCollateralValueInUsd;
    }

    function getUsdValue(address token, uint256 amount) public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (,int256 price,,,) = priceFeed.latestRoundData();
        // 1ETH = 1000 USD
        // The returned value from chainlink will be 1000 * 1e8
        // 1e8 = 10^8 = 100000000
        return (uint256(price) * ADDITIONAL_FEED_PRECISION * amount)/ PRECISION;
    }
}