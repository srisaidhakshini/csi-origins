"use client";

import { motion } from "framer-motion";
import { Bot, FileCode2, PhoneCall, Wallet } from "lucide-react";
import WavyUnderline from "./WavyUnderline";

const agents = [
  {
    id: "01",
    name: "audit agent",
    icon: <FileCode2 className="w-6 h-6" />,
    desc: "Verifies deliverables via cryptographic commit signatures and sandboxed CodeCrafters execution."
  },
  {
    id: "02",
    name: "strategy agent",
    icon: <Bot className="w-6 h-6" />,
    desc: "Calculates deterministic payout constraints. No raw LLM math hallucinations."
  },
  {
    id: "03",
    name: "voice agent",
    icon: <PhoneCall className="w-6 h-6" />,
    desc: "Captures dual verbal consent interactively via ElevenLabs streaming."
  },
  {
    id: "04",
    name: "execution agent",
    icon: <Wallet className="w-6 h-6" />,
    desc: "Releases instant bank payout automatically using Stitch API."
  }
];

export default function Architecture() {
  return (
    <section className="w-full bg-black py-32 px-6 overflow-hidden" id="architecture">
      <div className="max-w-7xl mx-auto">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          className="text-center mb-24 space-y-6"
        >
          <h2 className="text-4xl md:text-6xl font-display tracking-tight text-white relative inline-block">
            the agentic pipeline
            <WavyUnderline />
          </h2>
          <p className="text-neutral-400 text-lg max-w-2xl mx-auto">
            A specialized pipeline of agents. Each step is independently verifiable.
            No human intervention required until the money moves.
          </p>
        </motion.div>

        <div className="relative">
          {/* Connecting Line */}
          <div className="absolute top-1/2 left-0 w-full h-[2px] bg-gradient-to-r from-transparent via-white/20 to-transparent -translate-y-1/2 hidden md:block" />

          <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6 relative z-10">
            {agents.map((agent, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, y: 30 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, margin: "-50px" }}
                transition={{ duration: 0.6, delay: i * 0.15 }}
                whileHover={{ y: -10, scale: 1.02 }}
                className="group relative"
              >
                <div className="absolute inset-0 bg-gradient-to-b from-white/[0.08] to-transparent rounded-[32px] opacity-0 group-hover:opacity-100 transition-opacity duration-500 blur-xl" />
                <div className="relative h-full border border-white/10 bg-[#0a0a0a] p-8 rounded-[32px] hover:border-white/20 transition-all flex flex-col items-start gap-8 group-hover:bg-[#0c0c0c] shadow-xl group-hover:shadow-2xl">
                  <div className="w-full flex items-center justify-between">
                    <span className="text-sm font-mono text-neutral-500">{agent.id}</span>
                    <div className="w-12 h-12 rounded-full bg-white/5 border border-white/10 flex items-center justify-center text-white group-hover:bg-white group-hover:text-black group-hover:scale-110 transition-all duration-300">
                      {agent.icon}
                    </div>
                  </div>

                  <div>
                    <h3 className="text-2xl font-display tracking-tight text-white mb-3 group-hover:text-emerald-400 transition-colors">
                      {agent.name}
                    </h3>
                    <p className="text-neutral-400 leading-relaxed text-sm">
                      {agent.desc}
                    </p>
                  </div>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
