<template>
    <div class="flex flex-col items-end w-full" v-if="wallet.account">
        <p><strong>Address:</strong> {{ wallet.account }}</p>
        <p><strong>Network:</strong> {{ wallet.networkName }}</p>
        <p><strong>USDC Balance:</strong> {{ wallet.usdcBalance }} USDC</p>
        <p><strong>sXMR Balance:</strong> {{ wallet.sXMRBalance }} sXMR</p>
    </div>
    <button v-else @click="connect">Connect Wallet</button>
</template>

<script setup>
import { onMounted } from "vue";
import { useWallet } from "../composables/useWallet";
import { useWalletStore } from "../stores/walletStore";

const { connect, checkIfConnected } = useWallet();
const wallet = useWalletStore();

onMounted(async () => {
    await checkIfConnected();
});
</script>
