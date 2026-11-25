// The «Improvements» of a local model's card (p3.12.6), light and dark.
// Usage: DEMO_FAKE_HF=1 server, then node improvements-shots.mjs <url> <token> <outdir>
// (needs a Chromium: the Playwright image has one)
import { mkdir } from "node:fs/promises";
import { chromium } from "playwright-core";

const [url, token, out] = process.argv.slice(2);
await mkdir(out, { recursive: true });
const browser = await chromium.launch();
for (const scheme of ["light", "dark"]) {
  const page = await browser.newPage({
    viewport: { width: 1300, height: 1100 },
    colorScheme: scheme,
    locale: "it-IT",
  });
  page.on("pageerror", (e) => console.error("pageerror:", e.message));
  await page.goto(`${url}/#token=${token}`);
  await page.evaluate(() => localStorage.clear());
  await page.goto(`${url}/#token=${token}`);
  await page.waitForSelector(".bar, .top");
  await page.waitForTimeout(800);
  for (let i = 0; i < 4 && (await page.locator(".ui-modal-veil").count()); i++) {
    await page.keyboard.press("Escape");
    await page.waitForTimeout(200);
  }
  await page.locator(".bar-settings").click();
  await page.waitForSelector(".settings");
  await page.locator(".settings-nav button", { hasText: "Modelli e abbonamenti" }).click();
  await page.waitForTimeout(600);
  await page.locator("button", { hasText: "Un modello su questo computer" }).first().click();
  await page.waitForTimeout(1200);
  await page.locator(".gcard", { hasText: "Qwen3.8 27B" }).first().click();
  await page.waitForTimeout(1500);
  if (process.env.SHOTS_DEBUG) await page.screenshot({ path: `${out}/debug-${scheme}.png` });
  await page.waitForSelector(".impr");
  await page.waitForTimeout(500);
  await page.locator(".impr").scrollIntoViewIfNeeded();
  await page.screenshot({ path: `${out}/miglioramenti-${scheme}.png` });
  await page.close();
}
await browser.close();
