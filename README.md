# Baby Kick Count

A gentle, calming web app to help expectant parents track fetal movements during pregnancy.

[![Live Demo](https://img.shields.io/badge/Live%20Demo-babykickcount-5a8f5a?style=for-the-badge&logo=vercel&logoColor=white)](https://babykickcount.com)

## About

Baby Kick Count helps pregnant people in their third trimester monitor fetal movement patterns. Kick counting is used to track a baby's typical movement pattern - changes can be an early sign that warrants contacting a healthcare provider.

**Key Features:**
- One-tap kick logging with satisfying feedback
- Customizable tap sounds (Soft Click, Pop, Heartbeat, Bubble, or Silent)
- 2-hour session window targeting 10 movements
- Calendar view to track patterns over time
- Session history with detailed timestamps
- Offline-first PWA - works without internet
- Calming, anxiety-reducing design

## Try It

**[Launch Baby Kick Count](https://babykickcount.com)**

The app works best when added to your home screen for a native app experience.

## Screenshots

| Home | Settings | History |
|:----:|:--------:|:-------:|
| ![Home](public/screenshots/home.png) | ![Settings](public/screenshots/settings.png) | ![History](public/screenshots/history.png) |
| Tap the heart to count | Customize tap sounds | Calendar view of sessions |

## Tech Stack

- **Framework:** Next.js 15 with React 19
- **Styling:** Tailwind CSS
- **Storage:** IndexedDB via Dexie.js (offline-first)
- **Deployment:** Vercel
- **Testing:** Vitest + Playwright

## Development

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Run tests
npm test

# Build for production
npm run build
```

## Design Variations

The app includes multiple design themes accessible at:
- `/designs/serene` - Soft sage and cream (default)
- `/designs/clinical` - Clean medical aesthetic
- `/designs/joyful` - Playful and colorful
- `/designs/compare` - Side-by-side comparison

## Important Disclaimer

This app is for **educational purposes only** and is not a medical device. It does not diagnose conditions or predict outcomes. Always contact your healthcare provider if:
- Fetal movements change abruptly, slow down, or stop
- You cannot feel 10 movements after 2 hours of focused counting
- You have any concerns about your pregnancy

## License

MIT
