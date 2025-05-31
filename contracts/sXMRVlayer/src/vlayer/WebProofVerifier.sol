// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {WebProofProver} from "./WebProofProver.sol";

import {Proof} from "vlayer-0.1.0/Proof.sol";
import {Verifier} from "vlayer-0.1.0/Verifier.sol";
import { ERC20 } from "@openzeppelin-contracts-5.0.1/token/ERC20/ERC20.sol";

contract WebProofVerifier is Verifier {
    address public prover;

    address public sXMRAddress;

    mapping(address => uint256) public depositedLiqudity;
    mapping(address => uint256) public withdrawRequests;
    mapping(bytes32 => bool) private proceededtxIds;

    constructor(address _prover, address _sXMRAddress) {
        prover = _prover;
        sXMRAddress = _sXMRAddress;
    }

    event sXMRLiqudityDeposited(uint256 amount, address depositor);
    event xmrDeposited(uint256 amount, address recipient);
    event withdrawnLiquidity(uint256 amount, address requester);

    function depositLiquidity(
        uint256 amount
    )
        public
    {
        ERC20(sXMRAddress).transferFrom(msg.sender, address(this), amount);

        depositedLiqudity[msg.sender] += amount;

        emit sXMRLiqudityDeposited(amount, msg.sender);
    }

    function withdrawLiquidity(
        uint256 amount
    )
        public
    {
        require(
            depositedLiqudity[msg.sender] >= amount,
            "Insufficient liquidity"
        );

        depositedLiqudity[msg.sender] -= amount;

        ERC20(sXMRAddress).transfer(msg.sender, amount);

        emit withdrawnLiquidity(amount, msg.sender);
    }

    function verifyDeposit(
        Proof calldata,
        address evmRecipientAddress,
        string calldata txId,
        uint256 amount
    )
        public
        onlyVerified(prover, WebProofProver.main.selector)
    {
        bytes32 keyHash = keccak256(abi.encodePacked(txId));

        require(
            proceededtxIds[keyHash] == false,
            "Key already used"
        );

        proceededtxIds[keyHash] = true;

        ERC20(sXMRAddress).transfer(evmRecipientAddress, amount);

        emit xmrDeposited(amount, evmRecipientAddress);
    }
}
