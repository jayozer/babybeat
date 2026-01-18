'use client';

import { useState, useEffect, use } from 'react';
import Link from 'next/link';
import { format, differenceInSeconds } from 'date-fns';
import { getSession } from '@/lib/sessionService';
import { getKicksForSession } from '@/lib/kickService';
import type { KickSession, KickEvent } from '@/types';

interface SessionDetailPageProps {
  params: Promise<{ id: string }>;
}

function getStatusInfo(status: KickSession['status']) {
  switch (status) {
    case 'complete':
      return { label: 'Complete', emoji: '🎉', className: 'text-green-700' };
    case 'timeout':
      return { label: 'Time Limit Reached', emoji: '⏰', className: 'text-orange-700' };
    case 'ended_early':
      return { label: 'Ended Early', emoji: '⏹', className: 'text-gray-700' };
    default:
      return { label: status, emoji: '', className: 'text-gray-700' };
  }
}

function formatDuration(seconds: number): string {
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  if (mins === 0) return `${secs}s`;
  return secs > 0 ? `${mins}m ${secs}s` : `${mins}m`;
}

export default function SessionDetailPage({ params }: SessionDetailPageProps) {
  const resolvedParams = use(params);
  const [session, setSession] = useState<KickSession | null>(null);
  const [kicks, setKicks] = useState<KickEvent[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function loadSession() {
      try {
        const sessionData = await getSession(resolvedParams.id);
        if (!sessionData) {
          setError('Session not found');
          return;
        }
        setSession(sessionData);

        const kickData = await getKicksForSession(resolvedParams.id);
        setKicks(kickData);
      } catch (err) {
        setError('Failed to load session');
        console.error(err);
      } finally {
        setIsLoading(false);
      }
    }
    loadSession();
  }, [resolvedParams.id]);

  if (isLoading) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <p className="text-gray-500">Loading...</p>
      </div>
    );
  }

  if (error || !session) {
    return (
      <div className="flex min-h-screen flex-col items-center justify-center gap-4">
        <p className="text-gray-500">{error || 'Session not found'}</p>
        <Link href="/history" className="text-pink-500 hover:text-pink-600">
          Back to History
        </Link>
      </div>
    );
  }

  const statusInfo = getStatusInfo(session.status);
  const durationMinutes = session.durationSec
    ? Math.round(session.durationSec / 60)
    : 0;

  // Calculate intervals between kicks
  const kicksWithIntervals = kicks.map((kick, index) => {
    if (index === 0) {
      return { ...kick, intervalFromPrev: null };
    }
    const prevKick = kicks[index - 1];
    const interval = differenceInSeconds(
      new Date(kick.occurredAt),
      new Date(prevKick.occurredAt)
    );
    return { ...kick, intervalFromPrev: interval };
  });

  return (
    <main className="min-h-screen bg-gray-50 pb-20">
      {/* Header */}
      <header className="bg-white shadow-sm">
        <div className="max-w-md mx-auto px-4 py-4 flex items-center justify-between">
          <Link
            href="/history"
            className="text-pink-500 hover:text-pink-600 transition-colors"
          >
            &larr; Back
          </Link>
          <h1 className="text-lg font-bold text-gray-800">Session Details</h1>
          <div className="w-16" /> {/* Spacer for centering */}
        </div>
      </header>

      <div className="max-w-md mx-auto px-4 py-6 space-y-6">
        {/* Status card */}
        <div className="bg-white rounded-xl shadow-sm p-6 text-center">
          <div className="text-5xl mb-2">{statusInfo.emoji}</div>
          <h2 className={`text-xl font-bold ${statusInfo.className}`}>
            {statusInfo.label}
          </h2>
        </div>

        {/* Session metadata */}
        <div className="bg-white rounded-xl shadow-sm p-4">
          <h3 className="text-sm font-medium text-gray-500 mb-3">
            Session Details
          </h3>
          <div className="grid grid-cols-2 gap-4 text-sm">
            <div>
              <p className="text-gray-500">Date</p>
              <p className="font-medium text-gray-800">
                {session.startedAt
                  ? format(new Date(session.startedAt), 'MMM d, yyyy')
                  : 'N/A'}
              </p>
            </div>
            <div>
              <p className="text-gray-500">Duration</p>
              <p className="font-medium text-gray-800">{durationMinutes} min</p>
            </div>
            <div>
              <p className="text-gray-500">Started</p>
              <p className="font-medium text-gray-800">
                {session.startedAt
                  ? format(new Date(session.startedAt), 'h:mm a')
                  : 'N/A'}
              </p>
            </div>
            <div>
              <p className="text-gray-500">Ended</p>
              <p className="font-medium text-gray-800">
                {session.endedAt
                  ? format(new Date(session.endedAt), 'h:mm a')
                  : 'N/A'}
              </p>
            </div>
            <div>
              <p className="text-gray-500">Kicks</p>
              <p className="font-medium text-gray-800">
                {session.kickCount} / {session.targetCount}
              </p>
            </div>
            {session.strengthRating && (
              <div>
                <p className="text-gray-500">Strength</p>
                <p className="font-medium text-gray-800">
                  {session.strengthRating} / 5
                </p>
              </div>
            )}
          </div>

          {/* Notes */}
          {session.notes && (
            <div className="mt-4 pt-4 border-t border-gray-100">
              <p className="text-gray-500 text-sm mb-1">Notes</p>
              <p className="text-gray-800">{session.notes}</p>
            </div>
          )}
        </div>

        {/* Kick timeline */}
        {kicks.length > 0 && (
          <div className="bg-white rounded-xl shadow-sm p-4">
            <h3 className="text-sm font-medium text-gray-500 mb-3">
              Kick Timeline
            </h3>
            <div className="space-y-2">
              {kicksWithIntervals.map((kick, index) => (
                <div
                  key={kick.id}
                  className="flex items-center justify-between text-sm"
                >
                  <div className="flex items-center gap-3">
                    <span className="w-6 h-6 rounded-full bg-pink-100 text-pink-600 flex items-center justify-center text-xs font-medium">
                      {index + 1}
                    </span>
                    <span className="text-gray-800">
                      {format(new Date(kick.occurredAt), 'h:mm:ss a')}
                    </span>
                  </div>
                  {kick.intervalFromPrev !== null && (
                    <span className="text-gray-400 text-xs">
                      +{formatDuration(kick.intervalFromPrev)}
                    </span>
                  )}
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </main>
  );
}
