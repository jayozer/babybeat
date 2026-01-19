'use client';

import { useState, useEffect, useCallback } from 'react';

interface TimerDisplayProps {
  startedAt: string | null;
  timeLimitSec: number;
  isPaused: boolean;
  pausedDurationSec?: number;
}

function formatTime(seconds: number): string {
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const secs = Math.floor(seconds % 60);

  if (hours > 0) {
    return `${hours}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }
  return `${minutes}:${secs.toString().padStart(2, '0')}`;
}

export function SereneTimerDisplay({
  startedAt,
  timeLimitSec,
  isPaused,
  pausedDurationSec = 0,
}: TimerDisplayProps) {
  const [elapsed, setElapsed] = useState(0);

  const calculateElapsed = useCallback(() => {
    if (!startedAt) return 0;

    const startTime = new Date(startedAt).getTime();
    const now = Date.now();
    const totalElapsed = (now - startTime) / 1000;

    return Math.max(0, totalElapsed - pausedDurationSec);
  }, [startedAt, pausedDurationSec]);

  useEffect(() => {
    if (!startedAt || isPaused) {
      setElapsed(calculateElapsed());
      return;
    }

    setElapsed(calculateElapsed());

    const interval = setInterval(() => {
      setElapsed(calculateElapsed());
    }, 1000);

    return () => clearInterval(interval);
  }, [startedAt, isPaused, calculateElapsed]);

  const remaining = Math.max(0, timeLimitSec - elapsed);
  const isTimedOut = remaining <= 0 && startedAt !== null;
  const isWarning = remaining > 0 && remaining <= 600;

  return (
    <div className="animate-fade-in">
      {/* Card container */}
      <div className="bg-white/60 backdrop-blur-sm rounded-3xl px-8 py-6 shadow-[0_4px_20px_rgba(90,143,90,0.08)]">
        <div className="flex justify-between items-center gap-8">
          {/* Elapsed */}
          <div className="flex-1 text-center">
            <p className="text-xs text-[#858e85] uppercase tracking-widest mb-2 font-medium">
              Elapsed
            </p>
            <p
              className={`
                text-3xl font-semibold tabular-nums font-['Quicksand']
                ${isPaused ? 'text-[#e4cb9a]' : 'text-[#494d49]'}
              `}
            >
              {formatTime(elapsed)}
            </p>
          </div>

          {/* Divider */}
          <div className="w-px h-12 bg-gradient-to-b from-transparent via-[#d1e2d1] to-transparent" />

          {/* Remaining */}
          <div className="flex-1 text-center">
            <p className="text-xs text-[#858e85] uppercase tracking-widest mb-2 font-medium">
              Remaining
            </p>
            <p
              className={`
                text-3xl font-semibold tabular-nums font-['Quicksand']
                transition-colors duration-300
                ${isTimedOut ? 'text-[#9f8fc5]' : isWarning ? 'text-[#e4cb9a]' : 'text-[#494d49]'}
              `}
            >
              {formatTime(remaining)}
            </p>
          </div>
        </div>

        {/* Status indicators */}
        {isPaused && (
          <div className="mt-4 flex items-center justify-center gap-2 text-[#d4b576]">
            <span className="w-2 h-2 rounded-full bg-[#e4cb9a] animate-pulse" />
            <span className="text-sm font-medium">Session paused</span>
          </div>
        )}
        {isTimedOut && (
          <div className="mt-4 flex items-center justify-center gap-2 text-[#9f8fc5]">
            <span className="w-2 h-2 rounded-full bg-[#b9aed6]" />
            <span className="text-sm font-medium">Time limit reached</span>
          </div>
        )}
      </div>
    </div>
  );
}
