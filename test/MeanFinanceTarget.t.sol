// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./utils/TestHelper.sol";
import "../contracts/MeanFinanceTarget.sol";
import "@mean-finance/nft-descriptors/solidity/interfaces/IDCAHubPositionDescriptor.sol";
import {IDCAHub} from "@mean-finance/dca-v2-core/contracts/interfaces/IDCAHub.sol";

contract MeanFinanceTargetTest is TestHelper {
    // ============ Errors ============
    // error ProposedOwnable__onlyOwner_notOwner();

    // ============ Events ============
    event XReceiveDeposit(
        bytes32 _transferId,
        uint256 _amount, // must be amount in bridge asset less fees
        address _asset,
        address _originSender,
        uint32 _origin,
        bytes _callData,
        uint256 _positionId
    );

    // ============ Storage ============
    address private connext = address(1);
    address public notOriginSender =
        address(bytes20(keccak256("NotOriginSender")));

    address private deposit_from = address(2);
    address private deposit_to = address(3);
    uint32 private deposit_amount = 10;
    uint32 private deposit_amountOfSwaps = 10;
    uint32 private deposit_swapInterval = 10;
    address private deposit_owner = address(4);
    // IDCAPermissionManager.Permission[]  permissions;
    IDCAPermissionManager.PermissionSet[] deposit_permissions;
    // [    IDCAPermissionManager.PermissionSet(address(5), permissions)];

    MeanFinanceTarget private target;
    bytes32 public transferId = keccak256("12345");
    uint32 public amount = 10;

    function setUp() public override {
        super.setUp();
        target = new MeanFinanceTarget(MOCK_CONNEXT, MOCK_MEAN_FINANCE);

        vm.label(address(this), "TestContract");
        vm.label(address(target), "MeanFinanceTarget");
    }

    // ============ MeanFinanceTarget.xReceive ============
    function test_MeanFinanceTargetTest__xReceive_shouldWork() public {
        vm.prank(MOCK_CONNEXT);

        bytes memory _callData = abi.encodeWithSignature(
            "deposit(address,address,uint256,uint32,uint32,address,IDCAPermissionManager.PermissionSet[])",
            deposit_from,
            deposit_to,
            deposit_amount,
            deposit_amountOfSwaps,
            deposit_swapInterval,
            deposit_owner,
            deposit_permissions
        );

        // vm.expectCall(
        //     address(MOCK_MEAN_FINANCE),
        //     abi.encodeCall(
        //         IDCAHub.deposit,
        //         (
        //             deposit_from,
        //             deposit_to,
        //             deposit_amount,
        //             deposit_amountOfSwaps,
        //             deposit_swapInterval,
        //             deposit_owner,
        //             deposit_permissions
        //         )
        //     )
        // );

        target.xReceive(
            transferId,
            amount,
            MOCK_ERC20,
            notOriginSender,
            GOERLI_DOMAIN_ID,
            _callData
        );

        // vm.expectEmit(
        //     transferId,
        //     amount,
        //     MOCK_ERC20,
        //     notOriginSender,
        //     GOERLI_DOMAIN_ID,
        //     _callData,
        //     1
        // );
    }
}
