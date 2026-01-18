'use client';

import { useState } from 'react';
import Link from 'next/link';
import { OnboardingModal } from '@/components/OnboardingModal';

export default function InfoPage() {
  const [showOnboarding, setShowOnboarding] = useState(false);

  return (
    <main className="min-h-screen bg-gray-50 pb-20">
      {/* Header */}
      <header className="bg-white shadow-sm">
        <div className="max-w-md mx-auto px-4 py-4 flex items-center justify-between">
          <h1 className="text-xl font-bold text-gray-800">Information</h1>
          <Link
            href="/"
            className="text-pink-500 font-medium hover:text-pink-600 transition-colors"
          >
            Counter
          </Link>
        </div>
      </header>

      <div className="max-w-md mx-auto px-4 py-6 space-y-6">
        {/* How to Count */}
        <section className="bg-white rounded-xl shadow-sm p-5">
          <h2 className="text-lg font-bold text-gray-800 mb-3 flex items-center gap-2">
            <span>📖</span> How to Count Kicks
          </h2>
          <ol className="list-decimal list-inside space-y-2 text-gray-600">
            <li>Choose a time when your baby is usually active</li>
            <li>Get comfortable - lie on your side or sit with your feet up</li>
            <li>Start the counter and tap each time you feel movement</li>
            <li>Count any kick, roll, jab, or flutter as one movement</li>
            <li>Stop when you reach 10 movements</li>
          </ol>
          <p className="mt-4 text-sm text-gray-500">
            Most healthcare providers recommend counting kicks starting around
            28 weeks of pregnancy.
          </p>
          <button
            type="button"
            onClick={() => setShowOnboarding(true)}
            className="
              mt-4 text-pink-500 font-medium text-sm
              hover:text-pink-600 transition-colors
            "
          >
            View full tutorial &rarr;
          </button>
        </section>

        {/* The Goal */}
        <section className="bg-white rounded-xl shadow-sm p-5">
          <h2 className="text-lg font-bold text-gray-800 mb-3 flex items-center gap-2">
            <span>🎯</span> The 10 in 2 Hours Goal
          </h2>
          <p className="text-gray-600">
            The goal is to feel <strong>10 movements within 2 hours</strong>.
            Most babies will reach this goal in much less time - often within
            30 minutes.
          </p>
          <p className="mt-3 text-gray-600">
            Every baby has their own pattern of activity. Get to know your
            baby&apos;s normal movement patterns.
          </p>
        </section>

        {/* When to Contact Provider */}
        <section className="bg-orange-50 border border-orange-200 rounded-xl p-5">
          <h2 className="text-lg font-bold text-orange-800 mb-3 flex items-center gap-2">
            <span>⚠️</span> When to Contact Your Provider
          </h2>
          <ul className="space-y-2 text-orange-700">
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
          <p className="mt-4 text-sm text-orange-600">
            Trust your instincts. If something feels different, it&apos;s
            always okay to call your healthcare provider.
          </p>
        </section>

        {/* Tips */}
        <section className="bg-white rounded-xl shadow-sm p-5">
          <h2 className="text-lg font-bold text-gray-800 mb-3 flex items-center gap-2">
            <span>💡</span> Tips for Encouraging Movement
          </h2>
          <ul className="space-y-2 text-gray-600">
            <li>• Drink something cold or eat a snack</li>
            <li>• Lie on your left side</li>
            <li>• Gently press or jiggle your belly</li>
            <li>• Play music or talk to your baby</li>
            <li>• Take a short walk</li>
          </ul>
        </section>

        {/* Disclaimer */}
        <section className="bg-gray-100 rounded-xl p-5">
          <h2 className="text-sm font-bold text-gray-600 mb-2 flex items-center gap-2">
            <span>ℹ️</span> Disclaimer
          </h2>
          <p className="text-sm text-gray-500">
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
