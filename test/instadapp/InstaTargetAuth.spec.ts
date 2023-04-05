import { expect } from "chai";
import { ethers } from "hardhat";
import instaIndexABI from "../helpers/abis/instaindex.json";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Contract, Wallet } from "ethers";
import {
  defaultAbiCoder,
  joinSignature,
  keccak256,
  solidityKeccak256,
  toUtf8Bytes,
  _TypedDataEncoder,
} from "ethers/lib/utils";
import { sign } from "crypto";

// Hardcoded addresses on optimism
const instaIndexAddr = "0x6CE3e607C808b4f4C26B7F6aDAeB619e49CAbb25";

// DO NOT USE THIS KEY ON MAINNET
const TEST_PRIIVATE_KEY = "913b591c8abc30e7d3d2a4ebd560e1f02197cb701f077c9fcdc2ba8b0a7d9abe"; // address = 0xc1aAED5D41a3c3c33B1978EA55916f9A3EE1B397
const deployDSAv2 = async (owner: any) => {
  const instaIndex = await ethers.getContractAt(instaIndexABI, instaIndexAddr);
  const tx = await instaIndex.build(owner, 2, owner);
  const receipt = await tx.wait();

  const event = receipt.events.find((a: { event: string }) => a.event === "LogAccountCreated");
  return await ethers.getContractAt(instaIndexABI, event.args.account);
};

const deployInstaTargetAuth = async (dsaAddress: string) => {
  const instaTagetAuthFactory = await ethers.getContractFactory("InstaTargetAuth");
  const contractInstance = await instaTagetAuthFactory.deploy(dsaAddress);
  await contractInstance.deployed();
  return contractInstance;
};

const generateSignature = async (sender: Wallet, domain: any, castData: any, typeHash: string): Promise<string> => {
  const encodedData = defaultAbiCoder.encode(
    ["bytes32", "string[]", "bytes[]", "address"],
    [typeHash, castData._targetNames, castData._datas, castData._origin],
  );
  const domainSeparator = _TypedDataEncoder.hashDomain(domain);
  const digest = solidityKeccak256(
    ["string", "bytes32", "bytes32"],
    ["\x19\x01", domainSeparator, keccak256(encodedData)],
  );
  const signingKey = sender._signingKey();
  const signature = signingKey.signDigest(digest);
  const joinedSig = joinSignature(signature);
  return joinedSig;
};
describe("InstaTargetAuth", () => {
  let deployer: SignerWithAddress, sender: Wallet;
  let dsaContract: Contract;
  let instaTargetAuthContract: any;

  before(async () => {
    [deployer] = await ethers.getSigners();

    sender = new ethers.Wallet(TEST_PRIIVATE_KEY, ethers.provider);
    dsaContract = await deployDSAv2(deployer.address);
    // instaTargetAuthContract = await deployInstaTargetAuth(dsaContract.address);
  });
  describe("#verify", () => {
    it("happy: should verify successfully", async () => {
      // const authContractAddress = instaTargetAuthContract.address.toLowerCase();
      const authContractAddress = "0x6CE3e607C808b4f4C26B7F6aDAeB619e49CAbb25";
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

      const CASTDATA_TYPEHASH = keccak256(
        toUtf8Bytes("CastData(string[] _targetNames,bytes[] _datas,address _origin)"),
      );
      const signature = await generateSignature(sender, domain, castData, CASTDATA_TYPEHASH);
      console.log("> signature: ", signature);
      const verified = await instaTargetAuthContract.connect(deployer).verify(signature, sender.address, castData);
      expect(verified).to.be.true;
    });

    it("should return false if signature is invalid", async () => {
      const authContractAddress = instaTargetAuthContract.address.toLowerCase();
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

      const CASTDATA_TYPEHASH = keccak256(
        toUtf8Bytes("CastData(string[] _targetNames,bytes[] _datas,address _origin)"),
      );
      const signature = await generateSignature(sender, domain, castData, CASTDATA_TYPEHASH);
      const verified = await instaTargetAuthContract.connect(deployer).verify(signature, deployer.address, castData);
      expect(verified).to.be.false;
    });
  });

  describe("#authCast", () => {
    it("should revert if verification fails", async () => {});
    it("happy: should work", async () => {});
  });
});
