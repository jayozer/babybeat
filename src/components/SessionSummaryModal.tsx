'use client';

import { useState } from 'react';
import { format } from 'date-fns';
import type { KickSession, StrengthRating } from '@/types';

interface SessionSummaryModalProps {
  session: KickSession;
  onClose: () => void;
  onSaveDetails: (rating: StrengthRating | null, notes: string) => void;
  onStartNew: () => void;
}

export function SessionSummaryModal({
  session,
  onClose,
  onSaveDetails,
  onStartNew,
}: SessionSummaryModalProps) {
  const [strengthRating, setStrengthRating] = useState<StrengthRating | null>(
    session.strengthRating
  );
  const [notes, setNotes] = useState(session.notes ?? '');

  const isComplete = session.status === 'complete';
  const isTimeout = session.status === 'timeout';

  const durationMinutes = session.durationSec
    ? Math.round(session.durationSec / 60)
    : 0;

  const handleSave = () => {
    onSaveDetails(strengthRating, notes);
    onClose();
  };

  const handleStartNew = () => {
    onSaveDetails(strengthRating, notes);
    onStartNew();
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div
        className="bg-white rounded-2xl p-6 max-w-md w-full shadow-xl max-h-[90vh] overflow-y-auto"
        role="dialog"
        aria-modal="true"
        aria-labelledby="summary-title"
      >
        {/* Header */}
        <div className="text-center mb-6">
          <div className="text-5xl mb-2">
            {isComplete ? '🎉' : isTimeout ? '⏰' : '📝'}
          </div>
          <h2
            id="summary-title"
            className={`text-2xl font-bold ${
              isComplete
                ? 'text-green-700'
                : isTimeout
                  ? 'text-orange-700'
                  : 'text-gray-800'
            }`}
          >
            {isComplete && 'Session Complete!'}
            {isTimeout && 'Time Limit Reached'}
            {!isComplete && !isTimeout && 'Session Ended'}
          </h2>
        </div>

        {/* Session details */}
        <div className="bg-gray-50 rounded-xl p-4 mb-6">
          <div className="grid grid-cols-2 gap-4 text-sm">
            <div>
              <p className="text-gray-500">Kicks Recorded</p>
              <p className="text-2xl font-bold text-gray-800">
                {session.kickCount}
              </p>
            </div>
            <div>
              <p className="text-gray-500">Duration</p>
              <p className="text-2xl font-bold text-gray-800">
                {durationMinutes} min
              </p>
            </div>
            {session.startedAt && (
              <div>
                <p className="text-gray-500">Started</p>
                <p className="font-medium text-gray-800">
                  {format(new Date(session.startedAt), 'h:mm a')}
                </p>
              </div>
            )}
            {session.endedAt && (
              <div>
                <p className="text-gray-500">Ended</p>
                <p className="font-medium text-gray-800">
                  {format(new Date(session.endedAt), 'h:mm a')}
                </p>
              </div>
            )}
          </div>
        </div>

        {/* Timeout guidance */}
        {isTimeout && (
          <div className="bg-orange-50 border border-orange-200 rounded-xl p-4 mb-6">
            <p className="text-orange-800 font-medium mb-2">What to do next:</p>
            <ul className="text-orange-700 text-sm space-y-1">
              <li>• Try gentle techniques to encourage movement</li>
              <li>• Drink cold water or eat something sweet</li>
              <li>• Lie on your side and count again</li>
              <li>
                • <strong>Contact your healthcare provider</strong> if you&apos;re
                concerned
              </li>
            </ul>
          </div>
        )}

        {/* Strength rating */}
        <div className="mb-6">
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Movement Strength (optional)
          </label>
          <div className="flex justify-center gap-2">
            {([1, 2, 3, 4, 5] as StrengthRating[]).map((rating) => (
              <button
                key={rating}
                type="button"
                onClick={() =>
                  setStrengthRating(strengthRating === rating ? null : rating)
                }
                className={`
                  w-12 h-12 rounded-full font-bold text-lg
                  transition-all
                  ${
                    strengthRating === rating
                      ? 'bg-pink-500 text-white scale-110'
                      : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                  }
                `}
                aria-label={`Rate strength ${rating} out of 5`}
                aria-pressed={strengthRating === rating}
              >
                {rating}
              </button>
            ))}
          </div>
          <p className="text-xs text-gray-500 text-center mt-2">
            1 = Very weak • 5 = Very strong
          </p>
        </div>

        {/* Notes */}
        <div className="mb-6">
          <label
            htmlFor="session-notes"
            className="block text-sm font-medium text-gray-700 mb-2"
          >
            Notes (optional)
          </label>
          <textarea
            id="session-notes"
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            placeholder="Add any notes about this session..."
            className="
              w-full p-3 border border-gray-200 rounded-xl
              resize-none h-24
              focus:outline-none focus:ring-2 focus:ring-pink-300 focus:border-pink-300
            "
          />
        </div>

        {/* Actions */}
        <div className="flex flex-col gap-3">
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
          <button
            type="button"
            onClick={handleSave}
            className="
              w-full py-3 rounded-xl
              bg-gray-100 text-gray-700 font-medium
              hover:bg-gray-200 active:bg-gray-300
              transition-colors
            "
          >
            Close
          </button>
        </div>
      </div>
    </div>
  );
}
