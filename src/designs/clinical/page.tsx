'use client';

import { useState } from 'react';
import { ClinicalTapPad } from './components/TapPad';
import { ClinicalCountDisplay } from './components/CountDisplay';
import { ClinicalTimerDisplay } from './components/TimerDisplay';
import { ClinicalBottomNav } from './components/BottomNav';

interface DemoSession {
  startedAt: string;
  timeLimitSec: number;
  pausedDurationSec: number;
}

export function ClinicalCounterPage() {
  const [kickCount, setKickCount] = useState(4);
  const [isPaused, setIsPaused] = useState(false);
  const targetCount = 10;

  const [session] = useState<DemoSession>({
    startedAt: new Date(Date.now() - 15 * 60 * 1000).toISOString(),
    timeLimitSec: 7200,
    pausedDurationSec: 0,
  });

  const handleTap = () => {
    if (!isPaused && kickCount < targetCount) {
      setKickCount(prev => prev + 1);
    }
  };

  const isComplete = kickCount >= targetCount;

  return (
    <div className="min-h-screen bg-[#f7f9fc]">
      {/* Header */}
      <header className="bg-white border-b border-[#e2e8f0] sticky top-0 z-10">
        <div className="max-w-md mx-auto px-5 py-4 flex items-center justify-between">
          <div>
            <h1 className="text-lg font-semibold text-[#102a43]">
              Kick Counter
            </h1>
            <p className="text-xs text-[#718096]">
              Fetal Movement Tracker
            </p>
          </div>
          <div className="flex items-center gap-3">
            <span className="text-xs text-[#718096] font-mono">
              v1.0.0
            </span>
          </div>
        </div>
      </header>

      {/* Main content */}
      <main className="max-w-md mx-auto px-5 py-6 pb-28 space-y-5">
        {/* Count Display */}
        <ClinicalCountDisplay currentCount={kickCount} targetCount={targetCount} />

        {/* Timer Display */}
        <ClinicalTimerDisplay
          startedAt={session.startedAt}
          timeLimitSec={session.timeLimitSec}
          isPaused={isPaused}
          pausedDurationSec={session.pausedDurationSec}
        />

        {/* Tap Pad */}
        <ClinicalTapPad onClick={handleTap} disabled={isPaused || isComplete} />

        {/* Session Controls */}
        {!isComplete && (
          <div className="grid grid-cols-3 gap-3 animate-slide-up" style={{ animationDelay: '0.2s' }}>
            <button
              type="button"
              onClick={() => setKickCount(prev => Math.max(0, prev - 1))}
              disabled={kickCount === 0}
              className="
                px-4 py-3 rounded-lg
                bg-white border border-[#e2e8f0]
                text-[#4a5568] font-medium text-sm
                shadow-[0_1px_2px_rgba(16,42,67,0.05)]
                transition-all duration-150
                hover:border-[#cbd5e0] hover:shadow-[0_2px_4px_rgba(16,42,67,0.08)]
                focus:outline-none focus-visible:ring-2 focus-visible:ring-[#27ab83]
                disabled:opacity-40 disabled:cursor-not-allowed
              "
            >
              Undo
            </button>

            <button
              type="button"
              onClick={() => setIsPaused(prev => !prev)}
              className={`
                px-4 py-3 rounded-lg
                font-medium text-sm
                transition-all duration-150
                focus:outline-none focus-visible:ring-2 focus-visible:ring-[#27ab83]
                ${isPaused
                  ? 'bg-[#27ab83] text-white hover:bg-[#199473]'
                  : 'bg-white border border-[#e2e8f0] text-[#4a5568] shadow-[0_1px_2px_rgba(16,42,67,0.05)] hover:border-[#cbd5e0]'
                }
              `}
            >
              {isPaused ? 'Resume' : 'Pause'}
            </button>

            <button
              type="button"
              onClick={() => alert('End session')}
              className="
                px-4 py-3 rounded-lg
                bg-white border border-[#e2e8f0]
                text-[#e12d39] font-medium text-sm
                shadow-[0_1px_2px_rgba(16,42,67,0.05)]
                transition-all duration-150
                hover:border-[#e12d39]/30 hover:bg-[#fff5f5]
                focus:outline-none focus-visible:ring-2 focus-visible:ring-[#e12d39]
              "
            >
              End
            </button>
          </div>
        )}

        {/* Completion state */}
        {isComplete && (
          <button
            type="button"
            onClick={() => setKickCount(0)}
            className="
              w-full py-3.5 rounded-lg
              bg-[#102a43] text-white
              font-semibold text-sm
              shadow-[0_4px_12px_rgba(16,42,67,0.2)]
              transition-all duration-150
              hover:bg-[#243b53] hover:shadow-[0_6px_16px_rgba(16,42,67,0.25)]
              focus:outline-none focus-visible:ring-2 focus-visible:ring-[#27ab83] focus-visible:ring-offset-2
              animate-slide-up
            "
          >
            Start New Session
          </button>
        )}

        {/* Help text */}
        <p className="text-center text-xs text-[#a0aec0] mt-6">
          Tap the button above each time you feel your baby move.
          <br />
          Goal: {targetCount} movements within 2 hours.
        </p>
      </main>

      {/* Bottom Navigation */}
      <ClinicalBottomNav />
    </div>
  );
}

export default ClinicalCounterPage;
