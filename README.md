# 🚀 Blockchain Engineer Setup - Foundry

Setup complet pentru development blockchain profesional cu Foundry.

## 📋 Setup Inițial

### 1. Instalează Foundry

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### 2. Instalează dependențele

```bash
forge install OpenZeppelin/openzeppelin-contracts
forge install foundry-rs/forge-std
```

### 3. Pornește local node (Anvil)

```bash
anvil
```

## 📁 Structura Proiectului

```
block/
├── src/              # Smart contracte aici
├── test/             # Teste aici
├── script/           # Scripturi de deploy aici
├── lib/              # Dependențe (se creează automat)
└── foundry.toml      # Configurare Foundry
```

## 🎯 Proiecte de Făcut (în ordine)

### 1. ERC20 Token
- **Fișier:** `src/MyToken.sol`
- **Funcționalități:** mint, burn, transfer
- **Test:** `test/MyToken.t.sol`

### 2. ERC721 NFT
- **Fișier:** `src/MyNFT.sol`
- **Funcționalități:** mint, metadata, royalties
- **Test:** `test/MyNFT.t.sol`

### 3. Marketplace
- **Fișier:** `src/Marketplace.sol`
- **Funcționalități:** list, buy, cancel
- **Test:** `test/Marketplace.t.sol`

### 4. Vault cu Interest
- **Fișier:** `src/Vault.sol`
- **Funcționalități:** deposit, withdraw, calculate interest
- **Test:** `test/Vault.t.sol`

### 5. Multisig Wallet
- **Fișier:** `src/Multisig.sol`
- **Funcționalități:** propose, approve, execute
- **Test:** `test/Multisig.t.sol`

### 6. Upgradeable Contract
- **Fișier:** `src/UpgradeableContract.sol`
- **Funcționalități:** UUPS pattern
- **Test:** `test/UpgradeableContract.t.sol`

## 🧪 Comenzi Utile

```bash
# Rulează toate testele
forge test

# Rulează testele cu output detaliat
forge test -vvv

# Compilează contractele
forge build

# Rulează un script de deploy
forge script script/Deploy.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast

# Verifică coverage
forge coverage
```

## 📚 Resurse de Învățare

- **Solidity Docs:** https://docs.soliditylang.org/
- **Foundry Book:** https://book.getfoundry.sh/
- **OpenZeppelin:** https://docs.openzeppelin.com/contracts/

## 🔥 Next Steps

1. Creează folder-urile: `src/`, `test/`, `script/`
2. Scrie primul tău contract ERC20
3. Scrie testele pentru el
4. Rulează `forge test` și vezi dacă trece
5. Continuă cu următorul proiect!

**Scrie totul tu - asta e cum înveți! 💪**

