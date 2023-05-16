// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IGelato1Balance} from "./interfaces/IGelato1Balance.sol";

contract Gelato1BalanceAdapter {
    
    IGelato1Balance public gelato1balance;

    constructor (address _gelato1balance){
        gelato1balance = IGelato1Balance(_gelato1balance);
    }

    function depositTokens(address _sponsor, address _token, uint256 _amount) internal {

        require(_amount > 0, "Zero Amount");
        require(_sponsor != address(0), "Zero address");
        // Increasing the allowance 
        IERC20(_token).approve(address(gelato1balance), _amount);
        gelato1balance.depositToken(_sponsor, IERC20(_token), _amount);
    }    

}