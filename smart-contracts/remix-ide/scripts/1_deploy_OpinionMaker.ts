
import { deploy, wallet } from './ethers-lib'

// Optional: in case of using Web3 library
// import { deploy, wallet } from './web3-lib'

(async () => {
  try {
    const walletAddress = await wallet()
    const result = await deploy('SimpleOpinionMaker', [walletAddress])
    console.log(`address: ${result.address}`)
  } catch (e) {
    console.log(e.message)
  }
})()