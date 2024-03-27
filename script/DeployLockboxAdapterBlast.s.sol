// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {LockboxAdapterBlast} from "../contracts/integration/LockboxAdapterBlast.sol";

contract DeployLockboxAdapterBlast is Script {
  function run() public {
    vm.startBroadcast();

    new LockboxAdapterBlast(
      address(0x697402166Fbf2F22E970df8a6486Ef171dbfc524), // blastStandardBridge
      address(0xBf29A2D67eFb6766E44c163B19C6F4118b164702) // registry
    );

    vm.stopBroadcast();
  }
}
