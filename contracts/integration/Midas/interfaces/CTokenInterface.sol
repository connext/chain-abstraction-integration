// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface CTokenExtensionInterface {
  function transfer(address dst, uint256 amount) external returns (bool);
}

interface CTokenInterface {
  function asCTokenExtensionInterface() external view returns (CTokenExtensionInterface);
}
