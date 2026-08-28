"use client";

import { motion } from "framer-motion";

export default function Metrics() {
  return (
    <section className="w-full bg-black py-32 px-6 border-t border-white/5">
      <div className="max-w-7xl mx-auto">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-12 lg:gap-24 relative z-10">
          
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.8 }}
            className="flex flex-col items-center justify-center text-center space-y-6 group"
          >
            <h2 className="text-7xl md:text-9xl font-display tracking-tighter text-white group-hover:scale-105 transition-transform duration-500">
              90%
            </h2>
            <div className="space-y-4 flex flex-col items-center">
              <h3 className="text-2xl font-display tracking-tight text-emerald-400">
                reduction in resolution time
              </h3>
              <p className="text-neutral-400 text-lg leading-relaxed max-w-md">
                From 5+ days down to under 10 minutes. Based on timing a manual client-freelancer review cycle (avg 120 hours) versus EscrowGuard's automated workflow (avg 6 minutes).
              </p>
            </div>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.8, delay: 0.2 }}
            className="flex flex-col items-center justify-center text-center space-y-6 group"
          >
            <h2 className="text-7xl md:text-9xl font-display tracking-tighter text-white group-hover:scale-105 transition-transform duration-500">
              <span className="text-4xl md:text-6xl text-neutral-500">~$</span>0.05
            </h2>
            <div className="space-y-4 flex flex-col items-center">
              <h3 className="text-2xl font-display tracking-tight text-neutral-200">
                running cost per milestone
              </h3>
              <p className="text-neutral-400 text-lg leading-relaxed max-w-md">
                API costs across ElevenLabs streaming voice, Stitch bank transaction fees, and LLM inference hosted on Vercel infrastructure.
              </p>
            </div>
          </motion.div>

        </div>
      </div>
    </section>
  );
}
