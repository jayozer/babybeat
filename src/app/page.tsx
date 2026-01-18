'use client';

import { useState } from 'react';
import { TapPad } from '@/components/TapPad';
import { CountDisplay } from '@/components/CountDisplay';
import { TimerDisplay } from '@/components/TimerDisplay';
import { SessionControls } from '@/components/SessionControls';
import { SessionSummaryModal } from '@/components/SessionSummaryModal';
import { OnboardingModal, useOnboarding } from '@/components/OnboardingModal';
import { useSession } from '@/lib/SessionContext';
import { usePreferences } from '@/lib/PreferencesContext';
import { useBeforeUnload } from '@/hooks/useBeforeUnload';
import { useWakeLock } from '@/hooks/useWakeLock';
import type { StrengthRating } from '@/types';

function SessionPage() {
  const {
    state,
    tap,
    undo,
    pause,
    resume,
    endEarly,
    saveSessionDetails,
    resetSession,
    isSessionActive,
    isPaused,
    kickCount,
    targetCount,
  } = useSession();

  const [showSummary, setShowSummary] = useState(false);
  const { shouldShowOnboarding, isLoading: onboardingLoading, completeOnboarding } = useOnboarding();
  const { preferences } = usePreferences();

  // Warn user before closing page during active session
  useBeforeUnload(isSessionActive);

  // Keep screen awake during active session (if enabled)
  useWakeLock(preferences.keepScreenAwake, isSessionActive);

  if (state.isLoading || onboardingLoading) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <p className="text-gray-500">Loading...</p>
      </div>
    );
  }

  const isComplete = state.session?.status === 'complete';
  const isTimeout = state.session?.status === 'timeout';
  const isEndedEarly = state.session?.status === 'ended_early';
  const isFinished = isComplete || isTimeout || isEndedEarly;

  // Show summary modal when session finishes
  const shouldShowSummary = isFinished && state.session && !showSummary;

  const handleCloseSummary = () => {
    setShowSummary(true); // Mark as viewed
  };

  const handleSaveDetails = async (
    rating: StrengthRating | null,
    notes: string
  ) => {
    await saveSessionDetails(rating, notes);
  };

  const handleStartNew = () => {
    resetSession();
    setShowSummary(false);
  };

  return (
    <main className="flex min-h-screen flex-col items-center justify-between p-4 bg-gray-50">
      <div className="w-full max-w-md flex flex-col gap-6 py-8">
        {/* Header */}
        <h1 className="text-2xl font-bold text-center text-gray-800">
          Baby Kick Beat Counter
        </h1>

        {/* Error display */}
        {state.error && (
          <div className="bg-red-100 text-red-700 p-3 rounded-lg text-center">
            {state.error}
          </div>
        )}

        {/* Count Display */}
        <CountDisplay currentCount={kickCount} targetCount={targetCount} />

        {/* Timer Display */}
        <TimerDisplay
          startedAt={state.session?.startedAt ?? null}
          timeLimitSec={state.session?.timeLimitSec ?? 7200}
          isPaused={isPaused}
          pausedDurationSec={state.session?.pausedDurationSec ?? 0}
        />

        {/* Tap Pad */}
        <TapPad onClick={tap} disabled={isPaused || isFinished} />

        {/* Session Controls */}
        {isSessionActive && (
          <SessionControls
            onUndo={undo}
            onPause={pause}
            onResume={resume}
            onEnd={endEarly}
            canUndo={kickCount > 0}
            isPaused={isPaused}
          />
        )}

        {/* Start new session button (after summary dismissed) */}
        {isFinished && showSummary && (
          <button
            type="button"
            onClick={handleStartNew}
            className="
              w-full py-4 rounded-xl
              bg-pink-500 text-white font-bold text-lg
              hover:bg-pink-600 active:bg-pink-700
              transition-colors
            "
          >
            Start New Session
          </button>
        )}
      </div>

      {/* Session Summary Modal */}
      {shouldShowSummary && state.session && (
        <SessionSummaryModal
          session={state.session}
          onClose={handleCloseSummary}
          onSaveDetails={handleSaveDetails}
          onStartNew={handleStartNew}
        />
      )}

      {/* Onboarding Modal */}
      {shouldShowOnboarding && (
        <OnboardingModal onComplete={completeOnboarding} />
      )}
    </main>
  );
}

export default function Home() {
  return <SessionPage />;
}
