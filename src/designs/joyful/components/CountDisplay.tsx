'use client';

import { useState, useEffect, useRef } from 'react';

interface CountDisplayProps {
  currentCount: number;
  targetCount: number;
}

interface ConfettiPiece {
  id: number;
  x: number;
  color: string;
  delay: number;
  rotation: number;
}

export function JoyfulCountDisplay({ currentCount, targetCount }: CountDisplayProps) {
  const isComplete = currentCount >= targetCount;
  const [animateCount, setAnimateCount] = useState(false);
  const [showConfetti, setShowConfetti] = useState(false);
  const [confetti, setConfetti] = useState<ConfettiPiece[]>([]);
  const prevCountRef = useRef(currentCount);

  // Animate on count change
  useEffect(() => {
    if (currentCount !== prevCountRef.current) {
      setAnimateCount(true);
      setTimeout(() => setAnimateCount(false), 300);
      prevCountRef.current = currentCount;
    }
  }, [currentCount]);

  // Show confetti on completion
  useEffect(() => {
    if (isComplete && !showConfetti) {
      setShowConfetti(true);
      const colors = ['#ff8c78', '#ffc520', '#2dd4bf', '#f96d55', '#5eead4'];
      const pieces: ConfettiPiece[] = [];
      for (let i = 0; i < 20; i++) {
        pieces.push({
          id: i,
          x: Math.random() * 100,
          color: colors[Math.floor(Math.random() * colors.length)],
          delay: Math.random() * 0.5,
          rotation: Math.random() * 360,
        });
      }
      setConfetti(pieces);
    }
  }, [isComplete, showConfetti]);

  // Progress dots
  const dots = Array.from({ length: targetCount }, (_, i) => i < currentCount);

  return (
    <div
      className="relative flex flex-col items-center animate-pop-in"
      aria-live="polite"
      aria-atomic="true"
    >
      {/* Confetti */}
      {showConfetti && confetti.map(piece => (
        <span
          key={piece.id}
          className="absolute w-3 h-3 rounded-sm animate-confetti pointer-events-none"
          style={{
            left: `${piece.x}%`,
            top: '-20px',
            backgroundColor: piece.color,
            animationDelay: `${piece.delay}s`,
            transform: `rotate(${piece.rotation}deg)`,
          }}
        />
      ))}

      {/* Main count display */}
      <div className="relative">
        {/* Background glow for completion */}
        {isComplete && (
          <span className="absolute inset-0 -m-4 rounded-full bg-gradient-to-r from-[#ffc520]/30 to-[#2dd4bf]/30 blur-xl" />
        )}

        <div className="flex items-baseline gap-3">
          <span
            className={`
              text-8xl font-extrabold tabular-nums font-['Comfortaa']
              bg-gradient-to-br from-[#f96d55] to-[#e54e35] bg-clip-text text-transparent
              transition-transform duration-200
              ${animateCount && 'animate-heartbeat'}
              ${isComplete && 'from-[#14b8a6] to-[#0d9488]'}
            `}
          >
            {currentCount}
          </span>
        </div>
      </div>

      {/* Progress dots */}
      <div className="flex gap-2 mt-6 flex-wrap justify-center max-w-[200px]">
        {dots.map((filled, i) => (
          <span
            key={i}
            className={`
              w-4 h-4 rounded-full transition-all duration-300
              ${filled
                ? 'bg-gradient-to-br from-[#ff8c78] to-[#f96d55] shadow-[0_2px_8px_rgba(249,109,85,0.4)]'
                : 'bg-[#e8e4dd]'
              }
              ${filled && i === currentCount - 1 && 'animate-pop-in'}
            `}
            style={{ animationDelay: `${i * 0.05}s` }}
          />
        ))}
      </div>

      {/* Status message */}
      <div className="mt-6 text-center">
        {isComplete ? (
          <div className="flex flex-col items-center space-y-2 animate-pop-in">
            <span className="text-3xl">🎉</span>
            <span className="text-[#14b8a6] font-bold text-xl">
              Woohoo! Goal reached!
            </span>
            <span className="text-[#9a9184] text-sm">
              Your little one is active today!
            </span>
          </div>
        ) : (
          <div className="flex flex-col items-center space-y-1">
            <span className="text-[#665f56] text-lg font-semibold">
              {targetCount - currentCount} more kicks!
            </span>
            <span className="text-[#b5aea0] text-sm">
              You&apos;re doing great
            </span>
          </div>
        )}
      </div>
    </div>
  );
}
