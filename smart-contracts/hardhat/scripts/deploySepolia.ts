import { ethers } from "hardhat";
import * as dotenv from "dotenv";

async function main() {
  const [deployer] = await ethers.getSigners();
  
  const walletAddress = deployer.address;

  const ownerAddress = process.env.INITIAL_OWNER_ADDRESS || walletAddress;

  console.log("======================================")
  console.log("DEPLOYER:", walletAddress);
  console.log("Owner address for OM and TA:", ownerAddress)
  console.log("======================================")


  // OPINION MAKER
  console.log("START DEPLOYING OPINION MAKER")
  const providerOpinionMaker = new ethers.JsonRpcProvider(`https://testnet.sapphire.oasis.io`);
  const walletOpinionMaker = new ethers.Wallet(`${process.env.PRIVATE_KEY_OASIS}`, providerOpinionMaker);
  const ContractOpinionMaker = await ethers.getContractFactory("SimpleOpinionMaker", walletOpinionMaker);
  const contractOpinionMaker = await ContractOpinionMaker.deploy(ownerAddress);

  console.log("DEPLOYED OPINION MAKER")
  const addressOpinionMaker = contractOpinionMaker.target;
  console.log("Contract deployed to:", addressOpinionMaker);
  //   console.log("Contract: ", contractOpinionMaker)
  console.log("======================================")



  // TOKEN AUTHORITY
  console.log("START DEPLOYING TOKEN AUTHORITY")
  await new Promise(r => setTimeout(r, 15000)); // timer to prevent contract crashes
  const providerTokenAuthority = new ethers.JsonRpcProvider(`https://testnet.sapphire.oasis.io`);
  const walletTokenAuthority = new ethers.Wallet(`${process.env.PRIVATE_KEY_OASIS}`, providerTokenAuthority);
  const ContractTokenAuthority = await ethers.getContractFactory("SimpleTokenAuthority", walletTokenAuthority);
  const contractTokenAuthority = await ContractTokenAuthority.deploy(ownerAddress, addressOpinionMaker);

  console.log("DEPLOYED TOKEN AUTHORITY")
  const addressTokenAuthority = contractTokenAuthority.target;
  console.log("Contract deployed to:", addressTokenAuthority);
  //   console.log("Contract: ", contractTokenAuthority)
  await new Promise(r => setTimeout(r, 15000)); // timer to prevent contract crashes
  const [TAPublicKeyHash, TAPublicKeyAddress] = await contractTokenAuthority.getSigningKeypairPublicKey();

  console.log("Token Authority Public Key in hash value:",TAPublicKeyHash)
  console.log("Token Authority Public Key in address value:", TAPublicKeyAddress)
  console.log("======================================")



  // REGISTERED SMART CONTRACT
  console.log("START DEPLOYING REGISTERED SMART CONTRACT")
  const providerMain = new ethers.JsonRpcProvider(`https://sepolia.infura.io/v3/${process.env.INFURA_PROJECT_ID}`);
  const walletMain = new ethers.Wallet(`${process.env.PRIVATE_KEY_SEPOLIA}`, providerMain);

  const ContractMain = await ethers.getContractFactory("SampleRegisteredSmartContract", walletMain);
  const contractMain = await ContractMain.deploy(TAPublicKeyAddress);
  console.log("DEPLOYED REGISTERED SMART CONTRACT")
  const addressMain = contractMain.target;
  console.log("Contract deployed to:", addressMain);
  //   console.log("Contract: ", contractMain)

  console.log("=====SUMMARY=====")
  console.log("Opinion Maker - Oasis Sapphire testnet\nAddress:", addressOpinionMaker)
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
