'use client';

import { useState } from 'react';

interface SessionControlsProps {
  onUndo: () => void;
  onPause: () => void;
  onResume: () => void;
  onEnd: () => void;
  canUndo: boolean;
  isPaused: boolean;
}

export function SessionControls({
  onUndo,
  onPause,
  onResume,
  onEnd,
  canUndo,
  isPaused,
}: SessionControlsProps) {
  const [showConfirmEnd, setShowConfirmEnd] = useState(false);

  const handleEndClick = () => {
    setShowConfirmEnd(true);
  };

  const handleConfirmEnd = () => {
    setShowConfirmEnd(false);
    onEnd();
  };

  const handleCancelEnd = () => {
    setShowConfirmEnd(false);
  };

  return (
    <div className="flex flex-col gap-4 animate-fade-in">
      {/* Main controls row */}
      <div className="flex justify-center gap-4">
        {/* Undo button */}
        <button
          type="button"
          onClick={onUndo}
          disabled={!canUndo}
          aria-label="Undo last kick"
          className={`
            px-6 py-3 rounded-2xl
            bg-white/60 backdrop-blur-sm
            font-medium
            border border-[#e2e5e2]
            transition-all duration-200
            ${
              canUndo
                ? 'text-[#6b736b] hover:bg-white hover:shadow-md'
                : 'text-[#c7ccc7] cursor-not-allowed opacity-50'
            }
          `}
        >
          Undo
        </button>

        {/* Pause/Resume button */}
        <button
          type="button"
          onClick={isPaused ? onResume : onPause}
          aria-label={isPaused ? 'Resume session' : 'Pause session'}
          className={`
            px-6 py-3 rounded-2xl
            font-medium
            transition-all duration-200
            ${
              isPaused
                ? 'bg-[#a8c9a8] text-white hover:bg-[#7bab7b]'
                : 'bg-white/60 backdrop-blur-sm text-[#6b736b] border border-[#e2e5e2] hover:bg-white hover:shadow-md'
            }
          `}
        >
          {isPaused ? 'Resume' : 'Pause'}
        </button>

        {/* End button */}
        <button
          type="button"
          onClick={handleEndClick}
          aria-label="End session early"
          className="
            px-6 py-3 rounded-2xl
            bg-white/60 backdrop-blur-sm
            text-[#9f8fc5] font-medium
            border border-[#e6e1f1]
            transition-all duration-200
            hover:bg-[#f9f8fc] hover:shadow-md
          "
        >
          End
        </button>
      </div>

      {/* Confirmation dialog */}
      {showConfirmEnd && (
        <div className="fixed inset-0 bg-black/30 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div
            className="bg-white rounded-3xl p-6 max-w-sm w-full shadow-[0_8px_32px_rgba(90,143,90,0.15)] animate-fade-in"
            role="dialog"
            aria-modal="true"
            aria-labelledby="confirm-end-title"
          >
            <h2
              id="confirm-end-title"
              className="text-xl font-semibold text-[#494d49] mb-2"
              style={{ fontFamily: 'Quicksand, sans-serif' }}
            >
              End session early?
            </h2>
            <p className="text-[#6b736b] mb-6">
              Your current progress will be saved, but the session will be
              marked as ended early.
            </p>
            <div className="flex gap-3">
              <button
                type="button"
                onClick={handleCancelEnd}
                className="
                  flex-1 px-4 py-3
                  rounded-2xl font-medium
                  bg-[#f0f2f0] text-[#6b736b]
                  hover:bg-[#e2e5e2]
                  transition-all duration-200
                "
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={handleConfirmEnd}
                className="
                  flex-1 px-4 py-3
                  rounded-2xl font-medium
                  bg-[#9f8fc5] text-white
                  hover:bg-[#8a74b0]
                  transition-all duration-200
                "
              >
                End Session
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
