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
            { name: 'commit', type: 'byte32'}
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
    }
]


export default function RPSGame() {
    const { address } = useAccount()
    const [gameId, setGameId ] = useState(null)
    const [selectedMove, setSelectedMove] = useState(null)
    const [secret, setSecret ] = useState(null)
    const [commitHash, setCommitHash] = useState(null)

    const { data: gameCounter } = useReadContract({
        address: RPS_CONTRACT,
        abi: RPS_ABI,
        functionName: 'gameCounter'
    })

    const { data: gameInfo } = useReadContract({
        address: RPS_CONTRACT,
        abi: RPS_ABI,
        functionName: 'getGame',
        args: gameId ? [BigInt(gameId)] : undefined,
        enabled: !!gameId
    })

    const { writeContract, data: hash, isPending } = useWriteContract()
    const { isLoading: isConfirming, isSucces } = useWaitForTransactionReceipt({
        hash
    })

    useEffect(() => {
        if (isSucces && gameCounter && !gameId) {
            setGameId(Number(gameCounter))
        }
    }, [isSucces, gameCounter, gameId])


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
        if (!selectedMove || !secret || !address) return

        const secretBytes = keccak256(new TextEncoder().encode(secret))
        const commit = calculateCommit(selectedMove, secretBytes, address)
        setCommitHash(commit)

        writeContract({
            address: RPS_CONTRACT,
            abi: RPS_ABI,
            functionName: 'commitMove',
            args: [BigInt(gameId), commit]
        })
    }

    const revealMove = () => {
        if (!selectedMove || !secret) return

        const secretBytes = keccak256(new TextEncoder().encode(secret))

        writeContract({
            address: RPS_CONTRACT,
            abi: RPS_ABI,
            functionName: 'revealMove',
            args: [BigInt(gameId), selectedMove, secretBytes]
        })
    }

    const generateSecret = () => {
        return Math.random().toString(36).substring(7)
    }
    
    return (
        <div className="rps-game">
            <h1>Rock Paper Scissors</h1>

            <div>
                <button onClick={createGame} disabled={isPending}>
                    {isPending ? 'Creating...' : 'Create Game (0.01 ETH)'}
                </button>
            </div>

            {gameInfo && (
                <div>
                    <p>Player 1: {gameInfo[0]?.slice(0, 6)}...</p>
                    <p>Player 2: {gameInfo[1] ? gameInfo[1].slice(0 ,6) + '...' : 'Waiting...'}</p>
                    <p>Player 1 Commited: {gameInfo[3] ? 'Yes' : 'No'}</p>
                    <p>Player 2 Commited: {gameInfo[4] ? 'Yes' : 'No'}</p>
                    <p>Finished: {gameInfo[7] ? 'Yes' : 'No'}</p>
                </div>
            )}

            {gameCounter && gameCounter > 0n && !gameInfo && (
                <div>
                    <p>Available Games: {gameCounter.toString()}</p>
                    <button onClick={() => {
                        const id = Number(gameCounter)
                        setGameId(id)
                        joinGame(id)
                    }}>
                        Join Latest Game
                    </button>
                </div>
            )}

            {gameInfo && gameInfo[1] && !gameInfo[7] && (
                <div>
                    <h3>
                        Select YOUR move:
                    </h3>
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
                            <button onClick={commitMove} disabled={isPending}>
                                COmmit move
                            </button>
                        </div>

                    )}

                    {gameInfo[3] && gameInfo[4] && (
                        <button onClick={revealMove} disabled={isPending}>
                            Reveal Move
                        </button>
                    )}
                </div>
            )}

            <div>
                <Hand move={gameInfo?.[3] ? 1 : null} isAnimating={false}></Hand>
                <Hand move={gameInfo?.[4] ? 1 : null} isAnimating={false}></Hand>
            </div>
        </div>
    )
}