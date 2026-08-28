import Navbar from "@/components/Navbar";
import Hero from "@/components/Hero";
import Marquee from "@/components/Marquee";
import PoweredBy from "@/components/PoweredBy";
import ProblemSolution from "@/components/ProblemSolution";
import Comparison from "@/components/Comparison";
import Architecture from "@/components/Architecture";
import Metrics from "@/components/Metrics";
import Testimonials from "@/components/Testimonials";
import FAQ from "@/components/FAQ";
import CTA from "@/components/CTA";
import Footer from "@/components/Footer";

export default function Home() {
  return (
    <main className="flex min-h-screen flex-col bg-black selection:bg-emerald-500/30 selection:text-emerald-200">
      <Navbar />
      <Hero />
      <Marquee />
      <PoweredBy />
      <ProblemSolution />
      <Comparison />
      <Architecture />
      <Metrics />
      <Testimonials />
      <FAQ />
      <CTA />
      <Footer />
    </main>
  );
}
