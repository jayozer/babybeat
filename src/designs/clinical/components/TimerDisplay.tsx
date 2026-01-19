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

function formatTimeShort(seconds: number): string {
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);

  if (hours > 0) {
    return `${hours}h ${minutes}m`;
  }
  return `${minutes}m`;
}

export function ClinicalTimerDisplay({
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
  const timeProgress = (elapsed / timeLimitSec) * 100;

  return (
    <div className="animate-slide-up" style={{ animationDelay: '0.1s' }}>
      {/* Timer card */}
      <div className="bg-white border border-[#e2e8f0] rounded-lg shadow-[0_1px_3px_rgba(16,42,67,0.05)] overflow-hidden">
        {/* Header */}
        <div className="px-5 py-3 bg-[#f7f9fc] border-b border-[#e2e8f0] flex items-center justify-between">
          <span className="text-xs font-semibold text-[#627d98] uppercase tracking-wider">
            Session Timer
          </span>
          <div className="flex items-center gap-2">
            {isPaused ? (
              <span className="flex items-center gap-1.5 text-xs font-medium text-[#f0b429]">
                <span className="w-1.5 h-1.5 rounded-full bg-[#f0b429] animate-status-blink" />
                PAUSED
              </span>
            ) : isTimedOut ? (
              <span className="flex items-center gap-1.5 text-xs font-medium text-[#e12d39]">
                <span className="w-1.5 h-1.5 rounded-full bg-[#e12d39]" />
                TIMEOUT
              </span>
            ) : (
              <span className="flex items-center gap-1.5 text-xs font-medium text-[#27ab83]">
                <span className="w-1.5 h-1.5 rounded-full bg-[#27ab83] animate-minimal-pulse" />
                RUNNING
              </span>
            )}
          </div>
        </div>

        {/* Time displays */}
        <div className="px-5 py-5">
          <div className="grid grid-cols-2 gap-6">
            {/* Elapsed */}
            <div>
              <p className="text-xs text-[#718096] font-medium mb-1">Elapsed</p>
              <p
                className={`
                  text-3xl font-mono font-semibold tabular-nums
                  ${isPaused ? 'text-[#f0b429]' : 'text-[#102a43]'}
                `}
              >
                {formatTime(elapsed)}
              </p>
            </div>

            {/* Remaining */}
            <div>
              <p className="text-xs text-[#718096] font-medium mb-1">Remaining</p>
              <p
                className={`
                  text-3xl font-mono font-semibold tabular-nums
                  ${isTimedOut ? 'text-[#e12d39]' : isWarning ? 'text-[#f0b429]' : 'text-[#102a43]'}
                `}
              >
                {formatTime(remaining)}
              </p>
            </div>
          </div>

          {/* Timeline progress */}
          <div className="mt-5">
            <div className="relative h-1.5 bg-[#edf2f7] rounded overflow-hidden">
              <div
                className={`
                  absolute left-0 top-0 h-full rounded transition-all duration-1000 ease-linear
                  ${isTimedOut
                    ? 'bg-[#e12d39]'
                    : isWarning
                      ? 'bg-[#f0b429]'
                      : 'bg-[#0077e6]'
                  }
                `}
                style={{ width: `${Math.min(timeProgress, 100)}%` }}
              />
            </div>
            <div className="flex justify-between mt-2 text-xs text-[#a0aec0]">
              <span>0:00</span>
              <span className="font-medium text-[#627d98]">
                {formatTimeShort(timeLimitSec / 2)}
              </span>
              <span>{formatTimeShort(timeLimitSec)}</span>
            </div>
          </div>
        </div>

        {/* Quick stats */}
        <div className="px-5 py-3 bg-[#f7f9fc] border-t border-[#e2e8f0] flex items-center justify-between text-xs">
          <span className="text-[#718096]">
            Time limit: <span className="font-semibold text-[#4a5568]">{formatTimeShort(timeLimitSec)}</span>
          </span>
          <span className="text-[#718096]">
            Used: <span className="font-semibold text-[#4a5568]">{timeProgress.toFixed(1)}%</span>
          </span>
        </div>
      </div>
    </div>
  );
}
