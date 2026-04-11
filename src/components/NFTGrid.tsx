"use client"
import { useReadContract } from "wagmi"
import { MONAD_NFT_ADDRESS, MONAD_NFT_ABI } from "@/constants"
import { useState, useEffect } from "react"

function NFTCard({ tokenId }: { tokenId: number }) {
  const [svgData, setSvgData] = useState<string | null>(null)

  const { data: uri } = useReadContract({
    address: MONAD_NFT_ADDRESS,
    abi: MONAD_NFT_ABI,
    functionName: "tokenURI",
    args: [BigInt(tokenId)],
  })

  useEffect(() => {
    if (!uri) return
    try {
      const base64 = (uri as string).replace("data:application/json;base64,", "")
      const json = JSON.parse(atob(base64))
      setSvgData(json.image)
    } catch (err) {
      console.error(err)
    }
  }, [uri])

  return (
    <div className="border border-[#836EF9] rounded-xl overflow-hidden bg-white shadow-md">
      {svgData ? (
        <img src={svgData} alt={`MonadBlitz #${tokenId}`} className="w-full h-40 object-cover" />
      ) : (
        <div className="w-full h-40 bg-[#836EF9]/10 flex items-center justify-center">
          <p className="text-[#836EF9] text-sm">Loading...</p>
        </div>
      )}
      <div className="p-2 text-center">
        <p className="text-sm font-bold text-gray-700">#{tokenId}</p>
      </div>
    </div>
  )
}

export default function NFTGrid({ total }: { total: number }) {
  if (total === 0) return null

  // Show last 12 minted
  const tokenIds = Array.from(
    { length: Math.min(total, 12) },
    (_, i) => total - i
  ).filter(id => id > 0)

  return (
    <div className="w-full max-w-2xl mt-10">
      <h2 className="text-xl font-bold text-gray-800 mb-4 text-center">
        Recently Minted NFTs
      </h2>
      <div className="grid grid-cols-3 sm:grid-cols-4 gap-3">
        {tokenIds.map(id => (
          <NFTCard key={id} tokenId={id} />
        ))}
      </div>
    </div>
  )
}