"use client";

import { motion } from "framer-motion";
import { ArrowUpRight } from "lucide-react";
import WavyUnderline from "./WavyUnderline";

export default function CTA() {
  return (
    <section className="w-full bg-black py-40 px-6 relative overflow-hidden">
      {/* Background glow */}
      <div className="absolute inset-0 bg-emerald-500/5 blur-[120px] rounded-full scale-150 transform translate-y-1/2 pointer-events-none" />

      <div className="max-w-4xl mx-auto text-center relative z-10">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.8 }}
          className="space-y-12"
        >
          <h2 className="text-6xl md:text-8xl lg:text-9xl font-display tracking-tighter text-white relative inline-block">
            ready to build?
            <WavyUnderline className="h-6 md:h-10 -bottom-3 md:-bottom-5" />
          </h2>

          <p className="text-xl md:text-2xl text-neutral-400 max-w-2xl mx-auto">
            Stop arguing over milestones. Let the agentic pipeline verify, negotiate, and execute your payouts instantly.
          </p>

          <div className="flex flex-col sm:flex-row items-center justify-center gap-6 pt-8">
            <motion.button
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              className="w-full sm:w-auto group relative flex items-center justify-center gap-2 bg-emerald-500 text-black px-10 py-5 rounded-full font-medium text-lg overflow-hidden"
            >
              <span className="relative z-10 flex items-center gap-2">
                Deploy Your Agent <ArrowUpRight className="w-6 h-6 group-hover:translate-x-1 group-hover:-translate-y-1 transition-transform" />
              </span>
              <div className="absolute inset-0 bg-emerald-400 translate-y-[100%] group-hover:translate-y-0 transition-transform duration-300 ease-in-out" />
            </motion.button>

            <motion.button
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              className="w-full sm:w-auto flex items-center justify-center gap-2 bg-white/5 backdrop-blur-md px-10 py-5 rounded-full font-medium text-lg text-white border border-white/10 hover:bg-white/10 transition-colors"
            >
              Contact Sales
            </motion.button>
          </div>
        </motion.div>
      </div>
    </section>
  );
}
