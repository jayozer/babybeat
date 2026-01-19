/**
 * Service for managing user preferences in IndexedDB
 */
import { db } from './db';
import type { UserPreferences } from '@/types';
import { DEFAULT_PREFERENCES } from '@/types';

const PREFS_ID = 'user_prefs';

/**
 * Get user preferences from IndexedDB
 * Returns default preferences if none are stored
 */
export async function getPreferences(): Promise<UserPreferences> {
  const stored = await db.prefs.get(PREFS_ID);
  if (!stored) {
    return { ...DEFAULT_PREFERENCES };
  }
  // Merge with defaults to handle any new fields (exclude id from result)
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const { id, ...prefs } = stored;
  return { ...DEFAULT_PREFERENCES, ...prefs };
}

/**
 * Save user preferences to IndexedDB
 */
export async function savePreferences(prefs: Partial<UserPreferences>): Promise<UserPreferences> {
  const current = await getPreferences();
  const updated = { ...current, ...prefs };
  await db.prefs.put({ id: PREFS_ID, ...updated });
  return updated;
}

/**
 * Update a single preference
 */
export async function updatePreference<K extends keyof UserPreferences>(
  key: K,
  value: UserPreferences[K]
): Promise<UserPreferences> {
  return savePreferences({ [key]: value });
}

/**
 * Reset preferences to defaults
 */
export async function resetPreferences(): Promise<UserPreferences> {
  await db.prefs.put({ id: PREFS_ID, ...DEFAULT_PREFERENCES });
  return { ...DEFAULT_PREFERENCES };
}
