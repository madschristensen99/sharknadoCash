// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Proof} from "vlayer-0.1.0/Proof.sol";
import {Prover} from "vlayer-0.1.0/Prover.sol";
import {Web, WebProof, WebProofLib, WebLib} from "vlayer-0.1.0/WebProof.sol";

contract WebProofProver is Prover {
    using WebProofLib for WebProof;
    using WebLib for Web;

    string public constant DATA_URL =
        "https://localmonero.co/blocks/tx/";

    function main(
        WebProof calldata webProof,
        string calldata secretKey,
        string calldata txId,
        address evmRecipientAddress,
        string calldata xmrRecipientAddress
    )
        public
        view
        returns (Proof memory, string memory, address)
    {
        // Web memory web = webProof.verify(string.concat(DATA_URL, txId, '?xmraddress', xmrRecipientAddress, '&txprvkey=', secretKey));

        uint256 amount; // = web.jsonGetUint("amount");

        return (proof(), evmRecipientAddress, amount);
    }
}


