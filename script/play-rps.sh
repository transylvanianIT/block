#!/bin/bash

# Helper script pentru a juca Rock Paper Scissors
# Usage: ./play-rps.sh <contract_address> <game_id> <move> <secret>
# Move: 1=Rock, 2=Paper, 3=Scissors

CONTRACT=$1
GAME_ID=$2
MOVE=$3
SECRET=$4
PLAYER_ADDRESS=$5
RPC_URL="http://127.0.0.1:8545"

if [ -z "$CONTRACT" ] || [ -z "$GAME_ID" ] || [ -z "$MOVE" ] || [ -z "$SECRET" ] || [ -z "$PLAYER_ADDRESS" ]; then
    echo "Usage: ./play-rps.sh <contract> <game_id> <move> <secret> <player_address>"
    echo "Move: 1=Rock, 2=Paper, 3=Scissors"
    exit 1
fi

# Calculează commit hash
# Solidity: keccak256(abi.encodePacked(move, secret, playerAddress))
COMMIT=$(cast keccak $(cast --concat-hex $(cast --to-hex $MOVE) $(cast keccak "$SECRET") $(cast --to-checksum-address $PLAYER_ADDRESS)))

echo "Commit hash: $COMMIT"
echo ""
echo "Pentru commit, rulează:"
echo "cast send $CONTRACT \"commitMove(uint256,bytes32)\" $GAME_ID $COMMIT --rpc-url $RPC_URL --private-key <YOUR_KEY>"
echo ""
echo "Pentru reveal, rulează:"
echo "cast send $CONTRACT \"revealMove(uint256,uint8,bytes32)\" $GAME_ID $MOVE $(cast keccak \"$SECRET\") --rpc-url $RPC_URL --private-key <YOUR_KEY>"

