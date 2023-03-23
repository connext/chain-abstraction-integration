import { expect } from 'chai'
import { ethers } from 'hardhat'
import { utils } from 'ethers'
import { TypedDataUtils } from 'ethers-eip712'

const hardhatChainId = 31337

async function deploy() {
  // Contracts are deployed using the first signer/account by default
  const [owner, otherAccount] = await ethers.getSigners()

  const dsaAddr = '0x8f7492DE823025b4CfaAB1D34c58963F2af5DEDA'

  const contract = await ethers.getContractFactory('InstaTargetAuth')
  const instance = await contract.deploy(dsaAddr)
  await instance.deployed()

  const typedData = {
    types: {
      EIP712Domain: [
        { name: 'name', type: 'string' },
        { name: 'version', type: 'string' },
        { name: 'chainId', type: 'uint256' },
        { name: 'verifyingContract', type: 'address' },
      ],
      CastData: [
        { name: '_targetNames', type: 'string[]' },
        { name: '_datas', type: 'bytes[]' },
        { name: '_origin', type: 'address' },
      ],
    },
    primaryType: 'CastData' as const,
    domain: {
      name: 'InstadappTargetAuth',
      version: '1',
      chainId: hardhatChainId,
      verifyingContract: instance.address,
    },
    message: {
      _targetNames: ['target1', 'target2'],
      _datas: [
        ethers.utils.hexlify([1, 2, 3]),
        ethers.utils.hexlify([4, 5, 6]),
      ],
      _origin: await otherAccount.getAddress(),
    },
  }

  return { instance, owner, otherAccount, typedData }
}

describe.only('InstadappTargetAuth', function () {
  describe('#verify', function () {
    it('Should work', async function () {
      const { instance, owner, otherAccount, typedData } = await deploy()

      // const digest = TypedDataUtils.encodeDigest(typedData);
      const digest = await instance
        .connect(otherAccount)
        .createDigest(typedData.message)
      console.log(digest, utils.hexlify(digest))
      const signature = await otherAccount.signMessage(utils.hexlify(digest))
      console.log(`signature: ${signature}`)

      const { r, s, v } = ethers.utils.splitSignature(signature)
      console.log(r, s, v)

      const sender = await otherAccount.getAddress()
      console.log(`sender: ${sender}`)

      const msgHashBytes = utils.arrayify(utils.hashMessage(digest))
      // Now you have the digest,
      const recoveredAddress = utils.recoverAddress(msgHashBytes, signature)

      // const matches = expectedPublicKey === recoveredPubKey;

      console.log('APPROACH')
      console.log('EXPECTED ADDR:    ', sender)
      console.log('RECOVERED ADDR:   ', recoveredAddress)

      const verified = await instance
        .connect(otherAccount)
        .verify(typedData.message, sender, v, r, s)

      console.log(verified)
      expect(verified).to.be.true
    })
  })
})
