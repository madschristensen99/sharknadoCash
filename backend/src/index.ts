import express from 'express';
import { createContext, getConfig } from '@vlayer/sdk/config';
import { createVlayerClient } from '@vlayer/sdk';
import { spawn } from "child_process";

const proverAbi = [{"inputs":[],"name":"FailedInnerCall","type":"error"},{"inputs":[],"name":"DATA_URL","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"string[]","name":"parts","type":"string[]"}],"name":"concatStrings","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[{"components":[{"internalType":"string","name":"webProofJson","type":"string"}],"internalType":"struct WebProof","name":"webProof","type":"tuple"},{"internalType":"string","name":"secretKey","type":"string"},{"internalType":"string","name":"txId","type":"string"},{"internalType":"address","name":"evmRecipientAddress","type":"address"},{"internalType":"string","name":"xmrRecipientAddress","type":"string"}],"name":"main","outputs":[{"components":[{"components":[{"internalType":"bytes4","name":"verifierSelector","type":"bytes4"},{"internalType":"bytes32[8]","name":"seal","type":"bytes32[8]"},{"internalType":"enum ProofMode","name":"mode","type":"uint8"}],"internalType":"struct Seal","name":"seal","type":"tuple"},{"internalType":"bytes32","name":"callGuestId","type":"bytes32"},{"internalType":"uint256","name":"length","type":"uint256"},{"components":[{"internalType":"address","name":"proverContractAddress","type":"address"},{"internalType":"bytes4","name":"functionSelector","type":"bytes4"},{"internalType":"uint256","name":"settleChainId","type":"uint256"},{"internalType":"uint256","name":"settleBlockNumber","type":"uint256"},{"internalType":"bytes32","name":"settleBlockHash","type":"bytes32"}],"internalType":"struct CallAssumptions","name":"callAssumptions","type":"tuple"}],"internalType":"struct Proof","name":"","type":"tuple"},{"internalType":"address","name":"","type":"address"},{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"proof","outputs":[{"components":[{"components":[{"internalType":"bytes4","name":"verifierSelector","type":"bytes4"},{"internalType":"bytes32[8]","name":"seal","type":"bytes32[8]"},{"internalType":"enum ProofMode","name":"mode","type":"uint8"}],"internalType":"struct Seal","name":"seal","type":"tuple"},{"internalType":"bytes32","name":"callGuestId","type":"bytes32"},{"internalType":"uint256","name":"length","type":"uint256"},{"components":[{"internalType":"address","name":"proverContractAddress","type":"address"},{"internalType":"bytes4","name":"functionSelector","type":"bytes4"},{"internalType":"uint256","name":"settleChainId","type":"uint256"},{"internalType":"uint256","name":"settleBlockNumber","type":"uint256"},{"internalType":"bytes32","name":"settleBlockHash","type":"bytes32"}],"internalType":"struct CallAssumptions","name":"callAssumptions","type":"tuple"}],"internalType":"struct Proof","name":"","type":"tuple"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"blockNo","type":"uint256"}],"name":"setBlock","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"chainId","type":"uint256"},{"internalType":"uint256","name":"blockNo","type":"uint256"}],"name":"setChain","outputs":[],"stateMutability":"nonpayable","type":"function"}];

const app = express();
const port = process.env.PORT || 3000;

app.get('/api/zkproof/getProof', async (_req, res) => {

  console.log('hey')

  const { txid, key, address, ethereumRecipientAddress } = _req.query;

  const URL_TO_PROVE = `https://newrepo-production-1571.up.railway.app/verify?txid=${txid}&key=${key}&address=${address}`;

  const config = getConfig();
  const { chain, ethClient, account, proverUrl, confirmations, notaryUrl } =
    createContext(config);


  const vlayer = createVlayerClient({
    url: proverUrl,
    token: config.token,
  });


  console.log('config', config);

  // const webProof = await generateWebProof();

  const webProof2 = await fetch('https://web-proof-vercel.vercel.app/api/handler', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      url: URL_TO_PROVE,
      notary: "https://test-notary.vlayer.xyz",
      headers: []
    }),
  });

  const webProof = await webProof2.json();

  const { presentation } = webProof;

  const presentationJson = JSON.parse(presentation);

  console.log(presentationJson);

  console.log("✅ Web proof generated");

  const hash = await vlayer.prove({
    address: process.env.VITE_PROVER_ADDRESS as any,
    functionName: "main",
    proverAbi: proverAbi as any,
    args: [
      {
        webProofJson: String(presentation),
      },
      key,
      txid,
      ethereumRecipientAddress,
      address,
    ],
    chainId: chain.id,
    gasLimit: config.gasLimit,
  });
  
  console.log("Proving hash:", hash);
  
  const result = await vlayer.waitForProvingResult({ hash });
  
  console.log(result);
  const [proof] = result as any;
  console.log("✅ Proof generated");

  return res.json({
    proof,
  });
});

app.listen(port, () => {
  console.log(`Server is running on http://localhost:${port}`);
});