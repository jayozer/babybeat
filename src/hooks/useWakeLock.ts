'use client';

import { useEffect, useRef, useState } from 'react';

/**
 * Hook to keep the screen awake using the Wake Lock API.
 * Falls back gracefully if the API is not supported.
 */
export function useWakeLock(enabled: boolean, shouldActivate: boolean) {
  const wakeLockRef = useRef<WakeLockSentinel | null>(null);
  const [isActive, setIsActive] = useState(false);

  useEffect(() => {
    // Don't do anything if disabled or shouldn't activate
    if (!enabled || !shouldActivate) {
      // Release any existing wake lock
      if (wakeLockRef.current) {
        wakeLockRef.current.release().catch(() => {});
        wakeLockRef.current = null;
        setIsActive(false);
      }
      return;
    }

    // Check if Wake Lock API is supported
    if (typeof navigator === 'undefined' || !('wakeLock' in navigator)) {
      console.debug('Wake Lock API not supported');
      return;
    }

    let isSubscribed = true;

    const requestWakeLock = async () => {
      try {
        // Release any existing lock first
        if (wakeLockRef.current) {
          await wakeLockRef.current.release();
        }

        const wakeLock = await navigator.wakeLock.request('screen');

        if (isSubscribed) {
          wakeLockRef.current = wakeLock;
          setIsActive(true);

          // Handle visibility change (lock is released when page is hidden)
          wakeLock.addEventListener('release', () => {
            if (isSubscribed) {
              setIsActive(false);
            }
          });
        } else {
          // Component unmounted, release the lock
          wakeLock.release();
        }
      } catch (error) {
        console.debug('Failed to acquire wake lock:', error);
        setIsActive(false);
      }
    };

    const handleVisibilityChange = () => {
      if (document.visibilityState === 'visible' && isSubscribed) {
        requestWakeLock();
      }
    };

    requestWakeLock();
    document.addEventListener('visibilitychange', handleVisibilityChange);

    return () => {
      isSubscribed = false;
      document.removeEventListener('visibilitychange', handleVisibilityChange);

      if (wakeLockRef.current) {
        wakeLockRef.current.release().catch(() => {});
        wakeLockRef.current = null;
      }
    };
  }, [enabled, shouldActivate]);

  return isActive;
}
