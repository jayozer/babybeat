'use client';

import { useState, useEffect, useMemo } from 'react';
import {
  format,
  startOfMonth,
  endOfMonth,
  eachDayOfInterval,
  getDay,
  addMonths,
  subMonths,
  isSameDay,
  isToday,
  startOfDay,
} from 'date-fns';
import type { KickSession } from '@/types';

interface CalendarViewProps {
  sessions: KickSession[];
  selectedDate: Date;
  onSelectDate: (date: Date) => void;
}

interface DayInfo {
  date: Date;
  hasCompleteSession: boolean;
  hasTimeoutSession: boolean;
  hasEndedEarlySession: boolean;
}

export function CalendarView({
  sessions,
  selectedDate,
  onSelectDate,
}: CalendarViewProps) {
  const [currentMonth, setCurrentMonth] = useState(() => startOfMonth(selectedDate));

  // Update current month when selected date changes to a different month
  useEffect(() => {
    const selectedMonth = startOfMonth(selectedDate);
    if (selectedMonth.getTime() !== currentMonth.getTime()) {
      setCurrentMonth(selectedMonth);
    }
  }, [selectedDate, currentMonth]);

  // Group sessions by date
  const sessionsByDate = useMemo(() => {
    const map = new Map<string, KickSession[]>();
    sessions.forEach((session) => {
      if (!session.startedAt) return;
      const dateKey = startOfDay(new Date(session.startedAt)).toISOString();
      const existing = map.get(dateKey) || [];
      map.set(dateKey, [...existing, session]);
    });
    return map;
  }, [sessions]);

  // Generate calendar days for current month
  const calendarDays = useMemo(() => {
    const monthStart = startOfMonth(currentMonth);
    const monthEnd = endOfMonth(currentMonth);
    const days = eachDayOfInterval({ start: monthStart, end: monthEnd });

    return days.map((date): DayInfo => {
      const dateKey = startOfDay(date).toISOString();
      const daySessions = sessionsByDate.get(dateKey) || [];

      return {
        date,
        hasCompleteSession: daySessions.some((s) => s.status === 'complete'),
        hasTimeoutSession: daySessions.some((s) => s.status === 'timeout'),
        hasEndedEarlySession: daySessions.some((s) => s.status === 'ended_early'),
      };
    });
  }, [currentMonth, sessionsByDate]);

  // Calculate padding days for the first week
  const firstDayOfWeek = getDay(startOfMonth(currentMonth));
  const paddingDays = Array.from({ length: firstDayOfWeek }, (_, i) => i);

  const handlePrevMonth = () => {
    setCurrentMonth((prev) => subMonths(prev, 1));
  };

  const handleNextMonth = () => {
    setCurrentMonth((prev) => addMonths(prev, 1));
  };

  const weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  return (
    <div className="bg-white/70 backdrop-blur-sm rounded-3xl shadow-[0_4px_20px_rgba(90,143,90,0.08)] p-4">
      {/* Month navigation */}
      <div className="flex items-center justify-between mb-4">
        <button
          type="button"
          onClick={handlePrevMonth}
          className="p-2 hover:bg-[#f6f9f6] rounded-2xl transition-colors"
          aria-label="Previous month"
        >
          <span className="text-[#6b736b]">&larr;</span>
        </button>
        <h2
          className="text-lg font-semibold text-[#494d49]"
          style={{ fontFamily: 'Quicksand, sans-serif' }}
        >
          {format(currentMonth, 'MMMM yyyy')}
        </h2>
        <button
          type="button"
          onClick={handleNextMonth}
          className="p-2 hover:bg-[#f6f9f6] rounded-2xl transition-colors"
          aria-label="Next month"
        >
          <span className="text-[#6b736b]">&rarr;</span>
        </button>
      </div>

      {/* Week day headers */}
      <div className="grid grid-cols-7 gap-1 mb-2">
        {weekDays.map((day) => (
          <div
            key={day}
            className="text-center text-xs font-medium text-[#858e85] py-1"
          >
            {day}
          </div>
        ))}
      </div>

      {/* Calendar grid */}
      <div className="grid grid-cols-7 gap-1">
        {/* Padding for first week */}
        {paddingDays.map((i) => (
          <div key={`padding-${i}`} className="aspect-square" />
        ))}

        {/* Actual days */}
        {calendarDays.map((dayInfo) => {
          const isSelected = isSameDay(dayInfo.date, selectedDate);
          const isCurrentDay = isToday(dayInfo.date);
          const hasAnySession =
            dayInfo.hasCompleteSession ||
            dayInfo.hasTimeoutSession ||
            dayInfo.hasEndedEarlySession;

          return (
            <button
              key={dayInfo.date.toISOString()}
              type="button"
              onClick={() => onSelectDate(dayInfo.date)}
              className={`
                aspect-square
                flex flex-col items-center justify-center
                rounded-xl
                text-sm
                transition-all duration-200
                ${isSelected
                  ? 'bg-[#5a8f5a] text-white shadow-[0_2px_8px_rgba(90,143,90,0.3)]'
                  : isCurrentDay
                    ? 'bg-[#e8f0e8] text-[#477347]'
                    : 'hover:bg-[#f6f9f6] text-[#6b736b]'
                }
              `}
              aria-label={`${format(dayInfo.date, 'MMMM d, yyyy')}${hasAnySession ? ', has sessions' : ''}`}
              aria-pressed={isSelected}
            >
              <span className={isSelected ? 'font-bold' : ''}>
                {format(dayInfo.date, 'd')}
              </span>

              {/* Session indicators */}
              {hasAnySession && (
                <div className="flex gap-0.5 mt-0.5">
                  {dayInfo.hasCompleteSession && (
                    <span
                      className={`w-1.5 h-1.5 rounded-full ${
                        isSelected ? 'bg-white' : 'bg-[#7bab7b]'
                      }`}
                      aria-hidden="true"
                    />
                  )}
                  {dayInfo.hasTimeoutSession && (
                    <span
                      className={`w-1.5 h-1.5 rounded-full ${
                        isSelected ? 'bg-white' : 'bg-[#d4a373]'
                      }`}
                      aria-hidden="true"
                    />
                  )}
                  {dayInfo.hasEndedEarlySession && (
                    <span
                      className={`w-1.5 h-1.5 rounded-full ${
                        isSelected ? 'bg-white' : 'bg-[#b8a9c9]'
                      }`}
                      aria-hidden="true"
                    />
                  )}
                </div>
              )}
            </button>
          );
        })}
      </div>

      {/* Legend */}
      <div className="flex justify-center gap-4 mt-4 text-xs text-[#858e85]">
        <div className="flex items-center gap-1">
          <span className="w-2 h-2 rounded-full bg-[#7bab7b]" />
          <span>Complete</span>
        </div>
        <div className="flex items-center gap-1">
          <span className="w-2 h-2 rounded-full bg-[#d4a373]" />
          <span>Timeout</span>
        </div>
        <div className="flex items-center gap-1">
          <span className="w-2 h-2 rounded-full bg-[#b8a9c9]" />
          <span>Ended</span>
        </div>
      </div>
    </div>
  );
}
