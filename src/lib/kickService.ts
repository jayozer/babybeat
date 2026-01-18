import { v4 as uuidv4 } from 'uuid';
import { db } from './db';
import { updateSession } from './sessionService';
import type { KickEvent, KickSource } from '@/types';

/**
 * Registers a new kick event for a session
 * Updates the session's kickCount and writes to IndexedDB immediately
 */
export async function registerKick(
  sessionId: string,
  source: KickSource = 'tap'
): Promise<KickEvent> {
  const now = new Date().toISOString();

  // Get the current highest ordinal for this session
  const existingKicks = await db.events
    .where('sessionId')
    .equals(sessionId)
    .toArray();

  const maxOrdinal = existingKicks.reduce(
    (max, kick) => Math.max(max, kick.ordinal),
    0
  );

  const kickEvent: KickEvent = {
    id: uuidv4(),
    sessionId,
    occurredAt: now,
    ordinal: maxOrdinal + 1,
    source,
  };

  // Write to IndexedDB immediately
  await db.transaction('rw', db.events, db.sessions, async () => {
    await db.events.add(kickEvent);
    // Update the session's kick count
    await updateSession(sessionId, { kickCount: maxOrdinal + 1 });
  });

  return kickEvent;
}

/**
 * Returns all kicks for a session ordered by ordinal
 */
export async function getKicksForSession(
  sessionId: string
): Promise<KickEvent[]> {
  const kicks = await db.events
    .where('sessionId')
    .equals(sessionId)
    .toArray();

  return kicks.sort((a, b) => a.ordinal - b.ordinal);
}

/**
 * Deletes the most recent kick event for a session (for undo functionality)
 * Returns the deleted kick or undefined if no kicks exist
 */
export async function deleteLastKick(
  sessionId: string
): Promise<KickEvent | undefined> {
  const kicks = await getKicksForSession(sessionId);

  if (kicks.length === 0) {
    return undefined;
  }

  const lastKick = kicks[kicks.length - 1];

  // Delete from IndexedDB and update session
  await db.transaction('rw', db.events, db.sessions, async () => {
    await db.events.delete(lastKick.id);
    await updateSession(sessionId, { kickCount: kicks.length - 1 });
  });

  return lastKick;
}

/**
 * Returns the count of kicks for a session
 */
export async function getKickCount(sessionId: string): Promise<number> {
  return db.events.where('sessionId').equals(sessionId).count();
}

/**
 * Calculates the intervals between kicks in seconds
 */
export function calculateKickIntervals(kicks: KickEvent[]): number[] {
  if (kicks.length < 2) {
    return [];
  }

  const intervals: number[] = [];
  for (let i = 1; i < kicks.length; i++) {
    const prev = new Date(kicks[i - 1].occurredAt).getTime();
    const curr = new Date(kicks[i].occurredAt).getTime();
    intervals.push((curr - prev) / 1000);
  }

  return intervals;
}
