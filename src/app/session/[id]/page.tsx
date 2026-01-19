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
      return { label: 'Complete', emoji: '🎉', className: 'text-[#477347]' };
    case 'timeout':
      return { label: 'Time Limit Reached', emoji: '⏰', className: 'text-[#8b7355]' };
    case 'ended_early':
      return { label: 'Ended Early', emoji: '⏹', className: 'text-[#735d94]' };
    default:
      return { label: status, emoji: '', className: 'text-[#6b736b]' };
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
      <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-[#fefdfb] to-[#f6f9f6]">
        <p className="text-[#858e85]">Loading...</p>
      </div>
    );
  }

  if (error || !session) {
    return (
      <div className="flex min-h-screen flex-col items-center justify-center gap-4 bg-gradient-to-br from-[#fefdfb] to-[#f6f9f6]">
        <p className="text-[#858e85]">{error || 'Session not found'}</p>
        <Link href="/history" className="text-[#5a8f5a] hover:text-[#477347] transition-colors">
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
    <main className="min-h-screen bg-gradient-to-br from-[#fefdfb] via-[#fdf9f3] to-[#f6f9f6] pb-20">
      {/* Header */}
      <header className="bg-white/80 backdrop-blur-md border-b border-[#e8f0e8] sticky top-0 z-10">
        <div className="max-w-md mx-auto px-4 py-4 flex items-center justify-between">
          <Link
            href="/history"
            className="text-[#5a8f5a] hover:text-[#477347] transition-colors font-medium"
          >
            &larr; Back
          </Link>
          <h1
            className="text-lg font-semibold text-[#494d49]"
            style={{ fontFamily: 'Quicksand, sans-serif' }}
          >
            Session Details
          </h1>
          <div className="w-16" /> {/* Spacer for centering */}
        </div>
      </header>

      <div className="max-w-md mx-auto px-4 py-6 space-y-6">
        {/* Status card */}
        <div className="bg-white/70 backdrop-blur-sm rounded-3xl shadow-[0_4px_20px_rgba(90,143,90,0.08)] p-6 text-center">
          <div className="text-5xl mb-2">{statusInfo.emoji}</div>
          <h2
            className={`text-xl font-semibold ${statusInfo.className}`}
            style={{ fontFamily: 'Quicksand, sans-serif' }}
          >
            {statusInfo.label}
          </h2>
        </div>

        {/* Session metadata */}
        <div className="bg-white/70 backdrop-blur-sm rounded-3xl shadow-[0_4px_20px_rgba(90,143,90,0.08)] p-4">
          <h3 className="text-sm font-medium text-[#858e85] mb-3">
            Session Details
          </h3>
          <div className="grid grid-cols-2 gap-4 text-sm">
            <div>
              <p className="text-[#858e85]">Date</p>
              <p className="font-medium text-[#494d49]">
                {session.startedAt
                  ? format(new Date(session.startedAt), 'MMM d, yyyy')
                  : 'N/A'}
              </p>
            </div>
            <div>
              <p className="text-[#858e85]">Duration</p>
              <p className="font-medium text-[#494d49]">{durationMinutes} min</p>
            </div>
            <div>
              <p className="text-[#858e85]">Started</p>
              <p className="font-medium text-[#494d49]">
                {session.startedAt
                  ? format(new Date(session.startedAt), 'h:mm a')
                  : 'N/A'}
              </p>
            </div>
            <div>
              <p className="text-[#858e85]">Ended</p>
              <p className="font-medium text-[#494d49]">
                {session.endedAt
                  ? format(new Date(session.endedAt), 'h:mm a')
                  : 'N/A'}
              </p>
            </div>
            <div>
              <p className="text-[#858e85]">Kicks</p>
              <p className="font-medium text-[#494d49]">
                {session.kickCount} / {session.targetCount}
              </p>
            </div>
            {session.strengthRating && (
              <div>
                <p className="text-[#858e85]">Strength</p>
                <p className="font-medium text-[#494d49]">
                  {session.strengthRating} / 5
                </p>
              </div>
            )}
          </div>

          {/* Notes */}
          {session.notes && (
            <div className="mt-4 pt-4 border-t border-[#e8f0e8]">
              <p className="text-[#858e85] text-sm mb-1">Notes</p>
              <p className="text-[#494d49]">{session.notes}</p>
            </div>
          )}
        </div>

        {/* Kick timeline */}
        {kicks.length > 0 && (
          <div className="bg-white/70 backdrop-blur-sm rounded-3xl shadow-[0_4px_20px_rgba(90,143,90,0.08)] p-4">
            <h3 className="text-sm font-medium text-[#858e85] mb-3">
              Kick Timeline
            </h3>
            <div className="space-y-2">
              {kicksWithIntervals.map((kick, index) => (
                <div
                  key={kick.id}
                  className="flex items-center justify-between text-sm"
                >
                  <div className="flex items-center gap-3">
                    <span className="w-6 h-6 rounded-full bg-[#e8f0e8] text-[#5a8f5a] flex items-center justify-center text-xs font-medium">
                      {index + 1}
                    </span>
                    <span className="text-[#494d49]">
                      {format(new Date(kick.occurredAt), 'h:mm:ss a')}
                    </span>
                  </div>
                  {kick.intervalFromPrev !== null && (
                    <span className="text-[#a5ada5] text-xs">
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
