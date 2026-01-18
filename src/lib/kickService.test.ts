import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import 'fake-indexeddb/auto';
import { db } from './db';
import { createSession, getSession } from './sessionService';
import {
  registerKick,
  getKicksForSession,
  deleteLastKick,
  getKickCount,
  calculateKickIntervals,
} from './kickService';
import type { KickEvent } from '@/types';

describe('kickService', () => {
  beforeEach(async () => {
    await db.sessions.clear();
    await db.events.clear();
  });

  afterEach(async () => {
    await db.sessions.clear();
    await db.events.clear();
  });

  describe('registerKick', () => {
    it('creates a kick event with correct ordinal', async () => {
      const session = await createSession();
      const kick = await registerKick(session.id);

      expect(kick.id).toBeDefined();
      expect(kick.sessionId).toBe(session.id);
      expect(kick.ordinal).toBe(1);
      expect(kick.source).toBe('tap');
      expect(kick.occurredAt).toBeDefined();
    });

    it('increments ordinal for subsequent kicks', async () => {
      const session = await createSession();

      const kick1 = await registerKick(session.id);
      const kick2 = await registerKick(session.id);
      const kick3 = await registerKick(session.id);

      expect(kick1.ordinal).toBe(1);
      expect(kick2.ordinal).toBe(2);
      expect(kick3.ordinal).toBe(3);
    });

    it('updates session kickCount', async () => {
      const session = await createSession();

      await registerKick(session.id);
      await registerKick(session.id);
      await registerKick(session.id);

      const updated = await getSession(session.id);
      expect(updated?.kickCount).toBe(3);
    });

    it('writes to IndexedDB immediately', async () => {
      const session = await createSession();
      const kick = await registerKick(session.id);

      const stored = await db.events.get(kick.id);
      expect(stored).toBeDefined();
      expect(stored?.id).toBe(kick.id);
    });

    it('allows specifying source type', async () => {
      const session = await createSession();
      const kick = await registerKick(session.id, 'manual_edit');

      expect(kick.source).toBe('manual_edit');
    });
  });

  describe('getKicksForSession', () => {
    it('returns all kicks ordered by ordinal', async () => {
      const session = await createSession();

      await registerKick(session.id);
      await registerKick(session.id);
      await registerKick(session.id);

      const kicks = await getKicksForSession(session.id);

      expect(kicks).toHaveLength(3);
      expect(kicks[0].ordinal).toBe(1);
      expect(kicks[1].ordinal).toBe(2);
      expect(kicks[2].ordinal).toBe(3);
    });

    it('returns empty array for session with no kicks', async () => {
      const session = await createSession();
      const kicks = await getKicksForSession(session.id);

      expect(kicks).toHaveLength(0);
    });

    it('only returns kicks for the specified session', async () => {
      const session1 = await createSession();
      const session2 = await createSession();

      await registerKick(session1.id);
      await registerKick(session1.id);
      await registerKick(session2.id);

      const kicks1 = await getKicksForSession(session1.id);
      const kicks2 = await getKicksForSession(session2.id);

      expect(kicks1).toHaveLength(2);
      expect(kicks2).toHaveLength(1);
    });
  });

  describe('deleteLastKick', () => {
    it('removes the most recent kick', async () => {
      const session = await createSession();

      await registerKick(session.id);
      await registerKick(session.id);
      const kick3 = await registerKick(session.id);

      const deleted = await deleteLastKick(session.id);

      expect(deleted?.id).toBe(kick3.id);

      const remaining = await getKicksForSession(session.id);
      expect(remaining).toHaveLength(2);
    });

    it('updates session kickCount', async () => {
      const session = await createSession();

      await registerKick(session.id);
      await registerKick(session.id);
      await registerKick(session.id);

      await deleteLastKick(session.id);

      const updated = await getSession(session.id);
      expect(updated?.kickCount).toBe(2);
    });

    it('returns undefined when no kicks exist', async () => {
      const session = await createSession();
      const result = await deleteLastKick(session.id);

      expect(result).toBeUndefined();
    });

    it('can delete all kicks one by one', async () => {
      const session = await createSession();

      await registerKick(session.id);
      await registerKick(session.id);

      await deleteLastKick(session.id);
      await deleteLastKick(session.id);
      const result = await deleteLastKick(session.id);

      expect(result).toBeUndefined();

      const kicks = await getKicksForSession(session.id);
      expect(kicks).toHaveLength(0);

      const updated = await getSession(session.id);
      expect(updated?.kickCount).toBe(0);
    });
  });

  describe('getKickCount', () => {
    it('returns the correct count', async () => {
      const session = await createSession();

      expect(await getKickCount(session.id)).toBe(0);

      await registerKick(session.id);
      expect(await getKickCount(session.id)).toBe(1);

      await registerKick(session.id);
      await registerKick(session.id);
      expect(await getKickCount(session.id)).toBe(3);
    });
  });

  describe('calculateKickIntervals', () => {
    it('returns empty array for single kick', () => {
      const kicks: KickEvent[] = [
        {
          id: '1',
          sessionId: 'session-1',
          occurredAt: '2024-01-01T10:00:00.000Z',
          ordinal: 1,
          source: 'tap',
        },
      ];

      const intervals = calculateKickIntervals(kicks);
      expect(intervals).toHaveLength(0);
    });

    it('returns empty array for no kicks', () => {
      const intervals = calculateKickIntervals([]);
      expect(intervals).toHaveLength(0);
    });

    it('calculates intervals correctly', () => {
      const kicks: KickEvent[] = [
        {
          id: '1',
          sessionId: 'session-1',
          occurredAt: '2024-01-01T10:00:00.000Z',
          ordinal: 1,
          source: 'tap',
        },
        {
          id: '2',
          sessionId: 'session-1',
          occurredAt: '2024-01-01T10:00:30.000Z',
          ordinal: 2,
          source: 'tap',
        },
        {
          id: '3',
          sessionId: 'session-1',
          occurredAt: '2024-01-01T10:01:15.000Z',
          ordinal: 3,
          source: 'tap',
        },
      ];

      const intervals = calculateKickIntervals(kicks);

      expect(intervals).toHaveLength(2);
      expect(intervals[0]).toBe(30); // 30 seconds
      expect(intervals[1]).toBe(45); // 45 seconds
    });
  });
});
