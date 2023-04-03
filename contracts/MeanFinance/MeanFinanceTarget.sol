// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IConnext} from "@connext/interfaces/core/IConnext.sol";
import {IXReceiver} from "@connext/interfaces/core/IXReceiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./MeanFinanceAdapter.sol";
import "../Uniswap/UniswapV3ForwarderXReceiver.sol";

contract MeanFinanceTarget is MeanFinanceAdapter, UniswapV3ForwarderXReceiver {
    constructor(
        address _connext,
        address _uniswapSwapRouter
    ) UniswapV3ForwarderXReceiver(_connext, _uniswapSwapRouter) {}

    function _forwardFunctionCall(
        bytes memory _preparedData,
        bytes32,
        uint256,
        address
    ) internal override returns (bool) {
        // Decode calldata
        (
            uint256 amountOut,
            address toAsset,
            uint24 poolFee,
            uint256 amountOutMin,
            bytes memory forwardCallData
        ) = abi.decode(
                _preparedData,
                (uint256, address, uint24, uint256, bytes)
            );

        (
            address from,
            address to,
            uint32 amountOfSwaps,
            uint32 swapInterval,
            address owner,
            IDCAPermissionManager.PermissionSet[] memory permissions
        ) = abi.decode(
                forwardCallData,
                (
                    address,
                    address,
                    uint32,
                    uint32,
                    address,
                    IDCAPermissionManager.PermissionSet[]
                )
            );

        deposit(
            from,
            to,
            amountOut,
            amountOfSwaps,
            swapInterval,
            owner,
            permissions
        );
    }
}
