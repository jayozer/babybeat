/**
 * Tap feedback utilities for sound and vibration
 */

import type { SoundOption } from '@/types';

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
 * Play the soft click sound (original default)
 */
function playSoftClick(ctx: AudioContext): void {
  const oscillator = ctx.createOscillator();
  const gainNode = ctx.createGain();

  oscillator.connect(gainNode);
  gainNode.connect(ctx.destination);

  oscillator.type = 'sine';
  oscillator.frequency.setValueAtTime(800, ctx.currentTime);
  oscillator.frequency.exponentialRampToValueAtTime(400, ctx.currentTime + 0.05);

  gainNode.gain.setValueAtTime(0.3, ctx.currentTime);
  gainNode.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.08);

  oscillator.start(ctx.currentTime);
  oscillator.stop(ctx.currentTime + 0.1);
}

/**
 * Play a quick bright pop sound
 */
function playPop(ctx: AudioContext): void {
  const oscillator = ctx.createOscillator();
  const gainNode = ctx.createGain();

  oscillator.connect(gainNode);
  gainNode.connect(ctx.destination);

  oscillator.type = 'sine';
  oscillator.frequency.setValueAtTime(600, ctx.currentTime);
  oscillator.frequency.exponentialRampToValueAtTime(200, ctx.currentTime + 0.03);

  gainNode.gain.setValueAtTime(0.4, ctx.currentTime);
  gainNode.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.05);

  oscillator.start(ctx.currentTime);
  oscillator.stop(ctx.currentTime + 0.06);
}

/**
 * Play a warm heartbeat double thump
 */
function playHeartbeat(ctx: AudioContext): void {
  // First thump (louder)
  const osc1 = ctx.createOscillator();
  const gain1 = ctx.createGain();
  osc1.connect(gain1);
  gain1.connect(ctx.destination);

  osc1.type = 'sine';
  osc1.frequency.setValueAtTime(80, ctx.currentTime);
  osc1.frequency.exponentialRampToValueAtTime(60, ctx.currentTime + 0.08);

  gain1.gain.setValueAtTime(0.5, ctx.currentTime);
  gain1.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.1);

  osc1.start(ctx.currentTime);
  osc1.stop(ctx.currentTime + 0.12);

  // Second thump (softer, slightly delayed)
  const osc2 = ctx.createOscillator();
  const gain2 = ctx.createGain();
  osc2.connect(gain2);
  gain2.connect(ctx.destination);

  osc2.type = 'sine';
  osc2.frequency.setValueAtTime(70, ctx.currentTime + 0.12);
  osc2.frequency.exponentialRampToValueAtTime(50, ctx.currentTime + 0.2);

  gain2.gain.setValueAtTime(0, ctx.currentTime);
  gain2.gain.setValueAtTime(0.35, ctx.currentTime + 0.12);
  gain2.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.22);

  osc2.start(ctx.currentTime + 0.12);
  osc2.stop(ctx.currentTime + 0.25);
}

/**
 * Play a soft rising bubble sound
 */
function playBubble(ctx: AudioContext): void {
  const oscillator = ctx.createOscillator();
  const gainNode = ctx.createGain();

  oscillator.connect(gainNode);
  gainNode.connect(ctx.destination);

  oscillator.type = 'sine';
  oscillator.frequency.setValueAtTime(300, ctx.currentTime);
  oscillator.frequency.exponentialRampToValueAtTime(500, ctx.currentTime + 0.08);

  gainNode.gain.setValueAtTime(0.25, ctx.currentTime);
  gainNode.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.1);

  oscillator.start(ctx.currentTime);
  oscillator.stop(ctx.currentTime + 0.12);
}

/**
 * Play a sound based on the selected sound option
 */
export function playSound(option: SoundOption): void {
  if (typeof window === 'undefined') return;
  if (option === 'none') return;

  try {
    if (!audioContext) {
      initAudioContext();
    }

    if (!audioContext) return;

    // Resume if suspended (required after page becomes inactive)
    if (audioContext.state === 'suspended') {
      audioContext.resume();
    }

    switch (option) {
      case 'soft-click':
        playSoftClick(audioContext);
        break;
      case 'pop':
        playPop(audioContext);
        break;
      case 'heartbeat':
        playHeartbeat(audioContext);
        break;
      case 'bubble':
        playBubble(audioContext);
        break;
    }
  } catch (error) {
    // Silently fail if audio is not available
    console.debug('Audio feedback not available:', error);
  }
}

/**
 * Trigger haptic vibration if available
 * Note: navigator.vibrate() is NOT supported on iOS Safari.
 * Works on Android Chrome and some other mobile browsers.
 */
export function vibrate(): void {
  if (typeof window === 'undefined') return;
  if (typeof navigator === 'undefined') return;

  try {
    if ('vibrate' in navigator) {
      // Vibration pulse - 100ms is more noticeable than shorter durations
      navigator.vibrate(100);
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
  soundOption?: SoundOption;
  vibrationEnabled?: boolean;
} = {}): void {
  const { soundOption = 'soft-click', vibrationEnabled = true } = options;

  if (soundOption !== 'none') {
    playSound(soundOption);
  }

  if (vibrationEnabled) {
    vibrate();
  }
}
