// 3.11: a device live on the right, at a window's real size: Settings › Emulators, «Open» on the
// first device, then «Take control». Light and dark, computer and phone.
// Usage: node device-shots.mjs <url> <token> <outdir>   (the demo with DEMO_DEVICE_JPEG, or adb)
import { mkdir } from "node:fs/promises";
import { chromium } from "playwright-core";

const [url, token, out] = process.argv.slice(2);
await mkdir(out, { recursive: true });
const browser = await chromium.launch();
for (const [device, width, height] of [
  ["desk", 1440, 900],
  ["phone", 390, 844],
])
  for (const scheme of ["light", "dark"]) {
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
    for (let i = 0; i < 4 && (await page.locator(".ui-modal-veil").count()); i++) {
      await page.keyboard.press("Escape");
      await page.waitForTimeout(200);
    }
    if (device === "phone") {
      await page.locator('button[aria-label="Menu"]').click();
      await page.waitForTimeout(300);
    }
    await page.locator(".bar-settings").click();
    await page.waitForSelector(".settings");
    const names = await page.locator(".settings-nav .st-nav-item .st-nav-name").allTextContents();
    const i = names.findIndex((n) => /Emulatori/.test(n));
    if (device === "phone") {
      await page.locator(".st-pick").click();
      await page.locator(".st-sheet-list .st-nav-item").nth(i).click();
    } else await page.locator(".settings-nav .st-nav-item").nth(i).click();
    await page.waitForTimeout(1200);
    await page.locator(".settings-body button", { hasText: "Apri" }).first().click();
    await page.waitForSelector(".device-view img", { timeout: 20_000 });
    await page.waitForTimeout(1200);
    await page.screenshot({ path: `${out}/${device}-${scheme}-1-aperto.png` });
    await page.locator(".device-screen button", { hasText: "Prendi il controllo" }).click();
    await page.waitForTimeout(800);
    await page.screenshot({ path: `${out}/${device}-${scheme}-2-controllo.png` });
    // Given back, so the next round starts from the agents' screen again.
    await page.locator(".device-screen .screen-bar button").first().click();
    await page.waitForTimeout(500);
    await page.close();
  }
await browser.close();
console.log("done");
