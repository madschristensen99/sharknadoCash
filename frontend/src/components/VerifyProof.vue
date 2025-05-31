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
        <div class="mb-4">
            <label class="block mb-1">Tx Id</label>
            <input
                v-model.number="txId"
                type="text"
                class="w-full p-2 rounded bg-gray-800 border border-gray-700"
            />
        </div>
        <button
            type="submit"
            class="w-full bg-purple-600 hover:bg-purple-700 text-white py-2 rounded"
            :disabled="verifyState != 0"
            @click="verifyProof"
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
            v-if="verifyState === 2"
        >
            <span class="font-bold"> Proof verification was successfull! </span>
        </div>
        <div
            class="w-full flex flex-col items-center gap-4 justify-center mt-4 p-2 rounded bg-red-600"
            v-if="verifyState === 3"
        >
            <span class="font-bold"> Proof verification failed! </span>
            <p>{{ error.slice(0, 200) }}</p>
        </div>
    </div>
</template>

<script setup>
import { ref } from "vue";
import verifierJson from "@/abi/Verifier.json";
import { useWalletStore } from "../stores/walletStore";
import { storeToRefs } from "pinia";
import {
    createWalletClient,
    createPublicClient,
    http,
    custom,
    erc20Abi,
} from "viem";
import { sepolia } from "viem/chains";

const proofBytes = ref("");
const evmAddress = ref("");
const amount = ref(1000000000);
const txId = ref();

const USDC_CONTRACT = "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238";

const verifierAddress = "0xA97b067B7740eb4DBfDA2E0865FAE580a88374a4";
const abi = verifierJson.abi;

// 0 didn't start proving, 1 waiting for response,
// 2 success, 3 fail
const verifyState = ref(false);
const error = ref("");

function isValidEvmAddress(address) {
    return /^0x[a-fA-F0-9]{40}$/.test(address);
}

const submitProof = async () => {
    verifyState.value = 1;
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
            verifyState.value = 2;
        } else {
            verifyState.value = 3;
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

const verifyProof = async () => {
    verifyState.value = 1;
    const wallet = useWalletStore();

    await window.ethereum.request({ method: "eth_requestAccounts" });

    const walletClient = createWalletClient({
        chain: sepolia,
        transport: custom(window.ethereum),
    });

    const publicClient = createPublicClient({
        chain: sepolia,
        transport: http(),
    });

    const proofArg = JSON.parse(proofBytes.value)?.proof;

    console.log(proofBytes.value, evmAddress.value, txId.value, amount.value);
    console.log(proofArg);

    try {
        const hash = await walletClient.writeContract({
            address: verifierAddress,
            abi: abi,
            functionName: "verifyDeposit",
            args: [proofArg, evmAddress.value, txId.value, amount.value],
            client: walletClient,
            account: wallet.account,
        });

        const publicClient = createPublicClient({
            chain: sepolia,
            transport: http(),
        });

        const receipt = await publicClient.waitForTransactionReceipt({ hash });

        if (receipt.status !== "success") {
            throw new Error("Transaction failed or reverted.");
        }
    } catch (err) {
        error.value = err.message || "Unknown error";
        verifyState.value = 3;
    } finally {
        if (!error.value) {
            verifyState.value = 2;
        }
    }
};
</script>
