'use client';

import { useEffect, useRef, useState } from 'react';

interface CountDisplayProps {
  currentCount: number;
  targetCount: number;
}

export function ClinicalCountDisplay({ currentCount, targetCount }: CountDisplayProps) {
  const isComplete = currentCount >= targetCount;
  const progress = Math.min((currentCount / targetCount) * 100, 100);
  const [animateCount, setAnimateCount] = useState(false);
  const prevCountRef = useRef(currentCount);

  useEffect(() => {
    if (currentCount !== prevCountRef.current) {
      setAnimateCount(true);
      setTimeout(() => setAnimateCount(false), 200);
      prevCountRef.current = currentCount;
    }
  }, [currentCount]);

  return (
    <div
      className="animate-slide-up"
      aria-live="polite"
      aria-atomic="true"
    >
      {/* Main data card */}
      <div className="bg-white border border-[#e2e8f0] rounded-lg shadow-[0_1px_3px_rgba(16,42,67,0.05)] overflow-hidden">
        {/* Header */}
        <div className="px-5 py-3 bg-[#f7f9fc] border-b border-[#e2e8f0] flex items-center justify-between">
          <span className="text-xs font-semibold text-[#627d98] uppercase tracking-wider">
            Movement Count
          </span>
          <span className={`
            px-2 py-0.5 rounded text-xs font-semibold
            ${isComplete
              ? 'bg-[#c6f7e2] text-[#147d64]'
              : 'bg-[#e6f6ff] text-[#0077e6]'
            }
          `}>
            {isComplete ? 'TARGET MET' : 'IN PROGRESS'}
          </span>
        </div>

        {/* Count display */}
        <div className="px-5 py-8">
          <div className="flex items-baseline gap-4 justify-center">
            <span
              className={`
                text-7xl font-bold tabular-nums font-['Inter']
                tracking-tight
                transition-all duration-150
                ${isComplete ? 'text-[#147d64]' : 'text-[#102a43]'}
                ${animateCount && 'animate-count-up'}
              `}
            >
              {currentCount}
            </span>
            <span className="text-2xl text-[#a0aec0] font-medium">
              / {targetCount}
            </span>
          </div>

          {/* Progress bar */}
          <div className="mt-6">
            <div className="flex justify-between text-xs text-[#718096] mb-2">
              <span>Progress</span>
              <span className="font-mono font-medium">{progress.toFixed(0)}%</span>
            </div>
            <div className="h-2 bg-[#edf2f7] rounded overflow-hidden">
              <div
                className={`
                  h-full rounded transition-all duration-300 ease-out
                  ${isComplete
                    ? 'bg-gradient-to-r from-[#27ab83] to-[#3ebd93]'
                    : 'bg-gradient-to-r from-[#0077e6] to-[#4db5ff]'
                  }
                `}
                style={{ width: `${progress}%` }}
              />
            </div>
          </div>
        </div>

        {/* Footer stats */}
        <div className="px-5 py-3 bg-[#f7f9fc] border-t border-[#e2e8f0] flex justify-between">
          <div className="text-center">
            <span className="block text-lg font-semibold text-[#243b53]">
              {targetCount - currentCount}
            </span>
            <span className="text-xs text-[#718096]">Remaining</span>
          </div>
          <div className="text-center">
            <span className="block text-lg font-semibold text-[#243b53]">
              {((currentCount / targetCount) * 100).toFixed(0)}%
            </span>
            <span className="text-xs text-[#718096]">Complete</span>
          </div>
          <div className="text-center">
            <span className="block text-lg font-semibold text-[#243b53]">
              {targetCount}
            </span>
            <span className="text-xs text-[#718096]">Target</span>
          </div>
        </div>
      </div>

      {/* Status message */}
      {isComplete && (
        <div className="mt-4 p-4 bg-[#effcf6] border border-[#8eedc7] rounded-lg flex items-center gap-3 animate-slide-up">
          <div className="w-10 h-10 rounded-full bg-[#27ab83] flex items-center justify-center flex-shrink-0">
            <svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M5 10L8.5 13.5L15 7" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
          </div>
          <div>
            <p className="font-semibold text-[#0c6b58]">Target achieved</p>
            <p className="text-sm text-[#147d64]">
              {currentCount} movements recorded successfully
            </p>
          </div>
        </div>
      )}
    </div>
  );
}
