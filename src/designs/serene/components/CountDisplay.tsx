'use client';

interface CountDisplayProps {
  currentCount: number;
  targetCount: number;
}

export function SereneCountDisplay({ currentCount, targetCount }: CountDisplayProps) {
  const isComplete = currentCount >= targetCount;
  const progress = Math.min(currentCount / targetCount, 1);

  // SVG circle parameters
  const size = 200;
  const strokeWidth = 8;
  const radius = (size - strokeWidth) / 2;
  const circumference = 2 * Math.PI * radius;
  const strokeDashoffset = circumference * (1 - progress);

  return (
    <div
      className="flex flex-col items-center animate-fade-in"
      aria-live="polite"
      aria-atomic="true"
    >
      {/* Progress Ring */}
      <div className="relative">
        <svg
          width={size}
          height={size}
          className={`transform -rotate-90 ${!isComplete && 'animate-ring-glow'}`}
        >
          {/* Background circle */}
          <circle
            cx={size / 2}
            cy={size / 2}
            r={radius}
            stroke="#e8f0e8"
            strokeWidth={strokeWidth}
            fill="none"
          />
          {/* Progress circle */}
          <circle
            cx={size / 2}
            cy={size / 2}
            r={radius}
            stroke={isComplete ? '#5a8f5a' : 'url(#sereneGradient)'}
            strokeWidth={strokeWidth}
            fill="none"
            strokeLinecap="round"
            strokeDasharray={circumference}
            strokeDashoffset={strokeDashoffset}
            className="transition-all duration-500 ease-out"
          />
          <defs>
            <linearGradient id="sereneGradient" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor="#a8c9a8" />
              <stop offset="50%" stopColor="#7bab7b" />
              <stop offset="100%" stopColor="#9f8fc5" />
            </linearGradient>
          </defs>
        </svg>

        {/* Count in center */}
        <div className="absolute inset-0 flex flex-col items-center justify-center">
          <span
            className={`
              text-6xl font-bold tabular-nums font-['Quicksand']
              transition-all duration-300
              ${isComplete ? 'text-[#477347]' : 'text-[#494d49]'}
            `}
          >
            {currentCount}
          </span>
          <span className="text-lg text-[#a5ada5] font-medium mt-1">
            of {targetCount}
          </span>
        </div>
      </div>

      {/* Status message */}
      <div className="mt-6 text-center">
        {isComplete ? (
          <div className="flex flex-col items-center space-y-2">
            <span className="text-[#477347] font-semibold text-lg">
              Goal reached
            </span>
            <span className="text-[#858e85] text-sm">
              Your baby is active and healthy
            </span>
          </div>
        ) : (
          <div className="flex flex-col items-center space-y-1">
            <span className="text-[#6b736b] text-lg">
              {targetCount - currentCount} more to go
            </span>
            <span className="text-[#a5ada5] text-sm">
              Take your time, relax
            </span>
          </div>
        )}
      </div>
    </div>
  );
}
