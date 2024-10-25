// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

// Struct to group the parameters
struct KrnlPayload {
    bytes auth;
    bytes kernelResponses;
    bytes kernelParamObjects;
}

// Draft Version
contract KrnlRegistered is Ownable {
    error UnauthorizedTransaction();

    address public tokenAuthorityPublicKey;
    mapping(bytes => bool) public executed;

    modifier onlyAuthorized(KrnlPayload memory krnlPayload, bytes memory params) {
        if (!_isAuthorized(krnlPayload, params)) {
            revert UnauthorizedTransaction();
        }

        _;
    }

    constructor(address _tokenAuthorityPublicKey) Ownable(msg.sender) {
        tokenAuthorityPublicKey = _tokenAuthorityPublicKey;
    }

    function setTokenAuthorityPublicKey(address _tokenAuthorityPublicKey) external onlyOwner {
        tokenAuthorityPublicKey = _tokenAuthorityPublicKey;
    }

    function _isAuthorized(KrnlPayload memory krnlPayload, bytes memory params) private returns (bool) {
        (
            bytes memory kernelResponsesSignature,
            bytes32 kernelParamObjectsDigest,
            bytes memory signatureToken,
            bytes32 nonce
        ) = abi.decode(krnlPayload.auth, (bytes, bytes32, bytes, bytes32));

        if (executed[signatureToken]) {
            return false;
        }

        bytes32 kernelResponsesDigest = keccak256(abi.encode(krnlPayload.kernelResponses, msg.sender));
        bytes32 ethSignedKernelResponsesDigest = MessageHashUtils.toEthSignedMessageHash(kernelResponsesDigest);
        address recoveredAddress = ECDSA.recover(ethSignedKernelResponsesDigest, kernelResponsesSignature);
        if (recoveredAddress != tokenAuthorityPublicKey) {
            return false;
        }

        bytes32 calculatedKernelParamObjectsDigest = keccak256(abi.encode(krnlPayload.kernelParamObjects, msg.sender));
        if (calculatedKernelParamObjectsDigest != kernelParamObjectsDigest) {
            return false;
        }

        bytes32 functionParamsDigest = keccak256(abi.encode(params));

        bytes32 dataDigest = keccak256(abi.encode(functionParamsDigest, kernelParamObjectsDigest, msg.sender, nonce));
        bytes32 ethSignedDataDigest = MessageHashUtils.toEthSignedMessageHash(dataDigest);
        recoveredAddress = ECDSA.recover(ethSignedDataDigest, signatureToken);
        if (recoveredAddress != tokenAuthorityPublicKey) {
            return false;
        }

        executed[signatureToken] = true;
        return true;
    }
}