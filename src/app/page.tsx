"use client"

import { ConnectButton } from "@rainbow-me/rainbowkit"
import Link from "next/link"
import { useState, useEffect, useRef } from "react"
import {
  ArrowRight,
  ExternalLink,
  Lock,
  MapPin,
  CheckSquare,
  Zap,
  Clock,
  RefreshCw,
  Shield,
  AlertTriangle,
  Smartphone,
  Check,
} from "lucide-react"

const faqs = [
  {
    q: "What if the seller never delivers?",
    a: "If the seller hasn't marked your order as delivered within 7 days, you can call claimRefund() directly on the contract for a full refund. No middleman, no support ticket — just one transaction.",
  },
  {
    q: "What happens if I enter the wrong OTP?",
    a: "You get 4 attempts. If all 4 are exhausted, the order automatically enters Disputed state and is reviewed by the contract owner. This prevents brute-force guessing of the OTP.",
  },
  {
    q: "Can I dispute after confirming delivery?",
    a: "Yes — you have a 2-hour window after OTP confirmation. Raise a dispute before it closes and funds are frozen for review. After 2 hours, funds release automatically to the seller.",
  },
  {
    q: "Who handles disputes — isn't that centralised?",
    a: "Yes, dispute resolution in v1 is handled by the contract owner. This is a deliberate tradeoff — fully decentralised arbitration adds significant complexity. The resolution is still executed on-chain, meaning the outcome is publicly verifiable. A DAO or Kleros integration is a natural v2 direction.",
  },
  {
    q: "How does a seller set their prices?",
    a: 'Sellers call setPrice() on the contract per delivery zone (e.g. "lekki", "vi") with a USDC amount. They also call setAvailability(true) to open for orders. All prices are public on-chain — anyone can verify them.',
  },
  {
    q: "Does DispatchPay take a fee?",
    a: "The v1 contract charges zero platform fee. The full escrowed amount goes to the seller on release. You only pay Base Sepolia gas, which is minimal.",
  },
  {
    q: "Is the contract open source?",
    a: "Yes. EscrowCore is fully open source and verifiable on the Base Sepolia explorer. Every line of logic that handles your funds is public — no proprietary black boxes.",
  },
]

const zones = [
  { name: "Lekki", price: "$8.00", key: "lekki" },
  { name: "Victoria Island", price: "$10.00", key: "vi" },
  { name: "Ikoyi", price: "$9.00", key: "ikoyi" },
  { name: "Surulere", price: "$12.00", key: "surulere" },
  { name: "Ikeja", price: "$14.00", key: "ikeja" },
  { name: "Yaba", price: "$11.00", key: "yaba" },
  { name: "Ajah", price: "$13.00", key: "ajah" },
  { name: "Festac", price: "$15.00", key: "festac" },
]

function useReveal() {
  const ref = useRef<HTMLDivElement>(null)
  const [visible, setVisible] = useState(false)
  useEffect(() => {
    const el = ref.current
    if (!el) return
    const obs = new IntersectionObserver(
      ([entry]) => { if (entry.isIntersecting) { setVisible(true); obs.unobserve(el) } },
      { threshold: 0.07 }
    )
    obs.observe(el)
    return () => obs.disconnect()
  }, [])
  return { ref, visible }
}

function Reveal({ children, delay = 0 }: { children: React.ReactNode; delay?: number }) {
  const { ref, visible } = useReveal()
  return (
    <div
      ref={ref}
      style={{
        opacity: visible ? 1 : 0,
        transform: visible ? "translateY(0)" : "translateY(20px)",
        transition: `opacity 0.6s ${delay}s ease, transform 0.6s ${delay}s ease`,
      }}
    >
      {children}
    </div>
  )
}

const heroBgs = [
  "/images/hero1.jpg",
  "/images/hero2.jpg",
  "/images/hero3.jpg",
  "/images/hero4.jpg",
]

export default function Home() {
  const [openFaq, setOpenFaq] = useState<number | null>(null)
  const [mobileOpen, setMobileOpen] = useState(false)
  const [bgIndex, setBgIndex] = useState(0)
  const [prevBgIndex, setPrevBgIndex] = useState<number | null>(null)

  useEffect(() => {
    const interval = setInterval(() => {
      setBgIndex(i => {
        setPrevBgIndex(i)
        return (i + 1) % heroBgs.length
      })
    }, 10000)
    return () => clearInterval(interval)
  }, [])

  return (
    <main style={{ fontFamily: "'Cabinet Grotesk', 'Satoshi', sans-serif", background: "#0C0C0B", color: "#F0EDE6", minHeight: "100vh", overflowX: "hidden" }}>
      <style>{`
        @import url('https://api.fontshare.com/v2/css?f[]=cabinet-grotesk@400,500,700,800,900&f[]=satoshi@400,500,700&display=swap');
        @import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500&display=swap');

        *,*::before,*::after { box-sizing: border-box; margin: 0; padding: 0; }

        :root {
          --bg: #0C0C0B;
          --surface: #141412;
          --card: #1B1A17;
          --card2: #201F1B;
          --border: #252420;
          --border2: #2E2D29;
          --text: #F0EDE6;
          --muted: #7A7872;
          --subtle: #3A3935;
          --faint: #1F1E1B;
          --orange: #F05A1A;
          --orange-glow: rgba(240,90,26,0.15);
          --orange-border: rgba(240,90,26,0.28);
          --orange-text: #F26B30;
          --green: #3ECF8E;
          --red: #E05252;
          --amber: #F0A500;
          --mono: 'JetBrains Mono', monospace;
        }

        html { scroll-behavior: smooth; }
        body { -webkit-font-smoothing: antialiased; }

        body::before {
          content: '';
          position: fixed;
          inset: 0;
          background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='0.04'/%3E%3C/svg%3E");
          pointer-events: none;
          z-index: 0;
          opacity: .4;
        }

        /* NAV */
        .dp-nav {
          position: fixed; top: 0; left: 0; right: 0; z-index: 200;
          display: flex; align-items: center; justify-content: space-between;
          padding: 0 2.5rem; height: 64px;
          background: rgba(12,12,11,0.88); backdrop-filter: blur(20px);
          border-bottom: 1px solid var(--border);
        }
        .dp-logo { display: flex; align-items: center; gap: 10px; text-decoration: none; }
        .dp-logo-mark {
          width: 30px; height: 30px; background: var(--orange); border-radius: 7px;
          display: flex; align-items: center; justify-content: center;
          font-family: 'Cabinet Grotesk', sans-serif; font-size: 14px; font-weight: 900; color: #fff; flex-shrink: 0;
        }
        .dp-logo-text { font-family: 'Cabinet Grotesk', sans-serif; font-size: 1rem; font-weight: 800; color: var(--text); letter-spacing: -0.02em; }
        .dp-nav-links { display: flex; align-items: center; gap: 2.25rem; }
        .dp-nav-links a { font-size: .82rem; color: var(--muted); text-decoration: none; font-weight: 500; letter-spacing: .01em; transition: color .2s; }
        .dp-nav-links a:hover { color: var(--text); }
        .dp-nav-right { display: flex; align-items: center; gap: 1rem; }

        .dp-hamburger {
          display: none; flex-direction: column; gap: 5px; cursor: pointer;
          padding: 6px; background: none; border: none;
        }
        .dp-hamburger span { width: 22px; height: 1.5px; background: var(--muted); display: block; }

        .dp-mobile-menu {
          display: none; position: fixed; top: 64px; left: 0; right: 0; z-index: 199;
          background: var(--surface); border-bottom: 1px solid var(--border);
          padding: 1.5rem 2rem; flex-direction: column; gap: 1.25rem;
        }
        .dp-mobile-menu.open { display: flex; }
        .dp-mobile-menu a { font-size: .9rem; color: var(--muted); text-decoration: none; font-weight: 500; }

        /* HERO */
        .dp-hero { padding: 140px 2.5rem 80px; max-width: 1140px; margin: 0 auto; position: relative; }

        @keyframes fadeUp { from { opacity: 0; transform: translateY(16px); } to { opacity: 1; transform: translateY(0); } }
        @keyframes pulse { 0%,100% { opacity:1; transform:scale(1); } 50% { opacity:.4; transform:scale(.75); } }

        .dp-badge {
          display: inline-flex; align-items: center; gap: 8px;
          background: var(--orange-glow); border: 1px solid var(--orange-border);
          color: var(--orange-text); font-size: .72rem; font-weight: 700;
          padding: .35rem 1rem; border-radius: 4px; margin-bottom: 2rem;
          letter-spacing: .1em; text-transform: uppercase; font-family: var(--mono);
          animation: fadeUp .6s ease both;
        }
        .dp-badge-dot { width: 6px; height: 6px; background: var(--orange); border-radius: 50%; animation: pulse 2s infinite; }

        .dp-hero h1 {
          font-family: 'Cabinet Grotesk', 'Satoshi', sans-serif;
          font-size: clamp(2.4rem, 5vw, 4.2rem);
          font-weight: 900; line-height: .95; letter-spacing: -.04em;
          margin-bottom: 1.75rem; max-width: 860px;
          animation: fadeUp .6s .1s ease both;
        }
        .dp-hero h1 em { font-style: normal; color: var(--orange); }
        .dp-hero h1 .line2 { display: block; color: var(--muted); }

        .dp-hero-sub {
          font-size: .95rem; color: var(--muted); max-width: 460px;
          line-height: 1.75; font-weight: 400; margin-bottom: 1.5rem;
          animation: fadeUp .6s .2s ease both;
        }

        /* contract chip */
        .dp-contract-chip {
          display: inline-flex; align-items: center; gap: 8px;
          background: var(--faint); border: 1px solid var(--border2);
          border-radius: 6px; padding: .5rem 1rem; margin-bottom: 2rem;
          text-decoration: none; transition: border-color .2s;
          animation: fadeUp .6s .25s ease both;
        }
        .dp-contract-chip:hover { border-color: var(--orange); }
        .chip-label { font-size: .68rem; color: var(--muted); font-weight: 500; text-transform: uppercase; letter-spacing: .06em; }
        .chip-addr { font-family: var(--mono); font-size: .72rem; color: var(--orange-text); }

        .dp-hero-actions {
          display: flex; align-items: center; gap: .875rem; flex-wrap: wrap;
          animation: fadeUp .6s .3s ease both;
        }

        /* buttons */
        .dp-btn-primary {
          background: var(--orange); color: #fff; border: none;
          padding: .875rem 2rem; border-radius: 6px;
          font-family: 'Cabinet Grotesk', sans-serif; font-size: .92rem; font-weight: 700;
          cursor: pointer; display: inline-flex; align-items: center; gap: 8px;
          transition: transform .2s, box-shadow .2s; letter-spacing: -.01em; text-decoration: none;
        }
        .dp-btn-primary:hover { transform: translateY(-2px); box-shadow: 0 10px 32px rgba(240,90,26,.35); }
        .dp-btn-outline {
          background: transparent; color: var(--text); border: 1px solid var(--border2);
          padding: .875rem 2rem; border-radius: 6px;
          font-family: 'Cabinet Grotesk', sans-serif; font-size: .92rem; font-weight: 500;
          cursor: pointer; display: inline-flex; align-items: center; gap: 8px;
          transition: border-color .2s, background .2s; text-decoration: none;
        }
        .dp-btn-outline:hover { border-color: var(--orange); background: var(--orange-glow); }
        .dp-btn-dark {
          background: #0C0C0B; color: #fff; border: none;
          padding: .875rem 1.75rem; border-radius: 6px;
          font-family: 'Cabinet Grotesk', sans-serif; font-size: .88rem; font-weight: 700;
          cursor: pointer; display: inline-flex; align-items: center; gap: 8px;
          white-space: nowrap; transition: opacity .2s; letter-spacing: -.01em; text-decoration: none;
        }
        .dp-btn-dark:hover { opacity: .82; }
        .dp-btn-white-outline {
          background: transparent; color: #fff; border: 1.5px solid rgba(255,255,255,.45);
          padding: .875rem 1.75rem; border-radius: 6px;
          font-family: 'Cabinet Grotesk', sans-serif; font-size: .88rem; font-weight: 500;
          cursor: pointer; display: inline-flex; align-items: center; gap: 8px;
          white-space: nowrap; transition: background .2s; letter-spacing: -.01em; text-decoration: none;
        }
        .dp-btn-white-outline:hover { background: rgba(255,255,255,.12); }

        /* stats */
        .dp-stats {
          display: grid; grid-template-columns: repeat(4,1fr);
          border: 1px solid var(--border); border-radius: 10px; overflow: hidden;
          margin-top: 4.5rem; animation: fadeUp .6s .4s ease both;
        }
        .dp-stat {
          padding: 1.5rem 1.25rem; border-right: 1px solid var(--border);
          background: var(--surface); text-align: center; transition: background .2s;
        }
        .dp-stat:last-child { border-right: none; }
        .dp-stat:hover { background: var(--card); }
        .dp-stat-num { font-family: 'Cabinet Grotesk', sans-serif; font-size: 1.4rem; font-weight: 900; letter-spacing: -.04em; color: var(--text); line-height: 1; margin-bottom: .3rem; }
        .dp-stat-label { font-size: .7rem; color: var(--muted); letter-spacing: .04em; text-transform: uppercase; font-weight: 400; }

        /* divider */
        .dp-divider { height: 1px; background: var(--border); max-width: 1140px; margin: 0 auto; }

        /* sections */
        .dp-section { padding: 6rem 2.5rem; max-width: 1140px; margin: 0 auto; }
        .dp-sec-tag { font-size: .7rem; font-weight: 700; letter-spacing: .14em; text-transform: uppercase; color: var(--orange-text); margin-bottom: .75rem; font-family: var(--mono); }
        .dp-sec-title { font-family: 'Cabinet Grotesk', sans-serif; font-size: clamp(1.5rem,2.5vw,2rem); font-weight: 900; letter-spacing: -.035em; line-height: 1.05; margin-bottom: .9rem; }
        .dp-sec-sub { font-size: .92rem; color: var(--muted); max-width: 440px; line-height: 1.8; font-weight: 300; }

        /* steps */
        .dp-steps { display: grid; grid-template-columns: repeat(4,1fr); gap: 1px; background: var(--border); border-radius: 10px; overflow: hidden; margin-top: 3.5rem; }
        .dp-step { background: var(--surface); padding: 2rem 1.75rem; transition: background .2s; }
        .dp-step:hover { background: var(--card); }
        .dp-step-num { font-size: .65rem; font-weight: 700; letter-spacing: .14em; text-transform: uppercase; color: var(--subtle); margin-bottom: 1.25rem; font-family: var(--mono); }
        .dp-step-icon {
          width: 40px; height: 40px; background: var(--orange-glow); border: 1px solid var(--orange-border);
          border-radius: 8px; display: flex; align-items: center; justify-content: center; margin-bottom: 1.1rem; color: var(--orange-text);
        }
        .dp-step-fn { display: inline-block; font-size: .68rem; font-family: var(--mono); color: var(--orange-text); background: var(--orange-glow); padding: 2px 8px; border-radius: 3px; margin-bottom: .7rem; }
        .dp-step-title { font-family: 'Cabinet Grotesk', sans-serif; font-size: .95rem; font-weight: 800; letter-spacing: -.02em; margin-bottom: .55rem; }
        .dp-step-desc { font-size: .8rem; color: var(--muted); line-height: 1.75; font-weight: 300; }

        /* OTP visualizer */
        .dp-otp { margin-top: 2rem; background: var(--surface); border: 1px solid var(--border); border-radius: 12px; overflow: hidden; }
        .dp-otp-header {
          display: flex; align-items: center; justify-content: space-between;
          padding: 1.1rem 1.5rem; border-bottom: 1px solid var(--border);
        }
        .dp-otp-header-left { display: flex; align-items: center; gap: 10px; font-size: .85rem; font-weight: 600; font-family: 'Cabinet Grotesk', sans-serif; color: var(--orange-text); }
        .dp-otp-body { display: grid; grid-template-columns: 1fr 1px 1fr; }
        .dp-otp-col { padding: 1.75rem 2rem; }
        .dp-otp-sep { background: var(--border); }
        .dp-otp-role { font-size: .65rem; letter-spacing: .1em; text-transform: uppercase; color: var(--muted); font-family: var(--mono); margin-bottom: .75rem; }
        .dp-otp-action { font-size: .88rem; font-weight: 600; font-family: 'Cabinet Grotesk', sans-serif; margin-bottom: .5rem; }
        .dp-otp-detail { font-size: .78rem; color: var(--muted); line-height: 1.7; font-weight: 300; }
        .dp-otp-hash {
          display: inline-block; background: var(--faint); border: 1px solid var(--border2);
          border-radius: 5px; padding: .5rem .875rem; margin-top: .875rem;
          font-family: var(--mono); font-size: .65rem; color: var(--subtle); word-break: break-all; line-height: 1.5;
        }
        .dp-otp-code {
          display: inline-flex; align-items: center; gap: 6px;
          background: var(--faint); border: 1px solid var(--border2);
          border-radius: 5px; padding: .5rem .875rem; margin-top: .875rem;
          font-family: var(--mono); font-size: .85rem; letter-spacing: .12em; color: var(--orange-text);
        }
        .dp-otp-attempts { display: flex; gap: 5px; margin-top: .875rem; }
        .dp-otp-attempt { width: 10px; height: 10px; border-radius: 50%; background: var(--border2); border: 1px solid var(--border); }
        .dp-otp-attempt.ok { background: var(--green); border-color: var(--green); }

        /* lifecycle */
        .dp-track {
          display: flex; align-items: center;
          background: var(--surface); border: 1px solid var(--border); border-radius: 10px; overflow: hidden; margin-bottom: 1rem;
        }
        .dp-track-item { flex: 1; display: flex; flex-direction: column; align-items: center; gap: 6px; padding: 1.25rem .75rem; border-right: 1px solid var(--border); text-align: center; }
        .dp-track-item:last-child { border-right: none; }
        .dp-track-dot { width: 34px; height: 34px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 14px; border: 1.5px solid transparent; }
        .dp-track-dot.funded { background: rgba(240,165,0,.1); border-color: rgba(240,165,0,.35); }
        .dp-track-dot.delivered { background: var(--orange-glow); border-color: var(--orange-border); }
        .dp-track-dot.completed { background: rgba(62,207,142,.1); border-color: rgba(62,207,142,.3); }
        .dp-track-dot.released { background: rgba(62,207,142,.15); border-color: rgba(62,207,142,.4); }
        .dp-track-label { font-size: .7rem; color: var(--muted); font-weight: 400; letter-spacing: .02em; }

        .dp-alt-states { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
        .dp-alt-card { background: var(--surface); border: 1px solid var(--border); border-radius: 10px; padding: 1.25rem 1.5rem; }
        .dp-alt-card.disputed { border-color: rgba(224,82,82,.2); }
        .dp-alt-head { display: flex; align-items: center; gap: 10px; margin-bottom: .55rem; }
        .dp-alt-dot { width: 28px; height: 28px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 12px; border: 1.5px solid rgba(224,82,82,.35); background: rgba(224,82,82,.08); color: var(--red); flex-shrink: 0; }
        .dp-alt-title { font-size: .88rem; font-weight: 700; font-family: 'Cabinet Grotesk', sans-serif; }
        .dp-alt-desc { font-size: .78rem; color: var(--muted); line-height: 1.7; font-weight: 300; }

        /* trust */
        .dp-trust-grid { display: grid; grid-template-columns: repeat(3,1fr); gap: 1px; background: var(--border); border-radius: 10px; overflow: hidden; margin-top: 3.5rem; }
        .dp-trust-card { background: var(--surface); padding: 2rem 1.75rem; transition: background .2s; }
        .dp-trust-card:hover { background: var(--card); }
        .dp-trust-icon { width: 36px; height: 36px; background: var(--orange-glow); border-radius: 8px; display: flex; align-items: center; justify-content: center; margin-bottom: 1rem; color: var(--orange-text); }
        .dp-trust-title { font-size: .88rem; font-weight: 700; font-family: 'Cabinet Grotesk', sans-serif; margin-bottom: .45rem; }
        .dp-trust-desc { font-size: .78rem; color: var(--muted); line-height: 1.7; font-weight: 300; }

        /* seller section */
        .dp-seller { background: var(--surface); border: 1px solid var(--border); border-radius: 12px; overflow: hidden; margin-top: 3.5rem; }
        .dp-seller-top { display: grid; grid-template-columns: 1fr 1fr; }
        .dp-seller-col { padding: 2.5rem 2rem; border-right: 1px solid var(--border); }
        .dp-seller-col:last-child { border-right: none; }
        .dp-seller-col-tag { font-size: .65rem; letter-spacing: .12em; text-transform: uppercase; color: var(--muted); font-family: var(--mono); margin-bottom: .75rem; }
        .dp-seller-col-title { font-family: 'Cabinet Grotesk', sans-serif; font-size: 1rem; font-weight: 800; letter-spacing: -.02em; margin-bottom: .5rem; }
        .dp-seller-col-body { font-size: .8rem; color: var(--muted); line-height: 1.75; font-weight: 300; }
        .dp-code-block { margin-top: 1rem; background: var(--faint); border: 1px solid var(--border2); border-radius: 6px; padding: .875rem 1rem; font-family: var(--mono); font-size: .72rem; color: var(--muted); line-height: 1.9; }
        .dp-code-fn { color: var(--orange-text); }
        .dp-code-arg { color: #7EB8D4; }
        .dp-code-val { color: var(--green); }

        .dp-seller-flow { border-top: 1px solid var(--border); padding: 1.5rem 2rem; display: flex; align-items: center; gap: 0; overflow-x: auto; }
        .dp-sf-step { display: flex; align-items: center; gap: .75rem; flex-shrink: 0; }
        .dp-sf-num {
          width: 26px; height: 26px; border-radius: 50%;
          background: var(--orange-glow); border: 1px solid var(--orange-border);
          color: var(--orange-text); font-size: .72rem; font-weight: 700; font-family: var(--mono);
          display: flex; align-items: center; justify-content: center; flex-shrink: 0;
        }
        .dp-sf-text { font-size: .78rem; color: var(--muted); font-weight: 400; white-space: nowrap; }
        .dp-sf-arrow { font-size: 10px; color: var(--subtle); padding: 0 .875rem; flex-shrink: 0; }

        /* zones */
        .dp-zones-wrap { margin-top: 3.5rem; border: 1px solid var(--border); border-radius: 10px; overflow: hidden; }
        .dp-zones-header { display: flex; align-items: center; justify-content: space-between; padding: 1.1rem 1.5rem; border-bottom: 1px solid var(--border); background: var(--surface); }
        .dp-zones-header-left { display: flex; align-items: center; gap: 10px; font-size: .85rem; font-weight: 600; font-family: 'Cabinet Grotesk', sans-serif; }
        .dp-zones-header-right { font-size: .68rem; color: var(--subtle); letter-spacing: .06em; text-transform: uppercase; font-family: var(--mono); }
        .dp-zones-grid { display: grid; grid-template-columns: repeat(4,1fr); gap: 0; background: var(--border); }
        .dp-zone-item { background: var(--surface); padding: 1.25rem 1.5rem; border-right: 1px solid var(--border); border-bottom: 1px solid var(--border); transition: background .15s; }
        .dp-zone-item:nth-child(4n) { border-right: none; }
        .dp-zone-item:nth-child(n+5) { border-bottom: none; }
        .dp-zone-item:hover { background: var(--card); }
        .dp-zone-name { font-size: .78rem; font-weight: 500; color: var(--muted); margin-bottom: 4px; }
        .dp-zone-price { font-family: 'Cabinet Grotesk', sans-serif; font-size: 1.1rem; font-weight: 900; letter-spacing: -.03em; color: var(--text); line-height: 1; margin-bottom: 4px; }
        .dp-zone-key { font-size: .65rem; font-family: var(--mono); color: var(--subtle); }

        /* faq */
        .dp-faq { margin-top: 3.5rem; }
        .dp-faq-item { border-bottom: 1px solid var(--border); }
        .dp-faq-q { display: flex; align-items: center; justify-content: space-between; padding: 1.35rem 0; cursor: pointer; font-size: .92rem; font-weight: 500; gap: 1rem; user-select: none; transition: color .2s; }
        .dp-faq-q:hover { color: var(--orange-text); }
        .dp-faq-icon { width: 22px; height: 22px; border: 1px solid var(--border2); border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: .95rem; color: var(--muted); flex-shrink: 0; transition: transform .25s, border-color .2s, color .2s; line-height: 1; }
        .dp-faq-item.open .dp-faq-icon { transform: rotate(45deg); border-color: var(--orange); color: var(--orange-text); }
        .dp-faq-a { font-size: .82rem; color: var(--muted); line-height: 1.8; font-weight: 300; max-height: 0; overflow: hidden; transition: max-height .3s ease, padding-bottom .3s; }
        .dp-faq-item.open .dp-faq-a { max-height: 200px; padding-bottom: 1.25rem; }

        /* CTA */
        .dp-cta-wrap { padding: 2.5rem 2.5rem 6rem; max-width: 1140px; margin: 0 auto; }
        .dp-cta {
          background: var(--orange); border-radius: 14px; padding: 4rem 3.5rem;
          display: grid; grid-template-columns: 1fr auto; align-items: center; gap: 2rem;
          position: relative; overflow: hidden;
        }
        .dp-cta::before { content: ''; position: absolute; top: -80px; right: 80px; width: 320px; height: 320px; background: rgba(255,255,255,.06); border-radius: 50%; pointer-events: none; }
        .dp-cta::after { content: ''; position: absolute; bottom: -100px; right: -50px; width: 280px; height: 280px; background: rgba(0,0,0,.07); border-radius: 50%; pointer-events: none; }
        .dp-cta h2 { font-family: 'Cabinet Grotesk', sans-serif; font-size: clamp(1.5rem,2.5vw,2.2rem); font-weight: 900; letter-spacing: -.04em; color: #fff; line-height: 1.0; margin-bottom: .65rem; position: relative; }
        .dp-cta p { color: rgba(255,255,255,.75); font-size: .92rem; max-width: 400px; line-height: 1.75; font-weight: 300; position: relative; }
        .dp-cta-actions { display: flex; flex-direction: column; gap: .75rem; align-items: flex-end; position: relative; flex-shrink: 0; }

        /* footer */
        .dp-footer { border-top: 1px solid var(--border); padding: 1.75rem 2.5rem; display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 1rem; }
        .dp-footer-left { display: flex; align-items: center; gap: 1.5rem; }
        .dp-footer-logo { font-family: 'Cabinet Grotesk', sans-serif; font-size: .88rem; font-weight: 800; letter-spacing: -.02em; color: var(--text); }
        .dp-footer-tag { font-size: .68rem; color: var(--subtle); font-weight: 400; letter-spacing: .06em; text-transform: uppercase; font-family: var(--mono); }
        .dp-footer-links { display: flex; align-items: center; gap: 1.75rem; }
        .dp-footer-links a { font-size: .8rem; color: var(--muted); text-decoration: none; font-weight: 400; transition: color .2s; }
        .dp-footer-links a:hover { color: var(--text); }

        /* responsive */
        @media (max-width: 900px) {
          .dp-nav { padding: 0 1.25rem; }
          .dp-nav-links { display: none; }
          .dp-hamburger { display: flex; }
          .dp-hero { padding: 110px 1.25rem 60px; }
          .dp-stats { grid-template-columns: repeat(2,1fr); }
          .dp-stats .dp-stat:nth-child(2) { border-right: none; }
          .dp-section { padding: 4rem 1.25rem; }
          .dp-steps { grid-template-columns: 1fr 1fr; }
          .dp-otp-body { grid-template-columns: 1fr; }
          .dp-otp-sep { display: none; }
          .dp-trust-grid { grid-template-columns: 1fr 1fr; }
          .dp-seller-top { grid-template-columns: 1fr; }
          .dp-seller-col { border-right: none; border-bottom: 1px solid var(--border); }
          .dp-seller-col:last-child { border-bottom: none; }
          .dp-zones-grid { grid-template-columns: repeat(2,1fr); }
          .dp-zone-item:nth-child(2n) { border-right: none; }
          .dp-zone-item:nth-child(n+7) { border-bottom: none; }
          .dp-alt-states { grid-template-columns: 1fr; }
          .dp-cta { grid-template-columns: 1fr; padding: 2.5rem 1.75rem; }
          .dp-cta-actions { align-items: flex-start; flex-direction: row; flex-wrap: wrap; }
          .dp-footer { flex-direction: column; align-items: flex-start; }
        }
        @media (max-width: 540px) {
          .dp-steps { grid-template-columns: 1fr; }
          .dp-trust-grid { grid-template-columns: 1fr; }
        }
      `}</style>

      {/* NAV */}
      <nav className="dp-nav">
        <a className="dp-logo" href="#">
          <div className="dp-logo-mark">D</div>
          <span className="dp-logo-text">DispatchPay</span>
        </a>
        <div className="dp-nav-links">
          <a href="#how-it-works">How it works</a>
          <a href="#for-sellers">For sellers</a>
          <a href="#protections">Protections</a>
          <a href="#faq">FAQ</a>
        </div>
        <div className="dp-nav-right">
          <ConnectButton />
          <button className="dp-hamburger" onClick={() => setMobileOpen(o => !o)} aria-label="Menu">
            <span /><span /><span />
          </button>
        </div>
      </nav>
      <div className={`dp-mobile-menu${mobileOpen ? " open" : ""}`}>
        <a href="#how-it-works" onClick={() => setMobileOpen(false)}>How it works</a>
        <a href="#for-sellers" onClick={() => setMobileOpen(false)}>For sellers</a>
        <a href="#protections" onClick={() => setMobileOpen(false)}>Protections</a>
        <a href="#faq" onClick={() => setMobileOpen(false)}>FAQ</a>
      </div>

      {/* HERO */}
      <div style={{ position: "relative", width: "100%" }}>
        {heroBgs.map((src, i) => (
          <div
            key={src}
            style={{
              position: "absolute",
              inset: 0,
              backgroundImage: `url(${src})`,
              backgroundSize: "cover",
              backgroundPosition: "center",
              opacity: i === bgIndex ? 1 : 0,
              transition: "opacity 2.5s ease",
              zIndex: 0,
            }}
          />
        ))}
        <div style={{ position: "absolute", inset: 0, background: "linear-gradient(to bottom,rgba(12,12,11,0.72) 0%, rgba(12,12,11,0.88) 100%)", zIndex: 1 }} />
        <div className="dp-hero" style={{ position: "relative", zIndex: 2 }}>
          <div className="dp-badge"><span className="dp-badge-dot" />Live · Base Sepolia</div>
          <h1>
            Delivery payments<br />
            <em>that can&apos;t</em>
            <span className="line2">be faked.</span>
          </h1>
          <p className="dp-hero-sub">
            Funds are locked on-chain until your package arrives and you confirm it with a one-time code. No trust required — just cryptographic proof.
          </p>
          <a
            className="dp-contract-chip"
            href="https://sepolia.basescan.org/address/0xYOUR_DEPLOYED_CONTRACT_ADDRESS"
            target="_blank"
            rel="noopener noreferrer"
          >
            <span className="chip-label">Contract</span>
            <span className="chip-addr">0x0000…0000</span>
            <ExternalLink size={14} />
          </a>
          <div className="dp-hero-actions">
            <Link href="/buyer"><button className="dp-btn-primary">Place an order <ArrowRight size={14} /></button></Link>
            <Link href="/seller"><button className="dp-btn-outline">Become a seller</button></Link>
          </div>
          <div className="dp-stats">
            <div className="dp-stat"><div className="dp-stat-num">$0</div><div className="dp-stat-label">Platform fee</div></div>
            <div className="dp-stat"><div className="dp-stat-num">2 hr</div><div className="dp-stat-label">Dispute window</div></div>
            <div className="dp-stat"><div className="dp-stat-num">7 days</div><div className="dp-stat-label">Refund guarantee</div></div>
            <div className="dp-stat"><div className="dp-stat-num">100%</div><div className="dp-stat-label">Non-custodial</div></div>
          </div>
          <div style={{ display: "flex", gap: "6px", marginTop: "2rem" }}>
            {heroBgs.map((_, i) => (
              <button
                key={i}
                onClick={() => setBgIndex(i)}
                style={{
                  width: i === bgIndex ? "20px" : "6px",
                  height: "6px",
                  borderRadius: "3px",
                  background: i === bgIndex ? "var(--orange)" : "var(--subtle)",
                  border: "none",
                  cursor: "pointer",
                  padding: 0,
                  transition: "width 0.3s ease, background 0.3s ease",
                }}
              />
            ))}
          </div>
        </div>
      </div>

      <div className="dp-divider" />

      {/* HOW IT WORKS */}
      <section className="dp-section" id="how-it-works">
        <Reveal>
          <div className="dp-sec-tag">How it works</div>
          <h2 className="dp-sec-title">Four steps.<br />Zero trust needed.</h2>
          <p className="dp-sec-sub">Everything happens on-chain. Neither party can cheat — the contract enforces every rule.</p>
        </Reveal>
        <Reveal delay={0.1}>
          <div className="dp-steps">
            {[
              { num: "01", icon: <Lock size={18} />, fn: "createOrder()", title: "Buyer locks funds", desc: "Pick a seller and zone. The price is read straight from the contract — no manual input. Your payment is locked in escrow instantly." },
              { num: "02", icon: <MapPin size={18} />, fn: "markDelivered()", title: "Seller delivers", desc: "Seller delivers and generates a one-time OTP. The hash is stored on-chain. The raw OTP goes to the buyer via SMS or app notification." },
              { num: "03", icon: <CheckSquare size={18} />, fn: "confirmDelivery()", title: "Confirm with OTP", desc: "Enter the OTP to confirm receipt. You get 4 attempts. A 2-hour dispute window opens — raise a dispute before it closes if anything's wrong." },
              { num: "04", icon: <Zap size={18} />, fn: "releaseFunds()", title: "Funds auto-release", desc: "After 2 hours with no dispute, anyone can trigger the release. The frontend does this automatically — no extra transaction from the seller." },
            ].map(s => (
              <div className="dp-step" key={s.num}>
                <div className="dp-step-num">Step {s.num}</div>
                <div className="dp-step-icon">{s.icon}</div>
                <div className="dp-step-fn">{s.fn}</div>
                <div className="dp-step-title">{s.title}</div>
                <p className="dp-step-desc">{s.desc}</p>
              </div>
            ))}
          </div>
        </Reveal>

        {/* OTP Visualizer */}
        <Reveal delay={0.15}>
          <div className="dp-otp">
            <div className="dp-otp-header">
              <div className="dp-otp-header-left">
                <Smartphone size={14} />
                OTP delivery confirmation — how it actually works
              </div>
              <span style={{ fontSize: ".68rem", fontFamily: "var(--mono)", color: "var(--subtle)" }}>keccak256 verified</span>
            </div>
            <div className="dp-otp-body">
              <div className="dp-otp-col">
                <div className="dp-otp-role">Seller side</div>
                <div className="dp-otp-action">Generates OTP off-chain</div>
                <p className="dp-otp-detail">Raw code never touches the blockchain. Only its hash is stored — so the seller can&apos;t forge a &ldquo;delivered&rdquo; state without a real handoff.</p>
                <div className="dp-otp-hash">keccak256(&quot;482917&quot;) →<br />0x7f3a…c91b</div>
              </div>
              <div className="dp-otp-sep" />
              <div className="dp-otp-col">
                <div className="dp-otp-role">Buyer side</div>
                <div className="dp-otp-action">Receives raw OTP, enters it</div>
                <p className="dp-otp-detail">The contract hashes your input and checks it against the stored hash. 4 failed attempts freeze the order automatically.</p>
                <div className="dp-otp-code"><Check size={14} style={{ color: "var(--green)" }} /> 4 8 2 9 1 7</div>
                <div className="dp-otp-attempts">
                  <div className="dp-otp-attempt ok" />
                  <div className="dp-otp-attempt" />
                  <div className="dp-otp-attempt" />
                  <div className="dp-otp-attempt" />
                </div>
              </div>
            </div>
          </div>
        </Reveal>
      </section>

      <div className="dp-divider" />

      {/* LIFECYCLE */}
      <section className="dp-section">
        <Reveal>
          <div className="dp-sec-tag">Order lifecycle</div>
          <h2 className="dp-sec-title">Every on-chain state,<br />explained.</h2>
          <p className="dp-sec-sub">Your funds move through verifiable states. You always know exactly where your money is.</p>
        </Reveal>
        <Reveal delay={0.1}>
          <div style={{ marginTop: "3.5rem" }}>
            <div className="dp-track">
              {[
                { cls: "funded", emoji: "💰", label: "Funded" },
                { cls: "delivered", emoji: "📦", label: "Delivered" },
                { cls: "completed", emoji: "🔐", label: "Completed" },
                { cls: "released", emoji: "✅", label: "Released" },
              ].map(t => (
                <div className="dp-track-item" key={t.label}>
                  <div className={`dp-track-dot ${t.cls}`}>{t.emoji}</div>
                  <div className="dp-track-label">{t.label}</div>
                </div>
              ))}
            </div>
            <div className="dp-alt-states">
              <div className="dp-alt-card disputed">
                <div className="dp-alt-head">
                  <div className="dp-alt-dot">⚠️</div>
                  <div className="dp-alt-title">Disputed</div>
                </div>
                <p className="dp-alt-desc">Raised within the 2-hour window, or triggered after 4 failed OTP attempts. The contract owner investigates and resolves on-chain. Note: this is a centralised step by design — a deliberate v1 tradeoff.</p>
              </div>
              <div className="dp-alt-card refunded">
                <div className="dp-alt-head">
                  <div className="dp-alt-dot">↩️</div>
                  <div className="dp-alt-title">Refunded</div>
                </div>
                <p className="dp-alt-desc">Dispute resolved in the buyer&apos;s favour, or buyer calls <span style={{ fontFamily: "var(--mono)", fontSize: ".72rem", color: "var(--orange-text)" }}>claimRefund()</span> directly after 7 days of no delivery. No support ticket needed.</p>
              </div>
            </div>
          </div>
        </Reveal>
      </section>

      <div className="dp-divider" />

      {/* FOR SELLERS */}
      <section className="dp-section" id="for-sellers">
        <Reveal>
          <div className="dp-sec-tag">For sellers</div>
          <h2 className="dp-sec-title">Set up in three<br />on-chain calls.</h2>
          <p className="dp-sec-sub">No dashboard, no approval process. Deploy your zones, go live, start receiving orders.</p>
        </Reveal>
        <Reveal delay={0.1}>
          <div className="dp-seller">
            <div className="dp-seller-top">
              <div className="dp-seller-col">
                <div className="dp-seller-col-tag">Step 1 — Set your zones</div>
                <div className="dp-seller-col-title">Register delivery prices per zone</div>
                <p className="dp-seller-col-body">Call <span style={{ fontFamily: "var(--mono)", fontSize: ".78rem", color: "var(--orange-text)" }}>setPrice()</span> once per zone you deliver to, with a USDC amount. Buyers see your prices on-chain — no manual conversion needed.</p>
                <div className="dp-code-block">
                  <span className="dp-code-fn">setPrice</span>(<span className="dp-code-arg">&quot;lekki&quot;</span>, <span className="dp-code-val">8_000_000</span>)&nbsp;&nbsp;&nbsp;// $8.00<br />
                  <span className="dp-code-fn">setPrice</span>(<span className="dp-code-arg">&quot;vi&quot;</span>, <span className="dp-code-val">10_000_000</span>)&nbsp;&nbsp;&nbsp;&nbsp;// $10.00<br />
                  <span className="dp-code-fn">setPrice</span>(<span className="dp-code-arg">&quot;ikeja&quot;</span>, <span className="dp-code-val">14_000_000</span>)&nbsp;&nbsp;// $14.00
                </div>
              </div>
              <div className="dp-seller-col">
                <div className="dp-seller-col-tag">Step 2 — Go available</div>
                <div className="dp-seller-col-title">Toggle availability on-chain</div>
                <p className="dp-seller-col-body">Call <span style={{ fontFamily: "var(--mono)", fontSize: ".78rem", color: "var(--orange-text)" }}>setAvailability(true)</span> when you&apos;re open for orders. Toggle off during downtime — zone prices stay intact.</p>
                <div className="dp-code-block">
                  <span className="dp-code-fn">setAvailability</span>(<span className="dp-code-val">true</span>)&nbsp;&nbsp;&nbsp;// open<br />
                  <span className="dp-code-fn">setAvailability</span>(<span className="dp-code-val">false</span>)&nbsp;&nbsp;// pause<br />
                  <span style={{ color: "var(--subtle)" }}>// zones stay priced while paused</span>
                </div>
              </div>
            </div>
            <div className="dp-seller-flow">
              {[
                "setPrice() per zone",
                "setAvailability(true)",
                "Receive orders",
                "Deliver → markDelivered(otpHash)",
                "Funds auto-release after 2 hrs",
              ].map((text, i) => (
                <span key={i} style={{ display: "flex", alignItems: "center", gap: 0, flexShrink: 0 }}>
                  <span className="dp-sf-step">
                    <span className="dp-sf-num">{i + 1}</span>
                    <span className="dp-sf-text">{text}</span>
                  </span>
                  {i < 4 && <span className="dp-sf-arrow">→</span>}
                </span>
              ))}
            </div>
          </div>
        </Reveal>
      </section>

      <div className="dp-divider" />

      {/* PROTECTIONS */}
      <section className="dp-section" id="protections">
        <Reveal>
          <div className="dp-sec-tag">Buyer & seller protections</div>
          <h2 className="dp-sec-title">Built for trust.<br />On both sides.</h2>
          <p className="dp-sec-sub">The contract enforces protections for buyers and sellers. No platform sitting in the middle.</p>
        </Reveal>
        <Reveal delay={0.1}>
          <div className="dp-trust-grid">
            {[
              { icon: <Clock size={18} />, title: "2-hour dispute window", desc: "After OTP confirmation, you have 2 full hours to raise a dispute. Funds stay locked in the contract — neither party can access them." },
              { icon: <RefreshCw size={18} />, title: "7-day refund guarantee", desc: "If the seller never delivers within 7 days, you call claimRefund() directly on the contract. No support ticket, no wait." },
              { icon: <Shield size={18} />, title: "OTP-secured confirmation", desc: "Only the seller can generate the valid OTP. The hash lives on-chain. Four failed attempts auto-trigger a dispute — no brute-force possible." },
              { icon: <AlertTriangle size={18} />, title: "On-chain dispute resolution", desc: "Disputes are resolved by the contract owner and settled in a single on-chain transaction. Verifiable by anyone." },
              { icon: <MapPin size={18} />, title: "Zone-locked pricing", desc: "Prices per zone live on-chain. The contract reads them directly when an order is placed — what you see is what's enforced." },
              { icon: <Zap size={18} />, title: "Fully non-custodial", desc: "DispatchPay never holds your funds. The smart contract does. Money only moves when on-chain conditions are satisfied." },
            ].map(c => (
              <div className="dp-trust-card" key={c.title}>
                <div className="dp-trust-icon">{c.icon}</div>
                <div className="dp-trust-title">{c.title}</div>
                <p className="dp-trust-desc">{c.desc}</p>
              </div>
            ))}
          </div>
        </Reveal>
      </section>

      <div className="dp-divider" />

      {/* ZONES */}
      <section className="dp-section">
        <Reveal>
          <div className="dp-sec-tag">Zone pricing</div>
          <h2 className="dp-sec-title">Transparent,<br />on-chain prices.</h2>
          <p className="dp-sec-sub">Sellers register delivery prices per zone directly on the contract. All prices are in USDC — stable, no conversion needed.</p>
        </Reveal>
        <Reveal delay={0.1}>
          <div className="dp-zones-wrap">
            <div className="dp-zones-header">
              <div className="dp-zones-header-left">
                <MapPin size={14} style={{ color: "var(--orange-text)" }} />
                Lagos delivery zones · example pricing
              </div>
              <div className="dp-zones-header-right">Priced in USDC</div>
            </div>
            <div className="dp-zones-grid">
              {zones.map(z => (
                <div className="dp-zone-item" key={z.key}>
                  <div className="dp-zone-name">{z.name}</div>
                  <div className="dp-zone-price">{z.price}</div>
                  <div className="dp-zone-key">{z.key}</div>
                </div>
              ))}
            </div>
          </div>
        </Reveal>
      </section>

      <div className="dp-divider" />

      {/* FAQ */}
      <section className="dp-section" id="faq">
        <Reveal>
          <div className="dp-sec-tag">FAQ</div>
          <h2 className="dp-sec-title">Common questions.</h2>
        </Reveal>
        <Reveal delay={0.1}>
          <div className="dp-faq">
            {faqs.map((f, i) => (
              <div key={i} className={`dp-faq-item${openFaq === i ? " open" : ""}`}>
                <div className="dp-faq-q" onClick={() => setOpenFaq(openFaq === i ? null : i)}>
                  {f.q}
                  <span className="dp-faq-icon">+</span>
                </div>
                <div className="dp-faq-a">{f.a}</div>
              </div>
            ))}
          </div>
        </Reveal>
      </section>

      {/* CTA */}
      <div className="dp-cta-wrap">
        <Reveal>
          <div className="dp-cta">
            <div>
              <h2>Ready to send<br />or receive?</h2>
              <p>Connect your wallet and place your first escrow-backed delivery order in under a minute. No signup, no KYC.</p>
            </div>
            <div className="dp-cta-actions">
              <Link href="/buyer"><button className="dp-btn-dark">I&apos;m a buyer <ArrowRight size={14} /></button></Link>
              <Link href="/seller"><button className="dp-btn-white-outline">I&apos;m a seller <ArrowRight size={14} /></button></Link>
            </div>
          </div>
        </Reveal>
      </div>

      {/* FOOTER */}
      <footer className="dp-footer">
        <div className="dp-footer-left">
          <div className="dp-footer-logo">DispatchPay</div>
          <div className="dp-footer-tag">v1 · Base Sepolia</div>
        </div>
        <div className="dp-footer-links">
          <a href="https://sepolia.basescan.org/address/0xYOUR_DEPLOYED_CONTRACT_ADDRESS" target="_blank" rel="noopener noreferrer">Contract on Explorer</a>
          <a href="https://github.com/korexOnchain" target="_blank" rel="noopener noreferrer">GitHub</a>
          <a href="#">Docs</a>
        </div>
      </footer>
    </main>
  )
}
