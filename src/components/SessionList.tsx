'use client';

import { format, isSameDay } from 'date-fns';
import Link from 'next/link';
import type { KickSession } from '@/types';

interface SessionListProps {
  sessions: KickSession[];
  selectedDate: Date;
}

function getStatusBadge(status: KickSession['status']) {
  switch (status) {
    case 'complete':
      return {
        label: 'Complete',
        className: 'bg-green-100 text-green-700',
        emoji: '✓',
      };
    case 'timeout':
      return {
        label: 'Timeout',
        className: 'bg-orange-100 text-orange-700',
        emoji: '⏰',
      };
    case 'ended_early':
      return {
        label: 'Ended',
        className: 'bg-gray-100 text-gray-700',
        emoji: '⏹',
      };
    default:
      return {
        label: status,
        className: 'bg-gray-100 text-gray-600',
        emoji: '',
      };
  }
}

export function SessionList({ sessions, selectedDate }: SessionListProps) {
  // Filter sessions for selected date
  const filteredSessions = sessions.filter((session) => {
    if (!session.startedAt) return false;
    return isSameDay(new Date(session.startedAt), selectedDate);
  });

  // Sort by start time, most recent first
  const sortedSessions = [...filteredSessions].sort((a, b) => {
    const aTime = a.startedAt ? new Date(a.startedAt).getTime() : 0;
    const bTime = b.startedAt ? new Date(b.startedAt).getTime() : 0;
    return bTime - aTime;
  });

  if (sortedSessions.length === 0) {
    return (
      <div className="bg-white rounded-xl shadow-sm p-6 text-center">
        <div className="text-4xl mb-2">📭</div>
        <p className="text-gray-600">No sessions on this day</p>
        <p className="text-sm text-gray-400 mt-1">
          {format(selectedDate, 'EEEE, MMMM d, yyyy')}
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-3">
      <h3 className="text-sm font-medium text-gray-600 px-1">
        {format(selectedDate, 'EEEE, MMMM d, yyyy')}
      </h3>

      {sortedSessions.map((session) => {
        const badge = getStatusBadge(session.status);
        const durationMinutes = session.durationSec
          ? Math.round(session.durationSec / 60)
          : 0;

        return (
          <Link
            key={session.id}
            href={`/session/${session.id}`}
            className="
              block bg-white rounded-xl shadow-sm p-4
              hover:shadow-md transition-shadow
              active:bg-gray-50
            "
          >
            <div className="flex items-start justify-between">
              <div>
                <div className="flex items-center gap-2">
                  <span className="text-lg font-semibold text-gray-800">
                    {session.startedAt
                      ? format(new Date(session.startedAt), 'h:mm a')
                      : 'Not started'}
                  </span>
                  <span
                    className={`
                      px-2 py-0.5 rounded-full text-xs font-medium
                      ${badge.className}
                    `}
                  >
                    {badge.emoji} {badge.label}
                  </span>
                </div>
                <div className="text-sm text-gray-500 mt-1">
                  {session.kickCount} kicks in {durationMinutes} min
                </div>
              </div>
              <span className="text-gray-400">&rarr;</span>
            </div>

            {/* Optional rating/notes indicator */}
            {(session.strengthRating || session.notes) && (
              <div className="flex gap-2 mt-2 text-xs text-gray-400">
                {session.strengthRating && (
                  <span>Strength: {session.strengthRating}/5</span>
                )}
                {session.notes && <span>Has notes</span>}
              </div>
            )}
          </Link>
        );
      })}
    </div>
  );
}
