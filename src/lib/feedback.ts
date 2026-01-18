/**
 * Tap feedback utilities for sound and vibration
 */

let audioContext: AudioContext | null = null;

/**
 * Initialize the audio context (must be called after user interaction)
 */
export function initAudioContext(): void {
  if (typeof window === 'undefined') return;
  if (!audioContext) {
    audioContext = new (window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext)();
  }
}

/**
 * Play a short click sound using Web Audio API
 */
export function playClickSound(): void {
  if (typeof window === 'undefined') return;

  try {
    if (!audioContext) {
      initAudioContext();
    }

    if (!audioContext) return;

    // Resume if suspended (required after page becomes inactive)
    if (audioContext.state === 'suspended') {
      audioContext.resume();
    }

    // Create a short click oscillator
    const oscillator = audioContext.createOscillator();
    const gainNode = audioContext.createGain();

    oscillator.connect(gainNode);
    gainNode.connect(audioContext.destination);

    // Short, soft click sound
    oscillator.type = 'sine';
    oscillator.frequency.setValueAtTime(800, audioContext.currentTime);
    oscillator.frequency.exponentialRampToValueAtTime(400, audioContext.currentTime + 0.05);

    // Quick fade out
    gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
    gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.08);

    oscillator.start(audioContext.currentTime);
    oscillator.stop(audioContext.currentTime + 0.1);
  } catch (error) {
    // Silently fail if audio is not available
    console.debug('Audio feedback not available:', error);
  }
}

/**
 * Trigger haptic vibration if available
 */
export function vibrate(): void {
  if (typeof window === 'undefined') return;
  if (typeof navigator === 'undefined') return;

  try {
    if ('vibrate' in navigator) {
      // Short vibration pulse (50ms)
      navigator.vibrate(50);
    }
  } catch (error) {
    // Silently fail if vibration is not available
    console.debug('Vibration not available:', error);
  }
}

/**
 * Trigger tap feedback (sound and/or vibration based on preferences)
 */
export function triggerTapFeedback(options: {
  soundEnabled?: boolean;
  vibrationEnabled?: boolean;
} = {}): void {
  const { soundEnabled = true, vibrationEnabled = true } = options;

  if (soundEnabled) {
    playClickSound();
  }

  if (vibrationEnabled) {
    vibrate();
  }
}
