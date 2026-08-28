"use client";

import { motion } from "framer-motion";
import { X, Check } from "lucide-react";
import WavyUnderline from "./WavyUnderline";

const rows = [
  {
    feature: "Verification",
    upwork: "Human reviewer, subjective",
    fiverr: "Buyer manually checks",
    escrow: "Audit Agent runs your test suite in a live sandbox. 48/48 pass = funds unlock.",
  },
  {
    feature: "Dispute",
    upwork: "Support ticket. Wait 5–14 days.",
    fiverr: "5-day review period",
    escrow: "Voice Agent calls both parties and captures signed verbal agreement. Same day.",
  },
  {
    feature: "Payout",
    upwork: "Manual approval + 5-day hold",
    fiverr: "14-day clearance",
    escrow: "Execution Agent triggers Stitch bank transfer in seconds. No hold.",
  },
  {
    feature: "Fee",
    upwork: "10–20% of every payout",
    fiverr: "20% flat commission",
    escrow: "$0.05 flat. Zero commission. Zero percentage.",
  },
  {
    feature: "Automation",
    upwork: "None",
    fiverr: "None",
    escrow: "4 AI agents work in sequence: Audit → Strategy → Voice → Payout.",
  },
];

export default function Comparison() {
  return (
    <section
      className="w-full bg-black py-32 px-4 sm:px-8 border-t border-white/5"
      id="comparison"
    >
      <div className="max-w-6xl mx-auto">

        {/* heading */}
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
          className="mb-20"
        >
          <p className="text-sm text-neutral-500 mb-5">
            Why not just use Upwork or Fiverr?
          </p>
          <h2 className="font-display text-5xl sm:text-6xl md:text-7xl font-bold tracking-tight text-white leading-[1.05]">
            They send a human.{" "}
            <span className="relative inline-block">
              We send four agents.
              <WavyUnderline className="text-emerald-500/60 -bottom-3" />
            </span>
          </h2>
        </motion.div>

        {/* column headers */}
        <motion.div
          initial={{ opacity: 0, y: 12 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.45, delay: 0.1 }}
          className="grid grid-cols-[1.2fr_1fr_1fr_1.4fr] gap-0 pb-5 border-b border-white/10"
        >
          <div />
          <div className="px-6 border-l border-white/10">
            <p className="font-display text-xl font-bold text-neutral-400">Upwork</p>
          </div>
          <div className="px-6 border-l border-white/10">
            <p className="font-display text-xl font-bold text-neutral-400">Fiverr</p>
          </div>
          <div className="px-6 border-l border-emerald-500/40">
            <div className="flex items-center gap-3">
              <p className="font-display text-xl font-bold text-white">EscrowGuard</p>
              <span className="px-2.5 py-0.5 rounded-full bg-emerald-500/10 border border-emerald-500/25 text-emerald-400 text-xs font-display font-semibold">
                AI
              </span>
            </div>
          </div>
        </motion.div>

        {/* rows */}
        <div className="flex flex-col">
          {rows.map((row, i) => (
            <motion.div
              key={row.feature}
              initial={{ opacity: 0, y: 10 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.4, delay: 0.1 + i * 0.07 }}
              className="grid grid-cols-[1.2fr_1fr_1fr_1.4fr] gap-0 py-7 border-b border-white/[0.07] group hover:bg-white/[0.015] transition-colors -mx-4 px-4"
            >
              {/* feature */}
              <div className="flex items-center pr-6">
                <p className="font-display text-2xl font-bold text-white">{row.feature}</p>
              </div>

              {/* upwork */}
              <div className="px-6 border-l border-white/[0.08] flex items-start gap-2.5 pt-1">
                <X className="w-4 h-4 text-neutral-600 shrink-0 mt-0.5" />
                <p className="text-neutral-500 text-base leading-snug">{row.upwork}</p>
              </div>

              {/* fiverr */}
              <div className="px-6 border-l border-white/[0.08] flex items-start gap-2.5 pt-1">
                <X className="w-4 h-4 text-neutral-600 shrink-0 mt-0.5" />
                <p className="text-neutral-500 text-base leading-snug">{row.fiverr}</p>
              </div>

              {/* escrowguard */}
              <div className="px-6 border-l border-emerald-500/25 bg-emerald-500/[0.03] group-hover:bg-emerald-500/[0.055] transition-colors -my-7 py-7 flex items-start gap-2.5">
                <Check className="w-4 h-4 text-emerald-400 shrink-0 mt-0.5" />
                <p className="text-neutral-100 text-base font-medium leading-snug">{row.escrow}</p>
              </div>
            </motion.div>
          ))}
        </div>

        {/* bottom stats */}
        <motion.div
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5, delay: 0.3 }}
          className="mt-16 grid grid-cols-2 sm:grid-cols-4 gap-8"
        >
          {[
            ["6 min", "avg. resolution"],
            ["$0.05", "per milestone"],
            ["0%", "commission"],
            ["4 agents", "autonomous pipeline"],
          ].map(([value, label]) => (
            <div key={label} className="flex flex-col gap-2">
              <span className="font-display text-3xl font-bold text-emerald-400 tracking-tight">
                {value}
              </span>
              <span className="text-neutral-500 text-sm">
                {label}
              </span>
            </div>
          ))}
        </motion.div>

      </div>
    </section>
  );
}
