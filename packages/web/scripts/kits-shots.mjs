// 3.9.4: an agent's Tools tab with the tool groups (off by default, always on, off by you), dark and
// light, on a computer and on a phone. Usage: node kits-shots.mjs <url> <token> <outdir>
// (needs a Chromium: the Playwright image has one). Settings > Tools itself: settings-shots.mjs with
// the filter «strumenti».
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

for (const [device, width, height] of [
  ["desk", 1440, 900],
  ["phone", 390, 844],
]) {
  for (const scheme of ["dark", "light"]) {
    const page = await browser.newPage({
      viewport: { width, height },
      colorScheme: scheme,
      locale: "it-IT",
    });
    page.on("pageerror", (e) => console.error("pageerror:", e.message));
    await page.goto(`${url}/#token=${token}`);
    await page.evaluate(() => localStorage.clear());
    await page.goto(`${url}/#token=${token}`);
    await page.waitForSelector(".bar, .top");
    await page.waitForTimeout(800);
    await closeWindows(page);
    if (device === "phone") {
      await page.locator('button[aria-label="Menu"]').click();
      await page.waitForTimeout(300);
    }
    await page.locator(".bar-settings").click();
    await page.waitForSelector(".settings");
    if (device === "phone") {
      await page.locator(".st-pick").click();
      await page.locator(".st-sheet-list .st-nav-item", { hasText: "Agenti" }).first().click();
    } else await page.locator(".settings-nav .st-nav-item", { hasText: "Agenti" }).first().click();
    await page.waitForTimeout(900);
    await page.locator(".org-node.agent").first().click();
    await page.waitForSelector(".agent-panel-modal");
    await page.locator(".agent-panel-tabs button", { hasText: "Strumenti" }).click();
    await page.waitForSelector(".tl-kits .tl-kit");
    await page.waitForTimeout(600);
    const base = `${out}/${device}-${scheme}-agent-tools`;
    await page.locator(".tl-agent .tl-sum").first().scrollIntoViewIfNeeded();
    await page.screenshot({ path: `${base}-1.png` });
    await page.locator(".tl-kit").nth(3).scrollIntoViewIfNeeded();
    await page.screenshot({ path: `${base}-2.png` });
    await page.close();
  }
}
await browser.close();
