// Agents at work together (3.8.10): the bar's meter and the «queued» rows, a conversation that waits,
// the line in its window and the setting on the Agents page; dark and light, computer and phone.
// Usage: node queue-shots.mjs <url> <token> <outdir>   (demo with DEMO_QUEUE=1; needs a Chromium)
import { mkdir } from "node:fs/promises";
import { chromium } from "playwright-core";

const [url, token, out] = process.argv.slice(2);
await mkdir(out, { recursive: true });
const browser = await chromium.launch();

async function closeWindows(page) {
  for (let i = 0; i < 4 && (await page.locator(".ui-modal-veil").count()); i++) {
    await page.keyboard.press("Escape");
    await page.waitForTimeout(250);
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
    const shot = (name) => page.screenshot({ path: `${out}/${device}-${scheme}-${name}.png` });
    await page.goto(`${url}/#token=${token}`);
    await page.evaluate(() => localStorage.clear());
    await page.goto(`${url}/#token=${token}`);
    await page.waitForSelector(".bar, .top");
    await page.waitForTimeout(1200);
    await closeWindows(page);
    const menu = async () => {
      if (device !== "phone") return;
      await page.locator('button[aria-label="Menu"]').click();
      await page.waitForTimeout(300);
    };
    await menu();
    // The project's tree open: its agents' conversations with «queued (2nd of 3)».
    const demo = page.locator(".bar-item", { hasText: "Demo" }).first();
    if (await demo.count()) await demo.click();
    await page.waitForTimeout(400);
    await shot("01-bar");
    // The line in its window, from the meter.
    await page.locator(".tq-meter").click();
    await page.waitForSelector(".tq-list");
    await page.waitForTimeout(300);
    await shot("02-line");
    // A conversation that waits: its notice above the message box.
    await page.locator(".tq-item .tq-who").nth(1).click();
    await page.waitForSelector(".tq-notice");
    await page.waitForTimeout(500);
    await shot("03-conversation");
    // The setting on the Agents page.
    await closeWindows(page);
    await menu();
    await page.locator(".bar-settings").click();
    await page.waitForSelector(".settings");
    if (device === "phone") {
      await page.locator(".st-pick").click();
      await page.locator(".st-sheet-list .st-nav-item", { hasText: "Agenti" }).first().click();
    } else await page.locator(".settings-nav .st-nav-item", { hasText: "Agenti" }).first().click();
    await page.waitForSelector(".tq-card");
    await page.waitForTimeout(600);
    await page
      .locator(".tq-card")
      .screenshot({ path: `${out}/${device}-${scheme}-04-setting.png` });
    await shot("05-agents-page");
    await page.close();
  }
}
await browser.close();
console.log("done");
