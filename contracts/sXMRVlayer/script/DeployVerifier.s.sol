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

        WebProofVerifier simpleProver = new WebProofVerifier(address(0x38998FB1f83E0ff509d22A4369C90675b02F31ee), address(0x97028eA42bC77124c0e44EcEB7229c3EeDC3d257));
        console.log("SimpleProver contract deployed to:", address(simpleProver));
    }
}
