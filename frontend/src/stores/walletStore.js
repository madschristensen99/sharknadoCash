import { defineStore } from "pinia";
import { ref } from "vue";

const chains = {
  11155111: "Sepolia",
  1: "Mainnet",
};

export const useWalletStore = defineStore("wallet", () => {
  const account = ref(null);
  const networkName = ref(null);
  const usdcBalance = ref("0");

  const walletClient = ref(null);
  const publicClient = ref(null);

  const setAccount = (addr) => (account.value = addr);
  const setNetwork = (id) => (networkName.value = chains[id]);
  const setUsdcBalance = (balance) => (usdcBalance.value = balance);
  const setWalletClient = (client) => (walletClient.value = client);
  const setPublicClient = (client) => (publicClient.value = client);

  return {
    account,
    networkName,
    usdcBalance,
    setAccount,
    setNetwork,
    setUsdcBalance,
    setWalletClient,
    setPublicClient,
  };
});
