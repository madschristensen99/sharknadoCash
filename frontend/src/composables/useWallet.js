import {
  createPublicClient,
  http,
  createWalletClient,
  custom,
  erc20Abi,
  formatUnits,
} from "viem";
import { sepolia } from "viem/chains";
import { useWalletStore } from "../stores/walletStore";

const USDC_CONTRACT = "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238";

export function useWallet() {
  const wallet = useWalletStore();

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

    updateState(walletClient, publicClient);

    return { walletClient, publicClient };
  };

  const checkIfConnected = async () => {
    if (window.ethereum) {
      const walletClient = createWalletClient({
        chain: sepolia,
        transport: custom(window.ethereum),
      });

      const publicClient = createPublicClient({
        chain: sepolia,
        transport: http(),
      });

      updateState(walletClient, publicClient);
    }
  };

  const updateState = async (walletClient, publicClient) => {
    const [account] = await walletClient.getAddresses();
    const chainId = await walletClient.getChainId();

    wallet.setPublicClient(publicClient);
    wallet.setWalletClient(walletClient);
    wallet.setAccount(account);
    wallet.setNetwork(chainId);

    if (account) {
      const balance = await publicClient.readContract({
        address: USDC_CONTRACT,
        abi: erc20Abi,
        functionName: "balanceOf",
        args: [account],
      });

      const usdcBalance = formatUnits(balance, 6); // USDC has 6 decimals
      wallet.setUsdcBalance(usdcBalance);
    }
  };

  return { connect, checkIfConnected };
}
