// 3.12.1: «Oggi» with God giant on the orbit, Satellite in front, the agents' strip and God's
// nudge, light and dark, computer and phone. Against a demo started with DEMO_TOPICS=1 and
// DEMO_NUDGE=1. Usage: node simple-3121-shots.mjs <url> <token> <outdir> (the Playwright image)
import { mkdir } from "node:fs/promises";
import { chromium } from "playwright-core";

const [url, token, out] = process.argv.slice(2);
await mkdir(out, { recursive: true });
const browser = await chromium.launch();
const SCREENS = {
  computer: { width: 1280, height: 820 },
  telefono: { width: 390, height: 844 },
};

for (const [screen, viewport] of Object.entries(SCREENS)) {
  for (const [theme, tag] of [
    ["light", "chiaro"],
    ["dark", "scuro"],
  ]) {
    const page = await browser.newPage({
      viewport,
      colorScheme: theme,
      locale: "it-IT",
      deviceScaleFactor: screen === "telefono" ? 2 : 1,
    });
    page.on("pageerror", (e) => console.error("pageerror:", e.message));
    await page.addInitScript((t) => {
      localStorage.setItem("rg.theme", t);
      localStorage.setItem("rg.lang", "it");
      localStorage.removeItem("rg.ui");
    }, theme);
    const shot = (name, full = true) =>
      page.screenshot({ path: `${out}/3121_${screen}_${tag}_${name}.png`, fullPage: full });
    await page.goto(`${url}/#token=${token}`);
    await page.waitForSelector(".smp-card");
    await page.waitForSelector(".smp-nudge", { timeout: 8000 }).catch(() => {});
    await page.waitForTimeout(800);
    await page.evaluate(() => {
      const el = document.querySelector(".smp-today .smp-wrap");
      if (el) el.style.overflow = "visible";
    });
    await shot("01_oggi");

    await page.locator(".smp-names button.sat").click();
    await page.waitForTimeout(1300);
    await shot("02_satellite", false);
    await page.locator(".smp-names button").first().click();
    await page.waitForTimeout(1300);

    const minis = page.locator(".smp-sm");
    if ((await minis.count()) > 1) {
      await minis.nth(1).scrollIntoViewIfNeeded();
      const box = await minis.nth(1).boundingBox();
      if (box) await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
      await page.waitForTimeout(700);
      await page
        .locator(".smp-strip-wrap")
        .screenshot({ path: `${out}/3121_${screen}_${tag}_03_striscia.png` });
    }
    await page.close();
  }
}
await browser.close();
