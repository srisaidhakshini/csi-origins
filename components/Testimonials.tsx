"use client";

import { motion } from "framer-motion";
import WavyUnderline from "./WavyUnderline";

const testimonials = [
  {
    quote: "EscrowGuard eliminated my anxiety around client payments completely. The code passes the tests, I get paid. Simple.",
    author: "Alex Rivera",
    role: "Freelance Senior Engineer"
  },
  {
    quote: "As an agency owner, this pipeline saves me 20 hours a week in dispute negotiations. The AI evaluates without any bias.",
    author: "Sarah Chen",
    role: "Agency Founder"
  },
  {
    quote: "The ElevenLabs voice verification is seamless. My clients love the absolute transparency before money moves.",
    author: "David Kim",
    role: "Independent Contractor"
  },
  {
    quote: "It's the first time I've felt completely protected working with overseas developers. Math doesn't lie.",
    author: "Elena Rodriguez",
    role: "Product Manager"
  }
];

export default function Testimonials() {
  const items = [...testimonials, ...testimonials];

  return (
    <section className="w-full bg-black py-32 overflow-hidden border-t border-white/5" id="testimonials">
      <div className="max-w-7xl mx-auto px-6 mb-20 text-center">
        <h2 className="text-4xl md:text-6xl font-display tracking-tight text-white relative inline-block">
          trusted by builders
          <WavyUnderline />
        </h2>
      </div>

      <div className="relative flex whitespace-nowrap group">
        <div className="flex shrink-0 animate-[marquee_40s_linear_infinite] group-hover:[animation-play-state:paused] min-w-full justify-around">
          {items.map((item, i) => (
            <div
              key={i}
              className="w-[400px] md:w-[500px] mx-4 md:mx-6 flex-shrink-0 border border-white/10 bg-[#0a0a0a] p-8 md:p-10 rounded-tl-[48px] rounded-br-[48px] rounded-tr-xl rounded-bl-xl hover:border-emerald-500/30 transition-colors whitespace-normal"
            >
              <div className="text-emerald-500 text-4xl font-display mb-4 leading-none">"</div>
              <p className="text-neutral-300 text-lg md:text-xl leading-relaxed mb-8">
                {item.quote}
              </p>
              <div>
                <p className="text-white font-medium">{item.author}</p>
                <p className="text-neutral-500 text-sm">{item.role}</p>
              </div>
            </div>
          ))}
        </div>
        <div className="flex shrink-0 animate-[marquee_40s_linear_infinite] group-hover:[animation-play-state:paused] min-w-full justify-around">
          {items.map((item, i) => (
            <div
              key={`dup-${i}`}
              className="w-[400px] md:w-[500px] mx-4 md:mx-6 flex-shrink-0 border border-white/10 bg-[#0a0a0a] p-8 md:p-10 rounded-tl-[48px] rounded-br-[48px] rounded-tr-xl rounded-bl-xl hover:border-emerald-500/30 transition-colors whitespace-normal"
            >
              <div className="text-emerald-500 text-4xl font-display mb-4 leading-none">"</div>
              <p className="text-neutral-300 text-lg md:text-xl leading-relaxed mb-8">
                {item.quote}
              </p>
              <div>
                <p className="text-white font-medium">{item.author}</p>
                <p className="text-neutral-500 text-sm">{item.role}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
