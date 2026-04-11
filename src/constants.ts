export const MONAD_NFT_ADDRESS = "0x581E516E2a62Cf5338471AA9343EeF831A098CCd" as `0x${string}`
export const BATCH_MINTER_ADDRESS = "0x6026e7ECa0AA41381ca8D7D87290AF039795E891" as `0x${string}`

export const MONAD_NFT_ABI = [
  {
    name: "totalSupply",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "uint256" }]
  },
  {
    name: "tokenURI",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "tokenId", type: "uint256" }],
    outputs: [{ name: "", type: "string" }]
  },
  {
    name: "ownerOf",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "tokenId", type: "uint256" }],
    outputs: [{ name: "", type: "address" }]
  },
  {
    name: "MAX_SUPPLY",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "uint256" }]
  },
  {
    name: "balanceOf",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "owner", type: "address" }],
    outputs: [{ name: "", type: "uint256" }]
  }
] as const

export const BATCH_MINTER_ABI = [
  {
    name: "batchMint",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [
      { name: "to", type: "address" },
      { name: "amount", type: "uint256" }
    ],
    outputs: []
  },
  {
    name: "publicMint",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [],
    outputs: []
  },
  {
    name: "remainingSupply",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "uint256" }]
  },
  {
    name: "BatchMinted",
    type: "event",
    inputs: [
      { name: "to", type: "address", indexed: true },
      { name: "startId", type: "uint256", indexed: false },
      { name: "endId", type: "uint256", indexed: false },
      { name: "count", type: "uint256", indexed: false },
      { name: "timeTaken", type: "uint256", indexed: false }
    ]
  }
] as const