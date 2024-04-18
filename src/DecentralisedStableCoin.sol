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
* @title Decentralised Stable Coin
* @author ZinaW
* Collateral: ETC/BTC (Exogenous)
* Minting: Algorithmic
* Relative Stability: Pegged to USD
* This contract is going to be governed by a DSCEngine. It's the ERC20 implemention of our stablecoin.
*/

pragma solidity ^0.8.18;

import {ERC20Burnable, ERC20} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract DecentralisedStableCoin is ERC20Burnable, Ownable {
    error DencentralisedStableCoinError_MustBeGreaterThanZero();
    error DecentralisedStableCoinError_BurnAmountExceedsBalance();
    error DecentralisedStableCoinError_NotZeroAddress();

    constructor() ERC20("DecentralisedStableCoin", "DSC") {}

    // public means that it can be called from outside the contract
    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert DencentralisedStableCoinError_MustBeGreaterThanZero();
        }
        if (_amount > balance) {
            revert DecentralisedStableCoinError_BurnAmountExceedsBalance();
        }
        super.burn(_amount);
    }

    // external means that it can be called from outside the contract
    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            // address(0) is the zero address, uninitialized address which no one has private key for.
            revert DecentralisedStableCoinError_NotZeroAddress();
        }
        if (_amount <= 0) {
            revert DencentralisedStableCoinError_MustBeGreaterThanZero();
        }
        _mint(_to, _amount);
        return true; // this only happens when the minting is successful
    }
}
