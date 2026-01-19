// Session status types
export type SessionStatus =
  | 'idle'
  | 'active'
  | 'paused'
  | 'complete'
  | 'timeout'
  | 'ended_early';

// Kick event source types
export type KickSource = 'tap' | 'manual_edit';

// Strength rating type (1-5 scale)
export type StrengthRating = 1 | 2 | 3 | 4 | 5;

// Sound option types for tap feedback
export type SoundOption = 'soft-click' | 'pop' | 'heartbeat' | 'bubble' | 'none';

/**
 * Represents a kick counting session
 * A session tracks the user's attempt to count 10 fetal movements within 2 hours
 */
export interface KickSession {
  /** Unique identifier for the session */
  id: string;
  /** When the session record was created */
  createdAt: string;
  /** When counting actually started (first tap or explicit start) */
  startedAt: string | null;
  /** When the session ended (complete, timeout, or ended early) */
  endedAt: string | null;
  /** Current state of the session */
  status: SessionStatus;
  /** Target number of kicks (default 10) */
  targetCount: number;
  /** Time limit in seconds (default 7200 = 2 hours) */
  timeLimitSec: number;
  /** Current count of registered kicks */
  kickCount: number;
  /** Duration in seconds from start to end */
  durationSec: number | null;
  /** Optional strength rating (1-5) */
  strengthRating: StrengthRating | null;
  /** Optional notes added by the user */
  notes: string | null;
  /** User's timezone (IANA format if available) */
  timezone: string;
  /** Schema version for migrations */
  schemaVersion: number;
  /** Total time spent paused in seconds (for accurate elapsed time) */
  pausedDurationSec: number;
  /** When the session was last paused (null if not paused) */
  pausedAt: string | null;
}

/**
 * Represents a single kick/movement event within a session
 */
export interface KickEvent {
  /** Unique identifier for the event */
  id: string;
  /** Reference to the parent session */
  sessionId: string;
  /** When the kick was recorded */
  occurredAt: string;
  /** Order of this kick within the session (1-indexed) */
  ordinal: number;
  /** How the kick was recorded */
  source: KickSource;
}

/**
 * User preferences for the app
 */
export interface UserPreferences {
  /** Default target count for new sessions */
  defaultTargetCount: number;
  /** Default time limit for new sessions in seconds */
  defaultTimeLimitSec: number;
  /** Sound option for tap feedback */
  soundOption: SoundOption;
  /** Whether to vibrate on tap */
  vibrationEnabled: boolean;
  /** Whether to keep screen awake during active session */
  keepScreenAwake: boolean;
}

/**
 * Default values for user preferences
 */
export const DEFAULT_PREFERENCES: UserPreferences = {
  defaultTargetCount: 10,
  defaultTimeLimitSec: 7200, // 2 hours
  soundOption: 'soft-click',
  vibrationEnabled: true,
  keepScreenAwake: true,
};

/**
 * Default values for a new session
 */
export const DEFAULT_SESSION_VALUES = {
  targetCount: 10,
  timeLimitSec: 7200, // 2 hours
  schemaVersion: 1,
} as const;
