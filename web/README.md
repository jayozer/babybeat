# Baby Kick Count — Website (`web/`)

A calm, static marketing site for **babykickcount.com**, ready to deploy on Vercel.

## Files

```
web/
├── index.html              # landing page
├── privacy.html            # privacy policy
├── terms.html              # terms of use
├── styles.css              # shared styles
├── tweaks.jsx              # in-page Tweaks panel (palette, type, copy)
├── tweaks-panel.jsx        # Tweaks panel component
├── llms.txt                # AI-friendly site summary
├── robots.txt
├── sitemap.xml
├── manifest.webmanifest    # PWA manifest
├── vercel.json             # cache + security headers
├── README.md
└── images/
    ├── favicon.svg
    ├── og-cover.png        # 1200×630 open-graph share image — REPLACE
    ├── apple-touch-icon.png  # 180×180 — REPLACE
    ├── icon-192.png        # PWA icon — REPLACE
    ├── icon-512.png        # PWA icon — REPLACE
    ├── icon-maskable.png   # PWA maskable — REPLACE
    ├── screen-counter.png  # iPhone screenshot — DROP IN
    └── screen-calendar.png # iPhone screenshot — DROP IN
```

## Deploy on Vercel

1. Drop the contents of this folder at the root of your repo (or in a `web/` directory and set Vercel's "Root Directory" to `web`).
2. In Vercel: **Add New… → Project → Import** the repo.
3. **Framework preset:** Other (static).
4. **Build & Output:** leave the build command empty; output directory is the project root.
5. Add the custom domain `www.babykickcount.com` (and apex `babykickcount.com` redirecting to `www`).

## Drop in your iPhone screenshots

The hero references two screenshots and the feature grid one more:
- `web/images/screen-counter.png` — counter view (the heart screen)
- `web/images/screen-calendar.png` — calendar view

Recommended: PNG, ~1170×2532 (iPhone Pro screenshot at 3×). The site uses CSS `background-image` to render them inside the iPhone frame; if you want the placeholder mockup to disappear once the images are present, add the `has-shot` class:

```js
document.querySelectorAll('.phone-screen[data-shot]').forEach(el => el.classList.add('has-shot'));
```

…or just let the placeholders show until you upload — both look reasonable.

## Replace the social/PWA images

Generate from your final app icon:
- `og-cover.png` 1200×630 — used by OG/Twitter
- `apple-touch-icon.png` 180×180
- `icon-192.png`, `icon-512.png`, `icon-maskable.png`

I included an SVG placeholder for `og-cover.png`; rasterize it (or replace with a designed cover) before launch — Twitter/Facebook want PNG/JPG.

## Tweaks

Toggle the **Tweaks** panel from the studio toolbar to live-edit:
- Palette (sage / blush / cool / mono)
- Type pairing
- Hero headline + lede
- Show/hide the "coming soon" notice strip

Settings persist back to `index.html` so whatever you settle on becomes the deployed default.

## SEO checklist included
- ✅ Open Graph + Twitter Card meta
- ✅ Canonical URL
- ✅ Apple smart app banner placeholder (replace `app-id=` once App Store Connect issues one)
- ✅ Schema.org `MobileApplication` JSON-LD
- ✅ `llms.txt`
- ✅ `robots.txt`
- ✅ `sitemap.xml`
- ✅ PWA manifest
- ✅ Theme color, viewport, description

## Apple smart app banner
Once your app is live in the App Store, edit `index.html` and replace the `apple-itunes-app` meta tag:
```html
<meta name="apple-itunes-app" content="app-id=YOUR_APP_ID, app-argument=https://www.babykickcount.com/" />
```
