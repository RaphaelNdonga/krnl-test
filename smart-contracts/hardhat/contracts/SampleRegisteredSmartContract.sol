// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {KrnlRegistered, KrnlPayload} from "./KrnlRegistered.sol";

// Draft Version
contract SampleRegisteredSmartContract is KrnlRegistered {
    constructor(address _tokenAuthorityPublicKey) KrnlRegistered(_tokenAuthorityPublicKey) {}

    mapping(uint256 => string) sampleMapping;

    // protected function
    function protectedFunction(
        KrnlPayload memory krnlPayload,
        uint256 key,
        string memory value
    )
        external
        onlyAuthorized(krnlPayload, abi.encodePacked(key, value))
    {
        // implementation
        sampleMapping[key] = value;
    }

    function getFunction(uint256 key) external view returns (string memory) {
        return sampleMapping[key];
    }
}