// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Counter} from "../src/Counter.sol";
import { WebProofProver } from "../src/vlayer/WebProofProver.sol";

contract SimpleScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIV");
        vm.startBroadcast(deployerPrivateKey);

        WebProofProver simpleProver = new WebProofProver();
        console.log("SimpleProver contract deployed to:", address(simpleProver));
    }
}
