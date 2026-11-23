// 3.12.2: the search widgets in an answer (gallery, trains, products with stars, a route, a chart
// widget), light and dark, computer and phone. Against a demo started with DEMO_FOUND=1.
// Usage: node found-shots.mjs <url> <token> <outdir>   (the Playwright image has a Chromium)
import { mkdir } from "node:fs/promises";
import { chromium } from "playwright-core";

const [url, token, out] = process.argv.slice(2);
await mkdir(out, { recursive: true });
const browser = await chromium.launch();
const SCREENS = {
  computer: { width: 1280, height: 900 },
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
    await page.addInitScript(
      ([t]) => {
        localStorage.setItem("rg.theme", t);
        localStorage.setItem("rg.lang", "it");
        localStorage.setItem("rg.ui", "full");
      },
      [theme],
    );
    await page.goto(`${url}/#token=${token}`);
    await page.waitForSelector(".bar", { timeout: 20000 });
    await page
      .getByRole("button", { name: "Ho capito" })
      .click({ timeout: 5000 })
      .catch(() => {});
    if (screen === "telefono") await page.locator("button.menu").click();
    await page.getByRole("button", { name: "Chat", exact: true }).click();
    await page.getByText("Cosa ho trovato", { exact: true }).first().click();
    if (screen === "telefono")
      await page
        .locator(".veil")
        .click({ position: { x: 380, y: 400 } })
        .catch(() => {});
    await page.waitForTimeout(2500);

    await page.waitForSelector("[data-found=gallery]");
    await page.waitForSelector("[data-found=route]");
    await page.waitForTimeout(1200);
    const pick = async (sel, name) => {
      const el = page.locator(sel).first();
      await el.scrollIntoViewIfNeeded();
      await page.waitForTimeout(300);
      await el.screenshot({ path: `${out}/${screen}_${tag}_${name}.png` });
    };
    await pick("[data-found=gallery]", "galleria");
    await pick("[data-found=trips]", "treni");
    await pick(".products", "prodotti");
    await pick("[data-found=route]", "percorso");
    await pick(".widget-card", "widget-grafico");
    await page
      .locator(".dailychat, .chat")
      .first()
      .screenshot({ path: `${out}/${screen}_${tag}_chat.png` });
    await page.close();
  }
}
await browser.close();
