// The model picker (3.12.4): the composer's menu open on the demo server, computer 1440x900 and
// phone 390x844, light and dark; then the search typed, the current model lit.
// Usage: node model-picker-shots.mjs <url> <token> <outdir>   (a Chromium: the Playwright image)
import { mkdir } from "node:fs/promises";
import { chromium } from "playwright-core";

const [url, token, out] = process.argv.slice(2);
await mkdir(out, { recursive: true });
const browser = await chromium.launch();
for (const [device, viewport] of [
  ["computer", { width: 1440, height: 900 }],
  ["telefono", { width: 390, height: 844 }],
])
  for (const [theme, scheme] of [
    ["chiaro", "light"],
    ["scuro", "dark"],
  ]) {
    const page = await browser.newPage({ viewport, colorScheme: scheme, locale: "it-IT" });
    page.on("pageerror", (e) => console.error("pageerror:", e.stack));
    await page.goto(`${url}/#token=${token}`);
    await page.evaluate(() => localStorage.clear());
    await page.goto(`${url}/#token=${token}`);
    await page.waitForTimeout(2500);
    for (let i = 0; i < 3 && (await page.locator(".ui-modal-veil").count()) > 0; i++) {
      await page.keyboard.press("Escape");
      await page.waitForTimeout(400);
    }
    // On the phone the list of conversations hides behind the menu button.
    if (viewport.width < 600) {
      await page.locator("button[aria-label='Menu']").first().click();
      await page.waitForTimeout(700);
    }
    const row = page.locator(".session-row").first();
    await row.click({ force: true });
    await page.waitForTimeout(1500);
    await page.locator("button.more-button").first().click();
    const drop = page.locator(".more-panel .ui-drop.model .ui-drop-current").first();
    await drop.waitFor({ timeout: 15000 }).catch(async (e) => {
      await page.screenshot({ path: `${out}/debug-${device}-${theme}.png` });
      throw e;
    });
    await drop.click();
    await page.waitForSelector(".ui-drop-list");
    await page.waitForTimeout(500);
    await page.screenshot({ path: `${out}/selettore-${device}-${theme}.png` });
    await page.locator(".ui-drop-search").fill("opus");
    await page.waitForTimeout(300);
    await page.screenshot({ path: `${out}/selettore-${device}-${theme}-ricerca.png` });
    await page.close();
  }
await browser.close();
