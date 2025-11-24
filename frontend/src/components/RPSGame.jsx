import { useState, useEffect } from "react";
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import { parseEther, keccak256, encodePacked } from "viem";
import { RPS_CONTRACT } from "../config/wagmi";
import Hand from "./Hand";

const RPS_ABI = [
    {
        name: 'createGame',
        type: 'function',
        stateMutability: 'payable',
        inputs: [],
        outputs: []
    },
    {
        name: 'joinGame',
        type: 'function',
        stateMutability: 'payable',
        inputs: [{ name: 'gameId', type: 'uint256'}],
        outputs: []
    },
    {
        name: 'commitMove',
        type: 'function',
        inputs: [
            { name: 'gameId', type: 'uint256'},
            { name: 'commit', type: 'bytes32'}
        ],
        outputs: []
    },
    {
        name: 'revealMove',
        type: 'function',
        inputs: [
            { name: 'gameId', type: 'uint256' },
            { name: 'move', type:'uint8'},
            { name: 'secret', type:'bytes32'}
        ],
        outputs: []
    },
    {
        name: 'getGame',
        type: 'function',
        stateMutability: 'view',
        inputs: [{ name:'gameId', type: 'uint256' }],
        outputs: [
            { name: '_player1', type: 'address' },
            { name: '_player2', type: 'address' },
            { name: '_entryFee', type: 'uint256' },
            { name: '_player1Committed', type: 'bool' },
            { name: '_player2Committed', type: 'bool' },
            { name: '_player1Revealed', type: 'bool' },
            { name: '_player2Revealed', type: 'bool' },
            { name: '_finished', type: 'bool' }
          ]
    },
    {
        name: 'gameCounter',
        type: 'function',
        stateMutability: 'view',
        inputs: [],
        outputs: [{ name: '', type: 'uint256' }]
    },
    {
        name: 'getGameResult',
        type: 'function',
        stateMutability: 'view',
        inputs: [{ name: 'gameId', type: 'uint256' }],
        outputs: [
            { name: '_move1', type: 'uint8' },
            { name: '_move2', type: 'uint8' },
            { name: '_winner', type: 'address' }
        ]
    }
]


export default function RPSGame() {
    const { address } = useAccount()
    const [gameId, setGameId ] = useState(null)
    const [selectedMove, setSelectedMove] = useState(null)
    const [secret, setSecret ] = useState(null)
    const [commitHash, setCommitHash] = useState(null)

    const { data: gameCounter, refetch: refetchGameCounter } = useReadContract({
        address: RPS_CONTRACT,
        abi: RPS_ABI,
        functionName: 'gameCounter'
    })

    const { writeContract, data: hash, isPending } = useWriteContract()
    const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
        hash
    })

    const currentGameId = gameId || (isSuccess && gameCounter && gameCounter > 0n ? Number(gameCounter) : null)

    const { data: gameInfo, refetch: refetchGameInfo } = useReadContract({
        address: RPS_CONTRACT,
        abi: RPS_ABI,
        functionName: 'getGame',
        args: currentGameId ? [BigInt(currentGameId)] : undefined,
        enabled: !!currentGameId
    })

    const { data: gameResult } = useReadContract({
        address: RPS_CONTRACT,
        abi: RPS_ABI,
        functionName: 'getGameResult',
        args: gameInfo && gameInfo[7] && currentGameId ? [BigInt(currentGameId)] : undefined,
        enabled: !!(gameInfo && gameInfo[7] && currentGameId)
    })


    useEffect(() => {
        if (isSuccess && hash && !gameId) {
            setTimeout(() => {
                refetchGameCounter().then((result) => {
                    if (result.data && result.data > 0n) {
                        setGameId(Number(result.data))
                    }
                })
            }, 500);
        }
    }, [isSuccess, hash, refetchGameCounter, gameId])

    useEffect(() => {
        if (currentGameId) {
            refetchGameInfo()
            const interval = setInterval(() => {
                refetchGameInfo()
            }, 2000);
            return () => clearInterval(interval)
        }
    }, [currentGameId, refetchGameInfo])

    useEffect(() => {
        if (isSuccess && gameCounter !== undefined && gameCounter > 0n && !gameId){
            setGameId(Number(gameCounter))
        }
    }, [isSuccess, gameCounter, gameId])


    const createGame = () => {
        writeContract({
            address: RPS_CONTRACT,
            abi: RPS_ABI,
            functionName: 'createGame',
            value: parseEther('0.01')
        })
    }

    const joinGame = (id) => {
        writeContract({
            address: RPS_CONTRACT,
            abi: RPS_ABI,
            functionName: 'joinGame',
            args: [BigInt(id)],
            value: parseEther('0.01')
        })
    }

    const calculateCommit = (move, secret, playerAddress) => {
        return keccak256(
            encodePacked(
                ['uint8', 'bytes32', 'address'],
                [move, secret, playerAddress]
            )
        )
    }

    const commitMove = () => {
        if (!selectedMove || !secret || !address || !currentGameId) return

        const secretBytes = keccak256(new TextEncoder().encode(secret))
        const commit = calculateCommit(selectedMove, secretBytes, address)
        setCommitHash(commit)

        writeContract({
            address: RPS_CONTRACT,
            abi: RPS_ABI,
            functionName: 'commitMove',
            args: [BigInt(currentGameId), commit]
        })
    }

    const revealMove = () => {
        if (!selectedMove || !secret || !currentGameId) return

        const secretBytes = keccak256(new TextEncoder().encode(secret))

        writeContract({
            address: RPS_CONTRACT,
            abi: RPS_ABI,
            functionName: 'revealMove',
            args: [BigInt(currentGameId), selectedMove, secretBytes]
        })
    }

    const generateSecret = () => {
        return Math.random().toString(36).substring(7)
    }

    const getMoveName = (move) => {
        if (move === 1) return 'Rock ✊'
        if (move === 2) return 'Paper ✋'
        if (move === 3) return 'Scissors ✌️'
        return 'None'
    }
    
    return (
        <div className="rps-game">
            <h1>Rock Paper Scissors</h1>

            <div>
                <button onClick={createGame} disabled={isPending || isConfirming}>
                    {isPending ? 'Waiting for approval...' : isConfirming ? 'Creating game...' : 'Create Game (0.01 ETH)'}
                </button>
                {isSuccess && hash && (
                    <p style={{color: 'green'}}>Game created successfully! Transaction: {hash.slice(0, 10)}...</p>
                )}
                {gameCounter !== undefined && (
                    <p>Total Games: {gameCounter.toString()}</p>
                )}
                {currentGameId && (
                    <div style={{marginTop: '10px', padding:'10px', backgroundColor: '#f0f0f0', borderRadius:'5px'}}>
                        <h3>Game ID: {currentGameId}</h3>
                    </div>
                )}
            </div>

            {gameInfo && (
                <div style={{marginTop: '10px', padding: '10px', backgroundColor: '#e8f5e9', borderRadius: '5px'}}>
                    <h3>Game INFO:</h3>
                    <p>Player 1: {gameInfo[0]?.slice(0, 6)}...{gameInfo[0]?.slice(-4)}</p>
                    <p>Player 2: {gameInfo[1] ? gameInfo[1].slice(0, 6) + '...' + gameInfo[1].slice(-4) : 'Waiting for player 2...'}</p>
                    <p><strong>Entry Fee:</strong> {gameInfo[2] ? (Number(gameInfo[2]) / 1e18).toFixed(4) : '0'} ETH</p>
                    <p>Player 1 Committed: {gameInfo[3] ? 'Yes ✓' : 'No'}</p>
                    <p>Player 2 Committed: {gameInfo[4] ? 'Yes ✓' : 'No'}</p>
                    <p>Finished: {gameInfo[7] ? 'Yes' : 'No'}</p>
                </div>
            )}

            {gameCounter && gameCounter > 0n && (!gameInfo || !gameInfo[1]) && address && (
                <div>
                    <p>Available Games: {gameCounter.toString()}</p>
                    {!gameInfo || (gameInfo[0]?.toLowerCase() !== address?.toLowerCase()) ? (
                    <button onClick={() => {
                        const id = Number(gameCounter)
                        setGameId(id)
                        joinGame(id)
                    }} disabled={isPending || isConfirming}>
                        {isPending || isConfirming ? 'Joining...' : 'Join Latest Game (0.01 ETH)'}
                    </button>
            ) : (
                <p>You are already in this game as player 1</p> 
            )}
                </div>
            )}

            {gameInfo && gameInfo[1] && !gameInfo[7] && address && (
                <div>
                    <h3>Select YOUR move:</h3>
                    <p>You are: {gameInfo[0]?.toLowerCase() === address?.toLowerCase() ? 'Player 1' : 'Player 2'}</p>
                    
                    {(!gameInfo[3] && gameInfo[0]?.toLowerCase() === address?.toLowerCase()) || 
                     (!gameInfo[4] && gameInfo[1]?.toLowerCase() === address?.toLowerCase()) ? (
                        <>
                            <button onClick={() => { setSelectedMove(1); setSecret(generateSecret()) }}>
                                ✊ Rock
                            </button>
                            <button onClick={() => { setSelectedMove(2); setSecret(generateSecret()) }}>
                                ✋ Paper
                            </button>
                            <button onClick={() => { setSelectedMove(3); setSecret(generateSecret()) }}>
                                ✌️ Scissors
                            </button>

                            {selectedMove && (
                                <div>
                                    <p>Selected: {selectedMove === 1 ? 'Rock' : selectedMove === 2 ? 'Paper' : 'Scissors'}</p>
                                    <button onClick={commitMove} disabled={isPending || isConfirming}>
                                        {isPending || isConfirming ? 'Committing...' : 'Commit Move'}
                                    </button>
                                </div>
                            )}
                        </>
                    ) : (
                        <p>You have already committed your move. Waiting for the other player...</p>
                    )}

                    {gameInfo[3] && gameInfo[4] && (!gameInfo[5] || !gameInfo[6]) && (
                        <div>
                            <p>Both players committed! Now reveal your move:</p>
                            <button onClick={revealMove} disabled={isPending || isConfirming}>
                                {isPending || isConfirming ? 'Revealing...' : 'Reveal Move'}
                            </button>
                        </div>
                    )}

                    {gameInfo[5] && gameInfo[6] && (
                        <p>✓ Both players revealed! Game finished.</p>
                    )}
                </div>
            )}

            {gameInfo && !gameInfo[1] && (
                <div>
                    <p>⏳ Waiting for Player 2 to join the game...</p>
                    <p>Share the Game ID ({currentGameId}) with another player or open this page in another browser/account.</p>
                </div>
            )}

            {gameInfo && gameInfo[7] && gameResult && (
                <div style={{marginTop: '20px', padding: '15px', backgroundColor:'#fff3cd', borderRadius:'5px', border:'2px solid #ffc107'}}>
                    <h2 style={{marginTop: 0}}>Game Result</h2>

                    <div style={{marginTop: '10px'}}>
                        <p><strong>Player1 ({gameInfo[0]?.slice(0, 6)}...{gameInfo[0]?.slice(-4)})</strong> {getMoveName(Number(gameResult[0]))}</p>
                        <p><strong>Player2 ({gameInfo[1]?.slice(0, 6)}...{gameInfo[1]?.slice(-4)}):</strong> {getMoveName(Number(gameResult[1]))}</p>
                    </div>

                    <div style={{marginTop: '15px', padding: '10px', backgroundColor: gameResult[2] === '0x0000000000000000000000000000000000000000' ? '#e3f2fd' : '#c8e6c9', borderRadius: '5px'}}>
                        {gameResult[2] === '0x0000000000000000000000000000000000000000' ? (
                            <>
                                <p style={{fontSize: '18px', fontWeight: 'bold', margin: 0}}>🤝 It's a TIE!</p>
                                <p style={{margin: '5px 0 0 0'}}>
                                    ✅ Both players received their entry fee back ({gameInfo[2] ? (Number(gameInfo[2]) / 1e18).toFixed(4) : '0'} ETH each)
                                </p>
                            </>
                        ) : (
                            <>
                                <p style={{fontSize: '18px', fontWeight: 'bold', margin: 0, color: '#2e7d32'}}>
                                    🏆 Winner: {gameResult[2]?.toLowerCase() === gameInfo[0]?.toLowerCase() ? 'Player 1' : 'Player 2'}
                                </p>
                                <p style={{margin: '5px 0 0 0'}}>
                                    Address: {gameResult[2]?.slice(0, 6)}...{gameResult[2]?.slice(-4)}
                                </p>
                                <p style={{margin: '5px 0 0 0', fontWeight: 'bold', color: '#1b5e20'}}>
                                    💰 Prize: {gameInfo[2] ? ((Number(gameInfo[2]) * 2 * 0.95) / 1e18).toFixed(4) : '0'} ETH (after 5% house fee)
                                </p>
                                <p style={{margin: '10px 0 0 0', fontSize: '14px', color: '#4caf50', fontWeight: 'bold'}}>
                                    ✅ Prize automatically transferred to winner's wallet!
                                </p>
                            </>
                        )}
                    </div>
                </div>
            )}

            <div>
                <Hand move={gameInfo?.[3] ? 1 : null} isAnimating={false}></Hand>
                <Hand move={gameInfo?.[4] ? 1 : null} isAnimating={false}></Hand>
            </div>
        </div>
    )
}