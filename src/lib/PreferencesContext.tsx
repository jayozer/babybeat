'use client';

import {
  createContext,
  useContext,
  useState,
  useEffect,
  useCallback,
  type ReactNode,
} from 'react';
import type { UserPreferences } from '@/types';
import { DEFAULT_PREFERENCES } from '@/types';
import { getPreferences, savePreferences } from './preferencesService';

interface PreferencesContextType {
  preferences: UserPreferences;
  isLoading: boolean;
  updatePreferences: (prefs: Partial<UserPreferences>) => Promise<void>;
}

const PreferencesContext = createContext<PreferencesContextType | null>(null);

export function PreferencesProvider({ children }: { children: ReactNode }) {
  const [preferences, setPreferences] = useState<UserPreferences>(DEFAULT_PREFERENCES);
  const [isLoading, setIsLoading] = useState(true);

  // Load preferences on mount
  useEffect(() => {
    async function loadPreferences() {
      try {
        const prefs = await getPreferences();
        setPreferences(prefs);
      } catch (error) {
        console.error('Failed to load preferences:', error);
      } finally {
        setIsLoading(false);
      }
    }
    loadPreferences();
  }, []);

  const updatePreferences = useCallback(async (prefs: Partial<UserPreferences>) => {
    try {
      const updated = await savePreferences(prefs);
      setPreferences(updated);
    } catch (error) {
      console.error('Failed to save preferences:', error);
      throw error;
    }
  }, []);

  return (
    <PreferencesContext.Provider value={{ preferences, isLoading, updatePreferences }}>
      {children}
    </PreferencesContext.Provider>
  );
}

export function usePreferences() {
  const context = useContext(PreferencesContext);
  if (!context) {
    throw new Error('usePreferences must be used within a PreferencesProvider');
  }
  return context;
}
