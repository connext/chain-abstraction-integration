// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {CTokenInterface} from "./interfaces/CTokenInterface.sol";
import {ICToken, ICErc20} from "./interfaces/ICErc20.sol";
import {IComptroller} from "./interfaces/IComptroller.sol";

contract MidasProtocolAdapter {
  IComptroller public immutable comptroller;

  constructor(address _comptroller) {
    comptroller = IComptroller(_comptroller);
  }

  /**
   * @dev Internal function to mint cTokens and transfer them to the `minter`
   *
   * @param cTokenAddress The cToken address to mint
   * @param asset The underlying asset address
   * @param amount The amount of underlying asset
   * @param minter The recipient to transfer minted cTokens
   */
  function _mint(address cTokenAddress, address asset, uint256 amount, address minter) internal {
    require(minter != address(0), "zero address");
    require(amount > 0, "zero amount");

    ICToken cToken = ICToken(cTokenAddress);

    // Enter the market if the contract didn't enter the market, otherwise skip
    if (comptroller.checkMembership(address(this), cToken)) {
      address[] memory cTokens = new address[](1);
      cTokens[0] = cTokenAddress;
      comptroller.enterMarkets(cTokens);
    }

    // Approve underlying
    if (!cToken.isCEther()) {
      if (IERC20(asset).allowance(address(this), cTokenAddress) < amount) {
        IERC20(asset).approve(cTokenAddress, type(uint256).max);
      }
    }

    // Mint to this contract
    require(cToken.mint(amount) == 0, "mint failed");

    // Transfer all the cTokens to the minter
    CTokenInterface(cTokenAddress).asCTokenExtensionInterface().transfer(minter, cToken.balanceOf(address(this)));
  }
}
