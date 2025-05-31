<template>
    <form
        @submit.prevent="submitProof"
        class="bg-gray-900 p-6 rounded-xl shadow-lg"
    >
        <h2 class="text-xl font-semibold mb-4">Create Proof</h2>
        <div class="mb-4">
            <label class="block mb-1">Secret Key</label>
            <input
                v-model="secretKey"
                type="text"
                class="w-full p-2 rounded bg-gray-800 border border-gray-700"
            />
        </div>
        <div class="mb-4">
            <label class="block mb-1">Transaction ID</label>
            <input
                v-model="txId"
                type="text"
                class="w-full p-2 rounded bg-gray-800 border border-gray-700"
            />
        </div>
        <div class="mb-4">
            <label class="block mb-1">EVM Recipient Address</label>
            <input
                v-model="evmRecipient"
                type="text"
                class="w-full p-2 rounded bg-gray-800 border border-gray-700"
            />
        </div>
        <div class="mb-4">
            <label class="block mb-1">XMR Recipient Address</label>
            <input
                v-model="xmrRecipient"
                type="text"
                class="w-full p-2 rounded bg-gray-800 border border-gray-700"
            />
        </div>
        <button
            type="submit"
            class="w-full bg-purple-600 hover:bg-purple-700 text-white py-2 rounded"
        >
            Generate Proof
        </button>
    </form>
</template>

<script setup>
import { ref } from "vue";

const secretKey = ref("");
const txId = ref("");
const evmRecipient = ref("");
const xmrRecipient = ref("");

function isValidEvmAddress(address) {
    return /^0x[a-fA-F0-9]{40}$/.test(address);
}

const submitProof = () => {
    if (!secretKey.value || !txId.value || !xmrRecipient.value) {
        alert("Secret key and transaction ID Xmr Address are required.");
        return;
    }

    if (!isValidEvmAddress(evmRecipient.value)) {
        alert("Invalid EVM address.");
        return;
    }

    const proof = {
        secretKey: secretKey.value,
        txId: txId.value,
        evmRecipient,
        xmrRecipient,
    };

    console.log(proof);
};
</script>
