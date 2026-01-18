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
      <div className="flex min-h-screen items-center justify-center">
        <p className="text-gray-500">Loading...</p>
      </div>
    );
  }

  return (
    <main className="min-h-screen bg-gray-50 pb-20">
      {/* Header */}
      <header className="bg-white shadow-sm">
        <div className="max-w-md mx-auto px-4 py-4 flex items-center justify-between">
          <h1 className="text-xl font-bold text-gray-800">Settings</h1>
          <Link
            href="/"
            className="text-pink-500 font-medium hover:text-pink-600 transition-colors"
          >
            Counter
          </Link>
        </div>
      </header>

      <div className="max-w-md mx-auto px-4 py-6 space-y-6">
        {/* Feedback Settings */}
        <section className="bg-white rounded-xl shadow-sm overflow-hidden">
          <h2 className="px-5 py-3 text-sm font-medium text-gray-500 bg-gray-50">
            Tap Feedback
          </h2>

          {/* Sound toggle */}
          <div className="px-5 py-4 flex items-center justify-between border-b border-gray-100">
            <div>
              <p className="font-medium text-gray-800">Sound</p>
              <p className="text-sm text-gray-500">Play a click sound on tap</p>
            </div>
            <button
              type="button"
              role="switch"
              aria-checked={preferences.soundEnabled}
              onClick={() => handleToggle('soundEnabled')}
              className={`
                relative w-12 h-7 rounded-full transition-colors
                ${preferences.soundEnabled ? 'bg-pink-500' : 'bg-gray-300'}
              `}
            >
              <span
                className={`
                  absolute top-1 left-1 w-5 h-5 bg-white rounded-full shadow
                  transition-transform
                  ${preferences.soundEnabled ? 'translate-x-5' : 'translate-x-0'}
                `}
              />
            </button>
          </div>

          {/* Vibration toggle */}
          <div className="px-5 py-4 flex items-center justify-between">
            <div>
              <p className="font-medium text-gray-800">Vibration</p>
              <p className="text-sm text-gray-500">Haptic feedback on tap</p>
            </div>
            <button
              type="button"
              role="switch"
              aria-checked={preferences.vibrationEnabled}
              onClick={() => handleToggle('vibrationEnabled')}
              className={`
                relative w-12 h-7 rounded-full transition-colors
                ${preferences.vibrationEnabled ? 'bg-pink-500' : 'bg-gray-300'}
              `}
            >
              <span
                className={`
                  absolute top-1 left-1 w-5 h-5 bg-white rounded-full shadow
                  transition-transform
                  ${preferences.vibrationEnabled ? 'translate-x-5' : 'translate-x-0'}
                `}
              />
            </button>
          </div>
        </section>

        {/* Screen Settings */}
        <section className="bg-white rounded-xl shadow-sm overflow-hidden">
          <h2 className="px-5 py-3 text-sm font-medium text-gray-500 bg-gray-50">
            Screen
          </h2>

          {/* Keep screen awake toggle */}
          <div className="px-5 py-4 flex items-center justify-between">
            <div>
              <p className="font-medium text-gray-800">Keep Screen Awake</p>
              <p className="text-sm text-gray-500">
                Prevent screen from turning off during session
              </p>
            </div>
            <button
              type="button"
              role="switch"
              aria-checked={preferences.keepScreenAwake}
              onClick={() => handleToggle('keepScreenAwake')}
              className={`
                relative w-12 h-7 rounded-full transition-colors
                ${preferences.keepScreenAwake ? 'bg-pink-500' : 'bg-gray-300'}
              `}
            >
              <span
                className={`
                  absolute top-1 left-1 w-5 h-5 bg-white rounded-full shadow
                  transition-transform
                  ${preferences.keepScreenAwake ? 'translate-x-5' : 'translate-x-0'}
                `}
              />
            </button>
          </div>
        </section>

        {/* About */}
        <section className="bg-white rounded-xl shadow-sm overflow-hidden">
          <h2 className="px-5 py-3 text-sm font-medium text-gray-500 bg-gray-50">
            About
          </h2>
          <div className="px-5 py-4">
            <p className="font-medium text-gray-800">Baby Kick Beat Counter</p>
            <p className="text-sm text-gray-500 mt-1">Version 1.0.0</p>
          </div>
        </section>

        {/* Links */}
        <section className="bg-white rounded-xl shadow-sm overflow-hidden">
          <Link
            href="/info"
            className="
              block px-5 py-4 flex items-center justify-between
              hover:bg-gray-50 transition-colors border-b border-gray-100
            "
          >
            <span className="text-gray-800">Information & Help</span>
            <span className="text-gray-400">&rarr;</span>
          </Link>
          <Link
            href="/history"
            className="
              block px-5 py-4 flex items-center justify-between
              hover:bg-gray-50 transition-colors
            "
          >
            <span className="text-gray-800">Session History</span>
            <span className="text-gray-400">&rarr;</span>
          </Link>
        </section>
      </div>
    </main>
  );
}
