import { useAccount, useConnect, useDisconnect } from "wagmi"

export default function WalletButton() {
    const { address, isConnected } = useAccount()
    const { connect, connectors, error, isPending } = useConnect()
    const { disconnect } = useDisconnect()

    // Găsește connector-ul MetaMask
    const metaMaskConnector = connectors.find(c => c.id === 'injected' || c.name === 'MetaMask')

    if (isConnected) {
        return (
            <div>
                <p>Connected: {address?.slice(0, 6)}...{address?.slice(-4)}</p>
                <button onClick={() => disconnect()}>Disconnect</button>
            </div>
        )
    }

    return (
        <div>
            <button 
                onClick={() => {
                    if (metaMaskConnector) {
                        connect({ connector: metaMaskConnector })
                    } else {
                        console.error('MetaMask not found!')
                    }
                }}
                disabled={isPending || !metaMaskConnector}
            >
                {isPending ? 'Connecting...' : 'Connect Wallet'}
            </button>
            {error && <p style={{color: 'red'}}>Error: {error.message}</p>}
            {!metaMaskConnector && <p style={{color: 'orange'}}>MetaMask not detected. Please install MetaMask.</p>}
        </div>
    )
}