// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {WebProofProver} from "./WebProofProver.sol";

import {Proof} from "vlayer-0.1.0/Proof.sol";
import {Verifier} from "vlayer-0.1.0/Verifier.sol";
import { ERC20 } from "@openzeppelin-contracts-5.0.1/token/ERC20/ERC20.sol";

// import {ERC721} from "@openzeppelin-contracts-5.0.1/token/ERC721/ERC721.sol";

contract WebProofVerifier is Verifier {
    // using SafeERC20 for IERC20;

    address public prover;

    address public sXMRAddress;

    mapping(string => bool) public withdrawTxIdRequestCompleted;
    mapping(address => uint256) public depositedLiqudity;

    constructor(address _prover){
        prover = _prover;
    }

    event sXMRLiqudityDeposited(uint256 amount, address depositor);
    event sXMRWithdrawRequest(uint256 amount, string xmrAddress);
    event sXMRWLiquidityWithdraw(uint256 amount, address depositor);
    event sXMRWithdrawn(uint256 amount, address withdrawOperator);
    event xmrDeposited(uint256 amount, address recipient);

    function depositLiquidity(
        uint256 amount
    )
        public
    {
        // validate

        ERC20(sXMRAddress).transferFrom(msg.sender, address(this), amount);

        depositedLiqudity[msg.sender] += amount;

        emit sXMRLiqudityDeposited(amount, msg.sender);
    }

    function withdrawLiquidity(
        uint256 amount
    )
        public
    {
        require(depositedLiqudity[msg.sender] >= amount, "Insufficient liquidity");

        depositedLiqudity[msg.sender] -= amount;

        ERC20(sXMRAddress).transfer(msg.sender, amount);

        emit sXMRWLiquidityWithdraw(amount, msg.sender); // xmrAddress is not used here
    }

    // called by the depositor from XMR to ETH
    function verifyDeposit(
        Proof calldata,
        address evmRecipientAddress,
        string calldata amount
    )
        public
        onlyVerified(prover, WebProofProver.main.selector)
    {
        // is validation passed - release funds

        ERC20(sXMRAddress).transfer(evmRecipientAddress, amount);

        emit xmrDeposited(amount, evmRecipientAddress);
    }

    // called by the withdraw operator from ETH to XMR
    function verifyWithdraw(
        Proof calldata,
        address withdrawOperator,
        uint256 amount,
        string calldata input
    )
        public
        onlyVerified(prover, WebProofProver.main.selector)
    {
        // is validation passed - release funds

        ERC20(sXMRAddress).transfer(withdrawOperator, amount);

        emit sXMRWithdrawn(amount, withdrawOperator);
    }

    // called by the user to request withdraw
    function withdraw(
        string calldata xmrAddress,
        uint256 amount
    )
        public
    {
        ERC20(sXMRAddress).transferFrom(msg.sender, address(this), amount);

        emit sXMRWithdrawRequest(amount, xmrAddress);
    }
}
