# MonadBlitz NFT 

Batch mint 1000 unique on-chain SVG NFTs in a single transaction on Monad blockchain.

## What is this?

MonadBlitz NFT is a dApp that demonstrates Monad's parallel execution by minting 1000 fully on-chain generative NFTs in one transaction — something impossible on Ethereum.

Every NFT is unique, generated mathematically from its token ID. No IPFS. No artist. Pure Solidity.

## Why Monad?

- 10,000 TPS & 0.8s finality makes batch minting viable
- Parallel EVM execution handles the 1000 mint loop blazing fast
- Near-zero gas fees
- Full EVM compatibility — same Solidity, same tools

## Tech Stack

- **Smart Contracts** — Solidity, Foundry
- **Frontend** — Next.js 16, TypeScript, Tailwind CSS
- **Web3** — Wagmi, Viem, RainbowKit
- **Network** — Monad Testnet

## Contracts

| Contract | Address |
|----------|---------|
| MonadNFT | `0x581E516E2a62Cf5338471AA9343EeF831A098CCd` |
| BatchMinter | `0x6026e7ECa0AA41381ca8D7D87290AF039795E891` |

## Getting Started

### Prerequisites
- Node.js
- pnpm
- Foundry

### Installation

```bash
git clone https://github.com/korexOnchain/batch-nft-monad
cd batch-nft-monad
pnpm install
```

### Run Frontend

```bash
pnpm dev
```

### Deploy Contracts

```bash
cd contracts
forge script script/Deploy.s.sol --rpc-url https://testnet-rpc.monad.xyz --broadcast --account your-wallet
```

## How It Works

1. `MonadNFT.sol` — ERC721 contract that generates unique SVG art per token ID on-chain
2. `BatchMinter.sol` — mints up to 1000 NFTs in a single transaction
3. Frontend lets anyone connect wallet and mint on Monad Testnet

## Live Demo

Add Monad Testnet to your wallet:
- **RPC:** `https://testnet-rpc.monad.xyz`
- **Chain ID:** `10143`
- **Symbol:** `MON`
- **Explorer:** `https://testnet.monadexplorer.com`

Built at **Monad Blitz Lagos Hackathon** 