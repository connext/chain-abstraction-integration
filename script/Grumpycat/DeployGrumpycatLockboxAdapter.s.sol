// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {GrumpycatLockboxAdapter} from "../../contracts/integration/Grumpycat/GrumpycatLockboxAdapter.sol";

contract DeployGrumpycatLockboxAdapter is Script {
  function run(address lockbox, address erc20, address xerc20) external {
    vm.startBroadcast();

    new GrumpycatLockboxAdapter(lockbox, erc20, xerc20);

    vm.stopBroadcast();
  }
}
