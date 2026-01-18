import { v4 as uuidv4 } from 'uuid';
import { startOfDay, endOfDay } from 'date-fns';
import { db } from './db';
import type { KickSession } from '@/types';
import { DEFAULT_SESSION_VALUES } from '@/types';

/**
 * Creates a new kick counting session with default values
 */
export async function createSession(
  overrides?: Partial<KickSession>
): Promise<KickSession> {
  const now = new Date().toISOString();
  const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;

  const session: KickSession = {
    id: uuidv4(),
    createdAt: now,
    startedAt: null,
    endedAt: null,
    status: 'idle',
    targetCount: DEFAULT_SESSION_VALUES.targetCount,
    timeLimitSec: DEFAULT_SESSION_VALUES.timeLimitSec,
    kickCount: 0,
    durationSec: null,
    strengthRating: null,
    notes: null,
    timezone,
    schemaVersion: DEFAULT_SESSION_VALUES.schemaVersion,
    pausedDurationSec: 0,
    pausedAt: null,
    ...overrides,
  };

  await db.sessions.add(session);
  return session;
}

/**
 * Retrieves a session by ID
 */
export async function getSession(id: string): Promise<KickSession | undefined> {
  return db.sessions.get(id);
}

/**
 * Updates a session with the given fields
 */
export async function updateSession(
  id: string,
  updates: Partial<KickSession>
): Promise<void> {
  await db.sessions.update(id, updates);
}

/**
 * Returns all sessions ordered by createdAt descending (most recent first)
 */
export async function getAllSessions(): Promise<KickSession[]> {
  return db.sessions.orderBy('createdAt').reverse().toArray();
}

/**
 * Returns all sessions for a specific date
 */
export async function getSessionsByDate(date: Date): Promise<KickSession[]> {
  const dayStart = startOfDay(date).toISOString();
  const dayEnd = endOfDay(date).toISOString();

  return db.sessions
    .where('createdAt')
    .between(dayStart, dayEnd, true, true)
    .toArray();
}

/**
 * Returns the currently active or paused session, if any
 */
export async function getActiveSession(): Promise<KickSession | undefined> {
  const activeSessions = await db.sessions
    .where('status')
    .anyOf(['active', 'paused'])
    .toArray();

  return activeSessions[0];
}

/**
 * Deletes a session and all its associated kick events
 */
export async function deleteSession(id: string): Promise<void> {
  await db.transaction('rw', db.sessions, db.events, async () => {
    await db.events.where('sessionId').equals(id).delete();
    await db.sessions.delete(id);
  });
}
