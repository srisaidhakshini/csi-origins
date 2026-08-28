"use client";

const platforms = [
  "ElevenLabs",
  "Stitch",
  "CodeCrafters",
  "GitHub",
  "Vercel"
];

export default function PoweredBy() {
  return (
    <section className="w-full bg-black py-16 border-b border-white/5">
      <div className="max-w-7xl mx-auto px-6 flex flex-col items-center">
        <p className="text-neutral-500 font-mono text-sm tracking-widest uppercase mb-8">
          Powered by industry leaders
        </p>
        <div className="flex flex-wrap justify-center items-center gap-12 md:gap-24 opacity-50 hover:opacity-100 transition-opacity duration-500">
          {/* I have put their names in text here. 
              You can easily replace these <div> elements with actual <img src="..." /> or <svg> logos! */}
          {platforms.map((platform, i) => (
            <div key={i} className="text-xl md:text-2xl font-display font-bold text-white tracking-tight grayscale hover:grayscale-0 hover:text-emerald-400 transition-colors">
              {platform}
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
