// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ProtocolTargetAdapter {
  // The Connext contract on this domain
  receive() external payable virtual {}

  event HelloWorld(string);

  /// Modifier
  constructor() {}

  function hello(
    uint256 _amount, // from here: Add params for selected function
    address _asset,
    bytes calldata _data
  ) external payable returns (bytes memory) {
    // Decode calldata
    // () = abi.decode(_data, ());

    // ACTION
    emit HelloWorld("Hello World");
  }
}
