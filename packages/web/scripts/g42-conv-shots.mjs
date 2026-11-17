// G42.1: the page's side of the comparison with RGCompanion. Against the demo server with
// DEMO_CONV=1, the conversation «Il login di Bottega non funziona» from the bottom (the requests
// waiting) to the top, light and dark, computer 1440x900 and phone 390x844.
// Usage: node g42-conv-shots.mjs <url> <token> <outdir>   (a Chromium: the Playwright image)
import { mkdir } from "node:fs/promises";
import { chromium } from "playwright-core";

const [url, token, out] = process.argv.slice(2);
await mkdir(out, { recursive: true });
const browser = await chromium.launch();
const TITLE = "Il login di Bottega non funziona";

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
    // A window opened at start (what's new, a request): put away.
    for (let i = 0; i < 3 && (await page.locator(".ui-modal-veil").count()) > 0; i++) {
      await page.keyboard.press("Escape");
      await page.waitForTimeout(400);
    }
    // The conversation: from the list (the phone opens its menu first).
    const row = page.locator(".session-row", { hasText: TITLE }).first();
    if (!(await row.isVisible().catch(() => false))) {
      for (const sel of [".menu-button", "[aria-label='Menu']", ".bar-toggle"]) {
        const b = page.locator(sel).first();
        if (await b.isVisible().catch(() => false)) {
          await b.click();
          break;
        }
      }
      await page.waitForTimeout(600);
      const demo = page.locator(".bar-item", { hasText: "Demo" }).first();
      if (await demo.isVisible().catch(() => false)) await demo.click();
      await page.waitForTimeout(600);
    }
    // The page itself says the developer asks in that conversation: its «apri» opens it.
    const there = page.locator(".notice.elsewhere", { hasText: TITLE }).first();
    if (await there.isVisible().catch(() => false)) await there.locator("button.link").click();
    else await page.locator(".session-row", { hasText: TITLE }).first().click({ force: true });
    await page.waitForSelector(".chat-agent >> text=Sviluppatore", { timeout: 15000 });
    await page.waitForSelector(".bubble.assistant", { state: "attached" }).catch(async (e) => {
      await page.screenshot({ path: `${out}/debug-${device}-${theme}.png` });
      throw e;
    });
    await page.waitForTimeout(1500);
    for (let i = 1; i <= 24; i++) {
      await page.screenshot({
        path: `${out}/web-${device}-${theme}-${String(i).padStart(2, "0")}.png`,
      });
      // The list that really scrolls (the main conversation's, not a sub-agent's).
      const top = await page.evaluate(() => {
        const all = [...document.querySelectorAll(".chat-scroll")];
        const el = all.sort((a, b) => b.scrollHeight - a.scrollHeight)[0];
        if (!el) return 0;
        el.scrollTop = Math.max(0, el.scrollTop - el.clientHeight * 0.85);
        return el.scrollTop;
      });
      await page.waitForTimeout(350);
      if (top === 0) {
        await page.screenshot({
          path: `${out}/web-${device}-${theme}-${String(i + 1).padStart(2, "0")}.png`,
        });
        break;
      }
    }
    await page.close();
  }
await browser.close();
