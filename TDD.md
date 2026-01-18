# TDD (Web App) - Detailed Technical Design

## 1. Proposed architecture (MVP: offline-first, minimal backend)

### Recommendation for MVP

- Frontend-only PWA (no required login).
- Store all data locally in IndexedDB.
- Optional lightweight analytics (privacy-preserving) can be added later.

### Why

- Counting must work instantly and reliably even with poor connectivity.
- Avoids handling sensitive health-related data on servers in v1.

### Stack

- Next.js (TypeScript, React) for UI + routing.
- PWA: service worker + offline caching.
- IndexedDB wrapper: Dexie.js.
- Date utilities: date-fns.
- Testing: Vitest/Jest + React Testing Library + Playwright.

If you do want accounts/sync later, add a backend API + DB (Postgres) and keep the same domain model (see "Phase 2: Sync" below).

## 2. Domain model & data design

### 2.1 Entities

#### KickSession

- `id`: uuid
- `createdAt`: ISO string
- `startedAt`: ISO string | null
- `endedAt`: ISO string | null
- `status`: 'idle' | 'active' | 'paused' | 'complete' | 'timeout' | 'ended_early'
- `targetCount`: number (default 10)
- `timeLimitSec`: number (default 7200)
- `kickCount`: number (derived or stored)
- `durationSec`: number | null (endedAt - startedAt)
- `strengthRating`: 1 | 2 | 3 | 4 | 5 | null (optional; inspired by Count the Kicks strength feature)
- `notes`: string | null
- `timezone`: string (IANA TZ if available; else offset)
- `schemaVersion`: number

#### KickEvent

- `id`: uuid
- `sessionId`: uuid
- `occurredAt`: ISO string
- `ordinal`: number (1..N)
- `source`: 'tap' | 'manual_edit' (MVP mostly tap)

#### UserPreferences

- `defaultTargetCount`: number (10)
- `defaultTimeLimitSec`: number (7200)
- `soundEnabled`: boolean
- `vibrationEnabled`: boolean
- `keepScreenAwake`: boolean (default true)
- `guidanceMode`: 'count_to_ten' | 'pattern_aware'

Default `guidanceMode` is `count_to_ten` (matches your requirement and aligns with Cleveland Clinic's "time to 10 movements" method; with caveat that guidance varies).

### 2.2 IndexedDB schema (Dexie)

- **sessions table:** key `id`, indexes on `createdAt`, `startedAt`, `status`.
- **events table:** key `id`, indexes on `sessionId`, `occurredAt`.
- **prefs table:** key fixed `prefs`.

**Persistence rule (important):** Write every tap to IndexedDB immediately (or within a 100-200ms debounce) to prevent data loss on refresh/app close.

## 3. Session state machine & timing logic

### 3.1 State machine

```
Idle (no active session)
  StartSession -> Active

Active
  TapKick -> stays Active, appends KickEvent
  if kickCount == targetCount -> Complete
  if elapsed >= timeLimitSec -> Timeout
  Pause -> Paused
  EndEarly -> EndedEarly

Paused
  Resume -> Active
  EndEarly -> EndedEarly

Complete / Timeout / EndedEarly
  Archive -> stored and shown in history
```

### 3.2 Time calculation

- Store `startedAt` as wall-clock `Date.toISOString()`.
- During an active session:
  - `elapsedSec = (now - startedAt) - pausedDuration`.
  - `remainingSec = timeLimitSec - elapsedSec`.
- Use `requestAnimationFrame` or a 1-second interval for UI timer updates.
- Use a monotonic clock for drift correction where possible (e.g., base on `Date.now()` but re-check on visibility changes).

### 3.3 "2 hours to 10" rules

- Default `targetCount = 10`, `timeLimitSec = 7200` per your requirement and common "count to ten" framing (Cleveland Clinic notes the ACOG-style "time to 10; ideally within two hours").
- If `kickCount < 10` at timeout:
  - Mark session status `timeout`.
  - Show guidance: try techniques to encourage movement and/or contact provider if still no movement (wording should match your chosen clinical guidance set).

## 4. UX/UI design spec (beat counter feel)

### 4.1 Main "Tap Counter" screen

#### Layout

- Top: session status + small "Info" link (education).
- Center:
  - Big count: 7 / 10.
  - Big tappable pad (full-width, tall).
- Bottom:
  - Timer: 00:23:10 elapsed and 01:36:50 remaining.
  - Controls row: Undo | Pause/Resume | End.

#### Beat-counter affordances

- Tap pad responds like a metronome/tap-tempo:
  - Quick press animation.
  - Optional click sound (Web Audio).
  - Optional vibration (Vibration API).
  - Optional "interval since last tap" displayed small (like BPM tools show tempo, but here show spacing).

### 4.2 Calendar & history

- Month grid with:
  - Dot for any sessions.
  - Color/shape variants for complete vs timeout (ensure accessible contrast; also use icons).
- Day detail:
  - List of sessions with:
    - Start time.
    - Duration to 10 (or "Timed out at X").
    - Strength rating (if used).
- Session detail:
  - Kick timestamps list (and intervals).

### 4.3 Education content placement

- First-run modal: "How to Count".
- Steps based on Cleveland Clinic (choose time, get comfortable, start timer, count to 10, record minutes).
- Persistent "Info" page in nav.
- Disclaimer displayed in onboarding and in footer (educational only; not diagnosis/treatment).

## 5. Technical components (frontend)

### Routes

- `/` -> Today / current session.
- `/history` -> Calendar + list.
- `/session/:id` -> Session detail.
- `/settings` -> Preferences (sound, vibration, defaults, guidance mode).
- `/info` -> Educational content + disclaimer.

### React components

- TapPad
- CountDisplay
- TimerDisplay
- SessionControls
- StrengthRatingSelector
- NotesEditor
- SessionSummaryModal
- CalendarView
- SessionList
- SessionDetailTimeline
- ExportButton (optional MVP)

### State management

- Lightweight: React context + reducer for active session.
- Persisted store: Dexie service module.
- Keep domain logic in pure functions for testability.

## 6. Reliability features (must-have)

These are specifically to prevent the kinds of trust failures users complain about in similar apps (lost sessions, resets).

- **Session recovery on reload:** On app start, check for `status = 'active'` session; restore timer and continue.
- **Write-ahead persistence:**
  - On each tap: update in-memory, write `KickEvent` to IndexedDB, update session `kickCount` and `updatedAt`.
- **Prevent accidental navigation:** `beforeunload` prompt when session active.
- **Keep screen awake:** Use Wake Lock API during Active session (fallback: show "Keep screen on" tip).
- **Undo:** Deletes last `KickEvent` and decrements ordinal safely.

## 7. Security & privacy design

### MVP privacy posture (recommended)

- No account required; store data locally only.
- Provide "Delete all data" and "Export my data" actions.
- Clear disclaimer that this is educational and should be used with provider guidance.

### If/when you add cloud sync (Phase 2)

- Encrypt in transit (TLS) and at rest.
- Minimal data collection.
- User-controlled deletion.
- Consider whether this becomes "health data" under applicable laws; design accordingly.

## 8. Optional: Export/share (high value, still simple)

Count the Kicks highlights downloading/sharing kick data with providers.

### Export formats

- **CSV:** sessions + events.
- **Provider summary (printable):**
  - Last 7/14 days average time-to-10.
  - List of timeouts/incomplete sessions.
  - Notes and strength ratings.

## 9. Testing strategy

### 9.1 Unit tests (domain)

- `startSession()` sets correct defaults (10, 2h).
- `registerKick()` appends event, increments ordinal.
- `undoKick()` removes last event.
- `completeOnTarget()` ends session at 10.
- `timeoutAtLimit()` marks timeout at >= 7200 sec.
- Pause/resume time math (if implemented).

### 9.2 Component tests

- TapPad increments count on click/tap.
- Timer display updates.
- Undo disabled when count = 0.
- Summary modal shows correct duration.

### 9.3 E2E tests (Playwright)

- New user onboarding -> start session -> tap 10 -> session completes -> appears on calendar.
- Timeout path: simulate time passage -> incomplete session saved -> warning shown.
- Refresh mid-session -> session recovers.
- Offline mode: load app, complete session, confirm persistence.

### 9.4 Accessibility tests

- Keyboard-only flow to complete a session.
- Screen reader labels for tap pad, count, timer, controls.
- Touch target sizes (mobile viewport).

## 10. Deployment

- Host as a static + server-rendered Next.js app (Vercel/Netlify/Cloudflare).
- Enable PWA caching for:
  - App shell.
  - Fonts/icons.
  - Education content.
- Versioned schema migrations for IndexedDB.

## 11. Phase plan (web-first, then mobile)

### Phase 1 (Web MVP)

- Tap counter + 2-hour window + 10 target.
- Calendar/history.
- Local persistence + recovery.
- Education + disclaimer.

### Phase 2 (Web+ sync / export / reminders)

- Export/share summary.
- Browser notifications reminders (where supported).
- Optional login + sync.

### Phase 3 (iOS + Android)

- Reuse the same domain/session logic:
  - Either wrap the PWA (Capacitor).
  - Or build React Native/Flutter using shared logic spec from this TDD.
