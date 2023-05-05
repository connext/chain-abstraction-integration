// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;
pragma abicoder v2;

import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {IPeripheryPayments} from "@uniswap/v3-periphery/contracts/interfaces/IPeripheryPayments.sol";
import {IPeripheryImmutableState} from "@uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol";

/// @title Router token swapping functionality
interface ISmartRouter is ISwapRouter, IPeripheryPayments, IPeripheryImmutableState {

}
