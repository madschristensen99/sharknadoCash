// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Counter} from "../src/Counter.sol";
import { WebProofVerifier } from "../src/vlayer/WebProofVerifier.sol";

contract DeployVerifier is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIV");
        vm.startBroadcast(deployerPrivateKey);

        WebProofVerifier simpleProver = new WebProofVerifier(address(0xe5986C4fe91D4D50c5716DF805D877E31548c357));
        console.log("SimpleProver contract deployed to:", address(simpleProver));
    }
}
