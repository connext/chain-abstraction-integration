// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import {IConnext, TokenId} from "@connext/interfaces/core/IConnext.sol";
// import {IWeth} from "@connext/interfaces/core/IWeth.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

// import {SwapAdapter} from "../../shared/Swap/SwapAdapter.sol";

// contract ExampleSource is SwapAdapter {
//   // The Connext contract on this domain
//   IConnext public immutable connext;
//   /// @notice WETH address to handle native assets before swapping / sending.
//   IWeth public immutable weth;

//   receive() external payable virtual override(SwapAdapter) {}

//   constructor(address _connext, address _weth) SwapAdapter() {
//     connext = IConnext(_connext);
//     weth = IWeth(_weth);
//   }

//   function xDeposit(
//     address target,
//     uint32 destinationDomain,
//     address inputAsset,
//     address connextAsset,
//     uint256 amountIn,
//     uint256 connextSlippage,
//     uint24 sourcePoolFee,
//     uint256 sourceAmountOutMin,
//     bytes memory _callData
//   ) external payable returns (bytes32 transferId) {
//     // Sanity check: amounts above mins
//     require(amountIn > 0, "!amount");

//     uint256 amountOut = amountIn;

//     // wrap origin asset if needed
//     if (inputAsset == address(0)) {
//       weth.deposit{value: amountIn}();
//       inputAsset = address(weth);
//     } else {
//       TransferHelper.safeTransferFrom(inputAsset, msg.sender, address(this), amountIn);
//     }

//     // swap to donation asset if needed
//     if (inputAsset != connextAsset) {
//       require(connextApprovedAssets(connextAsset), "!connextAsset");
//       //   amountOut = swap(inputAsset, connextAsset, sourcePoolFee, amountIn, sourceAmountOutMin);
//     }

//     TransferHelper.safeApprove(connextAsset, address(connext), amountOut);
//     // xcall
//     // Perform connext transfer
//     transferId = connext.xcall{value: msg.value}(
//       destinationDomain, //
//       target, //
//       connextAsset, //
//       msg.sender, //
//       amountOut, //
//       connextSlippage, //
//       _callData //
//     );
//   }

//   /// INTERNAL
//   function connextApprovedAssets(address adopted) internal view returns (bool approved) {
//     TokenId memory canonical = connext.adoptedToCanonical(adopted);
//     approved = connext.approvedAssets(canonical);
//   }
// }
