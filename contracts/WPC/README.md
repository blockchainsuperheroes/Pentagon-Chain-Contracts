# Wrapped PC (WPC)

**ERC-20 wrapped version of Pentagon Chain gas token**

---

## Overview

WPC is the wrapped ERC-20 version of PC (Pentagon Chain's native gas token). Enables PC to be used in DeFi protocols, bridges, and smart contracts that require ERC-20 compatibility.

---

## Token Details

| Property | Value |
|----------|-------|
| Standard | ERC-20 |
| Decimals | 18 |
| Network | Pentagon Chain (3344) |
| Ratio | 1 WPC = 1 PC |

---

## Functions

| Function | Description |
|----------|-------------|
| `deposit()` | Wrap PC → WPC (payable) |
| `withdraw(amount)` | Unwrap WPC → PC |
| `transfer(to, amount)` | Standard ERC-20 transfer |
| `approve(spender, amount)` | Approve spending |

---

## Use Cases

- DEX liquidity pools
- Lending protocols
- Smart contract interactions
- Cross-chain bridges
- DeFi composability

---

## Wrapping

```solidity
// Wrap PC to WPC
wpc.deposit{value: 1 ether}();

// Unwrap WPC to PC
wpc.withdraw(1 ether);
```

---

*Pentagon Chain - Wrapped Gas Token*
