"use client";

import { motion } from "framer-motion";
import { ArrowUpRight, ShieldCheck } from "lucide-react";
import WavyUnderline from "./WavyUnderline";

export default function Hero() {
  return (
    <section className="relative min-h-screen flex items-center justify-center overflow-hidden w-full">
      {/* Background Video - No overlays for maximum clarity */}
      <div className="absolute inset-0 z-0 bg-black">
        <video
          src="/hero-section.mp4"
          autoPlay
          loop
          muted
          playsInline
          className="object-cover w-full h-full opacity-100"
        />
      </div>

      <div className="relative z-10 flex flex-col items-center justify-center text-center px-4 max-w-5xl mx-auto mt-20">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, ease: "easeOut" }}
          className="flex items-center gap-2 px-3 py-1.5 rounded-full border border-white/10 bg-black/40 backdrop-blur-md mb-8"
        >
          <ShieldCheck className="w-4 h-4 text-emerald-400" />
          <span className="text-sm text-neutral-200 font-medium">Autonomous Milestone & Escrow Agent</span>
        </motion.div>

        <motion.h1
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, ease: "easeOut", delay: 0.1 }}
          className="text-6xl md:text-8xl lg:text-[110px] leading-[0.95] tracking-tight font-display mb-8 drop-shadow-2xl"
        >
          trust <span className="text-neutral-400">coded in,</span><br />
          payments <span className="relative text-neutral-400 inline-block">
            released.
            <WavyUnderline animate />
          </span>
        </motion.h1>

        <motion.p
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, ease: "easeOut", delay: 0.2 }}
          className="text-lg md:text-xl text-neutral-300 max-w-2xl font-sans mb-12 drop-shadow-lg"
        >
          An autonomous pipeline that verifies work, agrees payout with both sides, and releases the payment. No human delays. Zero subjectivity.
        </motion.p>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, ease: "easeOut", delay: 0.3 }}
          className="flex items-center gap-4"
        >
          <motion.button 
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            className="group relative flex items-center gap-2 bg-white text-black px-8 py-4 rounded-full font-medium text-base overflow-hidden"
          >
            <span className="relative z-10 flex items-center gap-2">
              Deploy Agent <ArrowUpRight className="w-5 h-5 group-hover:translate-x-1 group-hover:-translate-y-1 transition-transform" />
            </span>
            <div className="absolute inset-0 bg-neutral-200 translate-y-[100%] group-hover:translate-y-0 transition-transform duration-300 ease-in-out" />
          </motion.button>
          
          <motion.button 
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            className="flex items-center gap-2 bg-black/40 backdrop-blur-md px-8 py-4 rounded-full font-medium text-base text-white border border-white/20 hover:bg-white/10 transition-colors"
          >
            Read Docs <ArrowUpRight className="w-5 h-5" />
          </motion.button>
        </motion.div>
      </div>
    </section>
  );
}
