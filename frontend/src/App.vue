<script setup>
import {
    createPublicClient,
    http,
    createWalletClient,
    custom,
    parseEther,
    formatUnits,
    erc20Abi,
} from "viem";
import { sepolia } from "viem/chains";
import { ref, onMounted } from "vue";
import WalletInfo from "./components/WalletInfo.vue";
import CreateProofForm from "./components/CreateProofForm.vue";

const address = ref(null);
const usdcBalance = ref(null);
const xmrRate = ref(0);

const connect = async () => {
    if (!window.ethereum) {
        throw new Error("MetaMask not found");
    }

    // Request wallet access
    await window.ethereum.request({ method: "eth_requestAccounts" });

    const walletClient = createWalletClient({
        chain: sepolia,
        transport: custom(window.ethereum),
    });

    const [account] = await walletClient.getAddresses();
    address.value = account;
    console.log(account);

    return { walletClient, publicClient, account };
};

const sendTransaction = async ({ to, amount }) => {
    const { walletClient, account } = await connect();

    const hash = await walletClient.sendTransaction({
        account,
        to,
        value: parseEther(amount), // amount in ETH as string
    });

    return hash;
};

const checkIfConnected = async () => {
    console.log("mount");
    if (window.ethereum) {
        const accounts = await window.ethereum.request({
            method: "eth_accounts",
        });
        if (accounts.length > 0) {
            address.value = accounts[0];
            console.log(address.value);
        }
    }
};

const fetchUSDCBalance = async () => {
    await checkIfConnected();
    const publicClient = createPublicClient({
        chain: sepolia,
        transport: http(), // fallback read client (optional)
    });
    console.log(publicClient);
    if (!address.value) return;
    const balance = await publicClient.readContract({
        address: USDC_CONTRACT,
        abi: erc20Abi,
        functionName: "balanceOf",
        args: [address.value],
    });
    console.log(balance);
    usdcBalance.value = formatUnits(balance, 6); // USDC has 6 decimals
};

const fetchXMRRate = async () => {
    function parseApiData(responseText) {
        // Remove the "data:" prefix if it exists
        const jsonString = responseText.startsWith("data:")
            ? responseText.substring(5)
            : responseText;

        try {
            // Parse the JSON string
            const jsonData = JSON.parse(jsonString);
            return jsonData;
        } catch (error) {
            console.error("Error parsing JSON:", error);
            return null;
        }
    }

    fetch(
        "https://hermes.pyth.network/v2/updates/price/stream?ids[]=0x46b8cc9347f04391764a0361e0b17c3ba394b001e7c304f7650f6376e37c321d",
    ).then((response) => {
        const reader = response.body.getReader();
        const decoder = new TextDecoder();
        function read() {
            return reader.read().then(({ done, value }) => {
                if (done) {
                    console.log("Stream complete");
                    return;
                }
                const responseFormatted = parseApiData(decoder.decode(value));
                console.log(responseFormatted.parsed);
                const price = responseFormatted.parsed[0].price.price;
                const offset = responseFormatted.parsed[0].price.expo;

                xmrRate.value = price * 10 ** offset;
                return read();
            });
        }
        return read();
    });
};

onMounted(async () => {
    // publicClient.value = publicClient
    // await checkIfConnected();
    // await fetchUSDCBalance();
    // await fetchXMRRate();
});
</script>

<template>
    <div class="text-white font-sans">
        <header
            class="p-4 text-center text-2xl font-bold bg-gradient-to-r from-purple-500 to-blue-500"
        >
            Sharknado
        </header>
        <main class="flex flex-col">
            <WalletInfo />
            <CreateProofForm />
        </main>
    </div>
</template>
