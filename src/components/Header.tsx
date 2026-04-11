"use client"
import { ConnectButton } from "@rainbow-me/rainbowkit"
import { FaGithub } from "react-icons/fa"

export default function Header() {
  return (
    <header className="w-full flex items-center justify-between px-8 py-4 border-b border-gray-200 bg-white">
      <div className="flex items-center gap-2">
        <span className="text-2xl font-bold text-[#836EF9]">MonadBlitz</span>
        <span className="text-2xl font-bold text-gray-800">NFT</span>
      </div>

      <div className="flex items-center gap-4">
        <a 
          href="https://github.com/korexOnchain"
          target="_blank"
          rel="noopener noreferrer"
          className="flex items-center gap-2 text-gray-700 hover:text-[#836EF9] transition-colors font-medium"
        >
          <FaGithub size={22} />
          <span className="hidden sm:block">GitHub</span>
        </a>
        <ConnectButton />
      </div>
    </header>
  )
}