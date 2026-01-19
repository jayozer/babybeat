'use client';

import { useState } from 'react';
import Link from 'next/link';
import { OnboardingModal } from '@/components/OnboardingModal';

export default function InfoPage() {
  const [showOnboarding, setShowOnboarding] = useState(false);

  return (
    <main className="min-h-screen bg-gradient-to-br from-[#fefdfb] via-[#fdf9f3] to-[#f6f9f6] pb-20">
      {/* Header */}
      <header className="bg-white/80 backdrop-blur-md border-b border-[#e8f0e8] sticky top-0 z-10">
        <div className="max-w-md mx-auto px-4 py-4 flex items-center justify-between">
          <h1
            className="text-xl font-semibold text-[#494d49]"
            style={{ fontFamily: 'Quicksand, sans-serif' }}
          >
            Information
          </h1>
          <Link
            href="/"
            className="text-[#5a8f5a] font-medium hover:text-[#477347] transition-colors"
          >
            Counter
          </Link>
        </div>
      </header>

      <div className="max-w-md mx-auto px-4 py-6 space-y-6">
        {/* How to Count */}
        <section className="bg-white/70 backdrop-blur-sm rounded-3xl shadow-[0_4px_20px_rgba(90,143,90,0.08)] p-5">
          <h2 className="text-lg font-semibold text-[#494d49] mb-3 flex items-center gap-2">
            <span>📖</span> How to Count Kicks
          </h2>
          <ol className="list-decimal list-inside space-y-2 text-[#6b736b]">
            <li>Choose a time when your baby is usually active</li>
            <li>Get comfortable - lie on your side or sit with your feet up</li>
            <li>Start the counter and tap each time you feel movement</li>
            <li>Count any kick, roll, jab, or flutter as one movement</li>
            <li>Stop when you reach 10 movements</li>
          </ol>
          <p className="mt-4 text-sm text-[#858e85]">
            Most healthcare providers recommend counting kicks starting around
            28 weeks of pregnancy.
          </p>
          <button
            type="button"
            onClick={() => setShowOnboarding(true)}
            className="
              mt-4 text-[#5a8f5a] font-medium text-sm
              hover:text-[#477347] transition-colors
            "
          >
            View full tutorial &rarr;
          </button>
        </section>

        {/* The Goal */}
        <section className="bg-white/70 backdrop-blur-sm rounded-3xl shadow-[0_4px_20px_rgba(90,143,90,0.08)] p-5">
          <h2 className="text-lg font-semibold text-[#494d49] mb-3 flex items-center gap-2">
            <span>🎯</span> The 10 in 2 Hours Goal
          </h2>
          <p className="text-[#6b736b]">
            The goal is to feel <strong className="text-[#494d49]">10 movements within 2 hours</strong>.
            Most babies will reach this goal in much less time - often within
            30 minutes.
          </p>
          <p className="mt-3 text-[#6b736b]">
            Every baby has their own pattern of activity. Get to know your
            baby&apos;s normal movement patterns.
          </p>
        </section>

        {/* When to Contact Provider */}
        <section className="bg-[#fdf9f3] border border-[#e6dcc5] rounded-3xl p-5">
          <h2 className="text-lg font-semibold text-[#8b7355] mb-3 flex items-center gap-2">
            <span>⚠️</span> When to Contact Your Provider
          </h2>
          <ul className="space-y-2 text-[#8b7355]">
            <li>
              • If you don&apos;t feel 10 movements within 2 hours
            </li>
            <li>
              • If your baby&apos;s movement pattern changes significantly
            </li>
            <li>
              • If you notice a decrease in your baby&apos;s usual activity
            </li>
            <li>
              • If you have any concerns about your baby&apos;s movements
            </li>
          </ul>
          <p className="mt-4 text-sm text-[#a58c6c]">
            Trust your instincts. If something feels different, it&apos;s
            always okay to call your healthcare provider.
          </p>
        </section>

        {/* Tips */}
        <section className="bg-white/70 backdrop-blur-sm rounded-3xl shadow-[0_4px_20px_rgba(90,143,90,0.08)] p-5">
          <h2 className="text-lg font-semibold text-[#494d49] mb-3 flex items-center gap-2">
            <span>💡</span> Tips for Encouraging Movement
          </h2>
          <ul className="space-y-2 text-[#6b736b]">
            <li>• Drink something cold or eat a snack</li>
            <li>• Lie on your left side</li>
            <li>• Gently press or jiggle your belly</li>
            <li>• Play music or talk to your baby</li>
            <li>• Take a short walk</li>
          </ul>
        </section>

        {/* Disclaimer */}
        <section className="bg-[#f6f9f6] rounded-3xl p-5">
          <h2 className="text-sm font-semibold text-[#6b736b] mb-2 flex items-center gap-2">
            <span>ℹ️</span> Disclaimer
          </h2>
          <p className="text-sm text-[#858e85]">
            This app is for educational and informational purposes only. It
            is not intended to diagnose, treat, cure, or prevent any medical
            condition. Always consult with your healthcare provider for
            medical advice and before making any health-related decisions.
          </p>
        </section>
      </div>

      {/* Onboarding modal */}
      {showOnboarding && (
        <OnboardingModal
          onComplete={() => setShowOnboarding(false)}
          isOpen={showOnboarding}
        />
      )}
    </main>
  );
}
