// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {LockboxAdapter} from "../contracts/integration/LockboxAdapter.sol";

contract DeployLockboxAdapter is Script {
  function run() public {
    // Retrieve the addresses from the command line arguments
    address connext = vm.envAddress("CONNEXT");
    address registry = vm.envAddress("REGISTRY");
    uint256 deployer = vm.envUint("DEPLOYER_PRIVATE_KEY");

    vm.startBroadcast(deployer);

    new LockboxAdapter(connext, registry);

    vm.stopBroadcast();
  }
}
