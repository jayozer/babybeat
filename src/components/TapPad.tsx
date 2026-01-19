'use client';

import { useState, useCallback, useRef, type KeyboardEvent } from 'react';
import { usePreferences } from '@/lib/PreferencesContext';
import { triggerTapFeedback, initAudioContext } from '@/lib/feedback';
import { useEffect } from 'react';

interface TapPadProps {
  onClick: () => void;
  disabled?: boolean;
}

export function TapPad({ onClick, disabled = false }: TapPadProps) {
  const [isPressed, setIsPressed] = useState(false);
  const [ripples, setRipples] = useState<{ id: number; x: number; y: number }[]>([]);
  const buttonRef = useRef<HTMLButtonElement>(null);
  const rippleIdRef = useRef(0);
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

  const addRipple = useCallback((clientX: number, clientY: number) => {
    if (!buttonRef.current) return;

    const rect = buttonRef.current.getBoundingClientRect();
    const x = clientX - rect.left;
    const y = clientY - rect.top;
    const id = rippleIdRef.current++;

    setRipples(prev => [...prev, { id, x, y }]);

    setTimeout(() => {
      setRipples(prev => prev.filter(r => r.id !== id));
    }, 800);
  }, []);

  const handlePress = useCallback((e?: React.MouseEvent) => {
    if (disabled) return;

    setIsPressed(true);
    onClick();

    // Trigger sound and/or vibration feedback
    triggerTapFeedback({
      soundOption: preferences.soundOption,
      vibrationEnabled: preferences.vibrationEnabled,
    });

    if (e) {
      addRipple(e.clientX, e.clientY);
    }

    setTimeout(() => {
      setIsPressed(false);
    }, 200);
  }, [onClick, disabled, addRipple, preferences.soundOption, preferences.vibrationEnabled]);

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
        min-h-[320px]
        rounded-[2.5rem]
        bg-gradient-to-br from-[#a8c9a8] via-[#7bab7b] to-[#5a8f5a]
        shadow-[0_8px_32px_rgba(90,143,90,0.25)]
        transition-all
        duration-300
        ease-out
        focus:outline-none
        focus:ring-4
        focus:ring-[#d1e2d1]
        focus:ring-offset-4
        focus:ring-offset-[#fefdfb]
        overflow-hidden
        ${isPressed ? 'scale-[0.97] shadow-[0_4px_16px_rgba(90,143,90,0.2)]' : 'scale-100 hover:shadow-[0_12px_40px_rgba(90,143,90,0.3)]'}
        ${disabled ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'}
      `}
    >
      {/* Soft inner glow */}
      <span
        className={`
          absolute
          inset-4
          rounded-[2rem]
          bg-gradient-to-t from-transparent to-white/20
          pointer-events-none
        `}
      />

      {/* Ripple effects */}
      {ripples.map(ripple => (
        <span
          key={ripple.id}
          className="absolute w-4 h-4 rounded-full bg-white/40 animate-soft-ripple pointer-events-none"
          style={{ left: ripple.x - 8, top: ripple.y - 8 }}
        />
      ))}

      {/* Content */}
      <span className="relative flex flex-col items-center justify-center text-white h-full">
        {/* Decorative circle behind icon */}
        <span className={`
          absolute w-28 h-28 rounded-full
          bg-white/10
          ${!disabled && 'animate-breathe'}
        `} />

        <span className="relative text-7xl mb-4 drop-shadow-lg">
          <svg width="80" height="80" viewBox="0 0 80 80" fill="none" xmlns="http://www.w3.org/2000/svg">
            {/* Gentle leaf/heart hybrid shape */}
            <path
              d="M40 70C40 70 65 55 65 35C65 21 54 15 40 25C26 15 15 21 15 35C15 55 40 70 40 70Z"
              fill="white"
              fillOpacity="0.9"
            />
            <path
              d="M40 60C40 60 55 50 55 38C55 30 48 26 40 32C32 26 25 30 25 38C25 50 40 60 40 60Z"
              fill="#5a8f5a"
              fillOpacity="0.6"
            />
          </svg>
        </span>

        <span className="text-2xl font-semibold tracking-wider opacity-95" style={{ fontFamily: 'Quicksand, sans-serif' }}>
          gentle tap
        </span>
        <span className="text-sm opacity-70 mt-2 font-light">
          when you feel movement
        </span>
      </span>

      {/* Pressed state overlay */}
      <span
        className={`
          absolute
          inset-0
          rounded-[2.5rem]
          bg-white
          transition-opacity
          duration-200
          pointer-events-none
          ${isPressed ? 'opacity-10' : 'opacity-0'}
        `}
      />
    </button>
  );
}
