// 3.9.4: a sub-agent has no mascot of its own (decision of 2026-11-19), it shows the ring in its
// parent's colour: the Coder's conversation with its two sub-agents' tabs, a sub-agent's tab
// open, and Settings › Agents; computer and phone, light and dark. Against the demo server with
// DEMO_SUBSIGN=1. Usage: node subsign-shots.mjs <url> <token> <outdir>   (the Playwright image)
import { mkdir } from "node:fs/promises";
import { chromium } from "playwright-core";

const [url, token, out] = process.argv.slice(2);
await mkdir(out, { recursive: true });
const browser = await chromium.launch();

for (const [device, width, height] of [
  ["computer", 1440, 900],
  ["phone", 390, 844],
])
  for (const scheme of ["light", "dark"]) {
    const page = await browser.newPage({
      viewport: { width, height },
      colorScheme: scheme,
      locale: "it-IT",
    });
    page.on("pageerror", (e) => console.error("pageerror:", e.message));
    const shot = (name) =>
      page.screenshot({ path: `${out}/pagina-${device}-${scheme}-${name}.png` });
    const phone = device === "phone";
    await page.goto(`${url}/#token=${token}`);
    await page.evaluate(() => localStorage.clear());
    await page.goto(`${url}/#token=${token}`);
    await page.waitForSelector(".top");
    await page.waitForTimeout(500);
    const menu = async () => {
      if (phone) {
        await page.locator('button[aria-label="Menu"]').click();
        await page.waitForTimeout(400);
      }
    };
    await menu();
    await page.locator(".bar-item", { hasText: "Demo" }).first().click();
    await page.waitForTimeout(400);
    await page.locator(".session-row .open", { hasText: "Pagina prodotto" }).first().click();
    await page.waitForSelector(".sub-tab");
    await page.waitForTimeout(1200);
    await shot("01-conversation");
    const tabs = page.locator(".sub-tab");
    console.log(`${device} ${scheme}: ${await tabs.count()} tabs, ${await page.locator(".sub-tab svg.sgn").count()} signs, ${await page.locator(".sub-tab svg.masc").count()} faces`);
    if ((await tabs.count()) > 1) {
      await tabs.nth(1).locator(".sub-tab-main").click();
      await page.waitForTimeout(1200);
      await shot("02-subagent-tab");
    }
    await menu();
    await page.locator(".bar-settings").click();
    await page.waitForSelector(".settings");
    await page.locator(".settings-nav .st-nav-item", { hasText: "Agenti" }).first().click();
    await page.waitForTimeout(1200);
    await shot("03-agents");
    console.log(`${device} ${scheme} agents: ${await page.locator("svg.sgn").count()} signs`);
    await page.close();
  }
await browser.close();
