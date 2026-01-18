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

  return `${hours.toString().padStart(2, '0')}:${minutes
    .toString()
    .padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
}

export function TimerDisplay({
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

    // Update immediately
    setElapsed(calculateElapsed());

    // Update every second
    const interval = setInterval(() => {
      setElapsed(calculateElapsed());
    }, 1000);

    return () => clearInterval(interval);
  }, [startedAt, isPaused, calculateElapsed]);

  const remaining = Math.max(0, timeLimitSec - elapsed);
  const isTimedOut = remaining <= 0 && startedAt !== null;
  const isWarning = remaining > 0 && remaining <= 600; // Last 10 minutes

  return (
    <div className="text-center space-y-4">
      {/* Elapsed time */}
      <div>
        <p className="text-sm text-gray-500 uppercase tracking-wide mb-1">
          Elapsed
        </p>
        <p
          className={`
            text-4xl font-mono font-bold tabular-nums
            ${isPaused ? 'text-yellow-600' : 'text-gray-800'}
          `}
        >
          {formatTime(elapsed)}
        </p>
      </div>

      {/* Remaining time */}
      <div>
        <p className="text-sm text-gray-500 uppercase tracking-wide mb-1">
          Remaining
        </p>
        <p
          className={`
            text-4xl font-mono font-bold tabular-nums
            ${isTimedOut ? 'text-red-600' : isWarning ? 'text-orange-500' : 'text-gray-800'}
          `}
        >
          {formatTime(remaining)}
        </p>
      </div>

      {/* Status indicators */}
      {isPaused && (
        <p className="text-yellow-600 font-medium animate-pulse">
          ⏸ Paused
        </p>
      )}
      {isTimedOut && (
        <p className="text-red-600 font-medium">
          ⏰ Time limit reached
        </p>
      )}
    </div>
  );
}
