'use client';

import { useEffect } from 'react';

/**
 * Hook to show a browser warning when the user tries to close the page
 * during an active session.
 */
export function useBeforeUnload(shouldWarn: boolean) {
  useEffect(() => {
    if (!shouldWarn) return;

    const handleBeforeUnload = (event: BeforeUnloadEvent) => {
      // Modern browsers require returnValue to be set
      event.preventDefault();
      // Legacy support - some browsers need returnValue
      event.returnValue = '';
      return '';
    };

    window.addEventListener('beforeunload', handleBeforeUnload);

    return () => {
      window.removeEventListener('beforeunload', handleBeforeUnload);
    };
  }, [shouldWarn]);
}
