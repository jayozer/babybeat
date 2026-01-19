'use client';

import { useState, useCallback, useRef, type KeyboardEvent } from 'react';

interface TapPadProps {
  onClick: () => void;
  disabled?: boolean;
}

export function ClinicalTapPad({ onClick, disabled = false }: TapPadProps) {
  const [isPressed, setIsPressed] = useState(false);
  const buttonRef = useRef<HTMLButtonElement>(null);

  const handlePress = useCallback(() => {
    if (disabled) return;

    setIsPressed(true);
    onClick();

    setTimeout(() => {
      setIsPressed(false);
    }, 150);
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
        min-h-[280px]
        rounded-xl
        bg-gradient-to-b from-[#102a43] to-[#243b53]
        border border-[#334e68]
        transition-all
        duration-150
        ease-out
        focus:outline-none
        focus-visible:ring-2
        focus-visible:ring-[#27ab83]
        focus-visible:ring-offset-2
        ${isPressed
          ? 'scale-[0.99] shadow-[inset_0_2px_8px_rgba(0,0,0,0.3)]'
          : 'shadow-[0_4px_12px_rgba(16,42,67,0.15)] hover:shadow-[0_6px_20px_rgba(16,42,67,0.2)]'
        }
        ${disabled ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'}
      `}
    >
      {/* Top status bar */}
      <div className="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-[#27ab83] to-[#3ebd93] rounded-t-xl" />

      {/* Content */}
      <div className="relative flex flex-col items-center justify-center text-white h-full px-6">
        {/* Icon */}
        <div className={`
          w-24 h-24 rounded-lg
          bg-[#27ab83]/20 border border-[#27ab83]/40
          flex items-center justify-center
          mb-6
          transition-all duration-150
          ${isPressed && 'bg-[#27ab83]/30 scale-95'}
        `}>
          <svg width="48" height="48" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path
              d="M24 6L24 42M6 24H42"
              stroke="#27ab83"
              strokeWidth="4"
              strokeLinecap="round"
            />
            <circle
              cx="24"
              cy="24"
              r="8"
              stroke="#27ab83"
              strokeWidth="3"
              fill="none"
            />
          </svg>
        </div>

        <span className="text-xl font-semibold tracking-wide text-white/95">
          Record Movement
        </span>
        <span className="text-sm text-[#9fb3c8] mt-2 font-medium">
          Tap when you feel a kick
        </span>

        {/* Keyboard hint */}
        <div className="absolute bottom-4 right-4 flex items-center gap-2 text-xs text-[#627d98]">
          <kbd className="px-2 py-1 bg-[#334e68] rounded text-[#9fb3c8] font-mono">
            Space
          </kbd>
          <span>or tap</span>
        </div>
      </div>

      {/* Active indicator */}
      {!disabled && (
        <div className="absolute bottom-4 left-4 flex items-center gap-2">
          <span className="w-2 h-2 rounded-full bg-[#27ab83] animate-minimal-pulse" />
          <span className="text-xs text-[#65d6ad] font-medium">Active</span>
        </div>
      )}

      {/* Pressed overlay */}
      <span
        className={`
          absolute
          inset-0
          rounded-xl
          bg-white
          transition-opacity
          duration-100
          pointer-events-none
          ${isPressed ? 'opacity-5' : 'opacity-0'}
        `}
      />
    </button>
  );
}
