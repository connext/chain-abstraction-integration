// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IDSA} from "./interfaces/IDSA.sol";
import {InstaTargetAuthInterface} from "./interfaces/InstaTargetAuthInterface.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract InstaTargetAuth is EIP712, InstaTargetAuthInterface {
    // Instadapp contract on this domain
    IDSA public dsa;

    constructor(address _dsa) EIP712("InstaTargetAuth", "1") {
        dsa = IDSA(_dsa);
    }

    function verify(
        bytes memory signature,
        address sender,
        CastData memory castData
    ) public view returns (bool) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "Cast(string[] _targetNames,bytes[] _datas,address _origin)"
                    ),
                    castData._targetNames,
                    castData._datas,
                    castData._origin
                )
            )
        );

        address signer = ECDSA.recover(digest, signature);
        return signer == sender;
    }

    function authCast(
        bytes memory signature,
        address sender,
        CastData memory castData
    ) public payable {
        require(verify(signature, sender, castData), "Invalid signature");

        // send funds to DSA
        dsa.cast{value: msg.value}(
            castData._targetNames,
            castData._datas,
            castData._origin
        );
    }

    function recover(
        bytes32 digest,
        bytes memory signature
    ) public pure returns (address) {
        return ECDSA.recover(digest, signature);
    }

    function createDigest(
        CastData memory castData
    ) public view returns (bytes32 digest) {
        digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "Cast(string[] _targetNames,bytes[] _datas,address _origin)"
                    ),
                    castData._targetNames,
                    castData._datas,
                    castData._origin
                )
            )
        );
    }
}
