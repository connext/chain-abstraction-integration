// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {DappRadarLockboxAdapter} from "../../contracts/integration/DappRadar/DappRadarLockboxAdapter.sol";

contract DeployDappRadarLockboxAdapter is Script {
  function run(address lockbox, address erc20, address xerc20) external {
    vm.startBroadcast();

    new DappRadarLockboxAdapter(lockbox, erc20, xerc20);

    vm.stopBroadcast();
  }
}
