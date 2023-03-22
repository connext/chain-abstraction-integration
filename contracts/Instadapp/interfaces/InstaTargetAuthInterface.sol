//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface InstaTargetAuthInterface {
    struct CastData {
        string[] _targetNames;
        bytes[] _datas;
        address _origin;
    }

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    function verify(
        CastData memory castData,
        address sender,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view returns (bool);

    function authCast(
        CastData memory castData,
        address sender,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}
