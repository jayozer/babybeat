'use client';

import { SessionProvider } from '@/lib/SessionContext';
import { PreferencesProvider } from '@/lib/PreferencesContext';
import type { ReactNode } from 'react';

export function Providers({ children }: { children: ReactNode }) {
  return (
    <PreferencesProvider>
      <SessionProvider>{children}</SessionProvider>
    </PreferencesProvider>
  );
}
