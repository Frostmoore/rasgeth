// 3.12.3: «Parti da…» in the create-agent flow, an agent's connections (the agent's settings,
// «Collegamenti») and the calendars in Settings, light and dark, computer and phone. Against a demo
// started with DEMO_SETS=1 (and DEMO_TOPICS=1, which skips the demo's long first tour).
// Usage: node sets-shots.mjs <url> <token> <outdir>   (the Playwright image has a Chromium)
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
    const context = await browser.newContext({
      viewport,
      colorScheme: theme,
      locale: "it-IT",
      deviceScaleFactor: screen === "telefono" ? 2 : 1,
    });
    await context.addInitScript(
      ([t]) => {
        localStorage.setItem("rg.theme", t);
        localStorage.setItem("rg.lang", "it");
        localStorage.setItem("rg.ui", "full");
      },
      [theme],
    );
    let page = await context.newPage();
    page.on("pageerror", (e) => console.error("pageerror:", e.message));
    const name = (n) => `${out}/${screen}-${tag}-${n}.png`;
    const open = async () => {
      await page.close();
      page = await context.newPage();
      await page.goto(`${url}/#token=${token}`);
      await page.waitForSelector(".bar", { timeout: 20000 });
      await page
        .getByRole("button", { name: "Ho capito" })
        .click({ timeout: 4000 })
        .catch(() => {});
      await page.waitForTimeout(1500);
      if (screen === "telefono") await page.locator("button.menu").click();
    };
    await open();
    // «Parti da…»: Agents, New agent, a set chosen.
    await page
      .locator("button", { hasText: /^Agenti/ })
      .first()
      .click();
    await page.locator("button.bar-new", { hasText: "Nuovo agente" }).first().click();
    await page.waitForSelector(".set-picker");
    await page.locator(".set-picker .ui-card", { hasText: "Segretario sui messaggi" }).click();
    await page.waitForTimeout(300);
    await page.locator(".set-picker").scrollIntoViewIfNeeded();
    await page.screenshot({ path: name("parti-da") });
    // The agent's page (Agents, its gear): its connections, any number, by kind.
    await open();
    await page
      .locator("button", { hasText: /^Agenti/ })
      .first()
      .click();
    await page.locator('button[title="La sua pagina"]').first().click();
    const conn = page.locator(".conn-editor:visible").first();
    await conn.locator(".ui-toggle").first().waitFor();
    await page.waitForTimeout(500);
    await page.mouse.move(viewport.width / 2 + 100, viewport.height / 2);
    await page.mouse.wheel(0, screen === "telefono" ? 700 : 330);
    await page.waitForTimeout(300);
    await page.screenshot({ path: name("collegamenti") });
    // The calendars: Settings > Automations (the computer's; the phone's navigation is another screen).
    if (screen === "computer") {
      await open();
      await page.getByRole("button", { name: "Impostazioni" }).first().click();
      await page.waitForTimeout(1500);
      await page
        .locator(".st-nav-name", { hasText: /^Automa/ })
        .first()
        .click();
      await page.waitForTimeout(800);
      await page
        .locator(".wz-sub:visible", { hasText: "Calendari" })
        .first()
        .scrollIntoViewIfNeeded();
      await page.screenshot({ path: name("calendari") });
    }
    await context.close();
  }
}
await browser.close();
