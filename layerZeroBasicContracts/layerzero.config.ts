import { EndpointId } from '@layerzerolabs/lz-definitions'
import { ExecutorOptionType } from '@layerzerolabs/lz-v2-utilities'

import type { OAppOmniGraphHardhat, OmniPointHardhat } from '@layerzerolabs/toolbox-hardhat'

const sepoliaContract: OmniPointHardhat = {
    eid: EndpointId.SEPOLIA_V2_TESTNET, // EndpointId.ETHEREUM_V2_MAINNET
    contractName: 'sXMRAdapter',
}

const baseSepoliaContract: OmniPointHardhat = {
    eid: EndpointId.BASESEP_V2_TESTNET, // EndpointId.BASE_V2_MAINNET
    contractName: 'sXMR',
}

const config: OAppOmniGraphHardhat = {
    contracts: [
        {
            contract: baseSepoliaContract,
        },
        {
            contract: sepoliaContract,
        },
    ],
    connections: [
        {
            from: baseSepoliaContract,
            to: sepoliaContract,
        },
        {
            from: sepoliaContract,
            to: baseSepoliaContract,
        },
    ],
}

export default config
