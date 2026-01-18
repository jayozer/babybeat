import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import 'fake-indexeddb/auto';
import { db } from './db';
import {
  createSession,
  getSession,
  updateSession,
  getAllSessions,
  getSessionsByDate,
  getActiveSession,
  deleteSession,
} from './sessionService';

describe('sessionService', () => {
  beforeEach(async () => {
    // Clear all tables before each test
    await db.sessions.clear();
    await db.events.clear();
  });

  afterEach(async () => {
    await db.sessions.clear();
    await db.events.clear();
  });

  describe('createSession', () => {
    it('creates a session with default values', async () => {
      const session = await createSession();

      expect(session.id).toBeDefined();
      expect(session.status).toBe('idle');
      expect(session.targetCount).toBe(10);
      expect(session.timeLimitSec).toBe(7200);
      expect(session.kickCount).toBe(0);
      expect(session.startedAt).toBeNull();
      expect(session.endedAt).toBeNull();
      expect(session.schemaVersion).toBe(1);
    });

    it('allows overriding default values', async () => {
      const session = await createSession({
        targetCount: 5,
        timeLimitSec: 3600,
      });

      expect(session.targetCount).toBe(5);
      expect(session.timeLimitSec).toBe(3600);
    });

    it('persists the session to the database', async () => {
      const session = await createSession();
      const retrieved = await db.sessions.get(session.id);

      expect(retrieved).toBeDefined();
      expect(retrieved?.id).toBe(session.id);
    });
  });

  describe('getSession', () => {
    it('retrieves a session by ID', async () => {
      const created = await createSession();
      const retrieved = await getSession(created.id);

      expect(retrieved).toBeDefined();
      expect(retrieved?.id).toBe(created.id);
    });

    it('returns undefined for non-existent session', async () => {
      const result = await getSession('non-existent-id');
      expect(result).toBeUndefined();
    });
  });

  describe('updateSession', () => {
    it('updates session fields', async () => {
      const session = await createSession();
      await updateSession(session.id, {
        status: 'active',
        startedAt: new Date().toISOString(),
        kickCount: 5,
      });

      const updated = await getSession(session.id);
      expect(updated?.status).toBe('active');
      expect(updated?.kickCount).toBe(5);
      expect(updated?.startedAt).toBeDefined();
    });
  });

  describe('getAllSessions', () => {
    it('returns all sessions ordered by createdAt descending', async () => {
      // Create sessions with small delays to ensure different timestamps
      const session1 = await createSession();
      await new Promise((r) => setTimeout(r, 10));
      const session2 = await createSession();
      await new Promise((r) => setTimeout(r, 10));
      const session3 = await createSession();

      const sessions = await getAllSessions();

      expect(sessions).toHaveLength(3);
      expect(sessions[0].id).toBe(session3.id);
      expect(sessions[1].id).toBe(session2.id);
      expect(sessions[2].id).toBe(session1.id);
    });

    it('returns empty array when no sessions exist', async () => {
      const sessions = await getAllSessions();
      expect(sessions).toHaveLength(0);
    });
  });

  describe('getSessionsByDate', () => {
    it('returns sessions for a specific date', async () => {
      const today = new Date();
      const session1 = await createSession();
      const session2 = await createSession();

      const sessions = await getSessionsByDate(today);

      expect(sessions).toHaveLength(2);
      expect(sessions.map((s) => s.id)).toContain(session1.id);
      expect(sessions.map((s) => s.id)).toContain(session2.id);
    });

    it('returns empty array for date with no sessions', async () => {
      await createSession();
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);

      const sessions = await getSessionsByDate(yesterday);
      expect(sessions).toHaveLength(0);
    });
  });

  describe('getActiveSession', () => {
    it('returns the active session', async () => {
      await createSession();
      const activeSession = await createSession({ status: 'active' });
      await createSession({ status: 'complete' });

      const result = await getActiveSession();

      expect(result).toBeDefined();
      expect(result?.id).toBe(activeSession.id);
    });

    it('returns the paused session', async () => {
      await createSession();
      const pausedSession = await createSession({ status: 'paused' });

      const result = await getActiveSession();

      expect(result).toBeDefined();
      expect(result?.id).toBe(pausedSession.id);
    });

    it('returns undefined when no active session', async () => {
      await createSession({ status: 'complete' });
      await createSession({ status: 'timeout' });

      const result = await getActiveSession();
      expect(result).toBeUndefined();
    });
  });

  describe('deleteSession', () => {
    it('deletes the session', async () => {
      const session = await createSession();
      await deleteSession(session.id);

      const result = await getSession(session.id);
      expect(result).toBeUndefined();
    });

    it('deletes associated kick events', async () => {
      const session = await createSession();
      await db.events.add({
        id: 'event-1',
        sessionId: session.id,
        occurredAt: new Date().toISOString(),
        ordinal: 1,
        source: 'tap',
      });

      await deleteSession(session.id);

      const events = await db.events
        .where('sessionId')
        .equals(session.id)
        .toArray();
      expect(events).toHaveLength(0);
    });
  });
});
