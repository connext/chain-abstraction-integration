//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IConnext } from "@connext/interfaces/core/IConnext.sol";
import { IXReceiver } from "@connext/interfaces/core/IXReceiver.sol";
import { IInstadappTargetAuth, CastData } from "./InstadappTargetAuth.sol";

contract InstadappTarget is IXReceiver {
  // Whitelist addresses allowed to  call xReceive
  // function whitelistAddress()

  // The Connext contract on this domain
  IConnext public connext;

  // The MetaTxAuthority contract on this domain
  IInstadappTargetAuth public targetAuth;

  modifier onlyConnext() {
    require(msg.sender == address(connext), "Caller must be Connext");
    _;
  }

  constructor(address _connext, address _targetAuth) {
    connext = IConnext(_connext);
    targetAuth = IInstadappTargetAuth(_targetAuth);
  }

  function xReceive(
    bytes32 _transferId,
    uint256 _amount, // must be amount in bridge asset less fees
    address _asset,
    address _originSender,
    uint32 _origin,
    bytes memory _callData
  ) external onlyConnext returns (bytes memory) {
    // Decode signed calldata
    (CastData memory _castData, address sender, uint8 v, bytes32 r, bytes32 s) = abi.decode(
      _callData,
      (CastData, address, uint8, bytes32, bytes32)
    );

    targetAuth.authCast(_castData, sender, v, r, s);
  }
}
