// 3.9.8: God on the Claude subscription (DEMO_CLAUDE_ENGINE=1) switches the machines on and lists
// them in the same turn; the conversation's header shows the plan's limits (5h and 7 days).
// Usage: node engine-tools-shots.mjs <url> <token> <outdir> <title>   (needs a Chromium)
import { mkdir } from "node:fs/promises";
import { chromium } from "playwright-core";

const [url, token, out, title] = process.argv.slice(2);
await mkdir(out, { recursive: true });
const browser = await chromium.launch();
const passes = [
  ["desk", 1440, 900, "dark"],
  ["desk", 1440, 900, "light"],
  ["phone", 390, 844, "dark"],
  ["phone", 390, 844, "light"],
];
for (const [device, width, height, scheme] of passes) {
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
  await page.waitForTimeout(1000);
  for (let i = 0; i < 4 && (await page.locator(".ui-modal-veil").count()); i++) {
    await page.keyboard.press("Escape");
    await page.waitForTimeout(200);
  }
  if (device === "phone") {
    await page.locator('button[aria-label="Menu"]').click();
    await page.waitForTimeout(300);
  }
  await page.getByText(title, { exact: false }).first().click();
  await page.waitForSelector(".bubble.assistant", { timeout: 15_000 });
  await page.waitForTimeout(1200);
  await page.screenshot({ path: `${out}/pagina-${device}-${scheme}-strumenti-stesso-turno.png` });
  await page.close();
}
await browser.close();
