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
    <div className="fixed inset-0 bg-black/30 backdrop-blur-sm flex items-center justify-center z-50 p-4">
      <div
        className="bg-white/95 backdrop-blur-md rounded-3xl p-6 max-w-md w-full shadow-[0_8px_32px_rgba(90,143,90,0.15)] max-h-[90vh] overflow-y-auto animate-fade-in"
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
            className={`text-2xl font-semibold ${
              isComplete
                ? 'text-[#477347]'
                : isTimeout
                  ? 'text-[#b8860b]'
                  : 'text-[#494d49]'
            }`}
            style={{ fontFamily: 'Quicksand, sans-serif' }}
          >
            {isComplete && 'Session Complete!'}
            {isTimeout && 'Time Limit Reached'}
            {!isComplete && !isTimeout && 'Session Ended'}
          </h2>
        </div>

        {/* Session details */}
        <div className="bg-[#f6f9f6] rounded-2xl p-4 mb-6">
          <div className="grid grid-cols-2 gap-4 text-sm">
            <div>
              <p className="text-[#858e85]">Kicks Recorded</p>
              <p className="text-2xl font-bold text-[#494d49]">
                {session.kickCount}
              </p>
            </div>
            <div>
              <p className="text-[#858e85]">Duration</p>
              <p className="text-2xl font-bold text-[#494d49]">
                {durationMinutes} min
              </p>
            </div>
            {session.startedAt && (
              <div>
                <p className="text-[#858e85]">Started</p>
                <p className="font-medium text-[#494d49]">
                  {format(new Date(session.startedAt), 'h:mm a')}
                </p>
              </div>
            )}
            {session.endedAt && (
              <div>
                <p className="text-[#858e85]">Ended</p>
                <p className="font-medium text-[#494d49]">
                  {format(new Date(session.endedAt), 'h:mm a')}
                </p>
              </div>
            )}
          </div>
        </div>

        {/* Timeout guidance */}
        {isTimeout && (
          <div className="bg-[#fdf9f3] border border-[#e6dcc5] rounded-2xl p-4 mb-6">
            <p className="text-[#8b7355] font-medium mb-2">What to do next:</p>
            <ul className="text-[#8b7355] text-sm space-y-1">
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
          <label className="block text-sm font-medium text-[#6b736b] mb-2">
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
                  transition-all duration-200
                  ${
                    strengthRating === rating
                      ? 'bg-[#5a8f5a] text-white scale-110 shadow-[0_4px_12px_rgba(90,143,90,0.3)]'
                      : 'bg-[#f0f2f0] text-[#6b736b] hover:bg-[#e8f0e8]'
                  }
                `}
                aria-label={`Rate strength ${rating} out of 5`}
                aria-pressed={strengthRating === rating}
              >
                {rating}
              </button>
            ))}
          </div>
          <p className="text-xs text-[#858e85] text-center mt-2">
            1 = Very weak • 5 = Very strong
          </p>
        </div>

        {/* Notes */}
        <div className="mb-6">
          <label
            htmlFor="session-notes"
            className="block text-sm font-medium text-[#6b736b] mb-2"
          >
            Notes (optional)
          </label>
          <textarea
            id="session-notes"
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            placeholder="Add any notes about this session..."
            className="
              w-full p-3 border border-[#e8f0e8] rounded-2xl
              resize-none h-24
              focus:outline-none focus:ring-2 focus:ring-[#a8c9a8] focus:border-[#a8c9a8]
              bg-white/60
              placeholder:text-[#a5ada5]
            "
          />
        </div>

        {/* Actions */}
        <div className="flex flex-col gap-3">
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
          <button
            type="button"
            onClick={handleSave}
            className="
              w-full py-3 rounded-2xl
              bg-[#f0f2f0] text-[#6b736b] font-medium
              hover:bg-[#e8f0e8] active:bg-[#dfe5df]
              transition-all duration-200
            "
          >
            Close
          </button>
        </div>
      </div>
    </div>
  );
}
