"use client";

import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Plus, Minus } from "lucide-react";
import WavyUnderline from "./WavyUnderline";

const faqs = [
  {
    question: "how does the audit agent evaluate subjective work?",
    answer: "EscrowGuard is designed for objective, deterministic deliverables (like passing test suites, achieving latency targets, or completing specific code constraints). It's built for mathematics and logic, not \"make this logo pop\" tasks."
  },
  {
    question: "which banks and countries are supported?",
    answer: "We use the Stitch API, which supports instant payouts to all major global banking networks and localized payment rails. If Stitch supports it, so do we."
  },
  {
    question: "what if a client refuses to provide verbal consent?",
    answer: "The funds remain mathematically locked in the secure escrow contract until the Voice Agent captures and cryptographically signs dual consent, or the objective timeout period is reached (resulting in an automatic dispute flag)."
  },
  {
    question: "do i need to know how to code to use escrowguard?",
    answer: "No. While the backend executes in sandboxed CodeCrafters environments, the UI handles all the complexity. You simply link your GitHub repo or upload your deliverables."
  }
];

export default function FAQ() {
  const [openIndex, setOpenIndex] = useState<number | null>(0);

  return (
    <section className="w-full bg-black py-40 px-6 border-t border-white/5" id="faq">
      <div className="max-w-3xl mx-auto">
        <div className="text-center mb-20">
          <h2 className="text-4xl md:text-6xl font-display tracking-tight text-white relative inline-block">
            frequently asked
            <WavyUnderline />
          </h2>
        </div>

        <div className="space-y-4">
          {faqs.map((faq, i) => {
            const isOpen = openIndex === i;

            return (
              <motion.div
                key={i}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: i * 0.1 }}
                className="border border-white/10 bg-[#0a0a0a] rounded-[24px] overflow-hidden"
              >
                <button
                  onClick={() => setOpenIndex(isOpen ? null : i)}
                  className="w-full flex items-center justify-between p-6 md:p-8 text-left hover:bg-white/[0.02] transition-colors"
                >
                  <span className="text-lg md:text-xl font-display text-white">{faq.question}</span>
                  <div className="w-10 h-10 rounded-full bg-white/5 flex items-center justify-center shrink-0 ml-4">
                    {isOpen ? (
                      <Minus className="w-5 h-5 text-emerald-400" />
                    ) : (
                      <Plus className="w-5 h-5 text-white" />
                    )}
                  </div>
                </button>

                <AnimatePresence>
                  {isOpen && (
                    <motion.div
                      initial={{ height: 0, opacity: 0 }}
                      animate={{ height: "auto", opacity: 1 }}
                      exit={{ height: 0, opacity: 0 }}
                      transition={{ duration: 0.3, ease: "easeInOut" }}
                    >
                      <div className="px-6 md:px-8 pb-8 pt-0 text-neutral-400 text-lg leading-relaxed">
                        {faq.answer}
                      </div>
                    </motion.div>
                  )}
                </AnimatePresence>
              </motion.div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
