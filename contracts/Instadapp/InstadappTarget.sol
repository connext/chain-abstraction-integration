//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IConnext} from "@connext/interfaces/core/IConnext.sol";
import {IXReceiver} from "@connext/interfaces/core/IXReceiver.sol";
import {InstaTargetAuthInterface as IAT} from "./interfaces/InstaTargetAuthInterface.sol";

contract InstadappTarget is IXReceiver {
    // Whitelist addresses allowed to  call xReceive
    // function whitelistAddress()

    // The Connext contract on this domain
    IConnext public connext;

    // The MetaTxAuthority contract on this domain
    IAT public targetAuth;

    modifier onlyConnext() {
        require(msg.sender == address(connext), "Caller must be Connext");
        _;
    }

    constructor(address _connext, address _targetAuth) {
        connext = IConnext(_connext);
        targetAuth = IAT(_targetAuth);
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
        (
            address dsaAddress,
            address auth,
            bytes memory signature,
            IAT.CastData memory _castData
        ) = abi.decode(_callData, (address, address, bytes, IAT.CastData));

        targetAuth.authCast(dsaAddress, auth, signature, _castData);
    }
}
