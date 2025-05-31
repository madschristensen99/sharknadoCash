// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Proof} from "vlayer-0.1.0/Proof.sol";
import {Prover} from "vlayer-0.1.0/Prover.sol";
import {Web, WebProof, WebProofLib, WebLib} from "vlayer-0.1.0/WebProof.sol";

contract sXMRWebProver is Prover {
    using WebProofLib for WebProof;
    using WebLib for Web;

    string public constant DATA_URL =
        "http://86.38.205.119:3005/verify?txid=b96790e316edc38f5e280641229afdff19962d11037c6e3f62aea69596fc2d58&key=0d1c95e40aaebb47a98b8537e8c0318d71000b3e0fc6a7e0d01df93541796701&address=75jwJ7i21MWM5XnodztaPrevsCR5xPRNziG6WN5CVEEJPPbB4e53M8FKHoPGFBxg4vQg7LAuLgReK3yT9b2p3XHJ3CTMYXa&network=stagenet";

    function main(
        WebProof calldata webProof,
        string calldata secretKey,
        string calldata txId,
        address evmRecipientAddress,
        string calldata xmrRecipientAddress
    )
        public
        view
        returns (Proof memory, address, string memory)
    {
        Web memory web = webProof.verify(string.concat(DATA_URL));

        string memory amount = web.jsonGetString("amount");

        return (proof(), evmRecipientAddress, amount);
    }
}


