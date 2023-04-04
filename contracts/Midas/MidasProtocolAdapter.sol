// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {CTokenInterface} from "./interfaces/CTokenInterface.sol";
import {ICToken, ICErc20} from "./interfaces/ICErc20.sol";
import {IComptroller} from "./interfaces/IComptroller.sol";

contract MidasProtocolAdapter {
  using SafeERC20 for IERC20;

  IComptroller public immutable comptroller;

  /// Payable
  receive() external payable virtual {}

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
      _safeApprove(IERC20(asset), cTokenAddress, amount);
    } else {
      require(asset == ICErc20(cTokenAddress).underlying(), "!underlying");
    }

    // Mint to this contract
    require(cToken.mint(amount) == 0, "mint failed");

    // Transfer all the cTokens to the minter
    CTokenInterface(cTokenAddress).asCTokenExtensionInterface().transfer(minter, cToken.balanceOf(address(this)));
  }

  /**
   * @dev Internal function to approve unlimited tokens of `erc20Contract` to `to`.
   */
  function _safeApprove(IERC20 token, address to, uint256 minAmount) private {
    uint256 allowance = token.allowance(address(this), to);

    if (allowance < minAmount) {
      if (allowance > 0) token.safeApprove(to, 0);
      token.safeApprove(to, type(uint256).max);
    }
  }
}
