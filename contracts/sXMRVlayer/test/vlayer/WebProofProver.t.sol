// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {VTest} from "vlayer-0.1.0/testing/VTest.sol";
import {WebProof, Web} from "vlayer-0.1.0/WebProof.sol";
import {Proof} from "vlayer-0.1.0/Proof.sol";

import { sXMRWebProver } from "../../src/vlayer/sXMRWebProver.sol";

contract WebProverTest is VTest {
    // using Strings for string;

    function test_verifiesWebProofAndRetrievesScreenName() public {
        WebProof memory webProof = WebProof(
            vm.readFile("testdata/web_proof.json")
        );
        sXMRWebProver prover = new sXMRWebProver();
        address account = vm.addr(1);

        string memory secretKey = "60166f73264a77544b7aa287d45d82b91bba023358ffd00c227489dbc48d5809";
        string memory txId = "250908a82e2ec72f20aab8072ab045c2bc1da531588a1a5b977052f3487d86a0";
        address evmRecipientAddress = vm.addr(1);
        string memory xmrRecipientAddress = "82Yy6ygohJZdungHrXovdDjdpAu31iGPsXTTZRnPYadgJ9735P8eBweHK5djgovYQhEqssjRaNZ4hhi1e3MyaS28T1X471g";

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

        assertEq(amount, "0");
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
