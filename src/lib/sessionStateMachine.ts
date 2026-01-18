import { getSession, updateSession } from './sessionService';
import { getKickCount } from './kickService';
import type { KickSession, SessionStatus } from '@/types';

/**
 * Starts a session, transitioning from idle to active
 */
export async function startSession(sessionId: string): Promise<KickSession> {
  const session = await getSession(sessionId);

  if (!session) {
    throw new Error(`Session not found: ${sessionId}`);
  }

  if (session.status !== 'idle') {
    throw new Error(`Cannot start session in status: ${session.status}`);
  }

  const now = new Date().toISOString();

  await updateSession(sessionId, {
    status: 'active',
    startedAt: now,
  });

  return { ...session, status: 'active', startedAt: now };
}

/**
 * Pauses an active session
 */
export async function pauseSession(sessionId: string): Promise<KickSession> {
  const session = await getSession(sessionId);

  if (!session) {
    throw new Error(`Session not found: ${sessionId}`);
  }

  if (session.status !== 'active') {
    throw new Error(`Cannot pause session in status: ${session.status}`);
  }

  const now = new Date().toISOString();

  await updateSession(sessionId, {
    status: 'paused',
    pausedAt: now,
  });

  return { ...session, status: 'paused', pausedAt: now };
}

/**
 * Resumes a paused session
 */
export async function resumeSession(sessionId: string): Promise<KickSession> {
  const session = await getSession(sessionId);

  if (!session) {
    throw new Error(`Session not found: ${sessionId}`);
  }

  if (session.status !== 'paused') {
    throw new Error(`Cannot resume session in status: ${session.status}`);
  }

  if (!session.pausedAt) {
    throw new Error('Session has no pausedAt timestamp');
  }

  // Calculate additional paused duration
  const pausedAt = new Date(session.pausedAt).getTime();
  const now = Date.now();
  const additionalPausedTime = (now - pausedAt) / 1000;
  const newPausedDuration = session.pausedDurationSec + additionalPausedTime;

  await updateSession(sessionId, {
    status: 'active',
    pausedAt: null,
    pausedDurationSec: newPausedDuration,
  });

  return {
    ...session,
    status: 'active',
    pausedAt: null,
    pausedDurationSec: newPausedDuration,
  };
}

/**
 * Ends a session early (before reaching target or timeout)
 */
export async function endSessionEarly(sessionId: string): Promise<KickSession> {
  const session = await getSession(sessionId);

  if (!session) {
    throw new Error(`Session not found: ${sessionId}`);
  }

  if (session.status !== 'active' && session.status !== 'paused') {
    throw new Error(`Cannot end session in status: ${session.status}`);
  }

  const now = new Date().toISOString();
  const durationSec = calculateDuration(session, now);

  await updateSession(sessionId, {
    status: 'ended_early',
    endedAt: now,
    durationSec,
  });

  return { ...session, status: 'ended_early', endedAt: now, durationSec };
}

/**
 * Completes a session when target count is reached
 */
export async function completeSession(sessionId: string): Promise<KickSession> {
  const session = await getSession(sessionId);

  if (!session) {
    throw new Error(`Session not found: ${sessionId}`);
  }

  if (session.status !== 'active') {
    throw new Error(`Cannot complete session in status: ${session.status}`);
  }

  const now = new Date().toISOString();
  const durationSec = calculateDuration(session, now);

  await updateSession(sessionId, {
    status: 'complete',
    endedAt: now,
    durationSec,
  });

  return { ...session, status: 'complete', endedAt: now, durationSec };
}

/**
 * Times out a session when time limit is reached
 */
export async function timeoutSession(sessionId: string): Promise<KickSession> {
  const session = await getSession(sessionId);

  if (!session) {
    throw new Error(`Session not found: ${sessionId}`);
  }

  if (session.status !== 'active') {
    throw new Error(`Cannot timeout session in status: ${session.status}`);
  }

  const now = new Date().toISOString();
  const durationSec = calculateDuration(session, now);

  await updateSession(sessionId, {
    status: 'timeout',
    endedAt: now,
    durationSec,
  });

  return { ...session, status: 'timeout', endedAt: now, durationSec };
}

/**
 * Checks if a session should auto-complete (reached target count)
 */
export async function checkAutoComplete(
  sessionId: string
): Promise<boolean> {
  const session = await getSession(sessionId);

  if (!session || session.status !== 'active') {
    return false;
  }

  const kickCount = await getKickCount(sessionId);
  return kickCount >= session.targetCount;
}

/**
 * Checks if a session should timeout (elapsed time >= time limit)
 */
export function checkTimeout(session: KickSession): boolean {
  if (session.status !== 'active' || !session.startedAt) {
    return false;
  }

  const elapsed = calculateElapsedSeconds(session);
  return elapsed >= session.timeLimitSec;
}

/**
 * Calculates elapsed seconds for a session, accounting for paused time
 */
export function calculateElapsedSeconds(session: KickSession): number {
  if (!session.startedAt) {
    return 0;
  }

  const startedAt = new Date(session.startedAt).getTime();
  const now = Date.now();
  let elapsed = (now - startedAt) / 1000;

  // Subtract paused duration
  elapsed -= session.pausedDurationSec;

  // If currently paused, also subtract time since paused
  if (session.status === 'paused' && session.pausedAt) {
    const pausedAt = new Date(session.pausedAt).getTime();
    elapsed -= (now - pausedAt) / 1000;
  }

  return Math.max(0, elapsed);
}

/**
 * Calculates remaining seconds for a session
 */
export function calculateRemainingSeconds(session: KickSession): number {
  const elapsed = calculateElapsedSeconds(session);
  return Math.max(0, session.timeLimitSec - elapsed);
}

/**
 * Helper to calculate duration from start to end
 */
function calculateDuration(session: KickSession, endTime: string): number {
  if (!session.startedAt) {
    return 0;
  }

  const startedAt = new Date(session.startedAt).getTime();
  const endedAt = new Date(endTime).getTime();
  let duration = (endedAt - startedAt) / 1000;

  // Subtract paused duration
  duration -= session.pausedDurationSec;

  // If currently paused, also calculate additional paused time
  if (session.status === 'paused' && session.pausedAt) {
    const pausedAt = new Date(session.pausedAt).getTime();
    duration -= (endedAt - pausedAt) / 1000;
  }

  return Math.max(0, duration);
}

/**
 * Returns valid next states from the current status
 */
export function getValidTransitions(
  status: SessionStatus
): SessionStatus[] {
  switch (status) {
    case 'idle':
      return ['active'];
    case 'active':
      return ['paused', 'complete', 'timeout', 'ended_early'];
    case 'paused':
      return ['active', 'ended_early'];
    case 'complete':
    case 'timeout':
    case 'ended_early':
      return []; // Terminal states
    default:
      return [];
  }
}
