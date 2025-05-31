// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Proof} from "vlayer-0.1.0/Proof.sol";
import {Prover} from "vlayer-0.1.0/Prover.sol";
import {Web, WebProof, WebProofLib, WebLib} from "vlayer-0.1.0/WebProof.sol";

contract WebProofProver is Prover {
    using WebProofLib for WebProof;
    using WebLib for Web;

    string public constant DATA_URL =
        "https://newrepo-production-1571.up.railway.app/verify";

    function main(
        WebProof calldata webProof,
        string calldata secretKey,
        string calldata txId,
        address evmRecipientAddress,
        string calldata xmrRecipientAddress
    )
        public
        view
        returns (Proof memory, address, string memory, uint256)
    {
        string[] memory params = new string[](7);
        params[0] = DATA_URL;
        params[1] = "?txid=";
        params[2] = txId;
        params[3] = "&key=";
        params[4] = secretKey;
        params[5] = "&address=";
        params[6] = xmrRecipientAddress;

        string memory concatenated = concatStrings(params);

        Web memory web = webProof.verify(concatenated);

        int256 amount = web.jsonGetInt("amount");

        require(amount > 0, "Amount must be greater than zero");

        return (proof(), evmRecipientAddress, txId, uint256(amount));
    }

    function concatStrings(string[] memory parts) public pure returns (string memory) {
        bytes memory result;
        for (uint256 i = 0; i < parts.length; i++) {
            result = abi.encodePacked(result, parts[i]);
        }
        return string(result);
    }
}
