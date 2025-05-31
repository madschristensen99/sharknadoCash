<template>
    <div class="bg-gray-900 p-6 rounded-xl shadow-lg">
        <h2 class="text-xl font-semibold mb-4">Verify Proof and claim funds</h2>
        <div class="mb-4">
            <label class="block mb-1">Proof (JSON)</label>
            <textarea
                v-model="proofBytes"
                rows="4"
                class="w-full p-2 rounded bg-gray-800 border border-gray-700"
            ></textarea>
        </div>
        <div class="mb-4">
            <label class="block mb-1">EVM Recipient Address</label>
            <input
                v-model="evmAddress"
                type="text"
                class="w-full p-2 rounded bg-gray-800 border border-gray-700"
            />
        </div>
        <div class="mb-4">
            <label class="block mb-1">Amount</label>
            <input
                v-model.number="amount"
                type="number"
                class="w-full p-2 rounded bg-gray-800 border border-gray-700"
            />
        </div>
        <button
            type="submit"
            class="w-full bg-purple-600 hover:bg-purple-700 text-white py-2 rounded"
            :disabled="verifyState != 0"
        >
            <span
                v-if="verifyState === 1"
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
                Verifying...
            </span>
            <span v-else> Verify Proof </span>
        </button>
        <div
            class="w-full flex flex-col items-center gap-4 justify-center mt-4 p-2 rounded bg-green-500"
            v-if="proofState === 2"
        >
            <span class="font-bold"> Proof verification was successfull! </span>
        </div>
        <div
            class="w-full flex flex-col items-center gap-4 justify-center mt-4 p-2 rounded bg-red-600"
            v-if="proofState === 3"
        >
            <span class="font-bold"> Proof verification failed! </span>
            <p>{{ error }}</p>
        </div>
    </div>
</template>

<script setup>
import { ref } from "vue";

const proofBytes = ref("");
const evmAddress = ref("");
const amount = ref();

// 0 didn't start proving, 1 waiting for response,
// 2 success, 3 fail
const verifyState = ref(false);
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
