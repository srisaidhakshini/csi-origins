"use client";

import { Shield, Lock, Zap, CheckCircle2, Code2 } from "lucide-react";

const words = [
  { text: "verify", icon: <CheckCircle2 className="w-5 h-5 text-emerald-400" /> },
  { text: "negotiate", icon: <Lock className="w-5 h-5 text-emerald-400" /> },
  { text: "execute", icon: <Zap className="w-5 h-5 text-emerald-400" /> },
  { text: "audit", icon: <Code2 className="w-5 h-5 text-emerald-400" /> },
  { text: "trust", icon: <Shield className="w-5 h-5 text-emerald-400" /> },
];

export default function Marquee() {
  // Duplicate array multiple times to ensure seamless infinite scroll
  const items = [...words, ...words, ...words, ...words, ...words, ...words];

  return (
    <div className="w-full bg-[#050505] py-5 border-y border-white/10 overflow-hidden flex whitespace-nowrap">
      <div className="flex shrink-0 animate-[marquee_50s_linear_infinite] min-w-full justify-around">
        {items.map((item, i) => (
          <div key={i} className="flex items-center gap-6 mx-8">
            <span className="font-display text-xl tracking-widest text-white/80">{item.text}</span>
            {item.icon}
          </div>
        ))}
      </div>
      <div className="flex shrink-0 animate-[marquee_50s_linear_infinite] min-w-full justify-around">
        {items.map((item, i) => (
          <div key={`dup-${i}`} className="flex items-center gap-6 mx-8">
            <span className="font-display text-xl tracking-widest text-white/80">{item.text}</span>
            {item.icon}
          </div>
        ))}
      </div>
    </div>
  );
}
