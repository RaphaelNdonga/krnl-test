// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SimpleOpinionMaker is Ownable {
  constructor(address initialOwner) Ownable(initialOwner) {}

  struct Execution {
    uint kernelId;
    bytes result;
    bytes proof;
    bool isValidated;
  }

  // keys are sorted alphabatically based on the resopnses in the uploaded open api specs
    struct Kernel2Result {
      string decNum;
      string decStr;
      string id;
      int num;
      bool flag;
      string name;
      address addr;
      string score;
    }

  // example use case: only give 'true' opinion when all kernels are executed with expected results and proofs
  function getOpinion(bytes calldata executionPlan, uint kernelId) onlyOwner external view returns (bool, bool, bytes memory) {
    (bool opinion, bool isFinalized, bytes memory _executionPlan) = _validateExecution(executionPlan, kernelId);

    return (opinion, isFinalized, _executionPlan);
  }

  function _validateExecution(bytes calldata executionPlan, uint kernelId) private pure returns (bool, bool, bytes memory) {
    bool _opinion;
    bool _isFinalized;

    Execution[] memory _executions = abi.decode(executionPlan, (Execution[]));

    for (uint256 i = 0; i < _executions.length; i++) {
      Execution memory _execution = _executions[i];
      if (_execution.kernelId == kernelId) {
        // Kernel 4: MultiView Option 5
        if (kernelId == 1) {
          (bool res1, uint res2) = abi.decode(_execution.result, (bool,uint256));
          (bool proof) = abi.decode(_execution.proof, (bool));

          // criteria
          if (res1 && res2 != 0 && proof) {
              _opinion = true;
          } else {
              _isFinalized = true;
          }   
        // Kernel 3: MockAPI
        } else if (kernelId == 2) {
          (Kernel2Result memory res) = abi.decode(_execution.result, (Kernel2Result));
          (bool proof) = abi.decode(_execution.proof, (bool));
          
          // criteria
          if (res.addr != address(0) && res.flag && proof) {
              _opinion = true;
          } else {
              _isFinalized = true;
          }
        }

        if (i == _executions.length - 1) {
          _isFinalized = true;
        }

        _execution.isValidated = true;

        break;
      }
    }

    return (_opinion, _isFinalized, abi.encode(_executions));
  }
}