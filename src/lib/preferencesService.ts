/**
 * Service for managing user preferences in IndexedDB
 */
import { db } from './db';
import type { UserPreferences } from '@/types';
import { DEFAULT_PREFERENCES } from '@/types';

const PREFS_ID = 'user_prefs';

/**
 * Migrate old preferences format to new format
 * Handles conversion of soundEnabled boolean to soundOption
 */
function migratePreferences(stored: Record<string, unknown>): Partial<UserPreferences> {
  const migrated: Partial<UserPreferences> = { ...stored } as Partial<UserPreferences>;

  // Migrate soundEnabled (boolean) to soundOption (SoundOption)
  if ('soundEnabled' in stored && !('soundOption' in stored)) {
    const soundEnabled = stored.soundEnabled as boolean;
    migrated.soundOption = soundEnabled ? 'soft-click' : 'none';
    delete (migrated as Record<string, unknown>).soundEnabled;
  }

  return migrated;
}

/**
 * Get user preferences from IndexedDB
 * Returns default preferences if none are stored
 */
export async function getPreferences(): Promise<UserPreferences> {
  const stored = await db.prefs.get(PREFS_ID);
  if (!stored) {
    return { ...DEFAULT_PREFERENCES };
  }
  // Migrate old format if needed, then merge with defaults
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const { id, ...prefs } = stored;
  const migrated = migratePreferences(prefs as Record<string, unknown>);
  return { ...DEFAULT_PREFERENCES, ...migrated };
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
