// 3.12.4: Settings > Messages (the secretary for other people): the page with the requests, the
// contacts and the accounts, a conversation, and the WhatsApp and Telegram guides, light and dark,
// computer and phone. Against a demo started with DEMO_SECRETARY=1 DEMO_TOPICS=1.
// Usage: node secretary-shots.mjs <url> <token> <outdir>   (the Playwright image has a Chromium)
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
    const page = await context.newPage();
    page.on("pageerror", (e) => console.error("pageerror:", e.message));
    page.on("console", (m) => m.type() === "error" && console.error("console:", m.text()));
    const name = (n) => `${out}/${screen}-${tag}-${n}.png`;
    await page.goto(`${url}/#token=${token}`);
    await page.waitForSelector(".bar", { timeout: 20000 });
    await page
      .getByRole("button", { name: "Ho capito" })
      .click({ timeout: 4000 })
      .catch(() => {});
    await page.waitForTimeout(1200);
    if (screen === "telefono") await page.locator("button.menu").click();
    await page.locator(".bar-settings").click();
    await page.waitForSelector(".settings");
    await page.waitForTimeout(500);
    if (screen === "telefono") {
      await page.locator("button.st-pick").click();
      await page.locator(".st-sheet-list .st-nav-item", { hasText: "Messaggi" }).click();
    } else {
      await page.locator(".st-nav-item", { hasText: "Messaggi" }).click();
    }
    await page.waitForSelector(".sc-contact", { timeout: 10000 });
    await page.waitForTimeout(600);
    await page.screenshot({ path: name("01-messaggi") });
    await page.locator(".sc-pending").first().scrollIntoViewIfNeeded();
    await page.screenshot({ path: name("02-richieste") });
    // A conversation.
    await page.locator(".sc-contact", { hasText: "Luca" }).click();
    await page.waitForSelector(".sc-thread .sc-msg");
    await page.waitForTimeout(400);
    await page.screenshot({ path: name("03-conversazione") });
    await page.keyboard.press("Escape");
    await page.waitForTimeout(300);
    // The WhatsApp guide: steps checked one by one.
    await page.locator("button.wz-tile", { hasText: "Collega WhatsApp Business" }).click();
    await page.waitForSelector(".sc-step.cur");
    await page.waitForTimeout(2200);
    await page.screenshot({ path: name("04-guida-whatsapp-passo-2") });
    const next = () => page.locator(".sc-step.cur .wz-btn.primary").click();
    await next();
    await page.locator(".sc-step.cur input").fill("1055555555");
    await next();
    await page.locator(".sc-step.cur input").fill("EAAG-wrong-token-0000000000000");
    await page.locator(".sc-step.cur .wz-btn.primary").click();
    await page.waitForSelector(".sc-step.cur .notice.error");
    await page.screenshot({ path: name("05-guida-token-sbagliato") });
    await page.locator(".sc-step.cur input").fill("EAAG-demo-token-0000000000");
    await page.locator(".sc-step.cur .wz-btn.primary").click();
    await page.waitForSelector('.sc-step.cur:has-text("segreto")');
    await page.locator(".sc-step.cur input").fill("0123456789abcdef0123456789abcdef");
    await next();
    await page.waitForSelector(".sc-copy");
    await page.waitForTimeout(500);
    await page.screenshot({ path: name("06-guida-webhook") });
    await page.keyboard.press("Escape");
    await page.waitForTimeout(300);
    // The Telegram guide.
    await page.locator("button.wz-tile", { hasText: "Collega un bot Telegram" }).click();
    await page.waitForSelector(".sc-step.cur");
    await page.waitForTimeout(2200);
    await page.screenshot({ path: name("07-guida-telegram") });
    await context.close();
  }
}
await browser.close();
