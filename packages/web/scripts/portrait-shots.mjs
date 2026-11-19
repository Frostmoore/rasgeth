// Settings › Portrait (3.9.4, «Mirror»): the traits grouped, «Where it comes from», «Change» and
// the text the agents read. Dark and light, computer and phone.
// Usage: node portrait-shots.mjs <url> <token> <outdir>   (needs a Chromium: the Playwright image)
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
    if (device === "phone") {
      await page.locator('button[aria-label="Menu"]').click();
      await page.waitForTimeout(300);
    }
    await page.locator(".bar-settings").click();
    await page.waitForSelector(".settings");
    if (device === "phone") {
      await page.locator(".st-pick").click();
      await page.locator(".st-sheet-list .st-nav-item", { hasText: "Ritratto" }).click();
    } else await page.locator(".settings-nav .st-nav-item", { hasText: "Ritratto" }).click();
    await page.waitForSelector(".pr-page");
    await page.waitForTimeout(600);
    await shot("01-ritratto");
    const full = await page.evaluate(() => {
      const b = document.querySelector(".settings-body");
      return b ? b.scrollHeight - b.clientHeight : 0;
    });
    await page.setViewportSize({ width, height: height + full });
    await page.waitForTimeout(300);
    await shot("02-ritratto-intero");
    await page.setViewportSize({ width, height });
    await page.locator(".mem-from").first().click();
    await page.waitForTimeout(400);
    await shot("03-da-dove-viene");
    await page.keyboard.press("Escape");
    await page.waitForTimeout(300);
    await page.locator(".pr-item .wz-btn", { hasText: "Cambia" }).first().click();
    await page.waitForTimeout(400);
    await shot("04-cambia");
    await page.keyboard.press("Escape");
    await page.waitForTimeout(300);
    await page.locator(".pr-page .wz-btn", { hasText: "Mostra il testo" }).click();
    await page.waitForTimeout(300);
    await page.locator(".pr-text").scrollIntoViewIfNeeded();
    await shot("05-testo-agenti");
    await page.close();
  }
}
await browser.close();
