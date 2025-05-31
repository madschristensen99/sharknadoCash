<template>
    <div class="bg-gray-900 p-6 rounded-xl shadow-lg">
        <h2 class="text-xl font-semibold mb-4">Verify Proof</h2>
        <div>
            <pre class="bg-gray-800 p-2 rounded text-sm mb-4">{{ proof }}</pre>
            <button
                @click="verifyProof"
                class="w-full bg-purple-600 hover:bg-purple-700 text-white py-2 rounded"
            >
                Verify
            </button>
        </div>
    </div>
</template>

<script setup></script>
