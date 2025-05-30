// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {WebProofProver} from "./WebProofProver.sol";

import {Proof} from "vlayer-0.1.0/Proof.sol";
import {Verifier} from "vlayer-0.1.0/Verifier.sol";

contract sXMRWebProofVerifier is Verifier {
    address public prover;

    mapping(uint256 => string) public tokenIdToMetadataUri;

    constructor(address _prover){
        prover = _prover;
    }

    function verify(
        Proof calldata,
        address evmRecipientAddress,
        uint256 amount
    )
        public
        onlyVerified(prover, WebProofProver.main.selector)
    {
        
    }
}
