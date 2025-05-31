// import { createVlayerClient } from "@vlayer/sdk";
// import proverSpec from "../out/WebProofProver.sol/WebProofProver";
// import verifierSpec from "../out/WebProofVerifier.sol/WebProofVerifier";
// import web_proof from "../testdata/web_proof.json";
// import web_proof_invalid_signature from "../testdata/web_proof_invalid_notary_pub_key.json";
// import * as assert from "assert";
// import { encodePacked, keccak256 } from "viem";

// import {
//   getConfig,
//   createContext,
//   deployVlayerContracts,
//   writeEnvVariables,
// } from "@vlayer/sdk/config";

// let config = getConfig();

// const { prover, verifier } = await deployVlayerContracts({
//   proverSpec,
//   verifierSpec,
// });

// console.log(prover);

// await writeEnvVariables(".env", {
//   VITE_PROVER_ADDRESS: prover,
//   VITE_VERIFIER_ADDRESS: verifier,
// });

// config = getConfig();
// const { chain, ethClient, account, proverUrl, confirmations } =
//   createContext(config);

// console.log("Chain:", chain.name);

// if (!account) {
//   throw new Error(
//     "No account found make sure EXAMPLES_TEST_PRIVATE_KEY is set in your environment variables",
//   );
// }

// const twitterUserAddress = account.address;
// const vlayer = createVlayerClient({
//   url: proverUrl,
//   token: config.token,
// });

// await testSuccessProvingAndVerification({
//   chain,
//   ethClient,
//   account,
//   confirmations,
// });

// await testFailedProving({ chain });

// async function testSuccessProvingAndVerification({
//   chain,
//   ethClient,
//   account,
//   confirmations,
// }: Required<
//   Pick<
//     ReturnType<typeof createContext>,
//     "chain" | "ethClient" | "account" | "confirmations"
//   >
// >) {
//   console.log("Proving...");

//   const hash = await vlayer.prove({
//     address: prover,
//     functionName: "main",
//     proverAbi: proverSpec.abi,
//     args: [
//       {
//         webProofJson: JSON.stringify(web_proof),
//       },
//       "0d1c95e40aaebb47a98b8537e8c0318d71000b3e0fc6a7e0d01df93541796701",
//       "b96790e316edc38f5e280641229afdff19962d11037c6e3f62aea69596fc2d58",
//       "0x2D0bf6D3BD0636eec331f7c2861F44D74a2dcaC3",
//       "75jwJ7i21MWM5XnodztaPrevsCR5xPRNziG6WN5CVEEJPPbB4e53M8FKHoPGFBxg4vQg7LAuLgReK3yT9b2p3XHJ3CTMYXa",
//     ],
//     chainId: chain.id,
//     gasLimit: config.gasLimit,
//   });
//   console.log(hash);

//   const result = await vlayer.waitForProvingResult({ hash });
//   const [proof, twitterHandle, address] = result;


  // console.log("Verifying...");

  // // Workaround for viem estimating gas with `latest` block causing future block assumptions to fail on slower chains like mainnet/sepolia
  // const gas = await ethClient.estimateContractGas({
  //   address: verifier,
  //   abi: verifierSpec.abi,
  //   functionName: "verify",
  //   args: [proof, twitterHandle, address],
  //   account,
  //   blockTag: "pending",
  // });

  // const txHash = await ethClient.writeContract({
  //   address: verifier,
  //   abi: verifierSpec.abi,
  //   functionName: "verify",
  //   args: [proof, twitterHandle, address],
  //   chain,
  //   account,
  //   gas,
  // });

  // await ethClient.waitForTransactionReceipt({
  //   hash: txHash,
  //   confirmations,
  //   retryCount: 60,
  //   retryDelay: 1000,
  // });

  // console.log("Verified!");

  // const balance = await ethClient.readContract({
  //   address: verifier,
  //   abi: verifierSpec.abi,
  //   functionName: "balanceOf",
  //   args: [twitterUserAddress],
  // });

  // assert.strictEqual(balance, 1n);

  // const tokenOwnerAddress = await ethClient.readContract({
  //   address: verifier,
  //   abi: verifierSpec.abi,
  //   functionName: "ownerOf",
  //   args: [generateTokenId(twitterHandle)],
  // });

  // assert.strictEqual(twitterUserAddress, tokenOwnerAddress);

  // const tokenURI = await ethClient.readContract({
  //   address: verifier,
  //   abi: verifierSpec.abi,
  //   functionName: "tokenURI",
  //   args: [generateTokenId(twitterHandle)],
  // });

  // assert.strictEqual(
  //   tokenURI,
  //   `https://faucet.vlayer.xyz/api/xBadgeMeta?handle=${twitterHandle}`,
  // );
//}



// async function testFailedProving({
//   chain,
// }: Pick<ReturnType<typeof createContext>, "chain">) {
//   try {
//     const hash = await vlayer.prove({
//       address: prover,
//       functionName: "main",
//       proverAbi: proverSpec.abi,
//       args: [
//         {
//           webProofJson: JSON.stringify(web_proof_invalid_signature),
//         },
//         twitterUserAddress,
//       ],
//       chainId: chain.id,
//       gasLimit: config.gasLimit,
//     });
//     await vlayer.waitForProvingResult({ hash });
//     throw new Error("Proving should have failed!");
//   } catch (error) {
//     assert.ok(
//       error instanceof Error,
//       `Invalid error returned: ${error as string}`,
//     );
//     assert.equal(
//       error.message,
//       'Preflight failed with error: Preflight: Transaction reverted: ContractError(Revert(Revert("Invalid notary public key")))',
//       `Error with wrong message returned: ${error.message}`,
//     );
//     console.log("✅ Done");
//   }
// }

// function generateTokenId(username: string): bigint {
//   return BigInt(keccak256(encodePacked(["string"], [username])));
// }



/// <reference types="bun" />

import { createVlayerClient } from "@vlayer/sdk";
import proverSpec from "../out/WebProofProver.sol/WebProofProver";
import verifierSpec from "../out/WebProofVerifier.sol/WebProofVerifier";
import web_proof from "../testdata/web_proof.json";
import web_proof_invalid_signature from "../testdata/web_proof_invalid_notary_pub_key.json";
import * as assert from "assert";
import { encodePacked, keccak256 } from "viem";

import {
  getConfig,
  createContext,
  deployVlayerContracts,
  writeEnvVariables,
} from "@vlayer/sdk/config";
import { spawn } from "child_process";
import { get } from "http";

const URL_TO_PROVE = "https://newrepo-production-1571.up.railway.app/verify?txid=b96790e316edc38f5e280641229afdff19962d11037c6e3f62aea69596fc2d58&key=0d1c95e40aaebb47a98b8537e8c0318d71000b3e0fc6a7e0d01df93541796701&address=75jwJ7i21MWM5XnodztaPrevsCR5xPRNziG6WN5CVEEJPPbB4e53M8FKHoPGFBxg4vQg7LAuLgReK3yT9b2p3XHJ3CTMYXa";

const config = getConfig();
const { chain, ethClient, account, proverUrl, confirmations, notaryUrl } =
  createContext(config);

 console.log(proverUrl);

if (!account) {
  throw new Error(
    "No account found make sure EXAMPLES_TEST_PRIVATE_KEY is set in your environment variables",
  );
}

const vlayer = createVlayerClient({
  url: proverUrl,
  token: config.token,
});

async function generateWebProof() {
  console.log("⏳ Generating web proof...");
  const { stdout } = await runProcess("vlayer", [
    "web-proof-fetch",
    "--notary",
    String(notaryUrl),
    "--url",
    URL_TO_PROVE,
  ]);
  return stdout;
}

console.log("⏳ Deploying contracts...");

// const { prover, verifier } = await deployVlayerContracts({
//   proverSpec,
//   verifierSpec,
//   proverArgs: [],
//   verifierArgs: [],
// });

await writeEnvVariables(".env", {
  VITE_PROVER_ADDRESS: '0x38998FB1f83E0ff509d22A4369C90675b02F31ee',
  VITE_VERIFIER_ADDRESS: "0xf60364b3fa5d3eaada7989dcd080d369617d59db",
});

// console.log("✅ Contracts deployed", { prover, verifier });

const webProof = await generateWebProof();

console.log("✅ Web proof generated");

console.log("Web proof:", webProof);

const prover = '0x38998FB1f83E0ff509d22A4369C90675b02F31ee';

console.log("⏳ Proving...");
const hash = await vlayer.prove({
  address: prover,
  functionName: "main",
  proverAbi: proverSpec.abi,
  args: [
    {
      webProofJson: String(webProof),
    },
    "0d1c95e40aaebb47a98b8537e8c0318d71000b3e0fc6a7e0d01df93541796701",
    "b96790e316edc38f5e280641229afdff19962d11037c6e3f62aea69596fc2d58",
    "0x2D0bf6D3BD0636eec331f7c2861F44D74a2dcaC3",
    "75jwJ7i21MWM5XnodztaPrevsCR5xPRNziG6WN5CVEEJPPbB4e53M8FKHoPGFBxg4vQg7LAuLgReK3yT9b2p3XHJ3CTMYXa",
  ],
  chainId: chain.id,
  gasLimit: config.gasLimit,
});

console.log("Proving hash:", hash);

const result = await vlayer.waitForProvingResult({ hash });

console.log(result);
const [proof, ...resr] = result;
console.log("✅ Proof generated");

console.log("Proof:", proof);

console.log(resr);

console.log("⏳ Verifying...");

const verifier = "0xA97b067B7740eb4DBfDA2E0865FAE580a88374a4"; // Replace with your verifier address

const verifyargs = [
  proof,
  "0x2D0bf6D3BD0636eec331f7c2861F44D74a2dcaC3",
  "b96790e316edc38f5e280641229afdff19962d11037c6e3f62aea69596fc2d58",
  1000000000,
];

const gas = await ethClient.estimateContractGas({
  address: verifier,
  abi: verifierSpec.abi,
  functionName: "verifyDeposit",
  args: verifyargs,
  account,
  blockTag: "pending",
});

const txHash = await ethClient.writeContract({
  address: verifier,
  abi: verifierSpec.abi,
  functionName: "verifyDeposit",
  args: verifyargs,
  chain,
  account,
  gas,
});

await ethClient.waitForTransactionReceipt({
  hash: txHash,
  confirmations,
  retryCount: 60,
  retryDelay: 1000,
});

function runProcess(
  cmd: string,
  args: string[],
): Promise<{ stdout: string; stderr: string }> {
  return new Promise((resolve, reject) => {
    const proc = spawn(cmd, args);
    let stdout = "";
    let stderr = "";
    proc.stdout.on("data", (data) => {
      stdout += data;
    });
    proc.stderr.on("data", (data) => {
      stderr += data;
    });
    proc.on("close", (code) => {
      if (code === 0) {
        resolve({ stdout, stderr });
      } else {
        reject(new Error(`Process failed: ${stderr}`));
      }
    });
    proc.on("error", (err) => {
      reject(err);
    });
  });
}



