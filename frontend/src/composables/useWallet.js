import {
  createPublicClient,
  http,
  createWalletClient,
  custom,
  parseEther,
} from "viem";
import { sepolia } from "viem/chains";

export function useWallet() {
  const connect = async () => {
    if (!window.ethereum) {
      throw new Error("MetaMask not found");
    }

    await window.ethereum.request({ method: "eth_requestAccounts" });

    const walletClient = createWalletClient({
      chain: sepolia,
      transport: custom(window.ethereum),
    });

    const publicClient = createPublicClient({
      chain: sepolia,
      transport: http(),
    });

    const [account] = await walletClient.getAddresses();

    return { walletClient, publicClient, account };
  };

  const checkIfConnected = async () => {
    if (window.ethereum) {
      const accounts = await window.ethereum.request({
        method: "eth_accounts",
      });

      return accounts[0];
    }
  };

  return { connect, checkIfConnected };
}
