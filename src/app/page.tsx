"use client"
import NFTGrid from "@/components/NFTGrid"
import { useState } from "react"
import { useAccount, useWriteContract, useReadContract, useWaitForTransactionReceipt } from "wagmi"
import {
  MONAD_NFT_ADDRESS,
  BATCH_MINTER_ADDRESS,
  BATCH_MINTER_ABI,
  MONAD_NFT_ABI
} from "@/constants"

export default function Home() {
  const { address, isConnected } = useAccount()
  const [mintStart, setMintStart] = useState<number | null>(null)
  const [elapsed, setElapsed] = useState<number | null>(null)
  const [txHash, setTxHash] = useState<string | null>(null)

  const { data: totalSupply } = useReadContract({
    address: MONAD_NFT_ADDRESS,
    abi: MONAD_NFT_ABI,
    functionName: "totalSupply",
  })

  const { data: remaining } = useReadContract({
    address: BATCH_MINTER_ADDRESS,
    abi: BATCH_MINTER_ABI,
    functionName: "remainingSupply",
  })

  const { writeContractAsync, isPending } = useWriteContract()

  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash: txHash as `0x${string}` | undefined,
  })

  const handleBatchMint = async () => {
    if (!address) return
    try {
      setMintStart(Date.now())
      setElapsed(null)
      const hash = await writeContractAsync({
        address: BATCH_MINTER_ADDRESS,
        abi: BATCH_MINTER_ABI,
        functionName: "batchMint",
        args: [address, BigInt(1000)],
      })
      setTxHash(hash)
      setElapsed(Date.now() - (mintStart ?? Date.now()))
    } catch (err) {
      console.error(err)
    }
  }

  const handlePublicMint = async () => {
    if (!address) return
    try {
      const hash = await writeContractAsync({
        address: BATCH_MINTER_ADDRESS,
        abi: BATCH_MINTER_ABI,
        functionName: "publicMint",
      })
      setTxHash(hash)
    } catch (err) {
      console.error(err)
    }
  }

  return (
    <main className="min-h-screen bg-white text-gray-800 flex flex-col items-center justify-center px-4">
      <div className="mb-8 text-center">
        <h1 className="text-5xl font-bold text-[#836EF9] mb-2">MonadBlitz NFT</h1>
        <p className="text-gray-500 text-lg">1000 unique on-chain NFTs. One transaction. Monad speed.</p>
      </div>

      <div className="grid grid-cols-2 gap-4 mb-8 w-full max-w-md">
        <div className="bg-[#836EF9]/10 border border-[#836EF9] rounded-xl p-4 text-center">
          <p className="text-sm text-gray-400">Minted</p>
          <p className="text-3xl font-bold text-[#836EF9]">{totalSupply?.toString() ?? "0"}</p>
        </div>
        <div className="bg-green-50 border border-green-400 rounded-xl p-4 text-center">
          <p className="text-sm text-gray-400">Remaining</p>
          <p className="text-3xl font-bold text-green-500">{remaining?.toString() ?? "2000"}</p>
        </div>
      </div>

      {isConnected && (
        <div className="flex flex-col gap-4 w-full max-w-md">
          <button
            onClick={handleBatchMint}
            disabled={isPending || isConfirming}
            className="w-full bg-[#836EF9] hover:bg-[#6B55D9] disabled:opacity-50 text-white font-bold py-4 px-8 rounded-xl text-xl transition-all shadow-lg"
          >
            {isPending ? "Confirm in wallet..." : isConfirming ? "Minting 1000 NFTs..." : "⚡ Mint 1000 NFTs"}
          </button>

          <button
            onClick={handlePublicMint}
            disabled={isPending || isConfirming}
            className="w-full bg-transparent border border-[#836EF9] hover:bg-[#836EF9]/10 disabled:opacity-50 text-[#836EF9] font-bold py-3 px-8 rounded-xl text-lg transition-all"
          >
            Mint 1 NFT
          </button>
        </div>
      )}

      {!isConnected && (
        <p className="text-gray-400 text-sm mt-4">Connect your wallet to start minting</p>
      )}

      {isSuccess && txHash && (
        <div className="mt-8 w-full max-w-md bg-green-50 border border-green-400 rounded-xl p-4">
          <p className="text-green-600 font-bold text-lg mb-2">✅ Minted successfully on Monad!</p>
          {elapsed && (
            <p className="text-gray-700 text-sm mb-2">
               Time: <span className="text-[#836EF9] font-bold">{(elapsed / 1000).toFixed(2)}s</span>
            </p>
          )}
          
            <a href={`https://testnet.monadexplorer.com/tx/${txHash}`}
            target="_blank"
            rel="noopener noreferrer"
            className="text-[#836EF9] underline text-sm break-all"
          >
            View on Monad Explorer {">"}
          </a>
        </div>
      )}

      <NFTGrid total={Number(totalSupply ?? 0)} />

    </main>
  )
}