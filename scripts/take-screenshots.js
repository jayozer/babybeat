const { chromium } = require('playwright');

async function takeScreenshots() {
  const browser = await chromium.launch();
  const context = await browser.newContext({
    viewport: { width: 390, height: 844 },
    deviceScaleFactor: 2,
  });

  const page = await context.newPage();

  // Home page - click Skip to dismiss onboarding
  await page.goto('https://www.babykickcount.com/');
  await page.waitForTimeout(2000);

  // Try to click Skip button if it exists
  try {
    await page.click('text=Skip', { timeout: 3000 });
    await page.waitForTimeout(1000);
  } catch (e) {
    console.log('No Skip button found, continuing...');
  }

  await page.screenshot({ path: 'public/screenshots/home.png' });
  console.log('Saved home.png');

  // Settings page
  await page.goto('https://www.babykickcount.com/settings');
  await page.waitForTimeout(2000);
  await page.screenshot({ path: 'public/screenshots/settings.png' });
  console.log('Saved settings.png');

  // History page
  await page.goto('https://www.babykickcount.com/history');
  await page.waitForTimeout(2000);
  await page.screenshot({ path: 'public/screenshots/history.png' });
  console.log('Saved history.png');

  await context.close();

  // OG Image - wider format for social sharing
  const ogContext = await browser.newContext({
    viewport: { width: 1200, height: 630 },
    deviceScaleFactor: 1,
  });

  const ogPage = await ogContext.newPage();
  await ogPage.goto('https://www.babykickcount.com/');
  await ogPage.waitForTimeout(2000);

  // Try to click Skip button if it exists
  try {
    await ogPage.click('text=Skip', { timeout: 3000 });
    await ogPage.waitForTimeout(1000);
  } catch (e) {
    console.log('No Skip button found for OG, continuing...');
  }

  await ogPage.screenshot({ path: 'public/og-image.png' });
  console.log('Saved og-image.png');

  await browser.close();
}

takeScreenshots().catch(console.error);
