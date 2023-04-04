// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ICToken} from "./ICToken.sol";

interface IComptroller {
  function checkMembership(address account, ICToken cToken) external view returns (bool);

  function enterMarkets(address[] memory cTokens) external returns (uint256[] memory);
}
