// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {VTest} from "vlayer-0.1.0/testing/VTest.sol";
import {WebProof, Web} from "vlayer-0.1.0/WebProof.sol";
import {Proof} from "vlayer-0.1.0/Proof.sol";

import { WebProofProver } from "../../src/vlayer/WebProofProver.sol";

contract WebProverTest is VTest {
    // using Strings for string;

    function test_verifiesWebProofAndRetrievesAddressAndAmount() public {
        WebProof memory webProof = WebProof(
            vm.readFile("testdata/web_proof.json")
        );
        WebProofProver prover = new WebProofProver();
        address account = vm.addr(1);

        string memory DATA_URL = "https://86.38.205.119:3005/verify"; 
        string memory secretKey = "0d1c95e40aaebb47a98b8537e8c0318d71000b3e0fc6a7e0d01df93541796701";
        string memory txId = "b96790e316edc38f5e280641229afdff19962d11037c6e3f62aea69596fc2d58";
        address evmRecipientAddress = vm.addr(1);
        string memory xmrRecipientAddress = "75jwJ7i21MWM5XnodztaPrevsCR5xPRNziG6WN5CVEEJPPbB4e53M8FKHoPGFBxg4vQg7LAuLgReK3yT9b2p3XHJ3CTMYXa";

        string[] memory params = new string[](7);
        params[0] = DATA_URL;
        params[1] = "?txid=";
        params[2] = txId;
        params[3] = "&key=";
        params[4] = secretKey;
        params[5] = "&address=";
        params[6] = xmrRecipientAddress;

        string memory concatRes = prover.concatStrings(params);

        assertEq(concatRes, "https://86.38.205.119:3005/verify?txid=b96790e316edc38f5e280641229afdff19962d11037c6e3f62aea69596fc2d58&key=0d1c95e40aaebb47a98b8537e8c0318d71000b3e0fc6a7e0d01df93541796701&address=75jwJ7i21MWM5XnodztaPrevsCR5xPRNziG6WN5CVEEJPPbB4e53M8FKHoPGFBxg4vQg7LAuLgReK3yT9b2p3XHJ3CTMYXa");

        callProver();
        (, address recipient, string memory amount) = prover.main(
            webProof,
            secretKey,
            txId,
            evmRecipientAddress,
            xmrRecipientAddress
        );
        

        // assert(screenName.equal("wktr0"));

        // uint256 amount = 0; // Replace with actual amount from webProof

        // assertEq(recipient, evmRecipientAddress);

        // assertEq(secretKey , "60166f73264a77544b7aa287d45d82b91bba023358ffd00c227489dbc48d5809");
    }

    // function test_failedVerificationBecauseOfInvlidNotaryPublicKey() public {
    //     WebProof memory webProof = WebProof(
    //         vm.readFile("testdata/web_proof_invalid_notary_pub_key.json")
    //     );
    //     WebProofProver prover = new WebProofProver();
    //     address account = vm.addr(1);

    //     callProver();
    //     try prover.main(webProof, account) returns (
    //         Proof memory,
    //         string memory,
    //         address
    //     ) {
    //         revert("Expected error");
    //     } catch Error(string memory reason) {
    //         assertEq(
    //             reason,
    //             'Preflight: Transaction reverted: ContractError(Revert(Revert("Invalid notary public key")))'
    //         );
    //     }
    // }
}