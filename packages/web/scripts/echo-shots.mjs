// Echo (3.9.6): the search over past conversations in the left bar, its results and nothing
// found. Dark and light, computer and phone.
// Usage: node echo-shots.mjs <url> <token> <outdir>   (needs a Chromium: the Playwright image)
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
    const shot = (name) =>
      page.screenshot({ path: `${out}/pagina-${device}-${scheme}-${name}.png` });
    await page.goto(`${url}/#token=${token}`);
    await page.evaluate(() => localStorage.clear());
    await page.goto(`${url}/#token=${token}`);
    await page.waitForSelector(".bar, .top");
    await page.waitForTimeout(1200);
    for (let i = 0; i < 4 && (await page.locator(".ui-modal-veil").count()); i++) {
      await page.keyboard.press("Escape");
      await page.waitForTimeout(250);
    }
    const openBar = async () => {
      if (device !== "phone") return;
      await page.locator('button[aria-label="Menu"]').click();
      await page.waitForTimeout(300);
    };
    await openBar();
    await shot("01-casella");
    const box = page.locator(".echo-bar input");
    await box.fill("report");
    await page.waitForSelector(".echo-hit");
    await page.waitForTimeout(400);
    await shot("02-risultati");
    await box.fill("zzzqqq");
    await page.waitForSelector(".echo-results .empty");
    await page.waitForTimeout(300);
    await shot("03-niente");
    await box.fill("report");
    await page.waitForSelector(".echo-hit");
    await page.locator(".echo-hit").first().click();
    await page.waitForTimeout(900);
    await shot("04-aperta");
    await page.close();
  }
}
await browser.close();
