'use client';

import { useState } from 'react';
import { JoyfulTapPad } from './components/TapPad';
import { JoyfulCountDisplay } from './components/CountDisplay';
import { JoyfulTimerDisplay } from './components/TimerDisplay';
import { JoyfulBottomNav } from './components/BottomNav';

interface DemoSession {
  startedAt: string;
  timeLimitSec: number;
  pausedDurationSec: number;
}

export function JoyfulCounterPage() {
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
    <div className="min-h-screen bg-gradient-to-b from-[#fff5f3] via-[#fffbeb] to-[#f0fdfa]">
      {/* Decorative background shapes */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none">
        <div className="absolute -top-20 -right-20 w-64 h-64 rounded-full bg-[#ffd4cd]/30 blur-3xl" />
        <div className="absolute top-1/3 -left-20 w-48 h-48 rounded-full bg-[#fff4c6]/40 blur-2xl" />
        <div className="absolute bottom-1/4 -right-10 w-40 h-40 rounded-full bg-[#ccfbf1]/40 blur-2xl" />
      </div>

      {/* Main content */}
      <main className="relative flex flex-col items-center px-6 pt-6 pb-28">
        <div className="w-full max-w-md flex flex-col gap-6">
          {/* Header */}
          <header className="text-center animate-pop-in">
            <h1 className="text-3xl font-bold text-[#554f48] font-['Comfortaa']">
              Baby Kick Counter
            </h1>
            <p className="text-sm text-[#9a9184] mt-1 font-medium">
              Count those happy kicks!
            </p>
          </header>

          {/* Count Display */}
          <JoyfulCountDisplay currentCount={kickCount} targetCount={targetCount} />

          {/* Timer Display */}
          <JoyfulTimerDisplay
            startedAt={session.startedAt}
            timeLimitSec={session.timeLimitSec}
            isPaused={isPaused}
            pausedDurationSec={session.pausedDurationSec}
          />

          {/* Tap Pad */}
          <JoyfulTapPad onClick={handleTap} disabled={isPaused || isComplete} />

          {/* Session Controls */}
          {!isComplete && (
            <div className="flex justify-center gap-3 animate-pop-in" style={{ animationDelay: '0.2s' }}>
              <button
                type="button"
                onClick={() => setKickCount(prev => Math.max(0, prev - 1))}
                disabled={kickCount === 0}
                className="
                  px-5 py-3 rounded-2xl
                  bg-white
                  text-[#7d756a] font-semibold
                  shadow-[0_4px_12px_rgba(0,0,0,0.08)]
                  transition-all duration-200
                  hover:shadow-[0_6px_16px_rgba(0,0,0,0.12)] hover:-translate-y-0.5
                  active:translate-y-0
                  disabled:opacity-40 disabled:cursor-not-allowed disabled:hover:translate-y-0
                "
              >
                Oops! Undo
              </button>

              <button
                type="button"
                onClick={() => setIsPaused(prev => !prev)}
                className={`
                  px-5 py-3 rounded-2xl
                  font-semibold
                  transition-all duration-200
                  ${isPaused
                    ? 'bg-gradient-to-r from-[#2dd4bf] to-[#14b8a6] text-white shadow-[0_4px_16px_rgba(45,212,191,0.35)]'
                    : 'bg-white text-[#7d756a] shadow-[0_4px_12px_rgba(0,0,0,0.08)]'
                  }
                  hover:-translate-y-0.5
                  active:translate-y-0
                `}
              >
                {isPaused ? 'Keep Going!' : 'Take a Break'}
              </button>

              <button
                type="button"
                onClick={() => alert('End session')}
                className="
                  px-5 py-3 rounded-2xl
                  bg-white
                  text-[#f96d55] font-semibold
                  shadow-[0_4px_12px_rgba(0,0,0,0.08)]
                  transition-all duration-200
                  hover:shadow-[0_6px_16px_rgba(249,109,85,0.2)] hover:-translate-y-0.5
                  active:translate-y-0
                "
              >
                All Done!
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
                bg-gradient-to-r from-[#ff8c78] via-[#f96d55] to-[#e54e35]
                text-white font-bold text-lg
                shadow-[0_8px_24px_rgba(249,109,85,0.35)]
                transition-all duration-300
                hover:shadow-[0_12px_32px_rgba(249,109,85,0.45)]
                hover:-translate-y-1
                active:translate-y-0
                animate-pop-in
              "
            >
              Start Another Session!
            </button>
          )}
        </div>
      </main>

      {/* Bottom Navigation */}
      <JoyfulBottomNav />
    </div>
  );
}

export default JoyfulCounterPage;
