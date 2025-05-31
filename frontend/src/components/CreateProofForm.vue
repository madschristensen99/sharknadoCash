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
            :disabled="proofState != 0"
        >
            <span
                v-if="proofState === 1"
                class="flex justify-center items-center"
            >
                <svg
                    class="animate-spin h-5 w-5 mr-2 text-white"
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                >
                    <circle
                        class="opacity-25"
                        cx="12"
                        cy="12"
                        r="10"
                        stroke="currentColor"
                        stroke-width="4"
                    ></circle>
                    <path
                        class="opacity-75"
                        fill="currentColor"
                        d="M4 12a8 8 0 018-8v4l3-3-3-3v4a8 8 0 00-8 8h4z"
                    ></path>
                </svg>
                Generating...
            </span>
            <span v-else> Generate Proof </span>
        </button>
        <div
            class="w-full flex flex-col items-center gap-4 justify-center mt-4 p-2 rounded bg-green-500"
            v-if="proofState === 2"
        >
            <span class="font-bold"> Proof generation was successfull! </span>
        </div>
        <div
            class="w-full flex flex-col items-center gap-4 justify-center mt-4 p-2 rounded bg-red-600"
            v-if="proofState === 3"
        >
            <span class="font-bold"> Proof generation failed! </span>
            <p>{{ error }}</p>
        </div>
    </form>
</template>

<script setup>
import { ref } from "vue";

const secretKey = ref("");
const txId = ref("");
const evmRecipient = ref("");
const xmrRecipient = ref("");

// 0 didn't start proving, 1 waiting for response,
// 2 success, 3 fail
const proofState = ref(false);
const error = ref("");

function isValidEvmAddress(address) {
    return /^0x[a-fA-F0-9]{40}$/.test(address);
}

const submitProof = async () => {
    proofState.value = 1;
    if (!secretKey.value || !txId.value || !xmrRecipient.value) {
        alert("Secret key and transaction ID Xmr Address are required.");
        return;
    }

    if (!isValidEvmAddress(evmRecipient.value)) {
        alert("Invalid EVM address.");
        return;
    }

    try {
        // Simulate API call delay
        await new Promise((resolve) => setTimeout(resolve, 1500));
    } finally {
        if (true) {
            proofState.value = 2;
        } else {
            proofState.value = 3;
            error.value = "idk error from api";
        }
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
