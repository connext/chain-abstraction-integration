import { expect } from "chai";
import { ethers } from "hardhat";
import { utils } from "ethers";
import { TypedDataUtils } from "ethers-eip712";

const hardhatChainId = 31337;

async function deploy() {
  // Contracts are deployed using the first signer/account by default
  const [owner, otherAccount] = await ethers.getSigners();

  const dsaAddr = "0x8f7492DE823025b4CfaAB1D34c58963F2af5DEDA";

  const contract = await ethers.getContractFactory("InstaTargetAuth");
  const instance = await contract.deploy(dsaAddr);
  await instance.deployed();

  return { instance, owner, otherAccount };
}

describe.only("InstadappTargetAuth", function () {
  describe("#verify", function () {
    it("Should work", async function () {
      const { instance, owner, otherAccount } = await deploy();

      const sender = await otherAccount.getAddress();
      console.log(`sender: ${sender}`);

      const domain = {
        name: "InstaTargetAuth",
        version: "1",
        chainId: hardhatChainId,
        verifyingContract: instance.address,
      };

      // The named list of all type definitions
      const types = {
        CastData: [
          { name: "_targetNames", type: "string[]" },
          { name: "_datas", type: "bytes[]" },
          { name: "_origin", type: "address" },
        ],
      };

      // The data to sign
      const value = {
        _targetNames: ["target1", "target2"],
        _datas: [
          ethers.utils.hexlify([1, 2, 3]),
          ethers.utils.hexlify([4, 5, 6]),
        ],
        _origin: sender,
      };

      const signature = await otherAccount._signTypedData(domain, types, value);
      console.log(`signature: ${signature}`);

      // const digest = TypedDataUtils.encodeDigest(typedData);
      const digest = await instance.connect(otherAccount).createDigest(value);

      console.log(digest);

      const msgHashBytes = utils.hashMessage(digest);
      const recoveredAddress = utils.verifyMessage(msgHashBytes, signature);

      const recover = await instance
        .connect(otherAccount)
        .recover(digest, signature);

      console.log("recover", recover);

      console.log("APPROACH");
      console.log("EXPECTED ADDR:    ", sender);
      console.log("RECOVERED ADDR:   ", recoveredAddress);

      const verified = await instance
        .connect(otherAccount)
        .verify(signature, sender, value);

      console.log(verified);
      expect(verified).to.be.true;
    });
  });
});
