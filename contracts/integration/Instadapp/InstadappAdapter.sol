// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IDSA} from "./interfaces/IDSA.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract InstadappAdapter is EIP712 {
  struct CastData {
    string[] _targetNames;
    bytes[] _datas;
    address _origin;
  }

  struct Sig {
    CastData castData;
    bytes32 salt;
  }

  mapping(address => bytes32) private sigRelayProtection;

  bytes32 public constant CASTDATA_TYPEHASH =
    keccak256("CastData(string[] _targetNames,bytes[] _datas,address _origin)");

  bytes32 public constant SIG_TYPEHASH =
    keccak256("Sig(CastData cast,bytes32 salt)CastData(string[] _targetNames,bytes[] _datas,address _origin)");

  constructor() EIP712("InstaTargetAuth", "1") {}

  /// Internal functions
  function authCast(
    address dsaAddress,
    address auth,
    bytes memory signature,
    CastData memory castData,
    bytes32 salt
  ) internal {
    IDSA dsa = IDSA(dsaAddress);
    require(dsa.isAuth(auth), "Invalid Auth");
    require(verify(auth, signature, castData, salt), "Invalid signature");

    /// Signature Replay Protection
    sigRelayProtection[auth] = salt;

    // send funds to DSA
    dsa.cast{value: msg.value}(castData._targetNames, castData._datas, castData._origin);
  }

  function verify(
    address auth,
    bytes memory signature,
    CastData memory castData,
    bytes32 salt
  ) internal view returns (bool) {
    bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(SIG_TYPEHASH, hash(castData), salt)));
    address signer = ECDSA.recover(digest, signature);
    return signer == auth;
  }

  function hash(CastData memory castData) internal pure returns (bytes32) {
    return keccak256(abi.encode(CASTDATA_TYPEHASH, castData._targetNames, castData._datas, castData._origin));
  }
}
