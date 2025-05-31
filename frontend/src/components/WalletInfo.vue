<template>
    <div v-if="wallet.account">
        <p><strong>Address:</strong> {{ wallet.account }}</p>
        <p><strong>Network:</strong> {{ wallet.networkName }}</p>
        <p><strong>USDC Balance:</strong> {{ wallet.usdcBalance }}</p>
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
    const walletAddress = await checkIfConnected();

    if (walletAddress) {
        wallet.setAccount(walletAddress);
    }
});
</script>
