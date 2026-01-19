import { db } from './db';
import type { KickSession, KickEvent, SessionStatus } from '@/types';

// Statuses that represent completed sessions (exportable)
const EXPORTABLE_STATUSES: SessionStatus[] = ['complete', 'timeout', 'ended_early'];

/**
 * Escapes a field value for CSV format
 * Handles commas, quotes, and newlines
 */
function escapeCSVField(value: string | number | null | undefined): string {
  if (value === null || value === undefined) {
    return '';
  }

  const stringValue = String(value);

  // If the value contains commas, quotes, or newlines, wrap in quotes and escape existing quotes
  if (stringValue.includes(',') || stringValue.includes('"') || stringValue.includes('\n')) {
    return `"${stringValue.replace(/"/g, '""')}"`;
  }

  return stringValue;
}

/**
 * Formats a date object to date string (YYYY-MM-DD)
 */
function formatDate(isoString: string): string {
  const date = new Date(isoString);
  return date.toLocaleDateString('en-CA'); // Returns YYYY-MM-DD format
}

/**
 * Formats a date object to time string (HH:MM:SS)
 */
function formatTime(isoString: string): string {
  const date = new Date(isoString);
  return date.toLocaleTimeString('en-GB', { hour12: false }); // Returns HH:MM:SS format
}

/**
 * Fetches all exportable sessions (completed, timeout, ended_early with startedAt)
 */
async function getExportableSessions(): Promise<KickSession[]> {
  const sessions = await db.sessions
    .where('status')
    .anyOf(EXPORTABLE_STATUSES)
    .toArray();

  // Filter out sessions that were never started
  return sessions
    .filter((session) => session.startedAt !== null)
    .sort((a, b) => new Date(a.startedAt!).getTime() - new Date(b.startedAt!).getTime());
}

/**
 * Fetches all kick events for a session
 */
async function getKicksForSession(sessionId: string): Promise<KickEvent[]> {
  const kicks = await db.events
    .where('sessionId')
    .equals(sessionId)
    .toArray();

  return kicks.sort((a, b) => a.ordinal - b.ordinal);
}

/**
 * Generates a summary CSV export (one row per session)
 */
export async function exportSummaryCSV(): Promise<string> {
  const sessions = await getExportableSessions();

  const headers = [
    'date',
    'start_time',
    'end_time',
    'duration_minutes',
    'kick_count',
    'target_count',
    'status',
    'strength_rating',
    'notes',
    'timezone',
  ];

  const rows = sessions.map((session) => {
    const durationMinutes =
      session.durationSec !== null ? (session.durationSec / 60).toFixed(1) : '';

    return [
      escapeCSVField(session.startedAt ? formatDate(session.startedAt) : ''),
      escapeCSVField(session.startedAt ? formatTime(session.startedAt) : ''),
      escapeCSVField(session.endedAt ? formatTime(session.endedAt) : ''),
      escapeCSVField(durationMinutes),
      escapeCSVField(session.kickCount),
      escapeCSVField(session.targetCount),
      escapeCSVField(session.status),
      escapeCSVField(session.strengthRating),
      escapeCSVField(session.notes),
      escapeCSVField(session.timezone),
    ].join(',');
  });

  // Add UTF-8 BOM for Excel compatibility
  const bom = '\uFEFF';
  return bom + [headers.join(','), ...rows].join('\n');
}

/**
 * Generates a detailed CSV export (one row per kick)
 */
export async function exportDetailedCSV(): Promise<string> {
  const sessions = await getExportableSessions();

  const headers = [
    'session_date',
    'session_start_time',
    'kick_number',
    'kick_time',
    'seconds_since_previous',
    'session_status',
    'session_kick_count',
  ];

  const allRows: string[] = [];

  for (const session of sessions) {
    // Skip sessions with 0 kicks in detailed export
    if (session.kickCount === 0) {
      continue;
    }

    const kicks = await getKicksForSession(session.id);

    kicks.forEach((kick, index) => {
      // Calculate seconds since previous kick
      let secondsSincePrevious = '';
      if (index > 0) {
        const prevTime = new Date(kicks[index - 1].occurredAt).getTime();
        const currTime = new Date(kick.occurredAt).getTime();
        secondsSincePrevious = String(Math.round((currTime - prevTime) / 1000));
      }

      const row = [
        escapeCSVField(session.startedAt ? formatDate(session.startedAt) : ''),
        escapeCSVField(session.startedAt ? formatTime(session.startedAt) : ''),
        escapeCSVField(kick.ordinal),
        escapeCSVField(formatTime(kick.occurredAt)),
        escapeCSVField(secondsSincePrevious),
        escapeCSVField(session.status),
        escapeCSVField(session.kickCount),
      ].join(',');

      allRows.push(row);
    });
  }

  // Add UTF-8 BOM for Excel compatibility
  const bom = '\uFEFF';
  return bom + [headers.join(','), ...allRows].join('\n');
}

/**
 * Triggers a browser download of a CSV file
 */
export function downloadCSV(csvContent: string, filename: string): void {
  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);

  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  link.style.display = 'none';

  document.body.appendChild(link);
  link.click();

  // Cleanup
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}

/**
 * Returns the count of exportable sessions
 */
export async function getExportableSessionCount(): Promise<number> {
  const sessions = await getExportableSessions();
  return sessions.length;
}
