// The guided install's window (3.11 phase 5), dark and light, on a computer and on a phone:
// Settings › Emulators with its buttons, the window with the steps and the licence, the licence
// accepted, the job with its bar, and the emulator's update. Needs the demo with
// DEMO_EMULATORS=1 DEMO_INSTALL_FAKE=1 (nothing is downloaded). Usage:
//   node emulator-install-shots.mjs <url> <token> <outdir>
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

async function emulators(page, device) {
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
    await page.locator(".st-sheet-list .st-nav-item", { hasText: "Emulatori" }).first().click();
  } else await page.locator(".settings-nav .st-nav-item", { hasText: "Emulatori" }).first().click();
  await page.waitForSelector(".ei-acts");
  await page.waitForTimeout(600);
}

for (const [device, width, height] of [
  ["desk", 1440, 900],
  ["phone", 390, 844],
]) {
  for (const scheme of ["dark", "light"]) {
    const name = (n) => `${out}/${device}-${scheme}-${n}.png`;
    const page = await browser.newPage({
      viewport: { width, height },
      colorScheme: scheme,
      locale: "it-IT",
    });
    page.on("pageerror", (e) => console.error("pageerror:", e.message));
    await emulators(page, device);
    await page.locator(".ei-acts").scrollIntoViewIfNeeded();
    await page.waitForTimeout(300);
    await page.screenshot({ path: name("1-buttons") });
    await page.locator(".ei-acts button", { hasText: "Installa quello che manca" }).click();
    await page.waitForSelector(".ei-plan");
    await page.waitForTimeout(600);
    await page.screenshot({ path: name("2-plan") });
    await page.locator(".ei-licence").first().scrollIntoViewIfNeeded();
    await page.waitForTimeout(300);
    await page.screenshot({ path: name("3-licence") });
    await page.locator(".ei-window [role=switch]").click();
    await page.waitForTimeout(300);
    await page.screenshot({ path: name("4-accepted") });
    await page.locator(".ei-window button", { hasText: /^\s*Installa\s*$/ }).click();
    await page.waitForSelector(".ei-window .ui-progress");
    await page.waitForTimeout(4500);
    await page.screenshot({ path: name("5-job") });
    await page.close();

    const again = await browser.newPage({
      viewport: { width, height },
      colorScheme: scheme,
      locale: "it-IT",
    });
    await emulators(again, device);
    await again.locator(".ei-acts button", { hasText: "Aggiorna l'emulatore" }).click();
    await again.waitForSelector(".ei-plan");
    await again.waitForTimeout(600);
    await again.screenshot({ path: name("6-update") });
    await again.close();
  }
}
await browser.close();
console.log("done");
