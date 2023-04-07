// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {SwapAdapter} from "../shared/Swap/SwapAdapter.sol";

contract SwapAndXCall is SwapAdapter {
  IConnext connext;

  constructor(address _connext) SwapAdapter() {}
}
