// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IConnext} from "@connext/interfaces/core/IConnext.sol";
import {IWeth} from "@connext/interfaces/core/IWeth.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ProtocolSource {
  // The Connext contract on this domain
  IConnext public immutable connext;
  /// @notice WETH address to handle native assets before swapping / sending.
  IWeth public immutable weth;

  receive() external payable virtual {}

  constructor(address _connext, address _weth) {
    connext = IConnext(_connext);
    weth = IWeth(_weth);
  }

  function xcall(
    address target,
    uint32 destinationDomain,
    address inputAsset,
    uint256 amountIn,
    uint256 connextSlippage,
    bytes memory _callData
  ) external payable returns (bytes32 transferId) {
    // Sanity check: amounts above mins
    require(amountIn > 0, "!amount");

    uint256 amountOut = amountIn;

    // wrap origin asset if needed
    if (inputAsset == address(0)) {
      weth.deposit{value: amountIn}();
      inputAsset = address(weth);
    } else {
      IERC20(inputAsset).transferFrom(msg.sender, address(this), amountIn);
    }

    IERC20(inputAsset).approve(address(connext), amountOut);
    // xcall
    // Perform connext transfer
    transferId = connext.xcall{value: msg.value}(
      destinationDomain, //
      target, //
      inputAsset, //
      msg.sender, //
      amountOut, //
      connextSlippage, //
      _callData //
    );
  }
}
