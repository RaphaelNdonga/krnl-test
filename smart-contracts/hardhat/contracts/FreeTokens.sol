// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {KRNL, KrnlPayload, KernelParameter, KernelResponse} from "./KRNL.sol";

contract FreeTokens is ERC20, KRNL {
    // Token Authority public key as a constructor
    uint256 balance;
    constructor(
        address _tokenAuthorityPublicKey
    ) KRNL(_tokenAuthorityPublicKey) ERC20("Free Token", "FreeTKN") {
        _mint(msg.sender, 100);
        balance = balanceOf(msg.sender);
    }

    // Results from kernel will be emitted through this event
    event Broadcast(address sender, uint256 score, string message);

    function protectedFunction(
        KrnlPayload memory krnlPayload,
        string memory input
    ) external onlyAuthorized(krnlPayload, abi.encode(input)) {
        // Decode response from kernel
        KernelResponse[] memory kernelResponses = abi.decode(
            krnlPayload.kernelResponses,
            (KernelResponse[])
        );
        uint256 balance_2;
        for (uint i; i < kernelResponses.length; i++) {
            if (kernelResponses[i].kernelId == 475) {
                balance_2 = abi.decode(kernelResponses[i].result, (uint256));
            }
        }

        // Emitting an event
        emit Broadcast(msg.sender, balance_2, input);
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
    function viewBalance(address account) external view returns (uint256) {
        return balanceOf(account);
    }
}
