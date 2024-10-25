// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@oasisprotocol/sapphire-contracts/contracts/Sapphire.sol";
import "@oasisprotocol/sapphire-contracts/contracts/EthereumUtils.sol";

contract SimpleTokenAuthority is Ownable {
  Keypair private signingKeypair;
  Keypair private accessKeypair;
  bytes32 private signingKeypairRetrievalPassword;
  address private opinionMaker;

  // https://api.docs.oasis.io/sol/sapphire-contracts/contracts/Sapphire.sol/library.Sapphire.html#secp256k1--secp256r1
  struct Keypair {
    bytes pubKey;
    bytes privKey;
  }

  struct Execution {
    uint kernelId;
    bytes result;
    bytes proof;
    bool isValidated;
  }

  mapping(address => bool) private whitelist; // krnlNodePubKey to bool
  mapping(bytes32 => bool) private runtimeDigests; // runtimeDigest to bool
  mapping(uint => bool) private kernels; // kernelId to bool

  constructor(address initialOwner, address _opinionMaker) Ownable(initialOwner) {
    signingKeypair = _generateKey();
    accessKeypair = _generateKey();
    opinionMaker = _opinionMaker;
  }

  modifier onlyAuthorized(bytes calldata auth) {
    (bytes32 entryId, bytes memory accessToken, bytes32 runtimeDigest, bytes memory runtimeDigestSignature) = abi.decode(auth, (bytes32, bytes, bytes32, bytes));
    require(_verifyAccessToken(entryId, accessToken));
    _;
  }

  modifier onlyValidated(bytes calldata executionPlan) {
    require(_verifyExecutionPlan(executionPlan));
     _;
  }

  modifier onlyAllowedKernel(uint kernelId) {
    require(kernels[kernelId]);
     _;
  }

  function _generateKey() private view returns (Keypair memory) {
    bytes memory seed = Sapphire.randomBytes(32, "");
    (bytes memory pubKey, bytes memory privKey) = Sapphire.generateSigningKeyPair(Sapphire.SigningAlg.Secp256k1PrehashedKeccak256, seed);

    return Keypair(pubKey, privKey);
  }

  function _verifyAccessToken(bytes32 entryId, bytes memory accessToken) private view returns (bool) {
    bytes memory digest =abi.encodePacked(keccak256(abi.encode(entryId)));

    return Sapphire.verify(Sapphire.SigningAlg.Secp256k1PrehashedKeccak256, accessKeypair.pubKey, digest,"", accessToken);
  }

  function _verifyRuntimeDigest(bytes32 runtimeDigest, bytes memory runtimeDigestSignature) private view returns (bool) {
    bytes32 digest = MessageHashUtils.toEthSignedMessageHash(runtimeDigest);
    address recoverPubKeyAddr = ECDSA.recover(digest, runtimeDigestSignature);

    return whitelist[recoverPubKeyAddr];
  }

  function _verifyExecutionPlan(bytes calldata executionPlan) private pure returns (bool) {
    Execution[] memory executions = abi.decode(executionPlan, (Execution[]));

    for (uint i = 0; i < executions.length; i++) {
      if (!executions[i].isValidated) {
        return false;
      }
    }

    return true;
  }

  function setOpinionMaker(address _opinionMaker) onlyOwner external {
    opinionMaker = _opinionMaker;
  }

  function setSigningKeypair(bytes calldata pubKey, bytes calldata privKey) onlyOwner external {
    signingKeypair = Keypair(pubKey, privKey);
  }

  function setSigningKeypairRetrievalPassword(string calldata _password) onlyOwner external {
    signingKeypairRetrievalPassword = keccak256(abi.encodePacked(_password));
  }

  function getSigningKeypairPublicKey() external view returns (bytes memory, address) {
    address signingKeypairAddress = EthereumUtils.k256PubkeyToEthereumAddress(signingKeypair.pubKey);

    return (signingKeypair.pubKey, signingKeypairAddress);
  }

  function getSigningKeypairPrivateKey(string calldata _password) onlyOwner external view returns (bytes memory) {
    require(signingKeypairRetrievalPassword == keccak256(abi.encodePacked(_password)));

    return signingKeypair.privKey;
  }

  function setWhitelist(address krnlNodePubKey, bool allowed) onlyOwner external {
    whitelist[krnlNodePubKey] = allowed;
  }

  function setRuntimeDigest(bytes32 runtimeDigest, bool allowed) onlyOwner external {
    runtimeDigests[runtimeDigest] = allowed;
  }

  function setKernel(uint kernelId, bool allowed) onlyOwner external {
    kernels[kernelId] = allowed;
  }

  function registerdApp(bytes32 entryId) external view returns(bytes memory) {
    bytes memory digest = abi.encodePacked(keccak256(abi.encode(entryId)));
    bytes memory accessToken = Sapphire.sign(Sapphire.SigningAlg.Secp256k1PrehashedKeccak256, accessKeypair.privKey, digest, "");
    
    return accessToken;
  }

  function isKernelAllowed(bytes calldata auth, uint kernelId) onlyAuthorized(auth) external view returns (bool) {
    return true;
  }

  function getOpinion(bytes calldata auth, bytes calldata executionPlan, uint kernelId) onlyAuthorized(auth) external view returns (bool, bool, bytes memory) {
    (bool success, bytes memory data) = opinionMaker.staticcall(
      abi.encodeWithSignature("getOpinion(bytes,uint256)", executionPlan, kernelId)
    );
    require(success);

    (bool opinion, bool isFinalized, bytes memory _executionPlan) = abi.decode(data, (bool, bool, bytes));

    return (opinion, isFinalized, _executionPlan);
  }

  function sign(bytes calldata auth, address senderAddress, bytes calldata executionPlan, bytes calldata functionParams, bytes calldata kernelParamObjects, bytes calldata kernelResponses) onlyAuthorized(auth) onlyValidated(executionPlan) external view returns(bytes memory, bytes32, bytes memory, bytes32) {
    bytes32 kernelResponsesDigest = keccak256(abi.encode(kernelResponses, senderAddress));
    bytes memory kernelResponsesSignature = Sapphire.sign(Sapphire.SigningAlg.Secp256k1PrehashedKeccak256, abi.encodePacked(signingKeypair.privKey), abi.encode(kernelResponsesDigest), "");
    
    bytes32 functionParamsDigest = keccak256(abi.encode(functionParams));
    bytes32 kernelParamObjectsDigest = keccak256(abi.encode(kernelParamObjects, senderAddress));
    bytes32 nonce = bytes32(Sapphire.randomBytes(32, ""));
    bytes32 dataDigest = keccak256(abi.encode(functionParamsDigest, kernelParamObjectsDigest, senderAddress, nonce));
    
    bytes memory signatureToken = Sapphire.sign(Sapphire.SigningAlg.Secp256k1PrehashedKeccak256, abi.encodePacked(signingKeypair.privKey), abi.encode(dataDigest), "");

    return (kernelResponsesSignature, kernelParamObjectsDigest, signatureToken, nonce);
  }
}