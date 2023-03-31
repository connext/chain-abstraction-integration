//SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import "@openzeppelin/contracts/utils/Address.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import {ProtocolTarget} from "./ProtocolTarget.sol";

contract Swapper is ProtocolTarget {
    ISwapRouter public immutable UniswapSwapRouter =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    constructor(address _connext) XReceiver(_connext) {}

    function forwardFunctionCall(
        bytes memory _data,
        uint256 _amount,
        address _asset
    ) internal virtual returns (bool) {
        (
            address fromAsset,
            address toAsset,
            uint24 poolFee,
            uint256 amountOutMin,
            address recipient
        ) = abi.decode(
                _data,
                (address, address, uint24, uint256, address)
            );

        TransferHelper.safeApprove(fromAsset, address(UniswapSwapRouter), _amount);
        // Set up uniswap swap params.
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: fromAsset,
                tokenOut: toAsset,
                fee: poolFee,
                recipient: recipient,
                deadline: block.timestamp,
                amountIn: _amount,
                amountOutMinimum: amountOutMin,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        ISwapRouter(swapper).exactInputSingle{value: value}(params);

        return true;
    }
}
