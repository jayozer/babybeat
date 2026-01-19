'use client';

import { useState, useEffect, useCallback } from 'react';

interface TimerDisplayProps {
  startedAt: string | null;
  timeLimitSec: number;
  isPaused: boolean;
  pausedDurationSec?: number;
}

function formatTime(seconds: number): { h: string; m: string; s: string } {
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const secs = Math.floor(seconds % 60);

  return {
    h: hours.toString().padStart(2, '0'),
    m: minutes.toString().padStart(2, '0'),
    s: secs.toString().padStart(2, '0'),
  };
}

export function JoyfulTimerDisplay({
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

  const elapsedTime = formatTime(elapsed);
  const remainingTime = formatTime(remaining);

  return (
    <div className="animate-pop-in">
      {/* Fun card with gradient border */}
      <div className="relative p-[3px] rounded-[2rem] bg-gradient-to-r from-[#ff8c78] via-[#ffc520] to-[#2dd4bf]">
        <div className="bg-white rounded-[calc(2rem-3px)] px-6 py-5">
          <div className="flex justify-around items-center">
            {/* Elapsed */}
            <div className="text-center">
              <p className="text-xs text-[#b5aea0] uppercase tracking-wider mb-2 font-semibold">
                Time spent
              </p>
              <div className="flex items-center gap-1">
                <TimeBlock value={elapsedTime.h} isPaused={isPaused} />
                <span className="text-xl text-[#d4cfc4] font-bold">:</span>
                <TimeBlock value={elapsedTime.m} isPaused={isPaused} />
                <span className="text-xl text-[#d4cfc4] font-bold">:</span>
                <TimeBlock value={elapsedTime.s} isPaused={isPaused} />
              </div>
            </div>

            {/* Fun divider */}
            <div className="flex flex-col items-center gap-1">
              <span className="w-2 h-2 rounded-full bg-[#ffc520]" />
              <span className="w-2 h-2 rounded-full bg-[#ff8c78]" />
              <span className="w-2 h-2 rounded-full bg-[#2dd4bf]" />
            </div>

            {/* Remaining */}
            <div className="text-center">
              <p className="text-xs text-[#b5aea0] uppercase tracking-wider mb-2 font-semibold">
                Time left
              </p>
              <div className="flex items-center gap-1">
                <TimeBlock value={remainingTime.h} isWarning={isWarning} isTimedOut={isTimedOut} />
                <span className={`text-xl font-bold ${isTimedOut ? 'text-[#2dd4bf]' : isWarning ? 'text-[#ffc520]' : 'text-[#d4cfc4]'}`}>:</span>
                <TimeBlock value={remainingTime.m} isWarning={isWarning} isTimedOut={isTimedOut} />
                <span className={`text-xl font-bold ${isTimedOut ? 'text-[#2dd4bf]' : isWarning ? 'text-[#ffc520]' : 'text-[#d4cfc4]'}`}>:</span>
                <TimeBlock value={remainingTime.s} isWarning={isWarning} isTimedOut={isTimedOut} />
              </div>
            </div>
          </div>

          {/* Status indicators */}
          {isPaused && (
            <div className="mt-4 flex items-center justify-center gap-2">
              <span className="text-2xl animate-bounce-gentle">⏸️</span>
              <span className="text-sm font-semibold text-[#ffc520]">Taking a break!</span>
            </div>
          )}
          {isTimedOut && (
            <div className="mt-4 flex items-center justify-center gap-2">
              <span className="text-2xl">⏰</span>
              <span className="text-sm font-semibold text-[#14b8a6]">Time&apos;s up!</span>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function TimeBlock({
  value,
  isPaused,
  isWarning,
  isTimedOut,
}: {
  value: string;
  isPaused?: boolean;
  isWarning?: boolean;
  isTimedOut?: boolean;
}) {
  let bgColor = 'bg-[#f3f1ed]';
  let textColor = 'text-[#554f48]';

  if (isPaused) {
    bgColor = 'bg-[#fff4c6]';
    textColor = 'text-[#dd7c02]';
  } else if (isTimedOut) {
    bgColor = 'bg-[#ccfbf1]';
    textColor = 'text-[#0d9488]';
  } else if (isWarning) {
    bgColor = 'bg-[#fff4c6]';
    textColor = 'text-[#dd7c02]';
  }

  return (
    <span
      className={`
        inline-block px-2 py-1 rounded-xl
        ${bgColor}
        ${textColor}
        text-2xl font-bold tabular-nums font-['Comfortaa']
        transition-colors duration-300
      `}
    >
      {value}
    </span>
  );
}
