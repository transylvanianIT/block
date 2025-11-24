#!/bin/bash

# Script pentru testarea Rock Paper Scissors
# Folosește: source script/test-rps.sh

echo "🎮 Rock Paper Scissors - Test Manual"
echo "======================================"
echo ""

# Verifică dacă Anvil rulează
if ! curl -s http://127.0.0.1:8545 > /dev/null 2>&1; then
    echo "❌ Anvil nu rulează! Pornește-l într-un alt terminal:"
    echo "   anvil"
    echo ""
    exit 1
fi

echo "✅ Anvil rulează"
echo ""

# Setează variabilele de bază
export RPC="http://127.0.0.1:8545"
export PRIVATE_KEY1="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"  # Account 0
export PRIVATE_KEY2="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"  # Account 1
export OWNER_ADDRESS="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

# Setează variabilele pentru scriptul de deploy
export PRIVATE_KEY=$PRIVATE_KEY1

# Obține adresele
ADDR1=$(cast wallet address $PRIVATE_KEY1)
ADDR2=$(cast wallet address $PRIVATE_KEY2)

echo "👤 Player 1: $ADDR1"
echo "👤 Player 2: $ADDR2"
echo ""

# Deploy contract
echo "📦 Deploy contract..."
echo "   Folosind PRIVATE_KEY: ${PRIVATE_KEY:0:10}..."
echo "   Folosind OWNER_ADDRESS: $OWNER_ADDRESS"
echo ""

# Folosim forge script cu variabilele de mediu setate
DEPLOY_OUTPUT=$(PRIVATE_KEY=$PRIVATE_KEY1 OWNER_ADDRESS=$OWNER_ADDRESS forge script script/DeployRPS.s.sol:DeployRPSScript --rpc-url $RPC --broadcast --private-key $PRIVATE_KEY1 2>&1)

# Caută adresa în output - poate fi în mai multe locuri
RPS=$(echo "$DEPLOY_OUTPUT" | grep -i "deployed at" | grep -o "0x[a-fA-F0-9]\{40\}" | head -1)

if [ -z "$RPS" ]; then
    # Încearcă alt pattern - "RPSGame deployed at:"
    RPS=$(echo "$DEPLOY_OUTPUT" | grep -i "RPSGame deployed" | grep -o "0x[a-fA-F0-9]\{40\}" | head -1)
fi

if [ -z "$RPS" ]; then
    # Ultimul pattern - orice adresă hex
    RPS=$(echo "$DEPLOY_OUTPUT" | grep -o "0x[a-fA-F0-9]\{40\}" | tail -1)
fi

if [ -z "$RPS" ]; then
    echo "❌ Deploy eșuat! Nu s-a găsit adresa contractului."
    echo "   Output deploy:"
    echo "$DEPLOY_OUTPUT" | tail -30
    exit 1
fi

export RPS
echo "✅ Contract deploy-at la: $RPS"

# Verifică dacă contractul există
sleep 2
CODE=$(cast code $RPS --rpc-url $RPC 2>&1)
if [ "$CODE" = "0x" ] || [ -z "$CODE" ] || echo "$CODE" | grep -qi "empty\|not found"; then
    echo "⚠️  ATENȚIE: Contractul pare să fie gol!"
    echo "   Verifică dacă Anvil rulează și nu a fost resetat."
    echo "   Output deploy (ultimele 20 linii):"
    echo "$DEPLOY_OUTPUT" | tail -20
    exit 1
fi

echo "✅ Contractul are cod (${#CODE} caractere)"
echo ""

# Step 1: Player 1 creează jocul
echo "🎯 Step 1: Player 1 creează jocul..."
cast send $RPS "createGame()" --value 0.01ether --private-key $PRIVATE_KEY1 --rpc-url $RPC
sleep 1
GAME_ID=$(cast call $RPS "gameCounter()" --rpc-url $RPC | cast --to-dec)
if [ -z "$GAME_ID" ] || [ "$GAME_ID" = "0" ]; then
    echo "❌ Eroare: Jocul nu s-a creat corect!"
    exit 1
fi
echo "✅ Joc creat! Game ID: $GAME_ID"
echo ""

# Step 2: Player 2 se alătură
echo "🎯 Step 2: Player 2 se alătură..."
if [ -z "$GAME_ID" ]; then
    echo "❌ Eroare: GAME_ID este gol! Nu pot continua."
    exit 1
fi
cast send $RPS "joinGame(uint256)" $GAME_ID --value 0.01ether --private-key $PRIVATE_KEY2 --rpc-url $RPC
echo "✅ Player 2 s-a alăturat!"
echo ""

# Step 3: Calculează commit hash-uri
echo "🎯 Step 3: Calculează commit hash-uri..."
echo ""
echo "Player 1 alege: Rock (1)"
MOVE1=1
# Secret-ul trebuie să fie bytes32 - folosim hash-ul unui string
SECRET1_BYTES32=$(cast keccak "mySecret123")
# Formatăm move ca hex (1 byte): 0x01
MOVE1_HEX=$(printf "0x%02x" $MOVE1)
# Concatenează: move (1 byte) + secret (32 bytes) + address (20 bytes)
COMMIT1_INPUT=$(cast --concat-hex $MOVE1_HEX $SECRET1_BYTES32 $ADDR1)
COMMIT1=$(cast keccak $COMMIT1_INPUT)
echo "   Move: $MOVE1_HEX"
echo "   Secret: $SECRET1_BYTES32"
echo "   Commit 1: $COMMIT1"
echo ""

echo "Player 2 alege: Paper (2)"
MOVE2=2
SECRET2_BYTES32=$(cast keccak "secret456")
MOVE2_HEX=$(printf "0x%02x" $MOVE2)
COMMIT2_INPUT=$(cast --concat-hex $MOVE2_HEX $SECRET2_BYTES32 $ADDR2)
COMMIT2=$(cast keccak $COMMIT2_INPUT)
echo "   Move: $MOVE2_HEX"
echo "   Secret: $SECRET2_BYTES32"
echo "   Commit 2: $COMMIT2"
echo ""

# Step 4: Commit mutările
echo "🎯 Step 4: Commit mutările..."
if [ -z "$GAME_ID" ]; then
    echo "❌ Eroare: GAME_ID este gol! Nu pot continua."
    exit 1
fi
cast send $RPS "commitMove(uint256,bytes32)" $GAME_ID $COMMIT1 --private-key $PRIVATE_KEY1 --rpc-url $RPC
cast send $RPS "commitMove(uint256,bytes32)" $GAME_ID $COMMIT2 --private-key $PRIVATE_KEY2 --rpc-url $RPC
echo "✅ Amândoi jucătorii au commit-at"
echo ""

# Step 5: Reveal mutările
echo "🎯 Step 5: Reveal mutările..."
cast send $RPS "revealMove(uint256,uint8,bytes32)" $GAME_ID $MOVE1 $SECRET1_BYTES32 --private-key $PRIVATE_KEY1 --rpc-url $RPC
cast send $RPS "revealMove(uint256,uint8,bytes32)" $GAME_ID $MOVE2 $SECRET2_BYTES32 --private-key $PRIVATE_KEY2 --rpc-url $RPC
echo "✅ Amândoi jucătorii au reveal-at"
echo ""

# Step 6: Verifică rezultatul
echo "🎯 Step 6: Verifică rezultatul..."
echo "Game ID: $GAME_ID"
GAME_INFO=$(cast call $RPS "getGame(uint256)" $GAME_ID --rpc-url $RPC 2>&1)
if [ $? -eq 0 ]; then
    echo "Game info: $GAME_INFO"
else
    echo "⚠️  Nu s-a putut citi game info (poate contractul e gol)"
fi
echo ""

# Verifică balanțele
BALANCE1=$(cast balance $ADDR1 --rpc-url $RPC)
BALANCE2=$(cast balance $ADDR2 --rpc-url $RPC)
echo "💰 Balance Player 1: $(cast --to-unit $BALANCE1 ether) ETH"
echo "💰 Balance Player 2: $(cast --to-unit $BALANCE2 ether) ETH"
echo ""

echo "✅ Test complet!"

