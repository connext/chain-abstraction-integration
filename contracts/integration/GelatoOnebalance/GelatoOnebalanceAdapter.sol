// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IGelatoOneBalance} from "./interfaces/IGelatoOneBalance.sol";

contract GelatoOneBalanceAdapter {
    /// @notice Gelato1Balance contract for deposit
    IGelatoOneBalance public gelato1balance;

    constructor (address _gelato1balance){
        gelato1balance = IGelatoOneBalance(_gelato1balance);
    }

    /// @notice Deposit tokens for paying fees
    /// @param _sponsor The address of the sponsor
    /// @param _token The address of token to deposit
    /// @param _amount How many tokens to be deposited
    function depositTokens(address _sponsor, address _token, uint256 _amount) internal {
        require(_amount > 0, "Zero Amount");
        require(_sponsor != address(0), "Zero address");
        // Increasing the allowance 
        if (IERC20(_token).allowance(address(this), address(gelato1balance)) < _amount) {
          IERC20(_token).approve(address(gelato1balance), type(uint256).max);
        }
        gelato1balance.depositToken(_sponsor, IERC20(_token), _amount);
    }    
    
}