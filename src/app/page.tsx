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
      <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-[#fefdfb] to-[#f6f9f6]">
        <p className="text-[#858e85]">Loading...</p>
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
    <main className="flex min-h-screen flex-col items-center justify-between p-4 bg-gradient-to-br from-[#fefdfb] via-[#fdf9f3] to-[#f6f9f6]">
      <div className="w-full max-w-md flex flex-col gap-8 py-8">
        {/* Header */}
        <header className="text-center animate-fade-in">
          <h1
            className="text-2xl font-semibold text-[#494d49] tracking-wide"
            style={{ fontFamily: 'Quicksand, sans-serif' }}
          >
            Baby Kick Count
          </h1>
          <p className="text-sm text-[#858e85] mt-1">
            Track your baby&apos;s movements gently
          </p>
        </header>

        {/* Error display */}
        {state.error && (
          <div className="bg-[#f9f8fc] border border-[#d3cce6] text-[#735d94] p-4 rounded-2xl text-center animate-fade-in">
            {state.error}
          </div>
        )}

        {/* Count Display */}
        <CountDisplay currentCount={kickCount} targetCount={targetCount} />

        {/* Timer Display */}
        <TimerDisplay
          startedAt={state.session?.startedAt ?? null}
          endedAt={state.session?.endedAt ?? null}
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
              w-full py-4 rounded-2xl
              bg-gradient-to-r from-[#a8c9a8] to-[#7bab7b]
              text-white font-semibold text-lg
              shadow-[0_4px_20px_rgba(90,143,90,0.25)]
              transition-all duration-300
              hover:shadow-[0_8px_30px_rgba(90,143,90,0.35)]
              active:scale-[0.98]
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
