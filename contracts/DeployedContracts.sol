// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title DeployedContracts
 * @dev Contains addresses of all deployed contracts for the SharknadoCash and Beraborrow integration
 * This file serves as a central reference for all contract addresses used in the project
 */
library DeployedContracts {
    // Core Protocol Addresses
    address public constant COLLATERAL_VAULT_IMPLEMENTATION = 0x6F55fcAc22678e5faECd96D434fc67ebC25Abd75;
    address public constant SORTED_DENS = 0x312711c156A8808D1bFb09c7d0Ca3A553affc3E6;
    address public constant BERABORROW_CORE = 0x12347cAF4300B1c4a9bF0Ae7DE2531A2BCFB93E9;
    address public constant NECT = 0x1cE0a25D13CE4d52071aE7e02Cf1F6606F4C79d3;
    address public constant BRIME_DEN = 0x8fAF95FeCD6e106808636C767e5C6F8B92dD1363;
    address public constant PRICE_FEED = 0xa686DC84330b1B3787816de2DaCa485D305c8589;
    address public constant BORROWER_OPERATIONS = 0xDB32cA8f3bB099A76D4Ec713a2c2AACB3d8e84B9;
    address public constant FACTORY = 0x8C2bc6eD330ce174c27487Cc1ea15ba2Ace4d3be;
    address public constant LIQUIDATION_MANAGER = 0x965dA3f96dCBfcCF3C1d0603e76356775b5afD2E;
    address public constant DEN_MANAGER_IMPLEMENTATION = 0x359Ba3964ED09e9570ce47B56e2d831D503db0a6;
    
    // Liquid Stability Pool Addresses
    address public constant LSP_IMPLEMENTATION = 0x8343a45D793688410A60d67eA17E8ce0ab3C2c24;
    address public constant LSP_PROXY = 0x597877Ccf65be938BD214C4c46907669e3E62128;
    
    // IBGT Vault Addresses
    address public constant IBGT_VAULT_IMPLEMENTATION = 0x1a29C90fA2F2f8D8744B4A8c2856035c37b772cC;
    address public constant IBGT_VAULT_PROXY = 0xE59AB0C3788217e48399Dae3CD11929789e4d3b2;
    
    // Getter Contracts
    address public constant DEN_MANAGER_GETTERS = 0xFA7908287c1f1B256831c812c7194cb95BB440e6;
    address public constant MULTI_DEN_GETTER = 0x0690d8b07eac444C76D6a0d8Af660f1cC4D1B73c;
    address public constant MULTI_COLLATERAL_HINT_HELPERS = 0x4A91b96A615D133e4196655Bc1735430ec97A391;
    address public constant LSP_GETTERS = 0xF8519658cfF16FA095A8bCEB3dCC576D94399e32;
    
    // Router Contracts
    address public constant COLL_VAULT_ROUTER = 0x5f1619FfAEfdE17F7e54f850fe90AD5EE44dbf47;
    address public constant LSP_ROUTER = 0x3A7ED65b35fDfaaCC9F0E881846A9F4E57181446;
    
    // Validator Pool
    address public constant VALIDATOR_POOL = 0x6F801d4610c5aE21ea28e255fB7c9c20480BA07a;
    
    // Oracle Addresses and Price Feed IDs
    address public constant BERACHAIN_PYTH_ORACLE = 0x2880aB155794e7179c9eE2e38200202908C17B43;
    bytes32 public constant XMR_USD_PYTH_PRICE_ID = 0x46b8cc9347f04391764a0361e0b17c3ba394b001e7c304f7650f6376e37c321d;
}
