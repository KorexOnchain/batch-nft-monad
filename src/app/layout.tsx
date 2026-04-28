import type { Metadata } from "next"
import "./globals.css"
import { Providers } from "./provider"
import { type ReactNode } from "react"
import { Geist } from "next/font/google";
import { cn } from "@/lib/utils";

const geist = Geist({subsets:['latin'],variable:'--font-sans'});

export const metadata: Metadata = {
  title: "DispatchPay",
  description: "Fast, secure escrow-based delivery payments on Monad",
}

export default function RootLayout(prop: { children: ReactNode }) {
  return (
    <html lang="en" className={cn("font-sans", geist.variable)}>
      <body>
        <Providers>
          {prop.children}
        </Providers>
      </body>
    </html>
  )
}