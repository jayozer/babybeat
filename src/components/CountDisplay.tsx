'use client';

interface CountDisplayProps {
  currentCount: number;
  targetCount: number;
}

export function CountDisplay({ currentCount, targetCount }: CountDisplayProps) {
  const isComplete = currentCount >= targetCount;

  return (
    <div
      className="text-center"
      aria-live="polite"
      aria-atomic="true"
    >
      <div className="flex items-baseline justify-center gap-2">
        <span
          className={`
            text-7xl font-bold tabular-nums
            transition-all duration-200
            ${isComplete ? 'text-green-600' : 'text-gray-800'}
          `}
        >
          {currentCount}
        </span>
        <span className="text-3xl text-gray-400 font-medium">
          / {targetCount}
        </span>
      </div>
      <p className="text-lg text-gray-500 mt-2">
        {isComplete ? (
          <span className="text-green-600 font-medium">
            Target reached!
          </span>
        ) : (
          <span>
            {targetCount - currentCount} more to go
          </span>
        )}
      </p>
    </div>
  );
}
