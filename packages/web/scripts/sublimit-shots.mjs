// A project's agent limit (2026-11-18): Settings › Projects with the slider, lowered to 0 (the line
// that says nobody is removed); dark and light. Usage: node sublimit-shots.mjs <url> <token> <outdir>   (the Playwright image)
import { mkdir } from "node:fs/promises";
import { chromium } from "playwright-core";

const [url, token, out] = process.argv.slice(2);
await mkdir(out, { recursive: true });
const browser = await chromium.launch();

async function closeWindows(page) {
  for (let i = 0; i < 4 && (await page.locator(".ui-modal-veil").count()); i++) {
    await page.keyboard.press("Escape");
    await page.waitForTimeout(200);
  }
}

// The phone's Settings › Projects: settings-shots.mjs (its section menu is a list there).
for (const [device, width, height] of [["computer", 1440, 900]])
  for (const scheme of ["light", "dark"]) {
    const page = await browser.newPage({
      viewport: { width, height },
      colorScheme: scheme,
      locale: "it-IT",
    });
    page.on("pageerror", (e) => console.error("pageerror:", e.message));
    const shot = (name) =>
      page.screenshot({ path: `${out}/pagina-${device}-${scheme}-${name}.png` });
    await page.goto(`${url}/#token=${token}`);
    await page.evaluate(() => localStorage.clear());
    await page.goto(`${url}/#token=${token}`);
    await page.waitForSelector(".bar, .top");
    await page.waitForTimeout(1000);
    await closeWindows(page);
    await page.locator(".bar-settings").click();
    await page.waitForSelector(".settings");
    await page.locator(".settings-nav .st-nav-item", { hasText: "Progetti" }).first().click();
    await page.waitForSelector(".pal");
    await page.waitForTimeout(500);
    const first = page.locator(".pal").first();
    await first.scrollIntoViewIfNeeded();
    await shot("01-progetti");
    // Down to 0 with the keyboard (Home), then wait for the save and the line under it.
    await first.locator('input[type="range"]').focus();
    await page.keyboard.press("Home");
    await page.waitForSelector(".pal-saved", { timeout: 10_000 });
    await page.waitForTimeout(600);
    await first.scrollIntoViewIfNeeded();
    await shot("02-solo-orchestratore");
    await first.screenshot({ path: `${out}/pagina-${device}-${scheme}-03-controllo.png` });
    // Back to 3 for the next round.
    await first.locator('input[type="range"]').focus();
    for (let i = 0; i < 3; i++) await page.keyboard.press("ArrowRight");
    await page.waitForSelector(".pal-saved", { timeout: 10_000 });
    await page.waitForTimeout(600);
    await page.close();
  }
await browser.close();
