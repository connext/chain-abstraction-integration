// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {ISwapper} from "../interfaces/ISwapper.sol";

/**
 * @title OneInchUniswapV3
 * @notice Swapper contract for 1inch swaps.
 */
contract OneInchSwapAdapter is ISwapper, Ownable2Step {
  using Address for address;
  using Address for address payable;

  address public immutable oneInchRouter = address(0x1111111254EEB25477B68fb85Ed929f73A960582);

  receive() external payable virtual {}

  struct SwapDescription {
    address srcToken;
    address dstToken;
    address srcReceiver;
    address dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 flags;
  }

  /**
   * @notice Swap the given amount of tokens using 1inch.
   * @dev Decode the passed in data and re-encode it with the correct amountIn. This is because the amountIn is not known
   * until the funds are transferred to this contract.
   * @param _amountIn Amount of tokens to swap.
   * @param _fromAsset Address of the token to swap from.
   * @param _toAsset Address of the token to swap to.
   * @param _swapData Data to pass to the 1inch aggregator router.
   */
  function callSwap(
    uint256 _amountIn,
    address _fromAsset,
    address _toAsset,
    bytes calldata _swapData // from 1inch API
  ) public payable returns (uint256 amountOut) {
    // transfer the funds to be swapped from the sender into this contract
    TransferHelper.safeTransferFrom(_fromAsset, msg.sender, address(this), _amountIn);

    if (IERC20(_fromAsset).allowance(address(this), address(oneInchRouter)) < _amountIn) {
      TransferHelper.safeApprove(_fromAsset, address(oneInchRouter), type(uint256).max);
    }

    // decode & encode the swap data
    // the data included with the swap encodes with the selector so we need to remove it
    // https://docs.1inch.io/docs/aggregation-protocol/smart-contract/UnoswapV3Router#uniswapv3swap
    bytes memory _data = decoderEncoderSwapAmount(_amountIn, _swapData);

    // Set up swap params
    // Approve the swapper if needed

    // The call to `uniswapV3Swap` executes the swap.
    // use actual amountIn that was sent to the xReceiver
    bytes memory returned = address(oneInchRouter).functionCall(_data, "!callSwap");

    ///TODO: Need to apply logic for decoding the amount out
    // (uint256 _a, uint256 _g) = abi.decode(returned, (uint256, uint256));
    // amountOut = _a;
    // transfer the swapped funds back to the sender
    // TransferHelper.safeTransfer(_toAsset, msg.sender, amountOut);
  }

  function decoderEncoderSwapAmount(uint256 _amount, bytes calldata _swapData) public returns (bytes memory) {
    // Decode and Encode the swap data with new amountIn
    (bool success, bytes memory data) = address(this).call(
      abi.encodeWithSelector(bytes4(_swapData[:4]), _amount, _swapData)
    );

    return data;
  }

  function swap(uint256 _amount, bytes calldata _swapData) internal pure returns (bytes memory) {
    // decode the swap data
    (address executor, SwapDescription memory desc, bytes memory permit, bytes memory _d) = abi.decode(
      _swapData[4:],
      (address, SwapDescription, bytes, bytes)
    );

    desc.amount = _amount;

    bytes memory encoded = abi.encodeWithSelector(bytes4(_swapData[:4]), executor, desc, permit, _d);
    return encoded;
  }

  function uniswapV3Swap(uint256 _amount, bytes calldata _swapData) internal pure returns (bytes memory) {
    // decode the swap data
    (uint256 amount, uint256 minReturn, uint256[] memory pools) = abi.decode(
      _swapData[4:],
      (uint256, uint256, uint256[])
    );

    // encode the swap data
    bytes memory encoded = abi.encodeWithSelector(bytes4(_swapData[:4]), _amount, minReturn, pools);
    return encoded;
  }
}
