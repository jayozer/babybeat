# PRD (Web App) - Baby Kick Beat Counter

## 1. Product summary

Build a web app that helps an expectant parent log fetal movements ("kicks") by tapping a large button, similar to a music beat counter. The app runs a 2-hour session window and aims to capture 10 movements; it stores a time-stamped log and shows history in a calendar.

Kick counting is used to monitor the baby's typical movement pattern; changes can be an early sign of distress, and users should be encouraged to contact their provider if movements change abruptly or if they cannot feel movement after focused counting.

## 2. Goals

### User goals

- Quickly log each movement with one tap (fast, low-cognitive load).
- See progress toward 10 movements and elapsed time.
- Review history (calendar + session details) to notice patterns and changes.
- Export/share session summaries with a healthcare provider (optional in MVP).

### Business/product goals

- Deliver a reliable, low-friction tracker comparable to leading apps (e.g., Count the Kicks emphasizes recording time to 10 movements and sharing with providers).
- Prioritize trust: reduce anxiety, prevent data loss, be transparent about non-diagnostic nature.

## 3. Target users

- **Primary:** Pregnant people in third trimester who are asked (or choose) to monitor fetal movement patterns (often around ~28 weeks onward).
- **Secondary:** Partners/support people who help track; clinicians reviewing exported summaries.

## 4. Key user stories

- As a user, I want to tap a big button each time I feel movement so I don't lose count.
- As a user, I want the session to automatically finish when I reach 10.
- As a user, I want to see how long it took to reach 10 and compare across days.
- As a user, I want a calendar to see which days I counted and open a session to see details.
- As a user, I want guidance for what to do if I can't reach 10 within 2 hours (and a reminder this is educational, not diagnostic).

## 5. Core experience (MVP scope)

### A. Onboarding / Education (lightweight)

- Explain what kick counting is and why it's used (monitoring patterns; changes may matter).
- Provide "how to count" steps (choose a time, get comfortable, start timer, count to 10, record minutes).
- Provide clear escalation copy:
  - If movements change abruptly/slow/stop: contact provider.
  - If unable to feel 10 movements after 2 hours of counting: contact provider for advice.
- Include disclaimer: educational only, not diagnosis/treatment.

### B. Beat-counter-style kick session

- **"Tap to Count" screen:**
  - Huge tap target (full-width button/pad).
  - Count display: X / 10.
  - Timer: elapsed + remaining out of 2:00:00.
  - Subtle feedback per tap (animation + optional click sound + optional vibration where supported).
- **Session rules:**
  - Session can auto-start on first tap.
  - Each tap logs a timestamp.
  - Auto-complete at 10.
  - If 2 hours elapse before 10: mark "Incomplete" and show guidance.
- **Controls:**
  - Undo last tap (for accidental tap).
  - Pause/Resume (optional MVP).
  - End session early (confirm dialog).

### C. Session summary

- When complete: show duration (minutes to 10), start time, end time, optional note, optional "movement strength" rating (1-5) inspired by Count the Kicks.
- When incomplete: show count achieved, elapsed time, and escalation guidance.

### D. Calendar + history

- **Calendar month view:**
  - Days with sessions indicated (dot/badge).
  - Click day to view sessions list (time, duration, complete/incomplete).
- **Session detail view:**
  - List of timestamps for each tap (and intervals between taps).
  - Notes, strength rating (if used).

## 6. Non-goals (explicit)

- Not a medical device; does not diagnose or predict outcomes.
- No fetal heartbeat monitoring or doppler-like features.
- No emergency detection claims.
- iOS/Android native apps are out of scope for this first PRD/TDD (but we'll design web logic to be reusable later).

## 7. Requirements

### Functional requirements

- **FR1:** Start a session and register taps as "kicks".
- **FR2:** Store per-tap timestamp and session metadata.
- **FR3:** Default target = 10, time window = 2 hours.
- **FR4:** Auto-complete at 10; auto-timeout at 2 hours.
- **FR5:** Calendar/history view of all sessions.
- **FR6:** Data persistence across refresh/reopen (no accidental loss).
- **FR7:** Education + disclaimer content shown on first run and accessible later.

### Non-functional requirements

- **NFR1:** Fast interaction: tap-to-record < 50ms perceived delay.
- **NFR2:** Offline-first (works with no network).
- **NFR3:** Accessibility: WCAG-friendly, large targets, keyboard operable.
- **NFR4:** Privacy-forward by default (local-only MVP; clear deletion).

## 8. Risks & mitigations

- **Guidelines differ by org/region.** Mitigation: make threshold configurable and emphasize "know your normal; contact provider if concerned." (Kicks Count UK explicitly discourages a universal "10 in 2 hours" rule.)
- **User anxiety.** Mitigation: calm copy; avoid alarmist tone; show supportive guidance (Cleveland Clinic notes kick counting shouldn't make you stressed).
- **Data loss = trust killer.** Mitigation: write to persistent storage on every tap; strong session recovery UX.

## 9. Success metrics (MVP)

- % sessions completed without error.
- "Accidental tap undo" usage rate (indicator of UI fit).
- Retention: users who log at least 4 sessions/week.
- Export usage (if included).
- Bug-free persistence (0% sessions lost after refresh).
