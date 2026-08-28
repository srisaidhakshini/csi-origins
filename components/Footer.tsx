export default function Footer() {
  return (
    <footer className="w-full bg-black pt-32 pb-8 px-6 border-t border-white/5 flex flex-col items-center justify-center overflow-hidden">
      <div className="w-full max-w-7xl mx-auto flex flex-col md:flex-row justify-between items-end mb-24 gap-8">
        <div className="space-y-4">
          <p className="text-white font-display text-xl tracking-tight">EscrowGuard</p>
          <p className="text-neutral-500 max-w-xs">
            An autonomous milestone & escrow agent.
            Origins 2026 Hackathon.
          </p>
        </div>
        <div className="flex flex-wrap gap-12 lg:gap-24 text-sm text-neutral-400">
          <div className="flex flex-col gap-3">
            <span className="text-white font-medium mb-1">Product</span>
            <a href="#problem" className="hover:text-white transition-colors">the problem</a>
            <a href="#solution" className="hover:text-white transition-colors">our solution</a>
            <a href="#architecture" className="hover:text-white transition-colors">pipeline</a>
            <a href="#testimonials" className="hover:text-white transition-colors">testimonials</a>
            <a href="#faq" className="hover:text-white transition-colors">faq</a>
          </div>
          <div className="flex flex-col gap-3">
            <span className="text-white font-medium mb-1">Team</span>
            <a href="#" className="hover:text-white transition-colors">Avanthika P</a>
            <a href="#" className="hover:text-white transition-colors">Gowreesh V T</a>
            <a href="#" className="hover:text-white transition-colors">Prodosh</a>
            <a href="#" className="hover:text-white transition-colors">Sri Saidhakshini</a>
          </div>
          <div className="flex flex-col gap-3">
            <span className="text-white font-medium mb-1">Links</span>
            <a href="#" className="hover:text-white transition-colors">GitHub</a>
            <a href="#" className="hover:text-white transition-colors">Docs</a>
            <a href="#" className="hover:text-white transition-colors">Pitch Deck</a>
          </div>
        </div>
      </div>
      
      <div className="w-full text-center">
        <h1 className="text-[12vw] font-display tracking-tighter text-white/5 leading-none select-none">
          escrowguard
        </h1>
      </div>
      
      <div className="w-full max-w-7xl mx-auto flex justify-between items-center pt-8 border-t border-white/5 mt-8 text-xs text-neutral-600">
        <span>© 2026 Cyber Catalysts</span>
        <span>CSI-VITC Origins Hackathon</span>
      </div>
    </footer>
  );
}
