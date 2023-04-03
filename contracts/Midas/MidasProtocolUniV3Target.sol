// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {MidasProtocolAdapter} from "./MidasProtocolAdapter.sol";
import {UniswapV3ForwarderXReceiver} from "../Uniswap/UniswapV3ForwarderXReceiver.sol";

contract MidasProtocolUniV3Target is
    MidasProtocolAdapter,
    UniswapV3ForwarderXReceiver
{}
