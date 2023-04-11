import { ethers, Wallet } from "ethers";
import {
  defaultAbiCoder,
  joinSignature,
  keccak256,
  solidityKeccak256,
  _TypedDataEncoder,
  toUtf8Bytes,
  formatBytes32String,
} from "ethers/lib/utils";

const generateSignature = async (
  sender: Wallet,
  domain: any,
  castData: any,
  typeHash: string,
  sigTypeHash: string,
  salt: string,
): Promise<string> => {
  const encodedData = defaultAbiCoder.encode(
    ["bytes32", "string[]", "bytes[]", "address"],
    [typeHash, castData._targetNames, castData._datas, castData._origin],
  );
  const sigTypedEncodedData = defaultAbiCoder.encode(
    ["bytes32", "bytes32", "bytes32"],
    [sigTypeHash, keccak256(encodedData), salt],
  );
  const domainSeparator = _TypedDataEncoder.hashDomain(domain);
  const digest = solidityKeccak256(
    ["string", "bytes32", "bytes32"],
    ["\x19\x01", domainSeparator, keccak256(sigTypedEncodedData)],
  );
  console.log({ digest });
  const signingKey = sender._signingKey();
  const signature = signingKey.signDigest("0x9efcb83cd0436c2c507075a156b9c17e7d701b8c240308e42db8b9cb2e5d5fc2");
  const joinedSig = joinSignature(signature);
  return joinedSig;
};

export const main = async () => {
  const TEST_PRIIVATE_KEY = "913b591c8abc30e7d3d2a4ebd560e1f02197cb701f077c9fcdc2ba8b0a7d9abe"; // address = 0xc1aAED5D41a3c3c33B1978EA55916f9A3EE1B397
  const sender = new ethers.Wallet(TEST_PRIIVATE_KEY);
  const authContractAddress = "0xc1aAED5D41a3c3c33B1978EA55916f9A3EE1B397";

  const domain = {
    name: "InstaTargetAuth",
    version: "1",
    chainId: 31337,
    verifyingContract: authContractAddress,
  };

  const castData = {
    _targetNames: ["target111", "target222", "target333"],
    _datas: [toUtf8Bytes("0x111"), toUtf8Bytes("0x222"), toUtf8Bytes("0x333")],
    _origin: sender.address.toLowerCase(),
  };

  const CASTDATA_TYPEHASH = keccak256(toUtf8Bytes("CastData(string[] _targetNames,bytes[] _datas,address _origin)"));
  const SIG_TYPEHASH = keccak256(
    toUtf8Bytes("Sig(CastData cast,bytes32 salt)CastData(string[] _targetNames,bytes[] _datas,address _origin)"),
  );
  const salt = formatBytes32String("1");

  const signature = await generateSignature(sender, domain, castData, CASTDATA_TYPEHASH, SIG_TYPEHASH, salt);

  console.log({ CASTDATA_TYPEHASH, SIG_TYPEHASH, signature });
};

main();
