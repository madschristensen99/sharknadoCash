// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import {Strings} from "@openzeppelin-contracts-5.0.1/utils/Strings.sol";

// import {Proof} from "vlayer-0.1.0/Proof.sol";
// import {Prover} from "vlayer-0.1.0/Prover.sol";
// import {Web, WebProof, WebProofLib, WebLib} from "vlayer-0.1.0/WebProof.sol";

// contract sXMRTransactionProver is Prover {
//     using Strings for string;
//     using WebProofLib for WebProof;
//     using WebLib for Web;

//     string constant DATA_URL = "https://localmonero.co/blocks/tx/";

//     function main(
//         WebProof calldata webProof,
//         string secretKey,
//         string txId,
//         address evmRecipientAddress,
//         string xmrRecipientAddress
//     )
//         public
//         view
//         returns (Proof memory, string memory, address)
//     {
//         Web memory web = webProof.verify(DATA_URL + txId + '?xmraddress' + xmrRecipientAddress + '&txprvkey=60166f73264a77544b7aa287d45d82b91bba023358ffd00c227489dbc48d5809');

//         uint256 amount = web.jsonGetUint("amount");

//         return (proof(), evmRecipientAddress, amount);
//     }
// }
