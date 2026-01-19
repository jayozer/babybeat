'use client';

import { useState } from 'react';
import { SereneTapPad } from './components/TapPad';
import { SereneCountDisplay } from './components/CountDisplay';
import { SereneTimerDisplay } from './components/TimerDisplay';
import { SereneBottomNav } from './components/BottomNav';

// Demo state for preview
interface DemoSession {
  startedAt: string;
  timeLimitSec: number;
  pausedDurationSec: number;
}

export function SereneCounterPage() {
  const [kickCount, setKickCount] = useState(4);
  const [isPaused, setIsPaused] = useState(false);
  const targetCount = 10;

  // Demo session data
  const [session] = useState<DemoSession>({
    startedAt: new Date(Date.now() - 15 * 60 * 1000).toISOString(), // 15 mins ago
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
    <div className="min-h-screen bg-gradient-to-br from-[#fefdfb] via-[#fdf9f3] to-[#f6f9f6]">
      {/* Main content */}
      <main className="flex flex-col items-center px-6 pt-8 pb-28">
        <div className="w-full max-w-md flex flex-col gap-8">
          {/* Header */}
          <header className="text-center animate-fade-in">
            <h1 className="text-2xl font-semibold text-[#494d49] font-['Quicksand'] tracking-wide">
              Baby Kick Counter
            </h1>
            <p className="text-sm text-[#858e85] mt-1">
              Track your baby&apos;s movements gently
            </p>
          </header>

          {/* Count Display with Progress Ring */}
          <SereneCountDisplay currentCount={kickCount} targetCount={targetCount} />

          {/* Timer Display */}
          <SereneTimerDisplay
            startedAt={session.startedAt}
            timeLimitSec={session.timeLimitSec}
            isPaused={isPaused}
            pausedDurationSec={session.pausedDurationSec}
          />

          {/* Tap Pad */}
          <SereneTapPad onClick={handleTap} disabled={isPaused || isComplete} />

          {/* Session Controls */}
          {!isComplete && (
            <div className="flex justify-center gap-4 animate-fade-in">
              <button
                type="button"
                onClick={() => setKickCount(prev => Math.max(0, prev - 1))}
                disabled={kickCount === 0}
                className="
                  px-6 py-3 rounded-2xl
                  bg-white/60 backdrop-blur-sm
                  text-[#6b736b] font-medium
                  border border-[#e2e5e2]
                  transition-all duration-200
                  hover:bg-white hover:shadow-md
                  disabled:opacity-40 disabled:cursor-not-allowed
                "
              >
                Undo
              </button>

              <button
                type="button"
                onClick={() => setIsPaused(prev => !prev)}
                className={`
                  px-6 py-3 rounded-2xl
                  font-medium
                  transition-all duration-200
                  ${isPaused
                    ? 'bg-[#a8c9a8] text-white hover:bg-[#7bab7b]'
                    : 'bg-white/60 backdrop-blur-sm text-[#6b736b] border border-[#e2e5e2] hover:bg-white hover:shadow-md'
                  }
                `}
              >
                {isPaused ? 'Resume' : 'Pause'}
              </button>

              <button
                type="button"
                onClick={() => alert('End session')}
                className="
                  px-6 py-3 rounded-2xl
                  bg-white/60 backdrop-blur-sm
                  text-[#9f8fc5] font-medium
                  border border-[#e6e1f1]
                  transition-all duration-200
                  hover:bg-[#f9f8fc] hover:shadow-md
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
                w-full py-4 rounded-2xl
                bg-gradient-to-r from-[#a8c9a8] to-[#7bab7b]
                text-white font-semibold text-lg
                shadow-[0_4px_20px_rgba(90,143,90,0.25)]
                transition-all duration-300
                hover:shadow-[0_8px_30px_rgba(90,143,90,0.35)]
                active:scale-[0.98]
              "
            >
              Start New Session
            </button>
          )}
        </div>
      </main>

      {/* Bottom Navigation */}
      <SereneBottomNav />
    </div>
  );
}

export default SereneCounterPage;
