import Navbar from "@/components/Navbar";
import Hero from "@/components/Hero";
import Marquee from "@/components/Marquee";
import PoweredBy from "@/components/PoweredBy";
import ProblemSolution from "@/components/ProblemSolution";
import Architecture from "@/components/Architecture";
import Metrics from "@/components/Metrics";
import Testimonials from "@/components/Testimonials";
import FAQ from "@/components/FAQ";
import CTA from "@/components/CTA";
import Footer from "@/components/Footer";

export default function Home() {
  return (
    <main className="flex min-h-screen flex-col bg-black">
      <Navbar />
      <Hero />
      <Marquee />
      <PoweredBy />
      <ProblemSolution />
      <Architecture />
      <Metrics />
      <Testimonials />
      <FAQ />
      <CTA />
      <Footer />
    </main>
  );
}
