// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {MidasProtocolAdapter} from "./MidasProtocolAdapter.sol";
import {UniswapV2ForwarderXReceiver} from "../Uniswap/UniswapV2ForwarderXReceiver.sol";

contract MidasProtocolUniV2Target is
    MidasProtocolAdapter,
    UniswapV2ForwarderXReceiver
{
    address public immutable COMPTROLLER_ADDRESS;

    constructor(
        address _connext,
        address _uniswapSwapRouter,
        address _comptroller
    ) UniswapV2ForwarderXReceiver(_connext, _uniswapSwapRouter) {
        COMPTROLLER_ADDRESS = _comptroller;
    }
}
