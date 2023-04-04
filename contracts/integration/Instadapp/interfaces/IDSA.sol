//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDSA {
  function cast(
    string[] calldata _targetNames,
    bytes[] calldata _datas,
    address _origin
  ) external payable returns (bytes32);

  function isAuth(address user) external view returns (bool);
}
