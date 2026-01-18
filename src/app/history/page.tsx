'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { CalendarView } from '@/components/CalendarView';
import { SessionList } from '@/components/SessionList';
import { getAllSessions } from '@/lib/sessionService';
import type { KickSession } from '@/types';

export default function HistoryPage() {
  const [sessions, setSessions] = useState<KickSession[]>([]);
  const [selectedDate, setSelectedDate] = useState<Date>(() => new Date());
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    async function loadSessions() {
      try {
        const allSessions = await getAllSessions();
        // Filter to only finished sessions
        const finishedSessions = allSessions.filter(
          (s) =>
            s.status === 'complete' ||
            s.status === 'timeout' ||
            s.status === 'ended_early'
        );
        setSessions(finishedSessions);
      } catch (error) {
        console.error('Failed to load sessions:', error);
      } finally {
        setIsLoading(false);
      }
    }
    loadSessions();
  }, []);

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
          <h1 className="text-xl font-bold text-gray-800">History</h1>
          <Link
            href="/"
            className="
              text-pink-500 font-medium
              hover:text-pink-600 transition-colors
            "
          >
            Counter
          </Link>
        </div>
      </header>

      <div className="max-w-md mx-auto px-4 py-6 space-y-6">
        {/* Calendar */}
        <CalendarView
          sessions={sessions}
          selectedDate={selectedDate}
          onSelectDate={setSelectedDate}
        />

        {/* Session List */}
        <SessionList sessions={sessions} selectedDate={selectedDate} />
      </div>
    </main>
  );
}
