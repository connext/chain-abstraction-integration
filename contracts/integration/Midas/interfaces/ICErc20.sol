// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ICToken} from "./ICToken.sol";

interface ICErc20 is ICToken {
  function underlying() external view returns (address);
}
