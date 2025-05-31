import express from 'express';
import { createContext, getConfig } from '@vlayer/sdk/config';
import { createVlayerClient } from '@vlayer/sdk';
import { spawn } from "child_process";

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

const app = express();
const port = process.env.PORT || 3000;

app.get('/', async (_req, res) => {

  const { txid, key, address } = _req.query;

  const URL_TO_PROVE = `https://newrepo-production-1571.up.railway.app/verify?txid=${txid}&key=${key}&address=${address}`;

  const config = getConfig();
  const { chain, ethClient, account, proverUrl, confirmations, notaryUrl } =
    createContext(config);

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

  const vlayer = createVlayerClient({
      url: proverUrl,
      token: config.token,
    });


  console.log('config', config);

  const webProof = await generateWebProof();

  const webProof2 = await fetch('https://web-proof-vercel.vercel.app/api/handler', {
    method: 'POST',
    body: JSON.stringify({
      url: URL_TO_PROVE,
      notary: "https://test-notary.vlayer.xyz",
      headers: []
    }),
  });

  console.log(webProof2);

  console.log("✅ Web proof generated");

  console.log("Web proof:", webProof);

  res.send('Hello from TypeScript server!');
  
});

app.listen(port, () => {
  console.log(`Server is running on http://localhost:${port}`);
});