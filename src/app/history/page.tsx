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
      <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-[#fefdfb] to-[#f6f9f6]">
        <p className="text-[#858e85]">Loading...</p>
      </div>
    );
  }

  return (
    <main className="min-h-screen bg-gradient-to-br from-[#fefdfb] via-[#fdf9f3] to-[#f6f9f6] pb-20">
      {/* Header */}
      <header className="bg-white/80 backdrop-blur-md border-b border-[#e8f0e8] sticky top-0 z-10">
        <div className="max-w-md mx-auto px-4 py-4 flex items-center justify-between">
          <h1
            className="text-xl font-semibold text-[#494d49]"
            style={{ fontFamily: 'Quicksand, sans-serif' }}
          >
            History
          </h1>
          <Link
            href="/"
            className="
              text-[#5a8f5a] font-medium
              hover:text-[#477347] transition-colors
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
