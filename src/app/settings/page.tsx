'use client';

import Link from 'next/link';
import { usePreferences } from '@/lib/PreferencesContext';

export default function SettingsPage() {
  const { preferences, updatePreferences, isLoading } = usePreferences();

  const handleToggle = async (key: 'soundEnabled' | 'vibrationEnabled' | 'keepScreenAwake') => {
    await updatePreferences({ [key]: !preferences[key] });
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
        {/* Feedback Settings */}
        <section className="bg-white/70 backdrop-blur-sm rounded-3xl shadow-[0_4px_20px_rgba(90,143,90,0.08)] overflow-hidden">
          <h2 className="px-5 py-3 text-sm font-medium text-[#858e85] bg-[#f6f9f6]/50">
            Tap Feedback
          </h2>

          {/* Sound toggle */}
          <div className="px-5 py-4 flex items-center justify-between border-b border-[#e8f0e8]">
            <div>
              <p className="font-medium text-[#494d49]">Sound</p>
              <p className="text-sm text-[#858e85]">Play a click sound on tap</p>
            </div>
            <button
              type="button"
              role="switch"
              aria-checked={preferences.soundEnabled}
              onClick={() => handleToggle('soundEnabled')}
              className={`
                relative w-12 h-7 rounded-full transition-colors duration-200
                ${preferences.soundEnabled ? 'bg-[#5a8f5a]' : 'bg-[#c7ccc7]'}
              `}
            >
              <span
                className={`
                  absolute top-1 left-1 w-5 h-5 bg-white rounded-full shadow
                  transition-transform duration-200
                  ${preferences.soundEnabled ? 'translate-x-5' : 'translate-x-0'}
                `}
              />
            </button>
          </div>

          {/* Vibration toggle */}
          <div className="px-5 py-4 flex items-center justify-between">
            <div>
              <p className="font-medium text-[#494d49]">Vibration</p>
              <p className="text-sm text-[#858e85]">Haptic feedback on tap</p>
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
            <p className="font-medium text-[#494d49]">Baby Kick Counter</p>
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
