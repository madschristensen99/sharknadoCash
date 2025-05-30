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
            config: {
                enforcedOptions: [
                    {
                        msgType: 1, // depending on OAppOptionType3
                        optionType: ExecutorOptionType.LZ_RECEIVE,
                        gas: 100000, // gas limit in wei for EndpointV2.lzReceive
                        value: 0, // msg.value in wei for EndpointV2.lzReceive
                      },
                ]
            }
        },
        {
            from: sepoliaContract,
            to: baseSepoliaContract,
            config: {
                enforcedOptions: [
                    {
                        msgType: 1, // depending on OAppOptionType3
                        optionType: ExecutorOptionType.LZ_RECEIVE,
                        gas: 100000, // gas limit in wei for EndpointV2.lzReceive
                        value: 0, // msg.value in wei for EndpointV2.lzReceive
                      },
                ]
            }
        },
    ],
}

export default config
