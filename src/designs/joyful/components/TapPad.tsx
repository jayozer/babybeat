'use client';

import { useState, useCallback, useRef, type KeyboardEvent } from 'react';

interface TapPadProps {
  onClick: () => void;
  disabled?: boolean;
}

export function JoyfulTapPad({ onClick, disabled = false }: TapPadProps) {
  const [isPressed, setIsPressed] = useState(false);
  const [showBurst, setShowBurst] = useState(false);
  const buttonRef = useRef<HTMLButtonElement>(null);

  const handlePress = useCallback(() => {
    if (disabled) return;

    setIsPressed(true);
    setShowBurst(true);
    onClick();

    setTimeout(() => {
      setIsPressed(false);
    }, 400);

    setTimeout(() => {
      setShowBurst(false);
    }, 600);
  }, [onClick, disabled]);

  const handleKeyDown = useCallback(
    (event: KeyboardEvent<HTMLButtonElement>) => {
      if (event.key === 'Enter' || event.key === ' ') {
        event.preventDefault();
        handlePress();
      }
    },
    [handlePress]
  );

  return (
    <div className="relative">
      {/* Burst effect circles */}
      {showBurst && (
        <>
          <span className="absolute inset-0 rounded-[3rem] bg-[#ff8c78]/30 animate-burst pointer-events-none" />
          <span className="absolute inset-4 rounded-[2.5rem] bg-[#ffc520]/30 animate-burst pointer-events-none" style={{ animationDelay: '0.1s' }} />
        </>
      )}

      <button
        ref={buttonRef}
        type="button"
        onClick={handlePress}
        onKeyDown={handleKeyDown}
        disabled={disabled}
        aria-label="Tap to record a kick"
        className={`
          relative
          w-full
          min-h-[320px]
          rounded-[3rem]
          bg-gradient-to-br from-[#ff8c78] via-[#f96d55] to-[#e54e35]
          shadow-[0_12px_40px_rgba(249,109,85,0.35)]
          transition-all
          duration-300
          ease-out
          focus:outline-none
          focus:ring-4
          focus:ring-[#ffd4cd]
          focus:ring-offset-4
          focus:ring-offset-[#faf9f7]
          overflow-hidden
          ${isPressed ? 'animate-tap-spring' : 'hover:shadow-[0_16px_50px_rgba(249,109,85,0.45)] hover:-translate-y-1'}
          ${disabled ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'}
        `}
      >
        {/* Decorative bubbles */}
        <span className="absolute top-6 right-8 w-12 h-12 rounded-full bg-white/20 animate-bounce-gentle" />
        <span className="absolute top-16 right-16 w-6 h-6 rounded-full bg-white/15" style={{ animationDelay: '0.3s' }} />
        <span className="absolute bottom-20 left-8 w-8 h-8 rounded-full bg-white/15 animate-bounce-gentle" style={{ animationDelay: '0.6s' }} />
        <span className="absolute bottom-12 left-20 w-4 h-4 rounded-full bg-white/20" />

        {/* Shine effect */}
        <span className="absolute -top-24 -left-24 w-48 h-48 bg-white/10 rounded-full blur-2xl" />

        {/* Content */}
        <span className="relative flex flex-col items-center justify-center text-white h-full">
          {/* Baby face icon */}
          <span className={`text-8xl mb-3 ${!disabled && !isPressed && 'animate-bounce-gentle'}`}>
            <svg width="100" height="100" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
              {/* Face circle */}
              <circle cx="50" cy="50" r="40" fill="white" fillOpacity="0.95" />
              {/* Cheeks */}
              <circle cx="30" cy="55" r="8" fill="#ffb5a8" fillOpacity="0.6" />
              <circle cx="70" cy="55" r="8" fill="#ffb5a8" fillOpacity="0.6" />
              {/* Eyes - happy closed */}
              <path d="M35 45C35 45 38 48 43 45" stroke="#665f56" strokeWidth="3" strokeLinecap="round" />
              <path d="M65 45C65 45 62 48 57 45" stroke="#665f56" strokeWidth="3" strokeLinecap="round" />
              {/* Smile */}
              <path d="M38 60C38 60 45 68 50 68C55 68 62 60 62 60" stroke="#665f56" strokeWidth="3" strokeLinecap="round" fill="none" />
              {/* Little hair tuft */}
              <path d="M45 15C45 15 50 8 55 15" stroke="#665f56" strokeWidth="2" strokeLinecap="round" fill="none" />
            </svg>
          </span>

          <span className="text-3xl font-bold tracking-wide font-['Comfortaa']">
            TAP!
          </span>
          <span className="text-base opacity-90 mt-2 font-medium">
            when baby kicks
          </span>
        </span>

        {/* Press overlay */}
        <span
          className={`
            absolute
            inset-0
            rounded-[3rem]
            bg-white
            transition-opacity
            duration-100
            pointer-events-none
            ${isPressed ? 'opacity-15' : 'opacity-0'}
          `}
        />
      </button>
    </div>
  );
}
