// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {NextLockboxAdapter} from "../../contracts/integration/Connext/NextLockboxAdapter.sol";

contract DeployNextLockboxAdapter is Script {
  function run(address lockbox, address erc20, address xerc20) external {
    vm.startBroadcast();

    new NextLockboxAdapter(lockbox, erc20, xerc20);

    vm.stopBroadcast();
  }
}
