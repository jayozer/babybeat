import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import 'fake-indexeddb/auto';
import { db } from './db';
import { createSession, getSession, updateSession } from './sessionService';
import { registerKick } from './kickService';
import {
  startSession,
  pauseSession,
  resumeSession,
  endSessionEarly,
  completeSession,
  timeoutSession,
  checkAutoComplete,
  checkTimeout,
  calculateElapsedSeconds,
  calculateRemainingSeconds,
  getValidTransitions,
} from './sessionStateMachine';
import type { KickSession } from '@/types';

describe('sessionStateMachine', () => {
  beforeEach(async () => {
    await db.sessions.clear();
    await db.events.clear();
  });

  afterEach(async () => {
    await db.sessions.clear();
    await db.events.clear();
  });

  describe('startSession', () => {
    it('transitions from idle to active', async () => {
      const session = await createSession();
      const started = await startSession(session.id);

      expect(started.status).toBe('active');
      expect(started.startedAt).toBeDefined();
    });

    it('persists the state change', async () => {
      const session = await createSession();
      await startSession(session.id);

      const retrieved = await getSession(session.id);
      expect(retrieved?.status).toBe('active');
    });

    it('throws error for non-idle session', async () => {
      const session = await createSession({ status: 'active' });

      await expect(startSession(session.id)).rejects.toThrow(
        'Cannot start session in status: active'
      );
    });

    it('throws error for non-existent session', async () => {
      await expect(startSession('non-existent')).rejects.toThrow(
        'Session not found'
      );
    });
  });

  describe('pauseSession', () => {
    it('transitions from active to paused', async () => {
      const session = await createSession();
      await startSession(session.id);
      const paused = await pauseSession(session.id);

      expect(paused.status).toBe('paused');
      expect(paused.pausedAt).toBeDefined();
    });

    it('throws error for non-active session', async () => {
      const session = await createSession();

      await expect(pauseSession(session.id)).rejects.toThrow(
        'Cannot pause session in status: idle'
      );
    });
  });

  describe('resumeSession', () => {
    it('transitions from paused to active', async () => {
      const session = await createSession();
      await startSession(session.id);
      await pauseSession(session.id);

      // Wait a bit to accumulate paused time
      await new Promise((r) => setTimeout(r, 50));

      const resumed = await resumeSession(session.id);

      expect(resumed.status).toBe('active');
      expect(resumed.pausedAt).toBeNull();
      expect(resumed.pausedDurationSec).toBeGreaterThan(0);
    });

    it('throws error for non-paused session', async () => {
      const session = await createSession();
      await startSession(session.id);

      await expect(resumeSession(session.id)).rejects.toThrow(
        'Cannot resume session in status: active'
      );
    });
  });

  describe('endSessionEarly', () => {
    it('transitions from active to ended_early', async () => {
      const session = await createSession();
      await startSession(session.id);
      const ended = await endSessionEarly(session.id);

      expect(ended.status).toBe('ended_early');
      expect(ended.endedAt).toBeDefined();
      expect(ended.durationSec).toBeDefined();
    });

    it('can end a paused session', async () => {
      const session = await createSession();
      await startSession(session.id);
      await pauseSession(session.id);
      const ended = await endSessionEarly(session.id);

      expect(ended.status).toBe('ended_early');
    });

    it('throws error for idle session', async () => {
      const session = await createSession();

      await expect(endSessionEarly(session.id)).rejects.toThrow(
        'Cannot end session in status: idle'
      );
    });
  });

  describe('completeSession', () => {
    it('transitions from active to complete', async () => {
      const session = await createSession();
      await startSession(session.id);
      const completed = await completeSession(session.id);

      expect(completed.status).toBe('complete');
      expect(completed.endedAt).toBeDefined();
      expect(completed.durationSec).toBeDefined();
    });

    it('throws error for non-active session', async () => {
      const session = await createSession();

      await expect(completeSession(session.id)).rejects.toThrow(
        'Cannot complete session in status: idle'
      );
    });
  });

  describe('timeoutSession', () => {
    it('transitions from active to timeout', async () => {
      const session = await createSession();
      await startSession(session.id);
      const timedOut = await timeoutSession(session.id);

      expect(timedOut.status).toBe('timeout');
      expect(timedOut.endedAt).toBeDefined();
    });

    it('throws error for non-active session', async () => {
      const session = await createSession();

      await expect(timeoutSession(session.id)).rejects.toThrow(
        'Cannot timeout session in status: idle'
      );
    });
  });

  describe('checkAutoComplete', () => {
    it('returns true when kick count reaches target', async () => {
      const session = await createSession({ targetCount: 3 });
      await updateSession(session.id, {
        status: 'active',
        startedAt: new Date().toISOString(),
      });

      await registerKick(session.id);
      await registerKick(session.id);
      await registerKick(session.id);

      const shouldComplete = await checkAutoComplete(session.id);
      expect(shouldComplete).toBe(true);
    });

    it('returns false when below target', async () => {
      const session = await createSession({ targetCount: 10 });
      await updateSession(session.id, {
        status: 'active',
        startedAt: new Date().toISOString(),
      });

      await registerKick(session.id);
      await registerKick(session.id);

      const shouldComplete = await checkAutoComplete(session.id);
      expect(shouldComplete).toBe(false);
    });

    it('returns false for non-active session', async () => {
      const session = await createSession();

      const shouldComplete = await checkAutoComplete(session.id);
      expect(shouldComplete).toBe(false);
    });
  });

  describe('checkTimeout', () => {
    it('returns true when elapsed exceeds time limit', () => {
      const startedAt = new Date(Date.now() - 8000 * 1000).toISOString(); // 8000 seconds ago
      const session: KickSession = {
        id: 'test',
        createdAt: startedAt,
        startedAt,
        endedAt: null,
        status: 'active',
        targetCount: 10,
        timeLimitSec: 7200, // 2 hours
        kickCount: 0,
        durationSec: null,
        strengthRating: null,
        notes: null,
        timezone: 'UTC',
        schemaVersion: 1,
        pausedDurationSec: 0,
        pausedAt: null,
      };

      expect(checkTimeout(session)).toBe(true);
    });

    it('returns false when within time limit', () => {
      const startedAt = new Date(Date.now() - 3600 * 1000).toISOString(); // 1 hour ago
      const session: KickSession = {
        id: 'test',
        createdAt: startedAt,
        startedAt,
        endedAt: null,
        status: 'active',
        targetCount: 10,
        timeLimitSec: 7200,
        kickCount: 0,
        durationSec: null,
        strengthRating: null,
        notes: null,
        timezone: 'UTC',
        schemaVersion: 1,
        pausedDurationSec: 0,
        pausedAt: null,
      };

      expect(checkTimeout(session)).toBe(false);
    });

    it('returns false for non-active session', () => {
      const session: KickSession = {
        id: 'test',
        createdAt: new Date().toISOString(),
        startedAt: null,
        endedAt: null,
        status: 'idle',
        targetCount: 10,
        timeLimitSec: 7200,
        kickCount: 0,
        durationSec: null,
        strengthRating: null,
        notes: null,
        timezone: 'UTC',
        schemaVersion: 1,
        pausedDurationSec: 0,
        pausedAt: null,
      };

      expect(checkTimeout(session)).toBe(false);
    });
  });

  describe('calculateElapsedSeconds', () => {
    it('calculates elapsed time correctly', () => {
      const startedAt = new Date(Date.now() - 1800 * 1000).toISOString(); // 30 min ago
      const session: KickSession = {
        id: 'test',
        createdAt: startedAt,
        startedAt,
        endedAt: null,
        status: 'active',
        targetCount: 10,
        timeLimitSec: 7200,
        kickCount: 0,
        durationSec: null,
        strengthRating: null,
        notes: null,
        timezone: 'UTC',
        schemaVersion: 1,
        pausedDurationSec: 0,
        pausedAt: null,
      };

      const elapsed = calculateElapsedSeconds(session);
      expect(elapsed).toBeCloseTo(1800, -1); // Within 10 seconds
    });

    it('accounts for paused duration', () => {
      const startedAt = new Date(Date.now() - 1800 * 1000).toISOString(); // 30 min ago
      const session: KickSession = {
        id: 'test',
        createdAt: startedAt,
        startedAt,
        endedAt: null,
        status: 'active',
        targetCount: 10,
        timeLimitSec: 7200,
        kickCount: 0,
        durationSec: null,
        strengthRating: null,
        notes: null,
        timezone: 'UTC',
        schemaVersion: 1,
        pausedDurationSec: 600, // 10 minutes paused
        pausedAt: null,
      };

      const elapsed = calculateElapsedSeconds(session);
      // 30 min - 10 min paused = 20 min
      expect(elapsed).toBeCloseTo(1200, -1);
    });

    it('returns 0 for session without startedAt', () => {
      const session: KickSession = {
        id: 'test',
        createdAt: new Date().toISOString(),
        startedAt: null,
        endedAt: null,
        status: 'idle',
        targetCount: 10,
        timeLimitSec: 7200,
        kickCount: 0,
        durationSec: null,
        strengthRating: null,
        notes: null,
        timezone: 'UTC',
        schemaVersion: 1,
        pausedDurationSec: 0,
        pausedAt: null,
      };

      const elapsed = calculateElapsedSeconds(session);
      expect(elapsed).toBe(0);
    });
  });

  describe('calculateRemainingSeconds', () => {
    it('calculates remaining time correctly', () => {
      const startedAt = new Date(Date.now() - 1800 * 1000).toISOString(); // 30 min ago
      const session: KickSession = {
        id: 'test',
        createdAt: startedAt,
        startedAt,
        endedAt: null,
        status: 'active',
        targetCount: 10,
        timeLimitSec: 7200, // 2 hours
        kickCount: 0,
        durationSec: null,
        strengthRating: null,
        notes: null,
        timezone: 'UTC',
        schemaVersion: 1,
        pausedDurationSec: 0,
        pausedAt: null,
      };

      const remaining = calculateRemainingSeconds(session);
      // 2 hours - 30 min = 1.5 hours = 5400 seconds
      expect(remaining).toBeCloseTo(5400, -1);
    });

    it('returns 0 when time is up', () => {
      const startedAt = new Date(Date.now() - 8000 * 1000).toISOString(); // 8000 sec ago
      const session: KickSession = {
        id: 'test',
        createdAt: startedAt,
        startedAt,
        endedAt: null,
        status: 'active',
        targetCount: 10,
        timeLimitSec: 7200,
        kickCount: 0,
        durationSec: null,
        strengthRating: null,
        notes: null,
        timezone: 'UTC',
        schemaVersion: 1,
        pausedDurationSec: 0,
        pausedAt: null,
      };

      const remaining = calculateRemainingSeconds(session);
      expect(remaining).toBe(0);
    });
  });

  describe('getValidTransitions', () => {
    it('returns correct transitions for idle', () => {
      expect(getValidTransitions('idle')).toEqual(['active']);
    });

    it('returns correct transitions for active', () => {
      expect(getValidTransitions('active')).toEqual([
        'paused',
        'complete',
        'timeout',
        'ended_early',
      ]);
    });

    it('returns correct transitions for paused', () => {
      expect(getValidTransitions('paused')).toEqual(['active', 'ended_early']);
    });

    it('returns empty array for terminal states', () => {
      expect(getValidTransitions('complete')).toEqual([]);
      expect(getValidTransitions('timeout')).toEqual([]);
      expect(getValidTransitions('ended_early')).toEqual([]);
    });
  });
});
