// The secret warning with «Invia comunque» (2026-11-19): a message that looks like it holds a
// secret, held back with its three ways out; dark and light, computer and phone.
// Usage: node secret-shots.mjs <url> <token> <outdir>   (the demo server; needs a Chromium)
import { mkdir } from "node:fs/promises";
import { chromium } from "playwright-core";

const [url, token, out] = process.argv.slice(2);
await mkdir(out, { recursive: true });
const browser = await chromium.launch();
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
    await page.waitForTimeout(1500);
    for (let i = 0; i < 4 && (await page.locator(".ui-modal-veil").count()); i++) {
      await page.keyboard.press("Escape");
      await page.waitForTimeout(250);
    }
    // A conversation from the list (the phone opens its menu first), unless one is open.
    if (
      !(await page
        .locator("textarea")
        .first()
        .isVisible()
        .catch(() => false))
    ) {
      for (const sel of ["header.top button.menu"]) {
        const b = page.locator(sel).first();
        if (await b.isVisible().catch(() => false)) {
          await b.click();
          break;
        }
      }
      await page.waitForTimeout(600);
      await page
        .locator(".session-row button.open")
        .first()
        .evaluate((el) => el.click());
      await page.waitForTimeout(1200);
    }
    const box = page.locator("textarea").first();
    await box.waitFor({ timeout: 15000 }).catch(async (e) => {
      await page.screenshot({ path: `${out}/debug-${device}-${scheme}.png` });
      throw e;
    });
    await box.fill("il codice del pacco è Ab3dE5fG7hJ9kL1mN3pQ5rS7tU, puoi controllarlo?");
    await page.locator("button.send").first().click();
    await page.waitForSelector(".ch-secret", { timeout: 10000 });
    await page.waitForTimeout(400);
    await page.screenshot({ path: `${out}/${device}-${scheme}-secret-warning.png` });
    await page.close();
  }
}
await browser.close();
console.log("done");
