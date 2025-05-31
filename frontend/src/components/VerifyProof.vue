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
import verifierJson from "@/abi/Verifier.json";
import { useWalletStore } from "../stores/walletStore";
import { storeToRefs } from "pinia";
import { createWalletClient, createPublicClient, http, custom } from "viem";
import { sepolia } from "viem/chains";

const proofBytes = ref("");
const evmAddress = ref("");
const amount = ref();
const txId = ref();

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

const verifyProof = async () => {
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

    const proofArg = {
        seal: {
            verifierSelector: "0xdeafbeef",
            seal: [
                "0x3f282b7a759b878e530fc51786435e1f55e096341a507e3a55f9f810ef529879",
                "0x0000000000000000000000000000000000000000000000000000000000000000",
                "0x0000000000000000000000000000000000000000000000000000000000000000",
                "0x0000000000000000000000000000000000000000000000000000000000000000",
                "0x0000000000000000000000000000000000000000000000000000000000000000",
                "0x0000000000000000000000000000000000000000000000000000000000000000",
                "0x0000000000000000000000000000000000000000000000000000000000000000",
                "0x0000000000000000000000000000000000000000000000000000000000000000",
            ],
            mode: 1,
        },
        callGuestId:
            "0xdcb00648ecc90d8bfe92aa8d51061beb0bcb110d274fc4a517e526574233d36b",
        length: 896,
        callAssumptions: {
            proverContractAddress: "0x38998fb1f83e0ff509d22a4369c90675b02f31ee",
            functionSelector: "0x1b0842f5",
            settleChainId: "0xaa36a7",
            settleBlockNumber: "0x80e85c",
            settleBlockHash:
                "0xcb82b7e2f5b7f40339786aa38419dea660f6fa2ab98874599a0cf37f50466b38",
        },
    };

    const result = await walletClient.writeContract({
        address: verifierAddress,
        abi: abi,
        functionName: "verifyDeposit",
        args: [
            proofArg,
            "0x2D0bf6D3BD0636eec331f7c2861F44D74a2dcaC3",
            "b96790e316edc38f5e280641229afdff19962d11037c6e3f62aea69596fc2d58",
            1000000000,
        ],
        client: walletClient,
        account: wallet.account,
    });

    console.log(result);
};
</script>
