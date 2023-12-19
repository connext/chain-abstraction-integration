// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {LockboxAdapter} from "../contracts/integration/LockboxAdapter.sol";

contract DeployLockboxAdapter is Script {
  function run(address connext, address registry) public {
    vm.startBroadcast();

    new LockboxAdapter(connext, registry);

    vm.stopBroadcast();
  }
}
