// 3.12.3: «Oggi» on a phone with the slimmer agents' strip and its balloon open above it, light and
// dark. Against a demo started with DEMO_TOPICS=1. Usage: node simple-3123-shots.mjs <url> <token> <outdir>
import { mkdir } from "node:fs/promises";
import { chromium } from "playwright-core";

const [url, token, out] = process.argv.slice(2);
await mkdir(out, { recursive: true });
const browser = await chromium.launch();
for (const [theme, tag] of [
  ["light", "chiaro"],
  ["dark", "scuro"],
]) {
  const page = await browser.newPage({
    viewport: { width: 390, height: 844 },
    colorScheme: theme,
    locale: "it-IT",
    deviceScaleFactor: 2,
  });
  page.on("pageerror", (e) => console.error("pageerror:", e.message));
  await page.addInitScript((t) => {
    localStorage.setItem("rg.theme", t);
    localStorage.setItem("rg.lang", "it");
    localStorage.removeItem("rg.ui");
  }, theme);
  await page.goto(`${url}/#token=${token}`);
  await page.waitForSelector(".smp-card");
  await page.waitForTimeout(800);
  const wrap = await page.locator(".smp-strip-wrap").boundingBox();
  console.log(tag, "strip height", wrap?.height);
  await page.screenshot({ path: `${out}/3123_telefono_${tag}_01_striscia.png` });
  const minis = page.locator(".smp-sm");
  const box = await minis.nth(1).boundingBox();
  if (box) await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
  await page.waitForTimeout(700);
  await page.screenshot({ path: `${out}/3123_telefono_${tag}_02_fumetto.png` });
  await page.close();
}
await browser.close();
