'use client';

import {
  createContext,
  useContext,
  useReducer,
  useEffect,
  useCallback,
  type ReactNode,
} from 'react';
import type { KickSession, KickEvent } from '@/types';
import { createSession, getActiveSession, updateSession } from './sessionService';
import { registerKick, deleteLastKick, getKicksForSession } from './kickService';
import {
  startSession as startSessionMachine,
  pauseSession as pauseSessionMachine,
  resumeSession as resumeSessionMachine,
  endSessionEarly as endSessionEarlyMachine,
  completeSession as completeSessionMachine,
  timeoutSession as timeoutSessionMachine,
  checkTimeout,
  calculateElapsedSeconds,
  calculateRemainingSeconds,
} from './sessionStateMachine';

// State type
interface SessionState {
  session: KickSession | null;
  kicks: KickEvent[];
  isLoading: boolean;
  error: string | null;
}

// Action types
type SessionAction =
  | { type: 'SET_LOADING'; payload: boolean }
  | { type: 'SET_ERROR'; payload: string | null }
  | { type: 'SET_SESSION'; payload: KickSession | null }
  | { type: 'SET_KICKS'; payload: KickEvent[] }
  | { type: 'ADD_KICK'; payload: KickEvent }
  | { type: 'REMOVE_LAST_KICK' }
  | { type: 'RESET' };

// Reducer
function sessionReducer(state: SessionState, action: SessionAction): SessionState {
  switch (action.type) {
    case 'SET_LOADING':
      return { ...state, isLoading: action.payload };
    case 'SET_ERROR':
      return { ...state, error: action.payload };
    case 'SET_SESSION':
      return { ...state, session: action.payload };
    case 'SET_KICKS':
      return { ...state, kicks: action.payload };
    case 'ADD_KICK':
      return { ...state, kicks: [...state.kicks, action.payload] };
    case 'REMOVE_LAST_KICK':
      return { ...state, kicks: state.kicks.slice(0, -1) };
    case 'RESET':
      return { session: null, kicks: [], isLoading: false, error: null };
    default:
      return state;
  }
}

// Context type
interface SessionContextType {
  state: SessionState;
  // Actions
  startNewSession: () => Promise<void>;
  tap: () => Promise<void>;
  undo: () => Promise<void>;
  pause: () => Promise<void>;
  resume: () => Promise<void>;
  endEarly: () => Promise<void>;
  saveSessionDetails: (rating: number | null, notes: string) => Promise<void>;
  resetSession: () => void;
  // Computed values
  elapsedSeconds: number;
  remainingSeconds: number;
  isSessionActive: boolean;
  isPaused: boolean;
  kickCount: number;
  targetCount: number;
}

const SessionContext = createContext<SessionContextType | null>(null);

// Initial state
const initialState: SessionState = {
  session: null,
  kicks: [],
  isLoading: true,
  error: null,
};

// Provider component
export function SessionProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(sessionReducer, initialState);

  // Load active session on mount
  useEffect(() => {
    async function loadActiveSession() {
      try {
        const activeSession = await getActiveSession();
        if (activeSession) {
          dispatch({ type: 'SET_SESSION', payload: activeSession });
          const kicks = await getKicksForSession(activeSession.id);
          dispatch({ type: 'SET_KICKS', payload: kicks });
        }
      } catch (err) {
        dispatch({ type: 'SET_ERROR', payload: 'Failed to load session' });
        console.error(err);
      } finally {
        dispatch({ type: 'SET_LOADING', payload: false });
      }
    }
    loadActiveSession();
  }, []);

  // Check for timeout periodically
  useEffect(() => {
    if (!state.session || state.session.status !== 'active') return;

    const interval = setInterval(async () => {
      if (state.session && checkTimeout(state.session)) {
        try {
          const timedOut = await timeoutSessionMachine(state.session.id);
          dispatch({ type: 'SET_SESSION', payload: timedOut });
        } catch (err) {
          console.error('Failed to timeout session:', err);
        }
      }
    }, 1000);

    return () => clearInterval(interval);
  }, [state.session]);

  // Start a new session
  const startNewSession = useCallback(async () => {
    try {
      dispatch({ type: 'SET_LOADING', payload: true });
      const newSession = await createSession();
      dispatch({ type: 'SET_SESSION', payload: newSession });
      dispatch({ type: 'SET_KICKS', payload: [] });
    } catch (err) {
      dispatch({ type: 'SET_ERROR', payload: 'Failed to create session' });
      console.error(err);
    } finally {
      dispatch({ type: 'SET_LOADING', payload: false });
    }
  }, []);

  // Tap to register a kick
  const tap = useCallback(async () => {
    try {
      let session = state.session;

      // Create session if none exists
      if (!session) {
        session = await createSession();
        dispatch({ type: 'SET_SESSION', payload: session });
      }

      // Start session if idle
      if (session.status === 'idle') {
        session = await startSessionMachine(session.id);
        dispatch({ type: 'SET_SESSION', payload: session });
      }

      // Don't allow taps if not active
      if (session.status !== 'active') return;

      // Register the kick
      const kick = await registerKick(session.id);
      dispatch({ type: 'ADD_KICK', payload: kick });

      // Update session kick count
      const updatedSession = {
        ...session,
        kickCount: state.kicks.length + 1,
      };
      dispatch({ type: 'SET_SESSION', payload: updatedSession });

      // Check for auto-complete
      if (updatedSession.kickCount >= updatedSession.targetCount) {
        const completed = await completeSessionMachine(session.id);
        dispatch({ type: 'SET_SESSION', payload: completed });
      }
    } catch (err) {
      dispatch({ type: 'SET_ERROR', payload: 'Failed to register kick' });
      console.error(err);
    }
  }, [state.session, state.kicks.length]);

  // Undo last kick
  const undo = useCallback(async () => {
    if (!state.session || state.kicks.length === 0) return;

    try {
      await deleteLastKick(state.session.id);
      dispatch({ type: 'REMOVE_LAST_KICK' });

      // Update session kick count
      const updatedSession = {
        ...state.session,
        kickCount: state.kicks.length - 1,
      };
      dispatch({ type: 'SET_SESSION', payload: updatedSession });
    } catch (err) {
      dispatch({ type: 'SET_ERROR', payload: 'Failed to undo kick' });
      console.error(err);
    }
  }, [state.session, state.kicks.length]);

  // Pause session
  const pause = useCallback(async () => {
    if (!state.session || state.session.status !== 'active') return;

    try {
      const paused = await pauseSessionMachine(state.session.id);
      dispatch({ type: 'SET_SESSION', payload: paused });
    } catch (err) {
      dispatch({ type: 'SET_ERROR', payload: 'Failed to pause session' });
      console.error(err);
    }
  }, [state.session]);

  // Resume session
  const resume = useCallback(async () => {
    if (!state.session || state.session.status !== 'paused') return;

    try {
      const resumed = await resumeSessionMachine(state.session.id);
      dispatch({ type: 'SET_SESSION', payload: resumed });
    } catch (err) {
      dispatch({ type: 'SET_ERROR', payload: 'Failed to resume session' });
      console.error(err);
    }
  }, [state.session]);

  // End session early
  const endEarly = useCallback(async () => {
    if (!state.session) return;
    if (state.session.status !== 'active' && state.session.status !== 'paused')
      return;

    try {
      const ended = await endSessionEarlyMachine(state.session.id);
      dispatch({ type: 'SET_SESSION', payload: ended });
    } catch (err) {
      dispatch({ type: 'SET_ERROR', payload: 'Failed to end session' });
      console.error(err);
    }
  }, [state.session]);

  // Save session details (rating and notes)
  const saveSessionDetails = useCallback(
    async (rating: number | null, notes: string) => {
      if (!state.session) return;

      try {
        await updateSession(state.session.id, {
          strengthRating: rating as 1 | 2 | 3 | 4 | 5 | null,
          notes: notes || null,
        });
        dispatch({
          type: 'SET_SESSION',
          payload: {
            ...state.session,
            strengthRating: rating as 1 | 2 | 3 | 4 | 5 | null,
            notes: notes || null,
          },
        });
      } catch (err) {
        dispatch({ type: 'SET_ERROR', payload: 'Failed to save session details' });
        console.error(err);
      }
    },
    [state.session]
  );

  // Reset session state
  const resetSession = useCallback(() => {
    dispatch({ type: 'RESET' });
  }, []);

  // Computed values
  const elapsedSeconds = state.session
    ? calculateElapsedSeconds(state.session)
    : 0;

  const remainingSeconds = state.session
    ? calculateRemainingSeconds(state.session)
    : 7200;

  const isSessionActive =
    state.session?.status === 'active' || state.session?.status === 'paused';

  const isPaused = state.session?.status === 'paused';

  const kickCount = state.kicks.length;

  const targetCount = state.session?.targetCount ?? 10;

  const value: SessionContextType = {
    state,
    startNewSession,
    tap,
    undo,
    pause,
    resume,
    endEarly,
    saveSessionDetails,
    resetSession,
    elapsedSeconds,
    remainingSeconds,
    isSessionActive,
    isPaused,
    kickCount,
    targetCount,
  };

  return (
    <SessionContext.Provider value={value}>{children}</SessionContext.Provider>
  );
}

// Hook to use the context
export function useSession() {
  const context = useContext(SessionContext);
  if (!context) {
    throw new Error('useSession must be used within a SessionProvider');
  }
  return context;
}
