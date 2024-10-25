
import { deploy } from './ethers-lib'

// Optional: in case of using Web3 library
// import { deploy } from './web3-lib'

(async () => {
  try {
    // Replace tokenAuthorityPublicKey with your Token Authority public from deployed Token Authority smart contract
    const tokenAuthorityPublicKey = "0x9999999999999999999999999"

    const result = await deploy('SampleContract', [tokenAuthorityPublicKey])
    console.log(`address: ${result.address}`)
  } catch (e) {
    console.log(e.message)
  }
})()