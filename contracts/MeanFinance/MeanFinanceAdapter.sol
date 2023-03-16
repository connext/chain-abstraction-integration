// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@mean-finance/dca-v2-core/contracts/interfaces/IDCAHub.sol";

abstract contract MeanFinanceAdapter {
    /// @notice MeanFinance IDCAHub contract for deposit
    /// @dev see https://docs.mean.finance/guides/smart-contract-registry
    IDCAHub public immutable hub =
        IDCAHub(0xA5AdC5484f9997fBF7D405b9AA62A7d88883C345);

    function deposit(
        address from,
        address to,
        uint256 amount,
        uint32 amountOfSwaps,
        uint32 swapInterval,
        address owner,
        IDCAPermissionManager.PermissionSet[] memory permissions
    ) internal returns (uint256 positionId) {
        // deposit
        IERC20(address(this)).approve(address(hub), amount);

        positionId = hub.deposit(
            from,
            to,
            amount,
            amountOfSwaps,
            swapInterval,
            owner,
            permissions
        );
    }
}
