import type { Metadata } from "next"
import "./globals.css"
import { Providers } from "./provider"
import { type ReactNode } from "react"
import Header from "@/components/Header"

export const metadata: Metadata = {
  title: "MonadBlitz NFT | Batch Mint 1000 NFTs",
  description: "Mint 1000 unique on-chain NFTs in one transaction on Monad",
}

export default function RootLayout(prop: { children: ReactNode }) {
  return (
    <html lang="en">
      <body>
        <Providers>
          <Header />
          {prop.children}
        </Providers>
      </body>
    </html>
  )
}