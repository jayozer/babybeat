'use client';

import { useState, useCallback, useRef, useEffect, type KeyboardEvent } from 'react';
import { usePreferences } from '@/lib/PreferencesContext';
import { triggerTapFeedback, initAudioContext } from '@/lib/feedback';

interface TapPadProps {
  onClick: () => void;
  disabled?: boolean;
}

export function TapPad({ onClick, disabled = false }: TapPadProps) {
  const [isPressed, setIsPressed] = useState(false);
  const buttonRef = useRef<HTMLButtonElement>(null);
  const { preferences } = usePreferences();

  // Initialize audio context on first user interaction
  useEffect(() => {
    const handleFirstInteraction = () => {
      initAudioContext();
      document.removeEventListener('touchstart', handleFirstInteraction);
      document.removeEventListener('click', handleFirstInteraction);
    };
    document.addEventListener('touchstart', handleFirstInteraction);
    document.addEventListener('click', handleFirstInteraction);
    return () => {
      document.removeEventListener('touchstart', handleFirstInteraction);
      document.removeEventListener('click', handleFirstInteraction);
    };
  }, []);

  const handlePress = useCallback(() => {
    if (disabled) return;

    setIsPressed(true);
    onClick();

    // Trigger sound and/or vibration feedback
    triggerTapFeedback({
      soundEnabled: preferences.soundEnabled,
      vibrationEnabled: preferences.vibrationEnabled,
    });

    // Reset animation after a short delay
    setTimeout(() => {
      setIsPressed(false);
    }, 150);
  }, [onClick, disabled, preferences.soundEnabled, preferences.vibrationEnabled]);

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
        min-h-[300px]
        rounded-3xl
        bg-gradient-to-br from-pink-400 to-pink-600
        shadow-lg
        transition-all
        duration-150
        ease-out
        focus:outline-none
        focus:ring-4
        focus:ring-pink-300
        focus:ring-offset-2
        active:scale-95
        disabled:opacity-50
        disabled:cursor-not-allowed
        disabled:active:scale-100
        ${isPressed ? 'scale-95 shadow-inner' : 'scale-100 hover:shadow-xl'}
      `}
    >
      {/* Ripple effect container */}
      <span
        className={`
          absolute
          inset-0
          rounded-3xl
          bg-white
          transition-opacity
          duration-150
          ${isPressed ? 'opacity-20' : 'opacity-0'}
        `}
      />

      {/* Content */}
      <span className="relative flex flex-col items-center justify-center text-white">
        <span className="text-6xl mb-2">👶</span>
        <span className="text-2xl font-bold tracking-wide">TAP</span>
        <span className="text-sm opacity-80 mt-1">when you feel movement</span>
      </span>
    </button>
  );
}
