// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "lib/forge-std/src/Script.sol";
import {InstadappTarget} from "../../contracts/integration/Instadapp/InstadappTarget.sol";

contract DeployInstadappTarget is Script {
  function run(address connext) external {
    vm.startBroadcast();

    new InstadappTarget(connext);

    vm.stopBroadcast();
  }
}
