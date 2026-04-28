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
"use client"

import { ConnectButton } from "@rainbow-me/rainbowkit";
import { Shield, Zap, MapPin, ArrowRight } from "lucide-react";
import { Button } from "@/components/ui/button";
import Link from "next/link";

// rest of the code stays exactly the same

export default function Home() {
  return (
    <main className="min-h-screen bg-gray-50">
      {/* Hero */}
      <section className="flex flex-col items-center justify-center text-center px-4 pt-24 pb-16">
        <div className="inline-flex items-center gap-2 bg-purple-100 text-purple-700 text-sm font-medium px-4 py-1.5 rounded-full mb-6">
          <Zap size={14} />
          Powered by Monad
        </div>

        <h1 className="text-5xl font-bold text-gray-900 max-w-3xl leading-tight mb-6">
          Delivery payments you can{" "}
          <span className="text-purple-600">actually trust</span>
        </h1>

        <p className="text-gray-500 text-lg max-w-xl mb-10">
          DispatchPay locks your payment in a smart contract until your package
          arrives. No middlemen. No fraud. Just secure, on-chain escrow.
        </p>

        <div className="flex flex-col sm:flex-row items-center gap-4">
          <ConnectButton />
          <Link href="/buyer">
            <Button variant="outline" className="gap-2">
              Place an order <ArrowRight size={16} />
            </Button>
          </Link>
        </div>
      </section>

      {/* How it works */}
      <section className="max-w-5xl mx-auto px-4 py-16">
        <h2 className="text-2xl font-bold text-gray-900 text-center mb-12">
          How it works
        </h2>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {[
            {
              step: "01",
              title: "Buyer locks funds",
              description:
                "Buyer selects a seller and zone. Payment is locked in the smart contract instantly.",
              icon: Shield,
            },
            {
              step: "02",
              title: "Seller delivers",
              description:
                "Seller delivers the package and generates a one-time OTP to confirm delivery.",
              icon: MapPin,
            },
            {
              step: "03",
              title: "Funds released",
              description:
                "Buyer confirms with the OTP. Funds are released to the seller after a 2-hour window.",
              icon: Zap,
            },
          ].map((item) => (
            <div
              key={item.step}
              className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100"
            >
              <div className="flex items-center gap-3 mb-4">
                <span className="text-purple-600 font-bold text-sm">
                  {item.step}
                </span>
                <div className="w-10 h-10 bg-purple-100 rounded-xl flex items-center justify-center">
                  <item.icon size={20} className="text-purple-600" />
                </div>
              </div>
              <h3 className="font-semibold text-gray-900 mb-2">{item.title}</h3>
              <p className="text-gray-500 text-sm leading-relaxed">
                {item.description}
              </p>
            </div>
          ))}
        </div>
      </section>

      {/* CTA */}
      <section className="max-w-2xl mx-auto px-4 py-16 text-center">
        <div className="bg-purple-600 rounded-3xl px-8 py-12">
          <h2 className="text-2xl font-bold text-white mb-3">
            Ready to get started?
          </h2>
          <p className="text-purple-200 mb-8">
            Connect your wallet and place your first order in under a minute.
          </p>
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
            <Link href="/buyer">
              <Button className="bg-white text-purple-600 hover:bg-purple-50 font-semibold gap-2">
                I'm a buyer <ArrowRight size={16} />
              </Button>
            </Link>
            <Link href="/seller">
              <Button
                variant="outline"
                className="border-white text-white hover:bg-purple-700 gap-2"
              >
                I'm a seller <ArrowRight size={16} />
              </Button>
            </Link>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="text-center text-gray-400 text-sm py-8">
        DispatchPay v1 · Built on Monad Testnet
      </footer>
    </main>
  );
}