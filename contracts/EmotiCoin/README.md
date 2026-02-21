# EmotiCoin - SocialFi Token Factory

**Pump.fun-style token launchpad for Pentagon Chain**

---

## Overview

EmotiCoin is Pentagon Chain's native SocialFi token platform. Create, launch, and graduate community tokens with built-in bonding curves and liquidity mechanics.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    EmotiCoin Factory                             │
│              (Deploy new community tokens)                       │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    EmotiCoin Token                               │
│                     (ERC-20 Base)                                │
│  • Community-owned                                               │
│  • Bonding curve pricing                                         │
│  • Auto-liquidity on graduation                                  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Bonding Curve                                  │
│          (Price increases with supply)                           │
│                                                                  │
│   Price = f(supply) → Early buyers get better price             │
│   Graduation threshold → Liquidity pool created                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## How It Works

**1. Token Creation**
- Anyone can create a new community token
- Set name, symbol, and metadata
- Initial supply minted to bonding curve

**2. Bonding Curve Phase**
- Buy/sell against the curve
- Price increases as supply grows
- All trades pay small fee to creator + protocol

**3. Graduation**
- When market cap reaches threshold
- Liquidity automatically added to DEX
- Token becomes freely tradeable

---

## Contracts

| Contract | Description | Status |
|----------|-------------|--------|
| EmotiCoin | ERC-20 token with bonding curve integration | Internal |
| EmotiCoinFactory | Deploy new tokens | Internal |
| EmotiCoinCurve | Bonding curve math | Internal |
| EchoVaultBondingCurve | Vault + graduation logic | Internal |

*Contracts deployed on Pentagon Chain. Source code internal. Contact for partnership.*

---

## Functions

**Factory:**
| Function | Description |
|----------|-------------|
| `createToken(name, symbol, metadata)` | Deploy new community token |
| `getToken(id)` | Get token address by ID |

**Token:**
| Function | Description |
|----------|-------------|
| `buy(amount)` | Buy tokens from curve |
| `sell(amount)` | Sell tokens to curve |
| `graduate()` | Trigger graduation (if threshold met) |

**Curve:**
| Function | Description |
|----------|-------------|
| `getPrice(supply)` | Calculate current price |
| `getBuyAmount(pcAmount)` | Tokens received for PC input |
| `getSellAmount(tokenAmount)` | PC received for token input |

---

## Fee Structure

| Fee | Recipient | Amount |
|-----|-----------|--------|
| Buy | Creator | 1% |
| Buy | Protocol | 1% |
| Sell | Creator | 1% |
| Sell | Protocol | 1% |
| Graduation | Liquidity Pool | Auto |

---

## Use Cases

- Community tokens
- Creator coins
- Meme tokens
- DAO governance tokens
- Gaming currencies

---

*Pentagon Chain - SocialFi for Everyone*
