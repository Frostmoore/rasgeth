// 3.12: the simple interface («B · Assistente», tavole-semplice/b-assistente.html), light and dark,
// computer and phone: «Oggi», a topic read as a document with its decision, «Sposta», the archive
// and the settings. Against a demo started with DEMO_TOPICS=1 (the installation opens simple).
// Usage: node simple-shots.mjs <url> <token> <outdir>   (the Playwright image has a Chromium)
import { mkdir } from "node:fs/promises";
import { chromium } from "playwright-core";

const [url, token, out] = process.argv.slice(2);
await mkdir(out, { recursive: true });
const browser = await chromium.launch();
const SCREENS = {
  computer: { width: 1280, height: 820 },
  telefono: { width: 390, height: 844 },
};
const accent = process.env.ACCENT ?? "blue";

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
    await page.addInitScript(
      ([t, a]) => {
        localStorage.setItem("rg.theme", t);
        localStorage.setItem("rg.accent", a);
        localStorage.setItem("rg.lang", "it");
        localStorage.removeItem("rg.ui");
      },
      [theme, accent],
    );
    const shot = (name) => page.screenshot({ path: `${out}/pagina_${screen}_${tag}_${name}.png` });
    await page.goto(`${url}/#token=${token}`);
    await page.waitForSelector(".smp-card");
    await page.waitForTimeout(500);
    await shot("01_oggi");

    await page.locator(".smp-card", { hasText: "Vacanza in Sardegna" }).click();
    await page.waitForSelector(".smp-doc .md-read");
    await page.waitForSelector(".smp-decide");
    await page.waitForTimeout(1200);
    await shot("02_conversazione");

    await page.locator(".smp-routed button", { hasText: "Sposta" }).click();
    await page.waitForSelector(".smp-modal .smp-move-row");
    await page.waitForTimeout(400);
    await shot("03_sposta");
    await page.keyboard.press("Escape");

    await page.locator(".smp-back").click();
    await page.locator(".smp-foot .smp-link").click();
    await page.waitForSelector(".smp-archived");
    await page.waitForTimeout(300);
    await shot("04_archivio");

    await page.locator(".smp-back").click();
    await page.locator('button[aria-label="Impostazioni"]').click();
    await page.waitForSelector(".smp-grp");
    await page.waitForTimeout(300);
    await shot("05_impostazioni");
    await page.close();
  }
}
await browser.close();
