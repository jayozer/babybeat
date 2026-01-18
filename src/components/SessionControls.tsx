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
    <div className="flex flex-col gap-4">
      {/* Main controls row */}
      <div className="flex justify-center gap-4">
        {/* Undo button */}
        <button
          type="button"
          onClick={onUndo}
          disabled={!canUndo}
          aria-label="Undo last kick"
          className={`
            flex items-center gap-2
            px-4 py-3
            rounded-xl
            font-medium
            transition-all
            ${
              canUndo
                ? 'bg-gray-100 text-gray-700 hover:bg-gray-200 active:bg-gray-300'
                : 'bg-gray-50 text-gray-300 cursor-not-allowed'
            }
          `}
        >
          <span className="text-xl">↩️</span>
          <span>Undo</span>
        </button>

        {/* Pause/Resume button */}
        <button
          type="button"
          onClick={isPaused ? onResume : onPause}
          aria-label={isPaused ? 'Resume session' : 'Pause session'}
          className={`
            flex items-center gap-2
            px-4 py-3
            rounded-xl
            font-medium
            transition-all
            ${
              isPaused
                ? 'bg-green-100 text-green-700 hover:bg-green-200 active:bg-green-300'
                : 'bg-yellow-100 text-yellow-700 hover:bg-yellow-200 active:bg-yellow-300'
            }
          `}
        >
          <span className="text-xl">{isPaused ? '▶️' : '⏸'}</span>
          <span>{isPaused ? 'Resume' : 'Pause'}</span>
        </button>

        {/* End button */}
        <button
          type="button"
          onClick={handleEndClick}
          aria-label="End session early"
          className="
            flex items-center gap-2
            px-4 py-3
            rounded-xl
            font-medium
            bg-red-100 text-red-700
            hover:bg-red-200 active:bg-red-300
            transition-all
          "
        >
          <span className="text-xl">⏹</span>
          <span>End</span>
        </button>
      </div>

      {/* Confirmation dialog */}
      {showConfirmEnd && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div
            className="bg-white rounded-2xl p-6 max-w-sm w-full shadow-xl"
            role="dialog"
            aria-modal="true"
            aria-labelledby="confirm-end-title"
          >
            <h2
              id="confirm-end-title"
              className="text-xl font-bold text-gray-800 mb-2"
            >
              End session early?
            </h2>
            <p className="text-gray-600 mb-6">
              Your current progress will be saved, but the session will be
              marked as ended early.
            </p>
            <div className="flex gap-3">
              <button
                type="button"
                onClick={handleCancelEnd}
                className="
                  flex-1 px-4 py-3
                  rounded-xl font-medium
                  bg-gray-100 text-gray-700
                  hover:bg-gray-200 active:bg-gray-300
                  transition-all
                "
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={handleConfirmEnd}
                className="
                  flex-1 px-4 py-3
                  rounded-xl font-medium
                  bg-red-600 text-white
                  hover:bg-red-700 active:bg-red-800
                  transition-all
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
