
import { deploy, wallet } from './ethers-lib'

// Optional: in case of using Web3 library
// import { deploy, wallet } from './web3-lib'

(async () => {
  try {
    // Replace opinionMakerAddress with your deployed address
    const opinionMakerAddress = "0x9999999999999999999999999"

    const walletAddress = await wallet()
    const result = await deploy('SimpleTokenAuthority', [walletAddress, opinionMakerAddress])
    console.log(`address: ${result.address}`)
  } catch (e) {
    console.log(e.message)
  }
})()