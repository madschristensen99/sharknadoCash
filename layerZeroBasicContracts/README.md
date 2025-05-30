<p align="center">
  <a href="https://layerzero.network">
    <img alt="LayerZero" style="width: 400px" src="https://docs.layerzero.network/img/LayerZero_Logo_White.svg"/>
  </a>
</p>

<p align="center">
  <a href="https://layerzero.network" style="color: #a77dff">Homepage</a> | <a href="https://docs.layerzero.network/" style="color: #a77dff">Docs</a> | <a href="https://layerzero.network/developers" style="color: #a77dff">Developers</a>
</p>

<h1 align="center">OFTAdapter Example</h1>

<p align="center">
  <a href="https://docs.layerzero.network/v2/developers/evm/oft/adapter" style="color: #a77dff">Quickstart</a> | <a href="https://docs.layerzero.network/contracts/oapp-configuration" style="color: #a77dff">Configuration</a> | <a href="https://docs.layerzero.network/contracts/options" style="color: #a77dff">Message Execution Options</a> | <a href="https://docs.layerzero.network/contracts/endpoint-addresses" style="color: #a77dff">Endpoint Addresses</a>
</p>

<p align="center">Template project for getting started with LayerZero's <code>OFTAdapter</code> contract development.</p>

### OFTAdapter additional setup:

- In your `hardhat.config.ts` file, add the following configuration to the network you want to deploy the OFTAdapter to:
  ```typescript
  // Replace `0x0` with the address of the ERC20 token you want to adapt to the OFT functionality.
  oftAdapter: {
      tokenAddress: '0x0',
  }
  ```

## 1) Developing Contracts

#### Installing dependencies

We recommend using `pnpm` as a package manager (but you can of course use a package manager of your choice):

```bash
pnpm install
```

#### Compiling your contracts

This project supports both `hardhat` and `forge` compilation. By default, the `compile` command will execute both:

```bash
pnpm compile
```

If you prefer one over the other, you can use the tooling-specific commands:

```bash
pnpm compile:forge
pnpm compile:hardhat
```

Or adjust the `package.json` to for example remove `forge` build:

```diff
- "compile": "$npm_execpath run compile:forge && $npm_execpath run compile:hardhat",
- "compile:forge": "forge build",
- "compile:hardhat": "hardhat compile",
+ "compile": "hardhat compile"
```

#### Running tests

Similarly to the contract compilation, we support both `hardhat` and `forge` tests. By default, the `test` command will execute both:

```bash
pnpm test
```

If you prefer one over the other, you can use the tooling-specific commands:

```bash
pnpm test:forge
pnpm test:hardhat
```

Or adjust the `package.json` to for example remove `hardhat` tests:

```diff
- "test": "$npm_execpath test:forge && $npm_execpath test:hardhat",
- "test:forge": "forge test",
- "test:hardhat": "$npm_execpath hardhat test"
+ "test": "forge test"
```

## 2) Deploying Contracts

Set up deployer wallet/account:

- Create `.env` file following `.env.example`
- Choose your preferred means of setting up your deployer wallet/account:

To deploy your contracts to your desired blockchains, run the following command:

This command will deploy both `sXMRAdapter` and `xXMR` contracts to selected networks. You should choose either `sepolia` or `mainnet` netwoks depending on your needs. Currently the deploy is optimized for `sepolia` network. If you want to deploy to `mainnet`, navigate to `layerzero.config.ts` and change contracts `eids` to commented ones.

```bash
npx hardhat lz:deploy
```

More information about available CLI arguments can be found using the `--help` flag:

```bash
npx hardhat lz:deploy --help
```

To wire deployed contracts together navigate to the `layerzero.config.ts` file, review the `eid` fields and connections between contracts. After that you can run following command:

```bash
npx hardhat lz:oapp:wire --oapp-config layerzero.config.ts
```

To check if contracts were indeed wired, run the following command:

```bash
npx hardhat lz:oapp:peers:get --oapp-config layerzero.config.ts
```

To verify the contracts, you can use the following command:

```bash
npx @layerzerolabs/verify-contract -d "./deployments" -n "<DEPLOYMENT_CHAIN>" -u "https://api.etherscan.io/api" -k "<API_KEY>"
```

example:

```bash
npx @layerzerolabs/verify-contract -d "./deployments" -n "ethereum-sepolia" -u "https://api.etherscan.io/api -k "X9A7B6C5D4E3F2G1H0I9J8K7L6M5N4O3"
```

By following these steps, you can focus more on creating innovative omnichain solutions and less on the complexities of cross-chain communication.

<br></br>

<p align="center">
  Join our community on <a href="https://discord-layerzero.netlify.app/discord" style="color: #a77dff">Discord</a> | Follow us on <a href="https://twitter.com/LayerZero_Labs" style="color: #a77dff">Twitter</a>
</p>
