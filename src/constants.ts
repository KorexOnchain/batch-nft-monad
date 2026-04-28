export const ESCROW_CONTRACT_ADDRESS =
    "0x09af4bc6C485720C116e7737d5CAc0463Aa6d0D2" as const;

// Base Sepolia USDC
export const USDC_ADDRESS =
    "0x036CbD53842c5426634e7929541eC2318f3dCF7e" as const;

export const ESCROW_ABI = [
    {
        type: "constructor",
        inputs: [{ name: "_usdc", type: "address" }],
        stateMutability: "nonpayable",
    },

    // ── View / Pure functions ─────────────────────────────────────
    { type: "function", name: "DISPUTE_WINDOW", inputs: [], outputs: [{ name: "", type: "uint256" }], stateMutability: "view" },
    { type: "function", name: "MAX_OTP_ATTEMPTS", inputs: [], outputs: [{ name: "", type: "uint8" }], stateMutability: "view" },
    { type: "function", name: "REFUND_TIMEOUT", inputs: [], outputs: [{ name: "", type: "uint256" }], stateMutability: "view" },
    { type: "function", name: "orderCount", inputs: [], outputs: [{ name: "", type: "uint256" }], stateMutability: "view" },
    { type: "function", name: "owner", inputs: [], outputs: [{ name: "", type: "address" }], stateMutability: "view" },
    { type: "function", name: "usdc", inputs: [], outputs: [{ name: "", type: "address" }], stateMutability: "view" },
    {
        type: "function",
        name: "getOrder",
        inputs: [{ name: "orderId", type: "uint256" }],
        outputs: [{
            name: "", type: "tuple",
            components: [
                { name: "buyer", type: "address" },
                { name: "seller", type: "address" },
                { name: "zone", type: "bytes32" },
                { name: "otpHash", type: "bytes32" },
                { name: "usdcAmount", type: "uint256" },
                { name: "createdAt", type: "uint256" },
                { name: "deliveredAt", type: "uint256" },
                { name: "confirmedAt", type: "uint256" },
                { name: "status", type: "uint8" },
            ],
        }],
        stateMutability: "view",
    },
    {
        type: "function",
        name: "orders",
        inputs: [{ name: "", type: "uint256" }],
        outputs: [
            { name: "buyer", type: "address" },
            { name: "seller", type: "address" },
            { name: "zone", type: "bytes32" },
            { name: "otpHash", type: "bytes32" },
            { name: "usdcAmount", type: "uint256" },
            { name: "createdAt", type: "uint256" },
            { name: "deliveredAt", type: "uint256" },
            { name: "confirmedAt", type: "uint256" },
            { name: "status", type: "uint8" },
        ],
        stateMutability: "view",
    },
    { type: "function", name: "getStatus", inputs: [{ name: "orderId", type: "uint256" }], outputs: [{ name: "", type: "uint8" }], stateMutability: "view" },
    { type: "function", name: "getPrice", inputs: [{ name: "seller", type: "address" }, { name: "zone", type: "bytes32" }], outputs: [{ name: "usdcAmount", type: "uint256" }], stateMutability: "view" },
    { type: "function", name: "isSellerReady", inputs: [{ name: "seller", type: "address" }, { name: "zone", type: "bytes32" }], outputs: [{ name: "", type: "bool" }], stateMutability: "view" },
    { type: "function", name: "sellerAvailable", inputs: [{ name: "", type: "address" }], outputs: [{ name: "", type: "bool" }], stateMutability: "view" },
    { type: "function", name: "sellerPrices", inputs: [{ name: "", type: "address" }, { name: "", type: "bytes32" }], outputs: [{ name: "", type: "uint256" }], stateMutability: "view" },
    { type: "function", name: "otpAttempts", inputs: [{ name: "", type: "uint256" }], outputs: [{ name: "", type: "uint8" }], stateMutability: "view" },
    { type: "function", name: "disputeTimeLeft", inputs: [{ name: "orderId", type: "uint256" }], outputs: [{ name: "", type: "uint256" }], stateMutability: "view" },

    // ── Write functions ───────────────────────────────────────────
    { type: "function", name: "setAvailability", inputs: [{ name: "available", type: "bool" }], outputs: [], stateMutability: "nonpayable" },
    { type: "function", name: "setPrice", inputs: [{ name: "zone", type: "bytes32" }, { name: "usdcAmount", type: "uint256" }], outputs: [], stateMutability: "nonpayable" },
    { type: "function", name: "removePrice", inputs: [{ name: "zone", type: "bytes32" }], outputs: [], stateMutability: "nonpayable" },
    {
        type: "function",
        name: "createOrder",
        inputs: [{ name: "seller", type: "address" }, { name: "zone", type: "bytes32" }],
        outputs: [{ name: "orderId", type: "uint256" }],
        stateMutability: "nonpayable", // no longer payable — uses USDC transferFrom
    },
    { type: "function", name: "markDelivered", inputs: [{ name: "orderId", type: "uint256" }, { name: "otpHash", type: "bytes32" }], outputs: [], stateMutability: "nonpayable" },
    { type: "function", name: "confirmDelivery", inputs: [{ name: "orderId", type: "uint256" }, { name: "otp", type: "string" }], outputs: [], stateMutability: "nonpayable" },
    { type: "function", name: "releaseFunds", inputs: [{ name: "orderId", type: "uint256" }], outputs: [], stateMutability: "nonpayable" },
    { type: "function", name: "disputeOrder", inputs: [{ name: "orderId", type: "uint256" }], outputs: [], stateMutability: "nonpayable" },
    { type: "function", name: "claimRefund", inputs: [{ name: "orderId", type: "uint256" }], outputs: [], stateMutability: "nonpayable" },
    { type: "function", name: "resolveDispute", inputs: [{ name: "orderId", type: "uint256" }, { name: "refundBuyer", type: "bool" }], outputs: [], stateMutability: "nonpayable" },
    { type: "function", name: "renounceOwnership", inputs: [], outputs: [], stateMutability: "nonpayable" },
    { type: "function", name: "transferOwnership", inputs: [{ name: "newOwner", type: "address" }], outputs: [], stateMutability: "nonpayable" },

    // ── Events ────────────────────────────────────────────────────
    { type: "event", name: "OrderCreated", inputs: [{ name: "orderId", type: "uint256", indexed: true }, { name: "buyer", type: "address", indexed: true }, { name: "seller", type: "address", indexed: true }, { name: "zone", type: "bytes32", indexed: false }, { name: "usdcAmount", type: "uint256", indexed: false }], anonymous: false },
    { type: "event", name: "OrderDelivered", inputs: [{ name: "orderId", type: "uint256", indexed: true }, { name: "otpHash", type: "bytes32", indexed: false }], anonymous: false },
    { type: "event", name: "OrderCompleted", inputs: [{ name: "orderId", type: "uint256", indexed: true }, { name: "confirmedAt", type: "uint256", indexed: false }], anonymous: false },
    { type: "event", name: "OrderReleased", inputs: [{ name: "orderId", type: "uint256", indexed: true }, { name: "usdcAmount", type: "uint256", indexed: false }], anonymous: false },
    { type: "event", name: "OrderRefunded", inputs: [{ name: "orderId", type: "uint256", indexed: true }], anonymous: false },
    { type: "event", name: "OrderDisputed", inputs: [{ name: "orderId", type: "uint256", indexed: true }], anonymous: false },
    { type: "event", name: "DisputeResolved", inputs: [{ name: "orderId", type: "uint256", indexed: true }, { name: "recipient", type: "address", indexed: false }, { name: "usdcAmount", type: "uint256", indexed: false }], anonymous: false },
    { type: "event", name: "PriceSet", inputs: [{ name: "seller", type: "address", indexed: true }, { name: "zone", type: "bytes32", indexed: false }, { name: "usdcAmount", type: "uint256", indexed: false }], anonymous: false },
    { type: "event", name: "PriceRemoved", inputs: [{ name: "seller", type: "address", indexed: true }, { name: "zone", type: "bytes32", indexed: false }], anonymous: false },
    { type: "event", name: "AvailabilityChanged", inputs: [{ name: "seller", type: "address", indexed: true }, { name: "available", type: "bool", indexed: false }], anonymous: false },
    { type: "event", name: "OTPFailed", inputs: [{ name: "orderId", type: "uint256", indexed: true }, { name: "attemptNumber", type: "uint8", indexed: false }, { name: "attemptsLeft", type: "uint8", indexed: false }], anonymous: false },
    { type: "event", name: "OwnershipTransferred", inputs: [{ name: "previousOwner", type: "address", indexed: true }, { name: "newOwner", type: "address", indexed: true }], anonymous: false },

    // ── Errors ────────────────────────────────────────────────────
    { type: "error", name: "EscrowCore__DisputeWindowClosed", inputs: [] },
    { type: "error", name: "EscrowCore__DisputeWindowOpen", inputs: [] },
    { type: "error", name: "EscrowCore__InvalidOTP", inputs: [] },
    { type: "error", name: "EscrowCore__InvalidOTPHash", inputs: [] },
    { type: "error", name: "EscrowCore__InvalidZone", inputs: [] },
    { type: "error", name: "EscrowCore__MaxAttemptsReached", inputs: [] },
    { type: "error", name: "EscrowCore__NotBuyer", inputs: [] },
    { type: "error", name: "EscrowCore__NotSeller", inputs: [] },
    { type: "error", name: "EscrowCore__SelfTrade", inputs: [] },
    { type: "error", name: "EscrowCore__SellerUnavailable", inputs: [] },
    { type: "error", name: "EscrowCore__TimeoutNotReached", inputs: [] },
    { type: "error", name: "EscrowCore__TransferFailed", inputs: [] },
    { type: "error", name: "EscrowCore__WrongStatus", inputs: [{ name: "expected", type: "uint8" }, { name: "actual", type: "uint8" }] },
    { type: "error", name: "EscrowCore__ZeroAddress", inputs: [] },
    { type: "error", name: "EscrowCore__ZeroPayment", inputs: [] },
    { type: "error", name: "EscrowCore__ZeroPrice", inputs: [] },
    { type: "error", name: "EscrowCore__ZoneNotFound", inputs: [] },
    { type: "error", name: "OwnableInvalidOwner", inputs: [{ name: "owner", type: "address" }] },
    { type: "error", name: "OwnableUnauthorizedAccount", inputs: [{ name: "account", type: "address" }] },
    { type: "error", name: "ReentrancyGuardReentrantCall", inputs: [] },
    { type: "error", name: "SafeERC20FailedOperation", inputs: [{ name: "token", type: "address" }] },
] as const;

export const escrowContract = {
    address: ESCROW_CONTRACT_ADDRESS,
    abi: ESCROW_ABI,
} as const;

// Minimal ERC-20 ABI for USDC approve + allowance checks
export const ERC20_ABI = [
    { type: "function", name: "approve", inputs: [{ name: "spender", type: "address" }, { name: "amount", type: "uint256" }], outputs: [{ name: "", type: "bool" }], stateMutability: "nonpayable" },
    { type: "function", name: "allowance", inputs: [{ name: "owner", type: "address" }, { name: "spender", type: "address" }], outputs: [{ name: "", type: "uint256" }], stateMutability: "view" },
    { type: "function", name: "balanceOf", inputs: [{ name: "account", type: "address" }], outputs: [{ name: "", type: "uint256" }], stateMutability: "view" },
    { type: "function", name: "decimals", inputs: [], outputs: [{ name: "", type: "uint8" }], stateMutability: "view" },
] as const;

export const usdcContract = {
    address: USDC_ADDRESS,
    abi: ERC20_ABI,
} as const;

// Status enum mapping
export const ORDER_STATUS = {
    0: "Funded",
    1: "Delivered",
    2: "Completed",
    3: "Released",
    4: "Refunded",
    5: "Disputed",
} as const;

export type OrderStatus = keyof typeof ORDER_STATUS;

// Helper — converts a zone string to bytes32 for contract calls
export function encodeZone(zone: string): `0x${string}` {
    const hex = Buffer.from(zone, "utf8").toString("hex").padEnd(64, "0");
    return `0x${hex}`;
}