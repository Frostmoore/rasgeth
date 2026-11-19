// A question from the Codex engine (3.9.5): the Chat on Codex asks about a UPS and waits on the
// question card (no bulleted text, no answer before the person's); an option chosen; then, on the
// last pass, the answer sent and Codex going on with it. Dark and light, computer and phone.
// Usage: node codex-ask-shots.mjs <url> <token> <outdir>   (demo with DEMO_CODEX_ASK=1; needs a Chromium)
import { mkdir } from "node:fs/promises";
import { chromium } from "playwright-core";

const [url, token, out] = process.argv.slice(2);
await mkdir(out, { recursive: true });
const browser = await chromium.launch();
const TITLE = "Gruppo di continuità (Codex)";
const passes = [
  ["desk", 1440, 900, "dark"],
  ["desk", 1440, 900, "light"],
  ["phone", 390, 844, "dark"],
  ["phone", 390, 844, "light"],
];

for (const [n, [device, width, height, scheme]] of passes.entries()) {
  const page = await browser.newPage({
    viewport: { width, height },
    colorScheme: scheme,
    locale: "it-IT",
  });
  page.on("pageerror", (e) => console.error("pageerror:", e.message));
  const shot = (name) => page.screenshot({ path: `${out}/pagina-${device}-${scheme}-${name}.png` });
  await page.goto(`${url}/#token=${token}`);
  await page.evaluate(() => localStorage.clear());
  await page.goto(`${url}/#token=${token}`);
  await page.waitForSelector(".bar, .top");
  await page.waitForTimeout(1000);
  for (let i = 0; i < 4 && (await page.locator(".ui-modal-veil").count()); i++) {
    await page.keyboard.press("Escape");
    await page.waitForTimeout(200);
  }
  if (device === "phone") {
    await page.locator('button[aria-label="Menu"]').click();
    await page.waitForTimeout(300);
  }
  await page.getByRole("button", { name: "Chat", exact: true }).first().click();
  await page.waitForTimeout(500);
  await page.getByText(TITLE, { exact: true }).first().click();
  await page.waitForSelector(".question-card .option", { timeout: 15_000 });
  await page.waitForTimeout(500);
  await shot("01-domanda");
  await page
    .locator(".question-card")
    .first()
    .screenshot({
      path: `${out}/pagina-${device}-${scheme}-01b-scheda.png`,
    });
  await page.locator(".question-card .option", { hasText: "300 W" }).click();
  await page.waitForTimeout(300);
  await shot("02-scelta");
  if (n === passes.length - 1) {
    // The answer goes back to Codex, which goes on with it.
    await page.locator(".question-card .permission-actions button.yes").first().click();
    await page.waitForSelector(".bubble.assistant", { timeout: 15_000 });
    await page.waitForTimeout(800);
    await shot("03-risposta");
  }
  await page.close();
}
await browser.close();
