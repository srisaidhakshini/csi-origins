"use client";

import { motion } from "framer-motion";
import { FileCode2, Clock, Scale, Bot, Users, CreditCard } from "lucide-react";
import WavyUnderline from "./WavyUnderline";

const problemItems = [
  {
    title: "who & how often",
    desc: "Freelancers and clients on every paid project — at each milestone hand-off.",
    icon: <Users className="w-6 h-6" />
  },
  {
    title: "today's workaround",
    desc: "Manual review and back-and-forth negotiation before either side agrees to release or accept payment.",
    icon: <Clock className="w-6 h-6" />
  },
  {
    title: "why it falls short",
    desc: "It's slow and subjective. Freelancers risk non-payment, and clients risk paying for unfinished or bad work.",
    icon: <Scale className="w-6 h-6" />
  }
];

const solutionItems = [
  {
    title: "the evidence",
    desc: "60%+ of freelancers report late or non-payment, and over 50% of contracts face scope-creep disputes.",
    icon: <FileCode2 className="w-6 h-6" />
  },
  {
    title: "our advantage",
    desc: "EscrowGuard replaces trust with cryptography. Code is evaluated objectively in sandboxes, and payments route automatically.",
    icon: <Bot className="w-6 h-6" />
  },
  {
    title: "the outcome",
    desc: "Zero disputes. Instant payouts via Stitch. Both parties proceed with absolute mathematical certainty.",
    icon: <CreditCard className="w-6 h-6" />
  }
];

export default function ProblemSolution() {
  return (
    <section className="w-full bg-black py-40 px-6">
      <div className="max-w-7xl mx-auto space-y-48">

        {/* Problem - Horizontal Timeline */}
        <div className="space-y-24" id="problem">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            className="text-center space-y-4"
          >
            <h2 className="text-4xl md:text-6xl font-display tracking-tight text-white relative inline-block">
              the problem
              <WavyUnderline className="text-rose-500/70" />
            </h2>
            <p className="text-neutral-400 text-lg max-w-2xl mx-auto mt-6">
              Freelancer and client money problems plague every milestone handoff.
            </p>
          </motion.div>

          <div className="relative">
            {/* Connecting Line */}
            <div className="absolute top-[32px] left-0 w-full h-[1px] bg-white/10 hidden md:block" />

            <div className="grid grid-cols-1 md:grid-cols-3 gap-12 md:gap-8 relative z-10">
              {problemItems.map((item, i) => (
                <motion.div
                  key={i}
                  initial={{ opacity: 0, y: 20 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true, margin: "-50px" }}
                  transition={{ duration: 0.5, delay: i * 0.15 }}
                  className="flex flex-col items-center text-center group bg-black py-0"
                >
                  <div className="w-16 h-16 rounded-full bg-[#0a0a0a] border border-white/10 flex items-center justify-center text-white mb-8 group-hover:bg-white group-hover:text-black group-hover:scale-110 transition-all duration-300">
                    <span className="font-display font-medium text-xl">0{i + 1}</span>
                  </div>
                  <h3 className="text-2xl font-display tracking-tight text-white mb-3">{item.title}</h3>
                  <p className="text-neutral-400 text-base leading-relaxed max-w-xs">{item.desc}</p>
                </motion.div>
              ))}
            </div>
          </div>
        </div>

        {/* Solution - Stacking Curved Cards */}
        <div className="flex flex-col lg:flex-row-reverse gap-12 lg:gap-24 items-start relative" id="solution">
          {/* Sticky Right Content */}
          <div className="lg:sticky lg:top-40 w-full lg:w-1/3 space-y-6">
            <motion.div
              initial={{ opacity: 0, x: 20 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true }}
            >
              <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-500/10 text-emerald-400 text-sm font-medium border border-emerald-500/20 mb-6">
                EscrowGuard
              </div>
              <h2 className="text-4xl md:text-6xl font-display tracking-tight text-white relative inline-block">
                our solution
                <WavyUnderline />
              </h2>
              <p className="text-neutral-400 text-lg mt-6">
                An autonomous agent pipeline that verifies, negotiates, and executes without bias.
              </p>
            </motion.div>
          </div>

          {/* Clean List Left */}
          <div className="w-full lg:w-2/3 flex flex-col">
            {solutionItems.map((item, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, margin: "-50px" }}
                transition={{ duration: 0.5, delay: i * 0.1 }}
                className="py-12 border-t border-white/10 flex flex-col md:flex-row gap-8 items-start first:border-t-0 first:pt-4 group"
              >
                <div className="bg-emerald-500/10 p-4 rounded-2xl shrink-0 text-emerald-400 group-hover:scale-110 transition-transform duration-300">
                  {item.icon}
                </div>
                <div>
                  <h3 className="text-2xl font-display tracking-tight text-white mb-3">{item.title}</h3>
                  <p className="text-neutral-400 text-lg leading-relaxed max-w-xl">{item.desc}</p>
                </div>
              </motion.div>
            ))}
          </div>
        </div>

      </div>
    </section>
  );
}
