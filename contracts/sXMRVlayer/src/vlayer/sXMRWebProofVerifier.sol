// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {sXMRWebProver} from "./sXMRWebProver.sol";

import {Proof} from "vlayer-0.1.0/Proof.sol";
import {Verifier} from "vlayer-0.1.0/Verifier.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract sXMRWebProofVerifier is Verifier {
    using SafeERC20 for IERC20;

    address public prover;

    address public sXMRAddress;

    mapping(uint256 => string) public tokenIdToMetadataUri;

    constructor(address _prover){
        prover = _prover;
    }

    event sXMRLiqudityDeposited(uint256 amount, address provider);


    function depositLiquidity(
        uint256 amount;
    ) {
        // validate

        IERC20(sXMRAddress).safeTransferFrom(msg.sender, address(this), amount);

        emit sXMRLiqudityDeposited(amount, msg.sender);
    }

    function verifyDeposit(
        Proof calldata,
        address evmRecipientAddress,
        uint256 amount
    )
        public
        onlyVerified(prover, sXMRWebProver.main.selector)
    {
        // is validation passed - release funds

        IERC20(sXMRAddress).safeTransfer(address(this), evmRecipientAddress);
    }
}
