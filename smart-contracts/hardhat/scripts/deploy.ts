import { ethers, run } from "hardhat";
import * as dotenv from "dotenv";

async function main() {
  const [deployer] = await ethers.getSigners();

  const walletAddress = deployer.address;

  const ownerAddress = process.env.INITIAL_OWNER_ADDRESS || walletAddress;

  console.log("======================================")
  console.log("DEPLOYER:", walletAddress);
  console.log("Owner address for OM and TA:", ownerAddress)
  console.log("======================================")


  // TOKEN AUTHORITY TokenAuthority.sol
  console.log("START DEPLOYING TOKEN AUTHORITY")
  const providerTokenAuthority = new ethers.JsonRpcProvider(`https://testnet.sapphire.oasis.io`);
  const walletTokenAuthority = new ethers.Wallet(`${process.env.PRIVATE_KEY_OASIS}`, providerTokenAuthority);

  const ContractTokenAuthority = await ethers.getContractFactory("TokenAuthority", walletTokenAuthority);
  const contractTokenAuthority = await ContractTokenAuthority.deploy(ownerAddress);

  console.log("DEPLOYED TOKEN AUTHORITY")
  const addressTokenAuthority = contractTokenAuthority.target;
  console.log("Contract deployed to:", addressTokenAuthority);
  //   console.log("Contract: ", contractTokenAuthority)
  await contractTokenAuthority.waitForDeployment()
  const [TAPublicKeyHash, TAPublicKeyAddress] = await contractTokenAuthority.getSigningKeypairPublicKey();

  console.log("Token Authority Public Key in hash value:", TAPublicKeyHash)
  console.log("Token Authority Public Key in address value:", TAPublicKeyAddress)
  console.log("======================================")



  // SMART CONTRACT Sample.sol
  const providerMain = new ethers.JsonRpcProvider(`https://sepolia.infura.io/v3/${process.env.INFURA_PROJECT_ID}`);
  const walletMain = new ethers.Wallet(`${process.env.PRIVATE_KEY_SEPOLIA}`, providerMain);

  const ContractMain = await ethers.getContractFactory("FreeTokens", walletMain);
  const contractMain = await ContractMain.deploy(TAPublicKeyAddress);
  await contractMain.waitForDeployment();
  const addressMain = contractMain.target;
  console.log("Contract deployed to:", addressMain);
  //   console.log("Contract: ", contractMain)

  console.log("=============== GET BALANCE TRANSACTION ==============")
  let balance = await contractMain.viewBalance(deployer.address)
  console.log("Balance: ", balance)
  console.log("======================================================")

  // SUMMARY
  console.log("=====SUMMARY=====")
  console.log("\nToken Authority - Oasis Sapphire testnet\nAddress:", addressTokenAuthority)
  console.log("\nRegistered Smart Contract - Sepolia\nAddress:", addressMain)
  console.log("=================")
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
