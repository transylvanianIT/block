import { createConfig, http } from 'wagmi'
import { defineChain } from 'viem'

const anvil = defineChain({
    id: 31337,
    name: 'Anvil',
    nativeCurrency: {
        decimals: 18,
        name: 'Ether',
        symbol: 'ETH',
    },
    rpcUrls: {
        default: {
            http: ['http://127.0.0.1:8545'],
        },
    },
})

export const config = createConfig({
    chains: [anvil],
    transports: {
        [anvil.id]: http('http://127.0.0.1:8545')
    }
})

export const RPS_CONTRACT = '0x5FbDB2315678afecb367f032d93F642f64180aa3'