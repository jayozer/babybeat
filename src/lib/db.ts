import Dexie, { type EntityTable } from 'dexie';
import type { KickSession, KickEvent, UserPreferences } from '@/types';

/**
 * BabyBeat IndexedDB database using Dexie
 *
 * Tables:
 * - sessions: Stores kick counting sessions
 * - events: Stores individual kick events within sessions
 * - prefs: Stores user preferences (single record with key 'prefs')
 */
class BabyBeatDatabase extends Dexie {
  sessions!: EntityTable<KickSession, 'id'>;
  events!: EntityTable<KickEvent, 'id'>;
  prefs!: EntityTable<UserPreferences & { id: string }, 'id'>;

  constructor() {
    super('BabyBeatDB');

    // Schema version 1
    this.version(1).stores({
      // Sessions table with indexes for common queries
      sessions: 'id, createdAt, startedAt, status',
      // Events table with indexes for session lookup and ordering
      events: 'id, sessionId, occurredAt',
      // Preferences table (single record)
      prefs: 'id',
    });
  }
}

// Create and export the database instance
export const db = new BabyBeatDatabase();

// Export the database class for testing purposes
export { BabyBeatDatabase };
