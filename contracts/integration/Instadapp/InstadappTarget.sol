//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IConnext} from "@connext/interfaces/core/IConnext.sol";
import {IXReceiver} from "@connext/interfaces/core/IXReceiver.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {InstadappAdapter} from "./InstadappAdapter.sol";

contract InstadappTarget is IXReceiver, InstadappAdapter {
  // The Connext contract on this domain
  IConnext public connext;

  event AuthCast(bytes32 transferId, address dsaAddress, address auth, bool success, bytes returnedData);

  modifier onlyConnext() {
    require(msg.sender == address(connext), "Caller must be Connext");
    _;
  }

  constructor(address _connext) {
    connext = IConnext(_connext);
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
    (address dsaAddress, address auth, bytes memory signature, CastData memory _castData) = abi.decode(
      _callData,
      (address, address, bytes, CastData)
    );

    require(dsaAddress != address(0), "!invalidFallback");
    IERC20(_asset).transferFrom(msg.sender, dsaAddress, _amount);

    (bool success, bytes memory returnedData) = address(this).call(
      abi.encodeWithSignature("authCast(address,address,bytes,CastData)", dsaAddress, auth, signature, _castData)
    );

    emit AuthCast(_transferId, dsaAddress, auth, success, returnedData);
  }
}
