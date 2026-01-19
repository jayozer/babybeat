'use client';

import Link from 'next/link';
import { usePreferences } from '@/lib/PreferencesContext';
import { playSound, initAudioContext } from '@/lib/feedback';
import type { SoundOption } from '@/types';
import { useEffect } from 'react';

const SOUND_OPTIONS: { value: SoundOption; label: string; description: string }[] = [
  { value: 'soft-click', label: 'Soft Click', description: 'Gentle click sound' },
  { value: 'pop', label: 'Pop', description: 'Quick bright pop' },
  { value: 'heartbeat', label: 'Heartbeat', description: 'Warm double thump' },
  { value: 'bubble', label: 'Bubble', description: 'Soft rising tone' },
  { value: 'none', label: 'None', description: 'Silent mode' },
];

export default function SettingsPage() {
  const { preferences, updatePreferences, isLoading } = usePreferences();

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

  const handleToggle = async (key: 'vibrationEnabled' | 'keepScreenAwake') => {
    await updatePreferences({ [key]: !preferences[key] });
  };

  const handleSoundOptionChange = async (option: SoundOption) => {
    await updatePreferences({ soundOption: option });
  };

  const handlePreviewSound = (option: SoundOption) => {
    if (option !== 'none') {
      playSound(option);
    }
  };

  if (isLoading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-[#fefdfb] to-[#f6f9f6]">
        <p className="text-[#858e85]">Loading...</p>
      </div>
    );
  }

  return (
    <main className="min-h-screen bg-gradient-to-br from-[#fefdfb] via-[#fdf9f3] to-[#f6f9f6] pb-20">
      {/* Header */}
      <header className="bg-white/80 backdrop-blur-md border-b border-[#e8f0e8] sticky top-0 z-10">
        <div className="max-w-md mx-auto px-4 py-4 flex items-center justify-between">
          <h1
            className="text-xl font-semibold text-[#494d49]"
            style={{ fontFamily: 'Quicksand, sans-serif' }}
          >
            Settings
          </h1>
          <Link
            href="/"
            className="text-[#5a8f5a] font-medium hover:text-[#477347] transition-colors"
          >
            Counter
          </Link>
        </div>
      </header>

      <div className="max-w-md mx-auto px-4 py-6 space-y-6">
        {/* Sound Settings */}
        <section className="bg-white/70 backdrop-blur-sm rounded-3xl shadow-[0_4px_20px_rgba(90,143,90,0.08)] overflow-hidden">
          <h2 className="px-5 py-3 text-sm font-medium text-[#858e85] bg-[#f6f9f6]/50">
            Tap Sound
          </h2>
          <p className="px-5 pb-2 text-sm text-[#858e85]">
            Select the sound played when you tap
          </p>

          <div className="divide-y divide-[#e8f0e8]">
            {SOUND_OPTIONS.map((option) => (
              <div
                key={option.value}
                className="px-5 py-3 flex items-center justify-between"
              >
                <label className="flex items-center gap-3 flex-1 cursor-pointer">
                  <input
                    type="radio"
                    name="soundOption"
                    value={option.value}
                    checked={preferences.soundOption === option.value}
                    onChange={() => handleSoundOptionChange(option.value)}
                    className="w-4 h-4 text-[#5a8f5a] border-[#c7ccc7] focus:ring-[#5a8f5a] focus:ring-offset-0"
                  />
                  <div>
                    <p className="font-medium text-[#494d49]">{option.label}</p>
                    <p className="text-sm text-[#858e85]">{option.description}</p>
                  </div>
                </label>
                {option.value !== 'none' && (
                  <button
                    type="button"
                    onClick={() => handlePreviewSound(option.value)}
                    className="ml-3 px-3 py-1.5 text-sm font-medium text-[#5a8f5a] hover:text-[#477347] hover:bg-[#f6f9f6] rounded-lg transition-colors flex items-center gap-1"
                    aria-label={`Preview ${option.label} sound`}
                  >
                    <svg
                      width="16"
                      height="16"
                      viewBox="0 0 24 24"
                      fill="currentColor"
                      xmlns="http://www.w3.org/2000/svg"
                    >
                      <path d="M8 5v14l11-7z" />
                    </svg>
                    Play
                  </button>
                )}
              </div>
            ))}
          </div>
        </section>

        {/* Vibration Settings */}
        <section className="bg-white/70 backdrop-blur-sm rounded-3xl shadow-[0_4px_20px_rgba(90,143,90,0.08)] overflow-hidden">
          <h2 className="px-5 py-3 text-sm font-medium text-[#858e85] bg-[#f6f9f6]/50">
            Haptic Feedback
          </h2>

          {/* Vibration toggle */}
          <div className="px-5 py-4 flex items-center justify-between">
            <div>
              <p className="font-medium text-[#494d49]">Vibration</p>
              <p className="text-sm text-[#858e85]">Haptic feedback on tap (Android only)</p>
            </div>
            <button
              type="button"
              role="switch"
              aria-checked={preferences.vibrationEnabled}
              onClick={() => handleToggle('vibrationEnabled')}
              className={`
                relative w-12 h-7 rounded-full transition-colors duration-200
                ${preferences.vibrationEnabled ? 'bg-[#5a8f5a]' : 'bg-[#c7ccc7]'}
              `}
            >
              <span
                className={`
                  absolute top-1 left-1 w-5 h-5 bg-white rounded-full shadow
                  transition-transform duration-200
                  ${preferences.vibrationEnabled ? 'translate-x-5' : 'translate-x-0'}
                `}
              />
            </button>
          </div>
        </section>

        {/* Screen Settings */}
        <section className="bg-white/70 backdrop-blur-sm rounded-3xl shadow-[0_4px_20px_rgba(90,143,90,0.08)] overflow-hidden">
          <h2 className="px-5 py-3 text-sm font-medium text-[#858e85] bg-[#f6f9f6]/50">
            Screen
          </h2>

          {/* Keep screen awake toggle */}
          <div className="px-5 py-4 flex items-center justify-between">
            <div>
              <p className="font-medium text-[#494d49]">Keep Screen Awake</p>
              <p className="text-sm text-[#858e85]">
                Prevent screen from turning off during session
              </p>
            </div>
            <button
              type="button"
              role="switch"
              aria-checked={preferences.keepScreenAwake}
              onClick={() => handleToggle('keepScreenAwake')}
              className={`
                relative w-12 h-7 rounded-full transition-colors duration-200
                ${preferences.keepScreenAwake ? 'bg-[#5a8f5a]' : 'bg-[#c7ccc7]'}
              `}
            >
              <span
                className={`
                  absolute top-1 left-1 w-5 h-5 bg-white rounded-full shadow
                  transition-transform duration-200
                  ${preferences.keepScreenAwake ? 'translate-x-5' : 'translate-x-0'}
                `}
              />
            </button>
          </div>
        </section>

        {/* About */}
        <section className="bg-white/70 backdrop-blur-sm rounded-3xl shadow-[0_4px_20px_rgba(90,143,90,0.08)] overflow-hidden">
          <h2 className="px-5 py-3 text-sm font-medium text-[#858e85] bg-[#f6f9f6]/50">
            About
          </h2>
          <div className="px-5 py-4">
            <p className="font-medium text-[#494d49]">Baby Kick Count</p>
            <p className="text-sm text-[#858e85] mt-1">Version 1.0.0</p>
          </div>
        </section>

        {/* Links */}
        <section className="bg-white/70 backdrop-blur-sm rounded-3xl shadow-[0_4px_20px_rgba(90,143,90,0.08)] overflow-hidden">
          <Link
            href="/info"
            className="
              block px-5 py-4 flex items-center justify-between
              hover:bg-[#f6f9f6] transition-colors border-b border-[#e8f0e8]
            "
          >
            <span className="text-[#494d49]">Information & Help</span>
            <span className="text-[#a5ada5]">&rarr;</span>
          </Link>
          <Link
            href="/history"
            className="
              block px-5 py-4 flex items-center justify-between
              hover:bg-[#f6f9f6] transition-colors
            "
          >
            <span className="text-[#494d49]">Session History</span>
            <span className="text-[#a5ada5]">&rarr;</span>
          </Link>
        </section>
      </div>
    </main>
  );
}
