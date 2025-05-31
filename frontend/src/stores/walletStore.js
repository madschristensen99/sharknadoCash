import { defineStore } from "pinia";
import { ref } from "vue";

export const useWalletStore = defineStore("wallet", () => {
  const account = ref(null);
  const networkName = ref(null);
  const usdcBalance = ref("0");

  const setAccount = (addr) => (account.value = addr);
  const setNetworkName = (name) => (networkName.value = name);
  const setUsdcBalance = (balance) => (usdcBalance.value = balance);

  return {
    account,
    networkName,
    usdcBalance,
    setAccount,
    setNetworkName,
    setUsdcBalance,
  };
});
