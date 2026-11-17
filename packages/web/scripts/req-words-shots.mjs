// p3.8.9: the requests' plain line on the page (DEMO_REQWORDS=1), desktop and phone, dark and light.
// Usage: node req-words-shots.mjs <url> <token> <outdir>   (the Playwright image has a Chromium)
import { mkdir } from "node:fs/promises";
import { chromium } from "playwright-core";

const [url, token, out] = process.argv.slice(2);
await mkdir(out, { recursive: true });
const browser = await chromium.launch();
for (const [device, viewport] of [
  ["computer", { width: 1440, height: 1000 }],
  ["phone", { width: 400, height: 860 }],
])
  for (const scheme of ["dark", "light"]) {
    const page = await browser.newPage({ viewport, colorScheme: scheme, locale: "it-IT" });
    page.on("pageerror", (e) => console.error("pageerror:", e.message));
    await page.goto(`${url}/#token=${token}`);
    await page.evaluate(() => localStorage.clear());
    await page.goto(`${url}/#token=${token}`);
    await page.waitForSelector(".bar, .top");
    await page.waitForTimeout(1500);
    // «What's new» first.
    const gotIt = page.locator("button", { hasText: "Ho capito" });
    if (await gotIt.count()) await gotIt.first().click();
    await page.locator('button[aria-label="Da approvare"]').first().click();
    await page.waitForSelector(".panel .permission");
    await page.waitForTimeout(1200);
    await page.screenshot({ path: `${out}/page-${device}-${scheme}.png`, fullPage: false });
    // The red card alone, and the ordinary one, each whole.
    const cards = page.locator(".panel .permission");
    for (let i = 0; i < (await cards.count()); i++) {
      const card = cards.nth(i);
      const red = await card.evaluate((e) => e.classList.contains("permission-critical"));
      await card.screenshot({
        path: `${out}/page-${device}-${scheme}-${red ? "critical" : "normal"}-${i}.png`,
      });
    }
    await page.close();
  }
await browser.close();
