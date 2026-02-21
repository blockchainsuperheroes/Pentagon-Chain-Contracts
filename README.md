# Pentagon Chain Ecosystem Solidity Contracts

Official smart contracts deployed on Pentagon Chain.

---

## 🔐 Security Bounty Program

Found a vulnerability? We reward responsible disclosure.

**Report to:** nftprof@pentagon.games

| Severity | Reward |
|----------|--------|
| Critical | Up to $10,000 |
| High | Up to $5,000 |
| Medium | Up to $1,000 |
| Low | Recognition |

All public contracts below are eligible for bounty review.

---

## Network Details

| Item | Value |
|------|-------|
| Chain ID | 3344 |
| RPC | https://rpc.pentagon.games |
| Explorer | https://explorer.pentagon.games |
| Symbol | PC |
| Gas Price | 1-2 Gwei (controlled) |

---

## ERC Proposals

### ERC-7857A: AI-Native NFT Standard

Pentagon Chain's proposal for autonomous agent identity. Enables AI agents to self-custody wallets and NFTs.

**Read the full proposal:** [EIPs/ERC-7857A-AINFT.md](./EIPs/ERC-7857A-AINFT.md)

**Key Features:**
- Deterministic wallet derivation from agent identity
- Agent self-custody via TEE/MPC
- Human control NFT for safety override
- Progressive certification tiers (L1-L4)

---

## Deployed Contracts

### Core

| Contract | Address | Description |
|----------|---------|-------------|
| PentagonAINFT | *Testnet* | ERC-7857A implementation |

---

## 📂 Public Contracts

| Folder | Description | Code |
|--------|-------------|------|
| [ATS](./contracts/ATS/) | Agent Test Standard - Soulbound certification | ✅ Public |
| [Badge](./contracts/Badge/) | Achievement badges | ✅ Public |
| [Banana](./contracts/Banana/) | Sample commodity token | ✅ Public |
| [EmotiCoin](./contracts/EmotiCoin/) | Pump.fun-style SocialFi launchpad | 📄 Docs only |
| [FoundationHero](./contracts/FoundationHero/) | BCSH Foundation NFTs | ✅ Public |
| [POW_SBT](./contracts/POW_SBT/) | Proof of Work soulbound tokens | ✅ Public |
| [SuperHeroes](./contracts/SuperHeroes/) | Hero NFT collection | ✅ Public |
| [SuperVillain](./contracts/SuperVillain/) | Villain NFT collection | ✅ Public |
| [WPC](./contracts/WPC/) | Wrapped PC (ERC-20) | ✅ Public |

---

## 🔴 HIGH BOUNTY - Cross-Chain Payment Processor

**Proprietary cross-chain payment stack. Deployed but unverified.**

| Network | Address |
|---------|---------|
| Ethereum | *Contact for address* |
| Pentagon Chain | *Contact for address* |

**HIGH BOUNTY for vulnerabilities.** Report to: nftprof@pentagon.games

---

## 📄 Internal Contracts (Docs Only)

The following contracts are documented but source code remains internal:

| Contract | Description | Status |
|----------|-------------|--------|
| EmotiCoin | Pump.fun-style bonding curve + token factory | Docs only |
| Pentaswap | Native DEX (Audited by CertiK) | Docs only |
| Gunnies | FPS game contracts | Docs only |
| EtherFantasy | Mobile game contracts | Docs only |
| PentaPets | Pet game contracts | Docs only |
| Mining | NFT mining mechanics | Docs only |
| NFTMarketplace | Marketplace contracts | Docs only |
| Khaos | Khaos token ecosystem | Docs only |
| Farming | Yield farming | Docs only |

*Contact us for partnership access to internal contracts.*

### DeFi (Pentaswap)

| Contract | Address | Description |
|----------|---------|-------------|
| *Coming soon* | | |

### NFT / Gaming

| Contract | Address | Description |
|----------|---------|-------------|
| *Coming soon* | | |

---

## Development

```bash
# Install dependencies
npm install

# Compile
npx hardhat compile

# Deploy
npx hardhat run scripts/deploy.js --network pentagon
```

---

## Hardhat Config

```javascript
networks: {
  pentagon: {
    url: "https://rpc.pentagon.games",
    chainId: 3344,
    accounts: [PRIVATE_KEY]
  }
}
```

---

## License

MIT

---

*Pentagon Chain - Where Humans and AI Meet*
